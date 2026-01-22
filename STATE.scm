;; SPDX-License-Identifier: PMPL-1.0-or-later
;; STATE.scm - Current project state

(define project-state
  `((metadata
      ((version . "0.3.0")
       (schema-version . "1")
       (created . "2025-11-01T00:00:00+00:00")
       (updated . "2026-01-22T16:00:00+00:00")
       (project . "IndieWeb2 Bastion")
       (repo . "indieweb2-bastion")))
    (current-position
      ((phase . "Active development - Consent portal")
       (overall-completion . 70)
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
          (dns-api . ((status . "partial") (completion . 60)
                      (notes . "GraphQL DNS APIs")))))
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
          "⧖ GraphQL DNS API completion"
          "⧖ Nickel config integration"
          "○ WordPress integration")))))))
    (blockers-and-issues
      ((critical . ())
       (high . ())
       (medium . ("GraphQL DNS APIs need completion" "WordPress integration pending"))
       (low . ("Documentation gaps"))))
    (critical-next-actions
      ((immediate . ("Complete GraphQL DNS APIs"))
       (this-week . ("Test Nickel configuration"))
       (this-month . ("WordPress consent flow integration"))))))
