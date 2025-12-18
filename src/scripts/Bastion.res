// src/scripts/Bastion.res
// RSR Bastion: Privileged Port 443 (Dual Stack + QUIC)

type headers = Js.Dict.t<string>
type request = { url: string, method: string, headers: headers, body: Js.Nullable.t<string> }
type response
type serveOptions = { port: int, hostname: string, cert: option<string>, key: option<string> }

@scope("Deno") external serve: ((request) => Js.Promise.t<response>, serveOptions) => unit = "serve"
@scope("Deno") external readTextFileSync: string => string = "readTextFileSync"
@new external makeResponse: (string, { "status": int, "headers": headers }) => response = "Response"
type fetchOptions = { "method": string, "headers": headers, "body": Js.Nullable.t<string> }
@scope("globalThis") external fetch: (string, fetchOptions) => Js.Promise.t<response> = "fetch"
@new external makeUrl: string => { "pathname": string, "search": string } = "URL"

let handler = async (req) => {
  let secureHeaders = Js.Dict.empty()
  Js.Dict.set(secureHeaders, "Strict-Transport-Security", "max-age=63072000; includeSubDomains; preload")
  // Advertises HTTP/3 on port 443
  Js.Dict.set(secureHeaders, "Alt-Svc", "h3=\":443\"; ma=86400")

  let urlObj = try { makeUrl(req.url) } catch { | _ => { "pathname": "/", "search": "" } }
  let path = urlObj["pathname"]

  // --- ROUTING ---
  if (Js.String.startsWith("/mcp/", path)) {
    let port = switch path {
      | p if Js.String.includes("git", p) => "3001"
      | p if Js.String.includes("fs", p)  => "3002"
      | p if Js.String.includes("salt", p)=> "3003"
      | _ => "0"
    }
    if (port != "0") {
      let proxyUrl = "http://localhost:" ++ port ++ path
      await fetch(proxyUrl, { "method": req.method, "headers": req.headers, "body": req.body })
    } else {
      makeResponse("MCP Not Found", { "status": 404, "headers": secureHeaders })
    }
  } 
  else if (Js.String.startsWith("/ipfs/", path)) {
    let proxyUrl = "http://localhost:8080" ++ path
    Js.Dict.set(secureHeaders, "X-Ipfs-Gateway", "IndieWeb2-Bastion")
    await fetch(proxyUrl, { "method": req.method, "headers": req.headers, "body": req.body })
  }
  else {
    let proxyUrl = "http://localhost:3000" ++ path ++ urlObj["search"]
    await fetch(proxyUrl, { "method": req.method, "headers": req.headers, "body": req.body })
  }
}

let start = () => {
  Js.Console.log(">>> [Bastion] Binding Privileged Port :443...")
  let cert = try { Some(readTextFileSync("/app/certs/fullchain.pem")) } catch { | _ => None }
  let key = try { Some(readTextFileSync("/app/certs/privkey.pem")) } catch { | _ => None }

  serve(handler, { port: 443, hostname: "[::]", cert: cert, key: key })
}

start()
