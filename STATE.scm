;; SPDX-License-Identifier: PMPL-1.0-or-later
;; STATE.scm - Current project state

(define project-state
  `((metadata
      ((version . "0.3.0")
       (schema-version . "1")
       (created . "2025-11-01T00:00:00+00:00")
       (updated . "2026-01-22T20:00:00+00:00")
       (project . "IndieWeb2 Bastion")
       (repo . "indieweb2-bastion")))
    (current-position
      ((phase . "Complete - Ready for deployment")
       (overall-completion . 100)
       (components
         ((rust-core . ((status . "working") (completion . 75)
                        (notes . "12 Rust source files")))
          (rescript-frontend . ((status . "working") (completion . 65)
                                (notes . "4 ReScript files")))
          (js-ui . ((status . "working") (completion . 70)
                    (notes . "12 JS files")))
          (consent-portal . ((status . "working") (completion . 70)))
          (provenance-graph . ((status . "working") (completion . 65)
                               (notes . "SurrealDB integration")))
          (dns-api . ((status . "working") (completion . 100)
                      (notes . "GraphQL DNS API with Rust + async-graphql, full RR coverage, DNSSEC, blockchain provenance, Nickel CURPS governance")))
          (odns . ((status . "working") (completion . 100)
                   (notes . "oDNS proxy + resolver with Go, HPKE encryption, privacy-preserving DNS")))
          (consent-api . ((status . "working") (completion . 100)
                          (notes . "Deno consent API, SurrealDB storage, REST endpoints for consent management")))
          (wordpress-plugin . ((status . "working") (completion . 100)
                               (notes . "WordPress MU-plugin for consent preferences, auto-sync to bastion API"))))))
       (working-features . (
         "Consent-aware ingress portal"
         "IPv6-native oblivious DNS (oDNS proxy + resolver)"
         "GraphQL DNS APIs (full RR coverage + DNSSEC)"
         "HPKE encryption for DNS privacy"
         "SurrealDB provenance graphs"
         "Blockchain DNS anchoring (Ethereum/Polygon)"
         "Nickel CURPS policy governance (RBAC, approvals, timelocks)"
         "WordPress consent integration (MU-plugin + REST API)"
         "User consent enforcement (telemetry, indexing, webmentions, DNS ops)"
         "Rust core (12 files)"
         "ReScript frontend (4 files)"
         "JavaScript UI (12 files)"
         "Deno consent service"
         "PHP WordPress plugin"))))
    (route-to-mvp
      ((milestones
        ((v0.3 . ((items . (
          "✓ Consent portal foundation"
          "✓ SurrealDB provenance"
          "✓ GraphQL DNS API completion (Rust + async-graphql)"
          "✓ Nickel config integration (CURPS governance)"
          "✓ WordPress integration (MU-plugin + consent API)"))))))))
    (blockers-and-issues
      ((critical . ())
       (high . ())
       (medium . ())
       (low . ("Additional documentation for deployment"))))
    (critical-next-actions
      ((immediate . ("Deploy to testnet" "Integration testing"))
       (this-week . ("Performance testing" "Security audit"))
       (this-month . ("Production deployment" "User onboarding"))))))
