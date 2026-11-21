# Tamper-Evident Guardrails

High-trust automation only holds if deterministic checks cannot be quietly
weakened to make a pull request pass. Every guardrail repository needs a
**guardrail tamper alarm** that fires whenever an agent or contributor modifies
enforcement settings or introduces a lint/test bypass.

## 1. Protected Guardrail Paths

Treat all deterministic enforcement files as protected:

- Linter & formatter config: `.golangci.yml` (or language equivalents)
- Build & check orchestration: `Makefile`, `scripts/`
- CI workflows & ownership: `.github/` (including `CODEOWNERS` and workflows)
- Architectural & doc-structure tests: `internal/core/boundary_test.go`,
  `internal/designdocs/` (or repo equivalents)
- Agent contract: `AGENTS.md`

## 2. `.github/CODEOWNERS`

Keep any existing default owner (`* @owner`), and explicitly list every
protected guardrail path so GitHub automatically requests maintainer review
whenever any of them change.

## 3. Diff-Audit Script (`scripts/guardrail-check.sh`)

Create a standalone bash script usable both locally (`make guardrail-check`)
and in CI, paired with throwaway-repo unit tests
(`scripts/guardrail-check_test.sh`, run inside `make test-scripts`):

- Inputs: `--base <ref>`, `--head <ref>`, optional `--markdown`.
- Checks:
  1. Any modified/added/deleted file matching the protected guardrail paths.
  2. Any newly added line (`+...`) in non-generated `.go` files containing
     `//nolint` or `// nolint`.
  3. Any newly added line in `*_test.go` files calling `t.Skip(`, `t.Skipf(`,
     or `t.SkipNow(`.
- Output:
  - Clean exit `0` when no guardrails or bypasses were touched.
  - Loud Markdown or CLI alarm listing every changed guardrail file and bypass
    line, plus a 3-point reviewer checklist:
    1. **Why** is this deterministic rule, linter, boundary, workflow, or bypass
       changing?
    2. Does it **tighten** or **loosen** enforcement?
    3. Apply the `guardrail-approved` label (or set `GUARDRAIL_APPROVED=true`
       locally) once reviewed and approved.
  - Exit `1` unless explicitly approved (`GUARDRAIL_APPROVED=true`).

### Required self-tests (`scripts/guardrail-check_test.sh`)

Run against temporary `git init` repos verifying:
1. Normal code change passes (`exit 0`).
2. Editing `.golangci.yml` trips the alarm (`exit 1`).
3. Editing `boundary_test.go` trips the alarm (`exit 1`).
4. Editing `.github/workflows/ci.yml` trips the alarm (`exit 1`).
5. Adding `//nolint:...` trips the alarm (`exit 1`).
6. Adding `t.Skip(...)` trips the alarm (`exit 1`).
7. Setting `GUARDRAIL_APPROVED=true` clears the alarm (`exit 0`).

## 4. PR Alarm Workflow (`.github/workflows/guardrails.yml`)

- Trigger on `pull_request` with `types: [opened, synchronize, reopened, labeled, unlabeled]`
  so applying or removing the `guardrail-approved` label re-evaluates the check
  immediately.
- Permissions: `contents: read`, `pull-requests: write`.
- Steps:
  1. Checkout with `fetch-depth: 0`.
  2. Run `scripts/guardrail-check.sh --base "$BASE_SHA" --head "$HEAD_SHA" --markdown`.
  3. When triggered, create or update a single PR comment marked with
     `<!-- guardrail-alarm -->` (avoid spamming duplicate comments on force
     pushes).
  4. Fail the job with `::error::` unless the PR carries the
     `guardrail-approved` label.

## 5. GitHub Branch Protection / Rulesets (Final Hard Gate)

A PR workflow alone is only a visible alarm until enforced in GitHub repository
settings. Remind the maintainer to configure branch protection / rulesets on
the default branch requiring:

- The main CI check job (e.g., `Format, lint, vet, security and test`)
- `Guardrail audit`
- Code owner review (from `.github/CODEOWNERS`)
