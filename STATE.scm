;;; STATE.scm — poly-iac-mcp
;; SPDX-License-Identifier: AGPL-3.0-or-later
;; SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell

(define metadata
  '((version . "1.0.0") (updated . "2025-12-17") (project . "poly-iac-mcp")))

(define current-position
  '((phase . "v1.0 - Core Adapters")
    (overall-completion . 45)
    (components
     ((rsr-compliance ((status . "complete") (completion . 100)))
      (terraform-adapter ((status . "complete") (completion . 100)))
      (pulumi-adapter ((status . "complete") (completion . 100)))
      (crossplane-adapter ((status . "planned") (completion . 0)))
      (cdk-adapter ((status . "planned") (completion . 0)))
      (tests ((status . "pending") (completion . 10)))
      (documentation ((status . "in-progress") (completion . 60)))))))

(define blockers-and-issues
  '((critical ())
    (high-priority (("Add input validation" . "security")))))

(define critical-next-actions
  '((immediate
     (("Add Crossplane adapter" . high)
      ("Add CDK adapter" . high)
      ("Input validation for all handlers" . high)))
    (this-week
     (("Add unit tests" . medium)
      ("Add integration tests" . medium)
      ("Complete documentation" . low)))))

(define roadmap
  '((v1.0 ((status . "current")
           (features . ("Terraform/OpenTofu adapter"
                       "Pulumi adapter"
                       "ReScript implementation"
                       "Deno runtime support"))))
    (v1.1 ((status . "planned")
           (features . ("Crossplane adapter"
                       "Input validation"
                       "Comprehensive tests"))))
    (v1.2 ((status . "planned")
           (features . ("CDK/CDKTF adapter"
                       "SSE transport support"
                       "Workspace management"))))
    (v2.0 ((status . "future")
           (features . ("Multi-project orchestration"
                       "Drift detection"
                       "Cost estimation integration"
                       "Policy enforcement"))))))

(define session-history
  '((snapshots
     ((date . "2025-12-15") (session . "initial") (notes . "SCM files added"))
     ((date . "2025-12-17") (session . "security-review") (notes . "Fixed security.md, guix.scm, deno.json, README, justfile naming")))))

(define state-summary
  '((project . "poly-iac-mcp")
    (completion . 45)
    (blockers . 0)
    (updated . "2025-12-17")))
