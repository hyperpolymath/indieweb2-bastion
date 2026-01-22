// SPDX-License-Identifier: Apache-2.0
//! GraphQL DNS API server for indieweb2-bastion
//!
//! Features:
//! - Full DNS RR coverage (A, AAAA, CNAME, MX, TXT, SRV, CAA, TLSA, NS, SOA, PTR)
//! - DNSSEC zone management
//! - Blockchain provenance anchoring (Ethereum/Polygon)
//! - SurrealDB graph storage
//! - Reverse DNS lookups

use async_graphql::{http::GraphiQLSource, EmptySubscription, Schema};
use async_graphql_axum::{GraphQLRequest, GraphQLResponse};
use axum::{
    extract::State,
    response::{Html, IntoResponse},
    routing::{get, post},
    Router,
};
use std::net::SocketAddr;
use tower_http::cors::CorsLayer;
use tracing::{info, Level};

mod blockchain;
mod db;
mod dnssec;
mod error;
mod models;
mod policy;
mod resolvers;
mod schema;

use crate::{
    db::Database,
    policy::PolicyEnforcer,
    resolvers::{MutationRoot, QueryRoot},
    schema::AppSchema,
};

use std::sync::Arc;
use tokio::sync::RwLock;

/// Application state shared across handlers
#[derive(Clone)]
pub struct AppState {
    pub db: Database,
    pub policy: Arc<RwLock<PolicyEnforcer>>,
}

/// GraphQL handler
async fn graphql_handler(
    State(state): State<AppState>,
    req: GraphQLRequest,
) -> GraphQLResponse {
    let schema = Schema::build(QueryRoot, MutationRoot, EmptySubscription)
        .data(state.db)
        .data(state.policy)
        .finish();

    schema.execute(req.into_inner()).await.into()
}

/// GraphiQL playground handler
async fn graphiql() -> impl IntoResponse {
    Html(GraphiQLSource::build().endpoint("/graphql").finish())
}

/// Health check handler
async fn health() -> &'static str {
    "OK"
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Initialize tracing
    tracing_subscriber::fmt()
        .with_max_level(Level::INFO)
        .with_target(false)
        .init();

    // Load environment variables
    dotenvy::dotenv().ok();

    info!("Starting GraphQL DNS API server...");

    // Initialize database connection
    let db = Database::connect("memory").await?;
    info!("Connected to SurrealDB");

    // Load Nickel policy configuration
    let policy_path = std::path::Path::new("../policy/curps/policy.ncl");
    let policy_enforcer = match PolicyEnforcer::from_nickel_file(policy_path) {
        Ok(enforcer) => {
            info!("Loaded CURPS policy v{}", enforcer.policy().version);
            Arc::new(RwLock::new(enforcer))
        }
        Err(e) => {
            tracing::warn!("Failed to load policy file ({}), using default policy", e);
            // Create a default policy enforcer for development
            let default_policy = policy::Policy {
                version: "0.1.0".to_string(),
                capabilities: std::collections::HashMap::new(),
                mutations: vec![],
                roles: vec![],
                routes: vec![],
                consent_bindings: vec![],
                constraints: policy::Constraints {
                    require_mtls: false,
                    log_all_mutations: true,
                    max_rate_rpm: 120,
                },
            };
            Arc::new(RwLock::new(PolicyEnforcer {
                policy: default_policy,
                proposals: std::collections::HashMap::new(),
            }))
        }
    };

    // Create application state
    let state = AppState {
        db,
        policy: policy_enforcer,
    };

    // Build router
    let app = Router::new()
        .route("/graphql", post(graphql_handler))
        .route("/graphiql", get(graphiql))
        .route("/health", get(health))
        .layer(CorsLayer::permissive())
        .with_state(state);

    // Start server
    let addr = SocketAddr::from(([0, 0, 0, 0], 8080));
    info!("GraphQL server listening on http://{}", addr);
    info!("GraphiQL playground: http://{}/graphiql", addr);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}
