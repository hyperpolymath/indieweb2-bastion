;; SPDX-License-Identifier: PMPL-1.0-or-later
(state
  (metadata
    (version "0.3.0")
    (last-updated "2026-02-14")
    (status active))
  (project-context
    (name "indieweb2-bastion")
    (purpose "Multi-chain blockchain IndieWeb platform with GraphQL DNS, DNSSEC, consent API, and policy enforcement")
    (completion-percentage 40))
  (components
    (component
      (name "graphql-dns-api")
      (language "rust")
      (status "partial")
      (notes "SQL injection fixed, CORS hardened, identity bypass fixed, BLAKE3 content hashing, kv-mem default"))
    (component
      (name "odns-rs/proxy")
      (language "rust")
      (status "complete")
      (notes "Kyber-1024 KEM + HKDF-SHA3-512 + XChaCha20-Poly1305; replaces Go odns-proxy (ADR-0003)"))
    (component
      (name "odns-rs/resolver")
      (language "rust")
      (status "complete")
      (notes "Kyber-1024 decapsulation + upstream DNS resolution; replaces Go odns-resolver (ADR-0003)"))
    (component
      (name "odns-proxy")
      (language "go")
      (status "deprecated")
      (notes "SUPERSEDED by odns-rs/proxy; pending removal"))
    (component
      (name "odns-resolver")
      (language "go")
      (status "deprecated")
      (notes "SUPERSEDED by odns-rs/resolver; pending removal"))
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
      (notes "CRYPTO-POLICY.scm + CRYPTO-POLICY.adoc + schema.ncl/policy.ncl"))
    (component
      (name "container-stack")
      (language "containerfile/toml")
      (status "complete")
      (notes "stapeln/cerro-torre build, selur seal, vordr run, selur-compose orchestration")))
  (blockers-and-issues
    (blocker "DNSSEC uses Ed25519 interim — target Ed448+Dilithium5")
    (blocker "Dilithium5 not yet integrated in graphql-dns-api")
    (issue "consent-api Ed25519 signing needs PQ upgrade")
    (issue "policy-gate ReScript component is stub")
    (issue "QUIC/HTTP3/IPv6-only transport not started"))
  (critical-next-actions
    (action "Integrate Dilithium5 + Ed448 hybrid signatures across all components")
    (action "Wire BLAKE3+SHAKE3-512 hashing into remaining services")
    (action "Implement policy-gate in ReScript")
    (action "Complete formal verification of crypto protocols (Coq/Isabelle)")
    (action "Migrate to QUIC/HTTP3/IPv6-only transport")
    (action "Enrol in gitbot-fleet, echidna, git-private-farm")))
