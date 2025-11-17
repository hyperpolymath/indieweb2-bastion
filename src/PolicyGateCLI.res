open Js

let readFile = (path: string): option<string> =>
  try Some(Node.Fs.readFileSync(path, {"encoding": "utf8"})->Node.Buffer.toString)
  catch _ => None

let exitWith = (code: int, msg: string) => {
  Node.Process.stderr->Node.Stream.Writable.write(msg ++ "\n")->ignore
  Node.Process.exit(code)
}

let () = {
  switch Node.Process.argv->Belt.Array.get(2) {
  | None => exitWith(2, "Usage: node PolicyGateCLI.js <policy.json>")
  | Some(path) =>
    switch readFile(path) {
    | None => exitWith(2, "Unable to read file: " ++ path)
    | Some(s) =>
      switch Json.parse(s) {
      | exception _ => exitWith(2, "Invalid JSON")
      | parsed =>
        switch PolicyDecode.decodePolicy(parsed) {
        | None => exitWith(2, "Policy shape invalid")
        | Some(policy) =>
          let errs = PolicyGate.validateAll(policy)
          if errs->Belt.Array.length == 0 {
            Js.log("Policy validation OK")
          } else {
            errs->Belt.Array.forEach(e => Js.log2("ERROR:", e))
            exitWith(1, "Policy validation failed")
          }
        }
      }
    }
  }
}
