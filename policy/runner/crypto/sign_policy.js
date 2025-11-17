// Deno — Ed25519 sign policy JSON (pure JS)
const [input, sigOut] = Deno.args;
if (!input || !sigOut) {
  console.error("Usage: sign_policy.js <policy.json> <policy.sig>");
  Deno.exit(2);
}
await Deno.mkdir(".tmp", { recursive: true });
const data = await Deno.readFile(input);
const keyPair = await crypto.subtle.generateKey({ name: "Ed25519" }, true, ["sign", "verify"]);
const signatureBuf = await crypto.subtle.sign("Ed25519", keyPair.privateKey, data);
const signature = new Uint8Array(signatureBuf);
await Deno.writeFile(sigOut, signature);
const jwk = await crypto.subtle.exportKey("jwk", keyPair.publicKey);
const signatureB64 = btoa(String.fromCharCode(...signature));
await Deno.writeTextFile(sigOut + ".json", JSON.stringify({ alg: "Ed25519", jwk, signature: signatureB64 }, null, 2));
console.log("Signed:", sigOut, sigOut + ".json");
