# Go Testing Layers Playbook

A high-trust codebase layers multiple independent verification techniques so
mistakes that slip past one layer are caught deterministically by another.

## 1. Unit Tests with Race Detector (Mandatory)

- Always run `go test -race ./...` in `make test` and PR CI.
- Mark every shared test helper with `t.Helper()` (enforced by `thelper`).
- Keep unit tests fast, hermetic, and free of ambient host state (`t.TempDir()`,
  injected clocks, fake/in-memory adapters).

## 2. Contract Tests (Required)

Lock the repository's **current** public contracts as-is before refactoring so
no future PR silently breaks callers or tools. Assume existing behavior is the
contract unless the user explicitly asks to change it; report any surprising
quirks discovered while writing the tests.

Cover every external surface the repository exposes:

- **CLI contract (`internal/cli/contract_test.go`):**
  - Exact command list, non-empty summaries, `help <cmd>` and `<cmd> --help`.
  - Exit-code contract (`0` success, `2` usage/flag errors, `1` domain/runtime
    errors).
  - End-to-end local command flow verifying generated files and secret handling.
- **HTTP / Web contract (`internal/web/contract_test.go`):**
  - Every route's status code and `Content-Type` (including `404` for unknown
    routes).
  - Auth/session/CSRF/Host/Origin guards (`401`, `403`, `421`).
  - Required security headers (`X-Content-Type-Options`, `X-Frame-Options`,
    `Referrer-Policy`, `Content-Security-Policy`) on every response.
  - Redirect safety against open-redirect and CRLF payloads.
- **RPC / MCP / API schema contract (`internal/mcp/contract_test.go`):**
  - Exact registered tool/endpoint names, descriptions, input schemas, and
    safety annotations (`ReadOnlyHint`, `DestructiveHint`, `IdempotentHint`,
    `OpenWorldHint`).
  - Read-only mode guarantee (zero mutating tools registered).
  - Structured JSON response shapes and path/scope escape refusals.
- **Core / library contract (`internal/core/contract_test.go`):**
  - Exported error sentinels (`errors.Is`), resource/config pins, secret
    redaction guarantees, and output mode contracts.

## 3. Regression Tests (Required)

Every bug, security finding, or CI flake that gets fixed receives a dedicated
test case or fuzz seed pinning the exact failure input (e.g., `/%2f%2fevil.com`,
`" .localhost"`, lowercase Docker 29 `error: no such object: <id>`).

## 4. Property & Invariant Tests (Required)

Unit tests often mirror the implementation's assumptions. Invariant tests check
universal laws across randomized valid inputs (using a deterministic seeded
`math/rand/v2.NewPCG` in tests so failures always reproduce):

- **Round-trip invariant:** Generate randomized valid specs/models -> serialize
  -> parse -> validate -> assert exact structural preservation.
- **Determinism invariant:** Render outputs twice from identical inputs ->
  assert every output file's path, permissions, and bytes are identical.
- **Secret non-leak invariant:** Generate unique high-entropy secrets -> run
  renders/exports/scaffolds/error paths -> assert no secret value ever leaks
  into non-secret files, HTML, logs, or responses.
- **Allocator / collision invariant:** Verify port, subnet, or ID allocators
  never collide with reserved/taken entries and stay within bounds.

## 5. Native Go Fuzz Tests (Required)

Add stdlib `Fuzz*` targets (`*testing.F`, zero extra dependencies) on every
parser, validator, merger, and untrusted input boundary:

- Config/YAML/JSON parsers and validators (must never panic; valid docs
  round-trip).
- Security validators: redirect paths, `Host`/`Origin` parsers, hostname/SAN
  certificate constraints, path traversal checks.
- Config mergers / template engines (owned/protected keys can never be
  overridden via case tricks, YAML aliases, merge keys, or custom tags).

Seed corpus runs automatically on every `go test ./...`. Run active fuzzing
via `make test-fuzz` (`FUZZTIME=3s` locally, `FUZZTIME=30s` nightly).

## 6. Real-Dependency Integration Tests (Required)

Test against real binaries and containers (Docker, databases, brokers, proxies)
rather than mocks alone, gated behind `//go:build integration`:

- Run on `main` (and before releases) if too slow for every PR; keep fast
  enough via bounded parallelism (e.g., lab slot semaphore).
- **Always assert zero leaked resources** (containers, networks, volumes) both
  in `t.Cleanup` and as a final `if: always()` CI step.
- **Watch out for real-world CI container pitfalls:**
  - Never capture `docker run -d` container IDs with `CombinedOutput()`; on a
    cold CI runner, image pull progress on stderr pollutes stdout. Use
    `cmd.Output()` (stdout only) and pass `--name`.
  - Avoid unnecessary `docker compose up --build` mid-test when preserving
    container logs across crash-recovery checks; older Compose versions can
    recreate unchanged built services and drop earlier logs.
  - Handle case/message drift across daemon versions (e.g., Docker 29 lowercase
    `error: no such object:`).

## 7. Nightly Deep Verification (Nice to Have)

Add `.github/workflows/nightly.yml` (`schedule` + `workflow_dispatch`) for
checks too slow for per-PR feedback:

- **Active fuzzing:** `make test-fuzz FUZZTIME=30s` across all fuzz targets.
- **Mutation testing (`gremlins`):** Run pinned `gremlins unleash
  --timeout-coefficient 20` against critical pure packages (auth, PKI, secrets,
  spec/parsers, business rules) to verify tests actually fail when code is
  mutated. Once baseline efficacy is known, consider adding
  `--threshold-efficacy <N>`.
- **Thin E2E browser smoke tests (if the repo has a web UI):** Keep a small
  Playwright smoke script (`tests/e2e/smoke.mjs` + `scripts/e2e.sh`) that boots
  the real compiled binary against a throwaway workspace, checks auth, key
  routes, interactive search/data endpoints, and asserts **zero console errors
  and zero uncaught page errors**. Isolate E2E npm deps under `tests/e2e/` and
  gitignore `tests/e2e/node_modules/`.
