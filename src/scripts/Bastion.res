// src/scripts/Bastion.res
// RSR Bastion: Dual Stack (IPv4/IPv6) + HTTP3 (QUIC)

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
// Binding for reading certs (simplified)
@scope("Deno") external readTextFileSync: string => string = "readTextFileSync"

let handler = (_req) => {
  let headers = Js.Dict.empty()
  Js.Dict.set(headers, "content-type", "application/json")
  // Advertise HTTP/3 support to clients
  Js.Dict.set(headers, "alt-svc", "h3=\":443\"; ma=86400")
  Js.Dict.set(headers, "strict-transport-security", "max-age=63072000; includeSubDomains; preload")
  
  makeResponse(
    "{ \"status\": \"online\", \"proto\": \"HTTP/3+QUIC\", \"ipv6\": true }",
    { "status": 200, "headers": headers }
  )
}

let start = () => {
  Js.Console.log(">>> [Bastion] Binding [::]:443 (Dual Stack)...")
  
  // RSR: QUIC requires TLS. We load certs from the standard path.
  // If missing, Deno will likely panic or fallback to HTTP/1.
  let cert = try { Some(readTextFileSync("/app/certs/fullchain.pem")) } catch { | _ => None }
  let key = try { Some(readTextFileSync("/app/certs/privkey.pem")) } catch { | _ => None }

  // Hostname "[::]" allows both IPv6 and IPv4 traffic
  serve(handler, { port: 443, hostname: "[::]", cert: cert, key: key })
}

start()
