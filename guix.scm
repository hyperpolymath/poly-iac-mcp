;; poly-iac-mcp - Guix Package Definition
;; Run: guix shell -D -f guix.scm

(use-modules (guix packages)
             (guix gexp)
             (guix git-download)
             (guix build-system gnu)
             ((guix licenses) #:prefix license:)
             (gnu packages base))

(define-public poly-iac-mcp
  (package
    (name "poly-iac-mcp")
    (version "1.0.0")
    (source (local-file "." "poly-iac-mcp-checkout"
                        #:recursive? #t
                        #:select? (git-predicate ".")))
    (build-system gnu-build-system)
    (synopsis "Unified MCP server for Infrastructure as Code")
    (description "Multi-tool IaC MCP server supporting Terraform, OpenTofu, Pulumi, Crossplane, and CDK.")
    (home-page "https://github.com/hyperpolymath/poly-iac-mcp")
    (license license:expat)))

;; Return package for guix shell
poly-iac-mcp
