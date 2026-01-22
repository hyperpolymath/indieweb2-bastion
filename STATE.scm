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
      ((phase . "Active development - Consent portal")
       (overall-completion . 85)
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
                      (notes . "GraphQL DNS API with Rust + async-graphql, full RR coverage, DNSSEC, blockchain provenance")))))
       (working-features . (
         "Consent-aware ingress portal"
         "IPv6-native oblivious DNS"
         "GraphQL DNS APIs"
         "SurrealDB provenance graphs"
         "Rust core (12 files)"
         "ReScript frontend (4 files)"
         "JavaScript UI (12 files)"))))
    (route-to-mvp
      ((milestones
        ((v0.3 . ((items . (
          "✓ Consent portal foundation"
          "✓ SurrealDB provenance"
          "✓ GraphQL DNS API completion (Rust + async-graphql)"
          "⧖ Nickel config integration"
          "○ WordPress integration")))))))
    (blockers-and-issues
      ((critical . ())
       (high . ())
       (medium . ("WordPress integration pending" "oDNS proxy/resolver implementation"))
       (low . ("Documentation gaps"))))
    (critical-next-actions
      ((immediate . ("Test GraphQL DNS API" "Deploy to testnet"))
       (this-week . ("Test Nickel configuration"))
       (this-month . ("WordPress consent flow integration"))))))
