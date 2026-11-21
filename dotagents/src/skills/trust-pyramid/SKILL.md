---
name: trust-pyramid
description: >-
  Audit a repository's deterministic guardrails and verification stack, identify
  gaps across formatting, linting, vet, architecture boundaries, security, and
  testing layers, produce a phased migration plan, and implement approved waves.
  Go-first in this version. Use when hardening a repo for high-trust
  engineering, tightening linters/boundaries, adding contract/regression/fuzz/
  integration tests, or migrating a codebase toward autonomous PR throughput.
---

# Trust Pyramid

Code generation is cheap; **verification is the bottleneck**. Throughput is a
function of trust, not raw parallelism. Automating a sloppy inner loop only
produces more slop and technical debt at scale.

The goal of this skill is to move a repository toward a **high-trust
engineering environment** where the codebase itself — not memory, prose, or
line-by-line human policing — catches mistakes deterministically before they
can merge:

1. **Codebase Design & Architecture (base):** Package boundaries, narrow APIs,
   and explicit dependency graphs that make cross-layer leaks and footgun usage
   structurally impossible.
2. **Static Analysis, Formatters & Security:** Exact pinned formatters, `vet`
   across all build tags, strict semantic and security linters, banned footgun
   APIs, vulnerability scans, and dead-code checks that turn local runs and CI
   red immediately.
3. **Executable Verification:** Layered tests — unit (`-race`), contract,
   regression, property/invariant, fuzz, real-dependency integration, mutation,
   and thin E2E smoke checks — that prove real behavior independently and defeat
   circular tests (buggy code paired with a test mirroring the same bug).
4. **Tamper-Evident Guardrails:** Deterministic rules protect themselves. Any
   change to linters, formatters, CI workflows, build scripts, boundary tests,
   or any newly added lint/test bypass (`//nolint`, `t.Skip`) triggers a loud
   review alarm and requires explicit maintainer approval.
5. **Prose & Human Review (narrow tip):** Keep written instructions minimal and
   reserve human review for architecture and subjective judgment.

Two operating principles guide every change:

- **Never repeat a correction.** Whenever a bug, bypass, or anti-pattern slips
  through, push enforcement down into a lint rule, boundary test, fuzz seed, or
  regression test so it cannot happen twice.
- **Code is memory.** Agents imitate whatever already exists in the repository.
  Keep the codebase free of dead code, stale patterns, and silent bypasses.

This version targets **Go repositories** ([Go guardrails](references/go.md),
[testing layers](references/testing-layers.md),
[tamper-evident guardrails](references/guardrails.md)). Future language adapters
follow the same five-stage workflow and add their own `references/<lang>.md`.

---

## 1. Survey the repository (read-only)

Inspect the repository before proposing anything. Do not edit files yet.

1. **Stack & layout:** Go version, `go.mod`, entry points (`cmd/`, binaries),
   internal vs. public packages, generated files, and external runtime
   dependencies (Docker, databases, brokers, browsers, CLIs).
2. **Actual dependency DAG:** Extract the live internal import graph (e.g.,
   `go list -json ./...`) and identify natural layers (entry points/wrappers,
   core/domain, adapters/runtime, leaf utilities).
3. **Existing checks & tooling parity:** `Makefile`, scripts, `.golangci.yml`,
   `.github/workflows/`, `.github/CODEOWNERS`, `AGENTS.md`. Note whether local
   and CI run the **exact same pinned tool versions**.
4. **Risk & bypass hotspots:** Scan for `os/exec`, `unsafe`, `math/rand`,
   `flag`, `http.DefaultClient` / `http.Get`, `time.Sleep`, `//nolint`, and
   `t.Skip`.
5. **Current test pyramid:** Inventory which layers already exist and whether
   they run with `-race`, build tags, real dependencies, cleanup assertions, or
   scheduled deep checks:
   - Unit tests (`-race`)
   - Contract tests (CLI, HTTP, RPC/MCP, public library APIs, schemas)
   - Regression tests (pinned bug fixes and security edge cases)
   - Property / invariant tests (determinism, secret non-leak, round-trips)
   - Fuzz tests (parsers, validators, untrusted inputs)
   - Integration tests (real containers/services, no-leak cleanup)
   - Mutation tests & thin E2E smoke tests (if the repo serves a UI)
6. **Security & hygiene posture:** `govulncheck`, `gosec`, `deadcode`,
   generated-file drift checks, and lockfile tidy checks.

Done when every layer has an evidence-backed status: **present**, **weak**
(exists but unpinned, partial, bypassable, or missing tags/`-race`),
**missing**, or **not applicable** (with reason).

---

## 2. Identify gaps against the three tiers

Read [references/go.md](references/go.md),
[references/testing-layers.md](references/testing-layers.md), and
[references/guardrails.md](references/guardrails.md), then map every survey
finding into three priority tiers:

| Tier | Goal | Includes |
| :--- | :--- | :--- |
| **Mandatory** | Non-negotiable floor before trusting high-volume PRs | Pinned local+CI tools, auto-formatter + diff check, `go vet` (all build tags), baseline linters, zero `//nolint`, package-DAG + stdlib import lock (`depguard` + AST `boundary_test.go`), `-race` unit tests, generated-file/lockfile drift checks, guardrail tamper alarm (`CODEOWNERS` + diff check + PR workflow) |
| **Required** | Shift from line-by-line review to high-trust verification | Security linters (`gosec`, `govulncheck`), banned footgun APIs (`forbidigo`), correctness/resource linters (`bodyclose`, `noctx`, `contextcheck`, `exhaustive`, `nilerr`, `nilnil`, `unparam`, `thelper`, `deadcode`), contract tests locking current behavior as-is, regression tests, property/invariant tests, native Go fuzz tests on untrusted boundaries, real-dependency integration tests |
| **Nice to Have** | Deep assurance against circular tests and regressions | Scheduled nightly workflow with longer active fuzzing, mutation testing (`gremlins` with efficacy tracking), thin E2E browser smoke tests (when a web UI exists), benchmarks where hot-path latency matters |

Only recommend layers that fit the repository. Omit items that do not apply and
state why (e.g., skip Playwright E2E for a pure CLI library).

---

## 3. Produce a phased migration plan

Never dump every linter, boundary, and test rewrite into a single risky change
on a large or active repo. Break the gaps into small, ordered **waves** — each
deliverable as its own clean, reviewable PR that leaves `main` greener than
before:

- **Wave 1 — Tooling parity & baseline hygiene:** Pin exact tool versions in
  `scripts/tools.sh` (`.tools/`), wire `Makefile` + CI cache to the same script,
  enable `gofumpt`/`goimports` (`make fmt` / `make fmt-check`), `go vet` across
  all build tags, `go mod tidy -diff`, and generated-file drift checks.
- **Wave 2 — Guardrail tamper alarm & race checks:** Add `CODEOWNERS` on
  guardrail paths, `scripts/guardrail-check.sh` (with self-tests), PR
  `guardrails.yml` alarm workflow, and `-race` on `make test`.
- **Wave 3 — Architecture DAG & stdlib boundaries:** Lock the actual internal
  import DAG in an AST `boundary_test.go`, enforce zero `//nolint` directives,
  and add `depguard` rules restricting `os/exec`, `unsafe`, `math/rand`, and
  `flag` to their exact legitimate locations.
- **Wave 4 — Strict correctness, security & dead-code checks:** Turn on `gosec`,
  `forbidigo`, `bodyclose`, `noctx`, `contextcheck`, `exhaustive`, `nilerr`,
  `nilnil`, `unparam`, `thelper`, `nolintlint`, `govulncheck`, and `deadcode`.
  Fix every real finding cleanly in source; document only genuinely unavoidable
  tool-level exclusions narrowly in `.golangci.yml` (zero `//nolint`).
- **Wave 5 — Contract & regression tests:** Lock the repository's **current**
  public contracts as-is (CLI commands/exit codes, HTTP routes/headers/auth,
  RPC/MCP schemas, exported library contracts) before refactoring anything, and
  add regression tests for every bug or security edge case fixed in Wave 4.
- **Wave 6 — Property/invariant, fuzz & integration tests:** Add deterministic
  invariant tests (determinism, secret non-leak, round-trip), native Go `Fuzz*`
  targets on parsers/validators/security handlers, and harden real-dependency
  integration tests (parallel safety, stdout/stderr hygiene, no-leak cleanup).
- **Wave 7 — Nightly deep verification:** Add scheduled `.github/workflows/nightly.yml`
  for longer active fuzzing, `gremlins` mutation testing on critical packages,
  and thin E2E smoke tests if applicable.

For every wave in the plan, list:
- Exact files to create or modify
- Known findings or refactors expected (grounded in the Stage 1 survey)
- Exact local verification commands and exit criteria
- Whether the wave touches protected guardrail files (expected to trip
  `Guardrail audit` until approved)

---

## 4. Wait for approval

Present the Stage 1 inventory table, the Stage 2 gap analysis, and the Stage 3
phased migration plan cleanly, then **stop and wait for the user's approval**
before modifying any files.

The user may approve:
- All waves at once
- Specific waves (e.g., "do Waves 1–3 first")
- Customizations to boundaries, allowed packages, or exemptions

Do not begin implementing until the user approves (unless the user's initial
request explicitly authorized immediate implementation of named waves).

---

## 5. Implement & verify approved waves

Execute approved waves in order:

1. **Fix root causes, never silence checks.** Do not add `//nolint` or loosen a
   rule just to make CI green. If a real bug surfaces (open redirect, weak
   validation, TOCTOU file deletion, race condition), fix it and pin a
   regression test or fuzz seed.
2. **Preserve current contracts first.** When adding contract tests, lock the
   exact current behavior; flag surprising quirks to the user separately rather
   than silently changing public behavior.
3. **Run the exact CI checks locally** through the pinned tool runner
   (`make check`, `make test-scripts`, `make test-fuzz`, `make test-mutation`,
   `make test-e2e`, and integration tests where relevant).
4. **Verify in CI**, including confirming that `Guardrail audit` alarms when
   guardrail files change and passes cleanly when they do not. Remind the user
   to mark both the main CI job and `Guardrail audit` as **required status
   checks** in GitHub branch protection / rulesets once merged.
5. **Report clearly:** Summarize what shipped per tier, list any real bugs or
   contract quirks caught by the new checks, and note the next wave (or
   recommended follow-ups like mutation efficacy thresholds).
