# IndieWeb2 CURPS policy — v0.1 strict

let schema = import "./schema.ncl"

let policy = schema.Policy {
  version = "0.1.0",

  capabilities = {
    maintainer          = "stub",
    trusted_contributor = "stub",
    default-consent     = "stub",
  },

  mutations = [
    {
      name = "rotate_keys",
      description = "Rotate bastion, resolver, and SDP credentials",
      approvals = 2,
      timelock_hours = 24,
    },
    {
      name = "mutate_dns",
      description = "Apply GraphQL DNS mutations (records/zones)",
      approvals = 1,
      timelock_hours = 1,
    },
  ],

  roles = [
    {
      name = "maintainer",
      members = ["identity:alice", "identity:jonathan"],
      privileges = ["publish_manifest", "rotate_keys", "mutate_dns"],
    },
    {
      name = "trusted_contributor",
      members = [],
      privileges = ["publish_manifest"],
    },
  ],

  routes = [
    {
      path = "/.well-known",
      plane = "data",
      methods = ["GET"],
      guards = ["waf", "policy-gate"],
    },
    {
      path = "/odns",
      plane = "data",
      methods = ["GET","POST"],
      guards = ["mtls", "waf", "policy-gate"],
    },
    {
      path = "/graphql-dns",
      plane = "control",
      methods = ["POST"],
      guards = ["mtls", "policy-gate"],
    },
  ],

  consent_bindings = [
    {
      name = "default-consent",
      manifest_ref = "ipfs://QmConsentManifest001",
      required = true,
      defaults = { telemetry = "off", indexing = "on" },
    },
  ],

  constraints = {
    require_mtls = true,
    log_all_mutations = true,
    max_rate_rpm = 120,
  },
}

export policy
