;; SPDX-License-Identifier: AGPL-3.0-or-later
;; SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
;; ECOSYSTEM.scm — indieweb2-bastion

(ecosystem
  (version "1.0.0")
  (name "indieweb2-bastion")
  (type "project")
  (purpose "IndieWeb2 is a next-generation framework for building audit-grade, consent-aware, and provenance-rich web infrastructure.")

  (position-in-ecosystem
    "Part of hyperpolymath ecosystem. Follows RSR guidelines.")

  (related-projects
    (project (name "rhodium-standard-repositories")
             (url "https://github.com/hyperpolymath/rhodium-standard-repositories")
             (relationship "standard")))

  (what-this-is "IndieWeb2 is a next-generation framework for building audit-grade, consent-aware, and provenance-rich web infrastructure.")
  (what-this-is-not "- NOT exempt from RSR compliance"))
