// src/scripts/Bastion.res
// RSR Bastion Gateway: Secure Deno Server

// Minimal binding for Deno.serve
type request
type response
type serveOptions = { port: int }

@scope("Deno") external serve: ((request) => response, serveOptions) => unit = "serve"
@new external makeResponse: (string, { "status": int, "headers": Js.Dict.t<string> }) => response = "Response"

let handler = (_req) => {
  let headers = Js.Dict.empty()
  Js.Dict.set(headers, "content-type", "application/json")
  Js.Dict.set(headers, "strict-transport-security", "max-age=63072000; includeSubDomains; preload")
  
  makeResponse(
    "{ \"status\": \"online\", \"system\": \"IndieWeb2 Bastion\", \"compliance\": \"RSR-Active\" }",
    { "status": 200, "headers": headers }
  )
}

let start = () => {
  Js.Console.log(">>> [Bastion] Initializing Secure Gateway on :8443...")
  serve(handler, { port: 8443 })
}

start()
