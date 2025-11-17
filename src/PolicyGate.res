let validateBasics = (p: PolicyTypes.policy): array<string> => {
  let errs = Belt.MutableQueue.make()
  if p.version == "" { Belt.MutableQueue.add(errs, "version must be non-empty") }
  p.routes->Belt.Array.forEach(r =>
    if r.plane == "control" && r.guards->Belt.Array.has("mtls") == false {
      Belt.MutableQueue.add(errs, {"control-plane route requires mtls: " ++ r.path})
    }
  )
  p.constraints.max_rate_rpm > 0 ? () : Belt.MutableQueue.add(errs, "max_rate_rpm must be > 0")
  Belt.MutableQueue.toArray(errs)
}

let validateParadoxExclusion = (p: PolicyTypes.policy): array<string> => {
  let errs = Belt.MutableQueue.make()
  p.roles->Belt.Array.forEach(role =>
    if role.name == "trusted_contributor" && role.privileges->Belt.Array.has("rotate_keys") {
      Belt.MutableQueue.add(errs, "trusted_contributor must not have rotate_keys")
    }
  )
  Belt.MutableQueue.toArray(errs)
}

let validateAll = (p: PolicyTypes.policy): array<string> =>
  Belt.Array.concatMany([
    validateBasics(p),
    validateParadoxExclusion(p),
  ])
