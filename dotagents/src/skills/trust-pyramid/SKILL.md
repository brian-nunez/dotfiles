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

Three operating principles guide every change:

- **Never repeat a correction.** Whenever a bug, bypass, or anti-pattern slips
  through, push enforcement down into a lint rule, boundary test, fuzz seed, or
  regression test so it cannot happen twice.
- **Code is memory.** Agents imitate whatever already exists in the repository.
  Keep the codebase free of dead code, stale patterns, and silent bypasses.
- **Every probe becomes a check.** A command you run to gather evidence
  (`govulncheck`, `deadcode`, `go mod tidy -diff`, a bypass grep) proves
  something only once. Each probe ships as a `make` target that local runs and
  CI both execute, so the evidence regenerates on every change.

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
   Classify the repository kind, because it decides the contract layer:
   - **Application:** ships binaries or services. Its contracts are its CLI,
     HTTP, and RPC/MCP surfaces.
   - **Library:** published modules that consumers import and version by
     semver. Its contract is the exported API of every released module,
     compared against the latest release tag.
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
**missing**, or **not applicable** (with reason), and every probe command you
ran is listed with the `make` target that will run it from now on.

---

## 2. Identify gaps against the three tiers

Read [references/go.md](references/go.md),
[references/testing-layers.md](references/testing-layers.md), and
[references/guardrails.md](references/guardrails.md), then map every survey
finding into three priority tiers:

| Tier | Goal | Includes |
| :--- | :--- | :--- |
| **Mandatory** | Non-negotiable floor before trusting high-volume PRs | Pinned local+CI tools, auto-formatter + diff check, `go vet` (all build tags), baseline linters, zero `//nolint`, package-DAG + stdlib import lock (`depguard` + AST `boundary_test.go`), `-race` unit tests, generated-file/lockfile drift checks, guardrail tamper alarm (`CODEOWNERS` + diff check + PR workflow) |
| **Required** | Shift from line-by-line review to high-trust verification | Security linters (`gosec`, `govulncheck`), banned footgun APIs (`forbidigo`), correctness/resource linters (`bodyclose`, `noctx`, `contextcheck`, `exhaustive`, `nilerr`, `nilnil`, `unparam`, `thelper`, `deadcode`), contract tests locking current behavior as-is (for a library: an API compatibility gate against the latest release tag), regression tests, property/invariant tests, native Go fuzz tests on untrusted boundaries, real-dependency integration tests |
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
  add regression tests for every bug or security edge case fixed in Wave 4. A
  library also gets the API compatibility gate
  ([testing layers §2](references/testing-layers.md)).
- **Wave 6 — Property/invariant, fuzz & integration tests:** Add deterministic
  invariant tests (determinism, secret non-leak, round-trip), native Go `Fuzz*`
  targets on parsers/validators/security handlers, and harden real-dependency
  integration tests (parallel safety, stdout/stderr hygiene, no-leak cleanup).
- **Wave 7 — Nightly deep verification:** Add scheduled `.github/workflows/nightly.yml`
  for longer active fuzzing, `gremlins` mutation testing on critical packages,
  and thin E2E smoke tests if applicable.

For every wave in the plan, list:
- The survey probes the wave turns into `make` targets
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

1. **Fix root causes in source.** Make CI green by fixing the code a check
   flags, and keep every rule at its approved strength.
2. **Triage every finding** with the findings protocol below.
3. **Write test oracles from the documentation.** Fuzz, property, and contract
   tests assert what the godoc, README, or spec promises, never what the code
   happens to do ([oracle independence](references/testing-layers.md)). When
   you delegate test writing to subagents, hand each one the documentation
   text as its specification.
4. **Run the exact CI checks locally** through the pinned tool runner
   (`make check`, `make test-scripts`, `make test-fuzz`, `make test-mutation`,
   `make test-e2e`, and integration tests where relevant).
5. **Verify in CI**, including confirming that `Guardrail audit` alarms when
   guardrail files change and passes cleanly when they do not. Remind the user
   to mark both the main CI job and `Guardrail audit` as **required status
   checks** in GitHub branch protection / rulesets once merged.
6. **Report clearly:** Summarize what shipped per tier, list every finding with
   its class and status from the protocol below, and note the next wave (or
   recommended follow-ups like mutation efficacy thresholds).

### Findings protocol

New checks surface findings faster than a wave can absorb them. Classify each
finding by comparing the code with its documentation, then act on the class:

| Class | Test | Action |
| :--- | :--- | :--- |
| **Bug** | Code contradicts its godoc, README, or spec | Report it with a proposed fix and the behavior change it causes. The user decides; the fix ships as its own PR with a regression test. |
| **Quirk** | Behavior is surprising but undocumented | Lock it in a contract test as-is and report it. Changing it is a separate, user-approved PR. |
| **Rule fallout** | Code fails a newly enabled rule | Fix it in a PR that lands before the rule's PR. When the fix changes public behavior, it is a user decision with its own release type. |

A new fuzz or property target that fails today ships together with its fix, or
stacks after the fix PR, so scheduled runs stay green from the day it merges.
