# CURPS Policy contracts — strict

let String = String
let Bool   = Bool
let Num    = Number

contract CapabilitySet = {
  maintainer          | String
  trusted_contributor | String
  default-consent     | String
}

contract Mutation = {
  name           | String
  description    | String
  approvals      | Num
  timelock_hours | Num
}

contract Role = {
  name        | String
  members     | Array(String)
  privileges  | Array(String)
}

contract Route = {
  path     | String
  plane    | String
  methods  | Array(String)
  guards   | Array(String)
}

contract ConsentDefaults = {
  telemetry | String
  indexing  | String
}

contract ConsentBinding = {
  name         | String
  manifest_ref | String
  required     | Bool
  defaults     | ConsentDefaults
}

contract Constraints = {
  require_mtls      | Bool
  log_all_mutations | Bool
  max_rate_rpm      | Num
}

contract Policy = {
  version          | String
  capabilities     | CapabilitySet
  mutations        | Array(Mutation)
  roles            | Array(Role)
  routes           | Array(Route)
  consent_bindings | Array(ConsentBinding)
  constraints      | Constraints
}

export {
  CapabilitySet,
  Mutation,
  Role,
  Route,
  ConsentDefaults,
  ConsentBinding,
  Constraints,
  Policy
}
