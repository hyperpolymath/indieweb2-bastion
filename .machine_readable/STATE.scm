;; SPDX-License-Identifier: PMPL-1.0-or-later
(state
  (metadata
    (version "0.4.0")
    (last-updated "2026-02-14")
    (status active))
  (project-context
    (name "indieweb2-bastion")
    (purpose "Multi-chain blockchain IndieWeb platform with GraphQL DNS, DNSSEC, consent API, and policy enforcement")
    (completion-percentage 50))
  (components
    (component
      (name "graphql-dns-api")
      (language "rust")
      (status "partial")
      (notes "SQL injection fixed, CORS hardened, identity bypass fixed, BLAKE3 content hashing, kv-mem default, axum 0.8"))
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
      (name "odns-rs/signatures")
      (language "rust")
      (status "complete")
      (notes "Hybrid Ed448+Dilithium5 (CPR-005): 11 tests pass, sign/verify/serialize roundtrip"))
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
      (status "functional")
      (notes "9 validators, crypto compliance checks, Deno runtime, ES module output"))
    (component
      (name "crypto-policy")
      (language "scheme/nickel/asciidoc")
      (status "defined")
      (notes "CRYPTO-POLICY.scm + CRYPTO-POLICY.adoc + schema.ncl/policy.ncl"))
    (component
      (name "container-stack")
      (language "containerfile/toml")
      (status "complete")
      (notes "stapeln/cerro-torre build, selur seal, vordr run, selur-compose orchestration"))
    (component
      (name "fleet-enrollment")
      (language "json/toml")
      (status "complete")
      (notes "gitbot-fleet findings, echidnabot.toml, git-private-farm manifest")))
  (scan-results
    (scan-date "2026-02-14")
    (tool "panic-attack assail")
    (total-findings 3)
    (finding "medium" "CommandInjection" "scripts/interactive_tidy.sh")
    (finding "medium" "PanicPath" "graphql-dns-api/tests/integration_test.rs")
    (finding "medium" "PanicPath" "odns-rs/common/src/crypto.rs"))
  (blockers-and-issues
    (blocker "DNSSEC uses Ed25519 interim — target Ed448+Dilithium5")
    (blocker "Dilithium5 not yet integrated in graphql-dns-api")
    (issue "consent-api Ed25519 signing needs PQ upgrade")
    (issue "QUIC/HTTP3/IPv6-only transport not started"))
  (critical-next-actions
    (action "Integrate Ed448+Dilithium5 hybrid signatures into graphql-dns-api DNSSEC")
    (action "Wire BLAKE3+SHAKE3-512 hashing into remaining services")
    (action "Complete formal verification of crypto protocols (Coq/Isabelle)")
    (action "Migrate to QUIC/HTTP3/IPv6-only transport")
    (action "Remove deprecated Go code")))
