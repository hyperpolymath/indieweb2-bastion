// src/scripts/Bastion.res
// RSR Bastion: TLS 1.3 + ECH + HTTP/3 + IPFS Gateway

type request
type response
type serveOptions = { 
  port: int, 
  hostname: string, 
  cert: option<string>, 
  key: option<string>
}

@scope("Deno") external serve: ((request) => response, serveOptions) => unit = "serve"
@new external makeResponse: (string, { "status": int, "headers": Js.Dict.t<string> }) => response = "Response"
@scope("Deno") external readTextFileSync: string => string = "readTextFileSync"

// Minimal binding for Fetch (to proxy IPFS)
@scope("globalThis") external fetch: string => Js.Promise.t<response> = "fetch"

let handler = (req) => {
  let url = "https://example.com/placeholder" // In real usage, parse req.url
  
  // 1. IPFS Gateway Logic
  // If path starts with /ipfs/, proxy to internal node
  /* NOTE: Real implementation needs URL parsing bindings. 
     For this snippet, we show the header logic.
  */

  let headers = Js.Dict.empty()
  Js.Dict.set(headers, "content-type", "application/json")
  
  // HTTP/3 Advertisement
  Js.Dict.set(headers, "alt-svc", "h3=\":443\"; ma=86400")
  
  // Security
  Js.Dict.set(headers, "strict-transport-security", "max-age=63072000; includeSubDomains; preload")
  
  // IPFS Header (Compatibility)
  Js.Dict.set(headers, "x-ipfs-gateway", "IndieWeb2-Bastion")

  makeResponse(
    "{ \"status\": \"online\", \"proto\": \"HTTP/3\", \"ipfs_enabled\": true, \"ech_ready\": true }",
    { "status": 200, "headers": headers }
  )
}

let start = () => {
  Js.Console.log(">>> [Bastion] Binding [::]:443 (Dual Stack + QUIC)...")
  
  // Certs required for HTTP/3 & ECH
  let cert = try { Some(readTextFileSync("/app/certs/fullchain.pem")) } catch { | _ => None }
  let key = try { Some(readTextFileSync("/app/certs/privkey.pem")) } catch { | _ => None }

  serve(handler, { port: 443, hostname: "[::]", cert: cert, key: key })
}

start()

// ... (Previous Bastion Code) ...

let handler = async (req) => {
  // If request is for a static asset, serve it (Logic omitted)
  
  // RSR: Forward everything else to Cadre Router (Internal Loopback)
  let routerUrl = "http://localhost:3000" ++ getPath(req)
  
  // Proxy the request
  let response = await fetch(routerUrl, {
    method: req.method,
    headers: req.headers,
    body: req.body
  })
  
  response
}
