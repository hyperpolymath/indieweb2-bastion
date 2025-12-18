let NonEmptyString = contract.from_predicate (fun s => if builtins.is_string s then string.length s > 0 else false)
let Port = contract.from_predicate (fun p => if builtins.is_number p then p >= 1 && p <= 65535 else false)
let AuditLevel = [| 'Trace, 'Debug, 'Info, 'Warn, 'Error, 'Critical, 'Audit |]
let TlsVersion = [| 'v1_2, 'v1_3 |]

{
  bastion = {
    meta = { name = "indieweb2-bastion", version = "0.1.0-alpha", environment = "production" },
    # UPDATED: Port 443
    network = { host = "0.0.0.0", port | Port = 443, fallback_port | Port = 8080 },
    security = { min_tls_version | TlsVersion = 'v1_3, headers = { strict_transport_security = "max-age=63072000", content_security_policy = "default-src 'self'" } },
    logging = { level | AuditLevel = 'Audit, provenance = { enabled = true, endpoint = "ws://surrealdb:8000/rpc" } }
  }
}
