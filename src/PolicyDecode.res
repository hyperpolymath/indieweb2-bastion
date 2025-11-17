open Js

let getString = (obj: Json.t, key: string): option<string> =>
  switch Json.classify(obj) {
  | JSONObject(o) =>
    switch Dict.get(o, key) {
    | Some(v) =>
      switch Json.classify(v) {
      | JSONString(s) => Some(s)
      | _ => None
      }
    | None => None
    }
  | _ => None
  }

let getBool = (obj: Json.t, key: string): option<bool> =>
  switch Json.classify(obj) {
  | JSONObject(o) =>
    switch Dict.get(o, key) {
    | Some(v) =>
      switch Json.classify(v) {
      | JSONBoolean(b) => Some(b)
      | _ => None
      }
    | None => None
    }
  | _ => None
  }

let getInt = (obj: Json.t, key: string): option<int> =>
  switch Json.classify(obj) {
  | JSONObject(o) =>
    switch Dict.get(o, key) {
    | Some(v) =>
      switch Json.classify(v) {
      | JSONNumber(n) => Some(Belt.Float.toInt(n))
      | _ => None
      }
    | None => None
    }
  | _ => None
  }

let getArray = (obj: Json.t, key: string): option<array<Json.t>> =>
  switch Json.classify(obj) {
  | JSONObject(o) =>
    switch Dict.get(o, key) {
    | Some(v) =>
      switch Json.classify(v) {
      | JSONArray(a) => Some(a)
      | _ => None
      }
    | None => None
    }
  | _ => None
  }

let getObject = (obj: Json.t, key: string): option<Json.t> =>
  switch Json.classify(obj) {
  | JSONObject(o) => Dict.get(o, key)
  | _ => None
  }

let decodeCapabilities = (obj: Json.t): option<PolicyTypes.capabilitySet> => {
  let maintainer = getString(obj, "maintainer")
  let tc = getString(obj, "trusted_contributor")
  let dc = getString(obj, "default-consent")
  switch (maintainer, tc, dc) {
  | (Some(m), Some(t), Some(d)) => Some({
      maintainer: m,
      trusted_contributor: t,
      default_consent: d,
    })
  | _ => None
  }
}

let decodeMutation = (obj: Json.t): option<PolicyTypes.mutation> => {
  switch (getString(obj, "name"), getString(obj, "description"), getInt(obj, "approvals"), getInt(obj, "timelock_hours")) {
  | (Some(name), Some(desc), Some(approvals), Some(hours)) =>
    Some({name, description: desc, approvals, timelock_hours: hours})
  | _ => None
  }
}

let decodeRole = (obj: Json.t): option<PolicyTypes.role> => {
  let members =
    switch getArray(obj, "members") {
    | Some(a) => a->Belt.Array.keepMap(v =>
        switch Json.classify(v) {
        | JSONString(s) => Some(s)
        | _ => None
        }
      )
    | None => [||]
    }
  let privileges =
    switch getArray(obj, "privileges") {
    | Some(a) => a->Belt.Array.keepMap(v =>
        switch Json.classify(v) {
        | JSONString(s) => Some(s)
        | _ => None
        }
      )
    | None => [||]
    }
  switch getString(obj, "name") {
  | Some(name) => Some({name, members, privileges})
  | None => None
  }
}

let decodeRoute = (obj: Json.t): option<PolicyTypes.route> => {
  let methods =
    switch getArray(obj, "methods") {
    | Some(a) => a->Belt.Array.keepMap(v =>
        switch Json.classify(v) {
        | JSONString(s) => Some(s)
        | _ => None
        }
      )
    | None => [||]
    }
  let guards =
    switch getArray(obj, "guards") {
    | Some(a) => a->Belt.Array.keepMap(v =>
        switch Json.classify(v) {
        | JSONString(s) => Some(s)
        | _ => None
        }
      )
    | None => [||]
    }
  switch (getString(obj, "path"), getString(obj, "plane")) {
  | (Some(path), Some(plane)) => Some({path, plane, methods, guards})
  | _ => None
  }
}

let decodeConsentDefaults = (obj: Json.t): option<PolicyTypes.consentDefaults> =>
  switch (getString(obj, "telemetry"), getString(obj, "indexing")) {
  | (Some(telemetry), Some(indexing)) => Some({telemetry, indexing})
  | _ => None
  }

let decodeConsentBinding = (obj: Json.t): option<PolicyTypes.consentBinding> => {
  let defaults = switch getObject(obj, "defaults") {
  | Some(o) => decodeConsentDefaults(o)
  | None => None
  }
  switch (getString(obj, "name"), getString(obj, "manifest_ref"), getBool(obj, "required"), defaults) {
  | (Some(name), Some(manifest_ref), Some(required), Some(defaults)) =>
    Some({name, manifest_ref, required, defaults})
  | _ => None
  }
}

let decodeConstraints = (obj: Json.t): option<PolicyTypes.constraints> =>
  switch (getBool(obj, "require_mtls"), getBool(obj, "log_all_mutations"), getInt(obj, "max_rate_rpm")) {
  | (Some(require_mtls), Some(log_all_mutations), Some(max_rate_rpm)) =>
    Some({require_mtls, log_all_mutations, max_rate_rpm})
  | _ => None
  }

let decodePolicy = (obj: Json.t): option<PolicyTypes.policy> => {
  let capabilities = getObject(obj, "capabilities")->Belt.Option.flatMap(decodeCapabilities)
  let mutations =
    switch getArray(obj, "mutations") {
    | Some(a) => a->Belt.Array.keepMap(decodeMutation)
    | None => [||]
    }
  let roles =
    switch getArray(obj, "roles") {
    | Some(a) => a->Belt.Array.keepMap(decodeRole)
    | None => [||]
    }
  let routes =
    switch getArray(obj, "routes") {
    | Some(a) => a->Belt.Array.keepMap(decodeRoute)
    | None => [||]
    }
  let consent_bindings =
    switch getArray(obj, "consent_bindings") {
    | Some(a) => a->Belt.Array.keepMap(decodeConsentBinding)
    | None => [||]
    }
  let constraints = getObject(obj, "constraints")->Belt.Option.flatMap(decodeConstraints)

  switch (getString(obj, "version"), capabilities, constraints) {
  | (Some(version), Some(capabilities), Some(constraints)) =>
    Some({
      version,
      capabilities,
      mutations,
      roles,
      routes,
      consent_bindings,
      constraints,
    })
  | _ => None
  }
}
