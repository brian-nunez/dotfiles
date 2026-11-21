# Go Guardrails Playbook

Concrete Go tooling, linter configuration, AST boundary tests, and CI wiring
used when migrating a Go repository up the Trust Pyramid.

## 1. Local & CI Tooling Parity (`scripts/tools.sh`)

Never rely on unpinned global binaries or mismatched GitHub Actions versions,
and do not pollute `go.mod` with dev-only linter modules.

- Pin every tool version in one script (`scripts/tools.sh`) and install into a
  gitignored `.tools/` directory (`/.tools/` in `.gitignore`):
  - `golangci-lint`: download official release tarball for `darwin`/`linux`
    (`amd64`/`arm64`) and verify against pinned **SHA-256 checksums**.
  - `govulncheck` (`golang.org/x/vuln/cmd/govulncheck@<pinned-version>`)
  - `deadcode` (`golang.org/x/tools/cmd/deadcode@<pinned-version>`)
  - `gremlins` (`github.com/go-gremlins/gremlins/cmd/gremlins@<pinned-version>`)
    installed on demand for mutation testing so regular PR checks stay fast.
- Wire both `Makefile` (`fmt`, `fmt-check`, `lint`, `vuln`, `deadcode`,
  `test-mutation`) and `.github/workflows/ci.yml` through `scripts/tools.sh`.
- Cache `.tools/` in GitHub Actions keyed on `runner.os`, `runner.arch`, and
  `hashFiles('scripts/tools.sh', ...)`.

### Standard `Makefile` targets

- `make tools` — install pinned PR check tools into `.tools/`
- `make fmt` — run pinned `golangci-lint fmt ./...` and `golangci-lint run --fix ./...`
- `make fmt-check` — `golangci-lint fmt --diff ./...` (strict CI check)
- `make vet` — `go vet ./...` plus every non-default build tag (`go vet -tags integration ./...`)
- `make lint` — `golangci-lint run ./...`
- `make vuln` — `govulncheck ./...`
- `make deadcode` — fail if `deadcode -test ./...` prints any unreachable function
- `make test` — `go test -race ./...`
- `make tidy-check` — `go mod tidy -diff`
- `make check` — runs every PR gate in order (`fmt-check vet lint vuln deadcode test test-scripts <drift-checks> tidy-check`)

## 2. Strict `.golangci.yml` (v2)

Include non-default build tags in `run.build-tags` (e.g. `integration`) so test
harnesses are linted with the same rigor as production code.

### Recommended linter set

- **Formatting:** `gofumpt`, `goimports` (with `local-prefixes` set to the
  module path).
- **Architecture & banned APIs:**
  - `depguard`:
    - Forbid `unsafe` everywhere.
    - Restrict `os/exec` in non-test files strictly to the explicit runtime/OS
      adapter files that need it (never allow arbitrary packages to shell out).
    - Forbid `math/rand` and `math/rand/v2` in security/crypto/auth/token
      packages (`crypto/rand` only).
    - Restrict `flag` (or CLI flag frameworks) to CLI entrypoint packages.
    - Restrict raw DB/HTTP/filesystem drivers to adapter layers where applicable.
  - `forbidigo`:
    - Ban `http.DefaultClient`, `http.Get`, `http.Post`, `http.PostForm`,
      `http.Head` in production code (force explicit `*http.Client` with
      timeouts).
    - Ban `time.Sleep` in production code (force context-aware timers/tickers).
- **Security:** `gosec` (command injection, weak crypto, file/dir permissions,
  integer overflow conversions, open redirects, symlink TOCTOU `G122`, unchecked
  slice bounds `G602`, goroutine context leaks `G118`).
- **Correctness & resource safety:** `bodyclose`, `contextcheck`, `copyloopvar`,
  `errorlint`, `exhaustive` (`default-signifies-exhaustive: true`), `intrange`,
  `nilerr`, `nilnil`, `noctx`, `nolintlint` (`allow-unused: false`,
  `require-explanation: true`, `require-specific: true`), `perfsprint`,
  `revive`, `thelper`, `unconvert`, `unparam`, `usestdlibvars`, `whitespace`,
  `misspell`, `gocritic`.
- **Style consistency (optional per repo):** `nlreturn`, `wsl_v5` when the repo
  already follows block-spacing conventions.

### Exclusion hygiene (zero `//nolint` policy)

- Do **not** scatter `//nolint` comments across Go source files.
- Keep `_test.go` exclusions minimal (`forbidigo`, `gosec`, `noctx` where test
  fixtures legitimately use `time.Sleep`, temp files, or helper commands).
- Exclude generated files (`_templ.go`, `*.pb.go`, etc.) only from hand-style
  linters, and verify them with a dedicated regeneration drift check in CI.
- Any rare, genuinely justified `gosec` or `contextcheck` exception belongs in
  `.golangci.yml` under `linters.exclusions.rules` scoped to the exact file path
  and rule ID with a comment explaining why — where `Guardrail audit` reviews
  every change.

## 3. AST Architecture Boundary Tests (`boundary_test.go`)

Complement `depguard` with a fast Go unit test (`go/parser` + `go/ast`) that
runs in `go test`:

1. **`TestPackageArchitectureBoundaries`:**
   - Survey the current graph with:
     ```bash
     go list -json ./...
     ```
   - Declare an explicit `allowedInternalImports` map listing **every**
     production package in the repo and the exact internal packages it may
     import.
   - Fail if any new package is added without being registered in the table.
   - Enforce layer direction (e.g., thin wrappers like `cli`/`http`/`mcp` talk
     only to `core`/`service`; leaf packages like `errs`/`pki`/`domain` import
     zero higher layers).
   - Double-enforce `os/exec` allowlist (exact file paths), `unsafe` ban, and
     `math/rand` ban in security packages.
2. **`TestCoreHasNoUserIO`** (for apps with CLI/web/MCP wrappers over a core):
   - Walk core and lower packages with `go/ast` and forbid `fmt.Print*`,
     `os.Exit`, `os.Stdin`/`Stdout`/`Stderr`, `log.Print*`/`Fatal*`/`Panic*`,
     and `flag`.
3. **`TestNoNolintDirectives`:**
   - Parse every non-generated `.go` file with `parser.ParseComments` and fail
     if any comment begins with `//nolint` or `// nolint`.

## 4. Common Security & Correctness Fixes During Migration

When enabling these checks on an existing Go codebase, fix real issues directly:

- **Open redirects (`gosec G710`):** Validate redirect targets both before and
  after `url.Parse` (reject `//`, `/\`, percent-encoded `/%2f%2f`, schemes,
  hosts, and `\r\n`) and reconstruct a clean relative URI (`&url.URL{Path, RawQuery}`).
- **Symlink TOCTOU in `filepath.WalkDir` (`gosec G122`):** Scope file/dir
  removals inside a managed directory using `os.OpenRoot(dir)` (Go 1.24+) and
  `root.Remove(...)`.
- **Detached shutdown context (`contextcheck` / `gosec G118`):** Use
  `context.WithTimeout(context.WithoutCancel(ctx), d)` instead of
  `context.Background()` in shutdown goroutines.
- **Unchecked stride loops (`gosec G602`):** Change `for i := 0; i < len(s); i += 2`
  to `for i := 0; i+1 < len(s); i += 2` (or slice-advance with `len(s) >= 2`).
- **Context-free listen/sleep (`noctx` / `forbidigo`):** Use
  `(&net.ListenConfig{}).Listen(ctx, ...)` and `time.NewTicker` / `time.NewTimer`
  with `select` on `ctx.Done()`.
- **Ambiguous `(nil, nil)` returns (`nilnil`):** Return `(val, ok, err)` or a
  sentinel error instead.

## 5. CI Uncommitted-Changes & Drift Gate

In `.github/workflows/ci.yml`, finish the check job with a clean working tree
assertion (`git status --porcelain`) after running `fmt-check`, `tidy-check`,
and code-generation checks so stale generated files can never land.
