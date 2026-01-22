// SPDX-License-Identifier: Apache-2.0
//! SurrealDB integration for DNS records and provenance graph

use crate::{
    error::{AppError, Result},
    models::{BlockchainProvenance, DNSRecord, DNSRecordType, DNSSECZone, RecordTypeCount},
};
use async_graphql::ID;
use surrealdb::{
    engine::local::{Db, RocksDb},
    Surreal,
};

/// Database connection wrapper
#[derive(Clone)]
pub struct Database {
    db: Surreal<Db>,
}

impl Database {
    /// Connect to SurrealDB
    pub async fn connect(path: &str) -> Result<Self> {
        let db = if path == "memory" {
            Surreal::new::<surrealdb::engine::local::Mem>(()).await?
        } else {
            Surreal::new::<RocksDb>(path).await?
        };

        // Use namespace and database
        db.use_ns("indieweb2").use_db("dns").await?;

        // Initialize schema
        Self::init_schema(&db).await?;

        Ok(Self { db })
    }

    /// Initialize database schema
    async fn init_schema(db: &Surreal<Db>) -> Result<()> {
        // DNS records table
        db.query(
            r#"
            DEFINE TABLE IF NOT EXISTS dns_records SCHEMAFULL;
            DEFINE FIELD IF NOT EXISTS name ON dns_records TYPE string;
            DEFINE FIELD IF NOT EXISTS type ON dns_records TYPE string;
            DEFINE FIELD IF NOT EXISTS ttl ON dns_records TYPE int;
            DEFINE FIELD IF NOT EXISTS value ON dns_records TYPE string;
            DEFINE FIELD IF NOT EXISTS dnssec ON dns_records TYPE bool;
            DEFINE FIELD IF NOT EXISTS rrsig ON dns_records TYPE option<string>;
            DEFINE FIELD IF NOT EXISTS blockchain_tx_hash ON dns_records TYPE option<string>;
            DEFINE FIELD IF NOT EXISTS created_at ON dns_records TYPE datetime;
            DEFINE FIELD IF NOT EXISTS updated_at ON dns_records TYPE datetime;

            DEFINE INDEX IF NOT EXISTS name_idx ON dns_records COLUMNS name;
            DEFINE INDEX IF NOT EXISTS type_idx ON dns_records COLUMNS type;
        "#,
        )
        .await?;

        // DNSSEC zones table
        db.query(
            r#"
            DEFINE TABLE IF NOT EXISTS dnssec_zones SCHEMAFULL;
            DEFINE FIELD IF NOT EXISTS zone ON dnssec_zones TYPE string;
            DEFINE FIELD IF NOT EXISTS enabled ON dnssec_zones TYPE bool;
            DEFINE FIELD IF NOT EXISTS ksk ON dnssec_zones TYPE option<string>;
            DEFINE FIELD IF NOT EXISTS zsk ON dnssec_zones TYPE option<string>;
            DEFINE FIELD IF NOT EXISTS ds_record ON dnssec_zones TYPE option<string>;
            DEFINE FIELD IF NOT EXISTS last_rotation ON dnssec_zones TYPE option<datetime>;

            DEFINE INDEX IF NOT EXISTS zone_idx ON dnssec_zones COLUMNS zone UNIQUE;
        "#,
        )
        .await?;

        // Blockchain provenance table
        db.query(
            r#"
            DEFINE TABLE IF NOT EXISTS blockchain_provenance SCHEMAFULL;
            DEFINE FIELD IF NOT EXISTS record_id ON blockchain_provenance TYPE string;
            DEFINE FIELD IF NOT EXISTS content_hash ON blockchain_provenance TYPE string;
            DEFINE FIELD IF NOT EXISTS network ON blockchain_provenance TYPE string;
            DEFINE FIELD IF NOT EXISTS tx_hash ON blockchain_provenance TYPE string;
            DEFINE FIELD IF NOT EXISTS block_number ON blockchain_provenance TYPE int;
            DEFINE FIELD IF NOT EXISTS timestamp ON blockchain_provenance TYPE datetime;

            DEFINE INDEX IF NOT EXISTS record_idx ON blockchain_provenance COLUMNS record_id;
        "#,
        )
        .await?;

        Ok(())
    }

    /// Create a new DNS record
    pub async fn create_record(&self, record: DNSRecord) -> Result<DNSRecord> {
        let created: Option<DNSRecord> = self
            .db
            .create("dns_records")
            .content(&record)
            .await?
            .into_iter()
            .next();

        created.ok_or_else(|| AppError::Internal("Failed to create record".to_string()))
    }

    /// Get DNS record by ID
    pub async fn get_record(&self, id: &str) -> Result<DNSRecord> {
        let record: Option<DNSRecord> = self
            .db
            .select(("dns_records", id))
            .await?;

        record.ok_or_else(|| AppError::RecordNotFound(id.to_string()))
    }

    /// Query DNS records
    pub async fn query_records(
        &self,
        name: Option<String>,
        record_type: Option<DNSRecordType>,
        limit: i32,
        offset: i32,
    ) -> Result<Vec<DNSRecord>> {
        let mut query = String::from("SELECT * FROM dns_records");
        let mut conditions = Vec::new();

        if let Some(name) = name {
            conditions.push(format!("name = '{}'", name));
        }

        if let Some(record_type) = record_type {
            conditions.push(format!("type = '{:?}'", record_type));
        }

        if !conditions.is_empty() {
            query.push_str(&format!(" WHERE {}", conditions.join(" AND ")));
        }

        query.push_str(&format!(" LIMIT {} START {}", limit, offset));

        let mut result = self.db.query(&query).await?;
        let records: Vec<DNSRecord> = result.take(0)?;

        Ok(records)
    }

    /// Update DNS record
    pub async fn update_record(&self, id: &str, record: DNSRecord) -> Result<DNSRecord> {
        let updated: Option<DNSRecord> = self
            .db
            .update(("dns_records", id))
            .content(&record)
            .await?;

        updated.ok_or_else(|| AppError::RecordNotFound(id.to_string()))
    }

    /// Delete DNS record
    pub async fn delete_record(&self, id: &str) -> Result<bool> {
        let _: Option<DNSRecord> = self.db.delete(("dns_records", id)).await?;
        Ok(true)
    }

    /// Get DNSSEC zone configuration
    pub async fn get_dnssec_zone(&self, zone: &str) -> Result<DNSSECZone> {
        let mut result = self
            .db
            .query("SELECT * FROM dnssec_zones WHERE zone = $zone")
            .bind(("zone", zone))
            .await?;

        let zones: Vec<DNSSECZone> = result.take(0)?;
        zones
            .into_iter()
            .next()
            .ok_or_else(|| AppError::ZoneNotFound(zone.to_string()))
    }

    /// Create or update DNSSEC zone
    pub async fn upsert_dnssec_zone(&self, zone: DNSSECZone) -> Result<DNSSECZone> {
        let created: Option<DNSSECZone> = self
            .db
            .upsert(("dnssec_zones", &zone.zone))
            .content(&zone)
            .await?;

        created.ok_or_else(|| AppError::Internal("Failed to upsert zone".to_string()))
    }

    /// Store blockchain provenance
    pub async fn store_provenance(&self, provenance: BlockchainProvenance) -> Result<BlockchainProvenance> {
        let created: Option<BlockchainProvenance> = self
            .db
            .create("blockchain_provenance")
            .content(&provenance)
            .await?
            .into_iter()
            .next();

        created.ok_or_else(|| AppError::Internal("Failed to store provenance".to_string()))
    }

    /// Get blockchain provenance for a record
    pub async fn get_provenance(&self, record_id: &str) -> Result<BlockchainProvenance> {
        let mut result = self
            .db
            .query("SELECT * FROM blockchain_provenance WHERE record_id = $record_id")
            .bind(("record_id", record_id))
            .await?;

        let provenances: Vec<BlockchainProvenance> = result.take(0)?;
        provenances
            .into_iter()
            .next()
            .ok_or_else(|| AppError::RecordNotFound(format!("No provenance for record {}", record_id)))
    }

    /// Get DNS statistics
    pub async fn get_statistics(&self) -> Result<(i32, Vec<RecordTypeCount>, i32, i32)> {
        // Total records
        let mut total_result = self.db.query("SELECT count() FROM dns_records GROUP ALL").await?;
        let total: Option<i32> = total_result.take("count")?;
        let total_records = total.unwrap_or(0);

        // Records by type
        let mut type_result = self
            .db
            .query("SELECT type, count() FROM dns_records GROUP BY type")
            .await?;
        let type_counts: Vec<RecordTypeCount> = type_result.take(0)?;

        // DNSSEC zones
        let mut dnssec_result = self
            .db
            .query("SELECT count() FROM dnssec_zones WHERE enabled = true GROUP ALL")
            .await?;
        let dnssec: Option<i32> = dnssec_result.take("count")?;
        let dnssec_zones = dnssec.unwrap_or(0);

        // Blockchain anchored
        let mut blockchain_result = self
            .db
            .query("SELECT count() FROM dns_records WHERE blockchain_tx_hash IS NOT NULL GROUP ALL")
            .await?;
        let blockchain: Option<i32> = blockchain_result.take("count")?;
        let blockchain_anchored = blockchain.unwrap_or(0);

        Ok((total_records, type_counts, dnssec_zones, blockchain_anchored))
    }
}
