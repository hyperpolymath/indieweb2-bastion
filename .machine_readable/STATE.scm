;; SPDX-License-Identifier: PMPL-1.0-or-later
(state
  (metadata
    (version "0.2.0")
    (last-updated "2026-02-14")
    (status active))
  (project-context
    (name "indieweb2-bastion")
    (purpose "Multi-chain blockchain IndieWeb platform with GraphQL DNS, DNSSEC, consent API, and policy enforcement")
    (completion-percentage 35))
  (components
    (component
      (name "graphql-dns-api")
      (language "rust")
      (status "partial")
      (notes "SQL injection fixed, CORS hardened, identity bypass fixed, BLAKE3 content hashing"))
    (component
      (name "odns-proxy")
      (language "go")
      (status "deprecated")
      (notes "Go is BANNED per language policy; rewrite in Rust planned (ADR-0003)"))
    (component
      (name "odns-resolver")
      (language "go")
      (status "deprecated")
      (notes "Go is BANNED per language policy; rewrite in Rust planned (ADR-0003)"))
    (component
      (name "consent-api")
      (language "deno")
      (status "production")
      (notes "Ed25519 signing — needs Ed448+Dilithium5 upgrade per CRYPTO-POLICY.adoc"))
    (component
      (name "webmention-rate-limiter")
      (language "rust")
      (status "partial")
      (notes "Rate limiting functional; no direct crypto usage"))
    (component
      (name "policy-gate")
      (language "rescript")
      (status "stub")
      (notes "Not yet implemented"))
    (component
      (name "crypto-policy")
      (language "scheme/nickel/asciidoc")
      (status "defined")
      (notes "CRYPTO-POLICY.scm + CRYPTO-POLICY.adoc + schema.ncl/policy.ncl")))
  (blockers-and-issues
    (blocker "Go rewrite needed for odns-proxy and odns-resolver (ADR-0003)")
    (blocker "DNSSEC uses Ed25519 interim — target Ed448+Dilithium5")
    (blocker "Post-quantum crypto libraries not yet integrated (Kyber, Dilithium)")
    (issue "consent-api Ed25519 signing needs PQ upgrade")
    (issue "policy-gate ReScript component is stub"))
  (critical-next-actions
    (action "Implement oDNS Rust rewrite with Kyber-1024 + HKDF-SHAKE512")
    (action "Integrate pqcrypto crates for Dilithium5 + Kyber-1024")
    (action "Implement policy-gate in ReScript")
    (action "Complete formal verification of crypto protocols (Coq/Isabelle)")
    (action "Migrate to QUIC/HTTP3/IPv6-only transport")))
