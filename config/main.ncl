# RSR Configuration Schema v1.0
# Enforces "Audit-Grade" defaults.

let NonEmptyString = contract.from_predicate (fun s => 
  if builtins.is_string s then string.length s > 0 else false
)

let Port = contract.from_predicate (fun p => 
  if builtins.is_number p then p >= 1 && p <= 65535 else false
)

# The Rhodium Audit Level Contract
let AuditLevel = [| 'Trace, 'Debug, 'Info, 'Warn, 'Error, 'Critical, 'Audit |]

# Tls Version Contract (RSR strictness: 1.2 is legacy, 1.3 is standard)
let TlsVersion = [| 'v1_2, 'v1_3 |]

# Schema Definition
{
  bastion = {
    meta = {
      name = "indieweb2-bastion",
      version = "0.1.0-alpha",
      environment | default = "production",
    },

    network = {
      host | NonEmptyString | default = "0.0.0.0",
      # Default to 8443 as per RSR standard for secure gateways
      port | Port | default = 8443,
      # Fallback port if 8443 is privileged/taken
      fallback_port | Port | default = 8080,
      
      # Oblivious DNS Upstream
      odns_upstream | NonEmptyString | default = "https://odns.indieweb2.net/dns-query",
    },

    security = {
      # RSR mandates TLS 1.3 for all ingress
      min_tls_version | TlsVersion | default = 'v1_3,
      
      # Headers strictly enforcing policy
      headers = {
        strict_transport_security = "max-age=63072000; includeSubDomains; preload",
        content_security_policy   = "default-src 'self'; script-src 'self' 'wasm-unsafe-eval';",
        x_content_type_options    = "nosniff",
      },
      
      auth = {
        # Integration with IndieAuth
        provider_url | NonEmptyString | default = "https://auth.indieweb2.net",
        required_scope | NonEmptyString | default = "bastion:admin",
      }
    },

    # The "Audit-Grade" Logging Config
    logging = {
      level | AuditLevel | default = 'Audit,
      
      # Provenance Graph Integration (SurrealDB)
      provenance = {
        enabled | bool | default = true,
        endpoint | NonEmptyString | default = "ws://surrealdb:8000/rpc",
        namespace | NonEmptyString | default = "indieweb2",
        database | NonEmptyString | default = "provenance_logs",
      }
    },
    
    # Progressive Web App configuration
    pwa = {
      enabled | bool | default = true,
      manifest_path | NonEmptyString | default = "/manifest.json",
      service_worker_strategy | [| 'NetworkFirst, 'CacheFirst, 'StaleWhileRevalidate |] | default = 'NetworkFirst,
    }
  }
}
