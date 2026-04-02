# Contributors Guide

## Package Purpose

`MacroDataFetchers.jl` provides a unified Julia interface for downloading
macroeconomic data from external providers. Version `v0.1.0` is intentionally
scoped to the FRED `series/observations` endpoint.

## Source Tree Overview

```text
src/
├── MacroDataFetchers.jl
├── core/
│   ├── cache.jl
│   ├── errors.jl
│   ├── fetch.jl
│   ├── http.jl
│   ├── options.jl
│   ├── types.jl
│   └── utils.jl
└── sources/
    ├── abstract_source.jl
    └── fred/
        ├── fred.jl
        ├── options.jl
        ├── parse.jl
        ├── request.jl
        └── schema.jl
```

## Development Approach

- Work milestone by milestone according to `.agents/MacroDataFetchers-v0-1-0.md`.
- Update `.agents/progress-v0-1-0.md` after each completed milestone.
- Stop after each milestone and wait for explicit approval before continuing.

## Internal Naming Conventions

- Public API is intentionally small: `AbstractDataSource`, `Fred`, `fetch_data`,
  and `clear_cache!`.
- Internal helper functions are prefixed with `_`.
- Provider-specific logic should live under `src/sources/<provider>/`.

## Documentation Conventions

- Public types and functions should have Julia docstrings compatible with
  Documenter.jl.
- Important architectural helpers should also have internal docstrings.
- User-facing docs live under `docs/src/`.

## Testing Structure

- The main offline package tests live in `test/runtests.jl`.
- Agent-only smoke checks live in `.agents/internal-smoke.jl`.
- Prefer mocked HTTP responses for offline coverage.
- The `.agents/internal-smoke.jl` checks are for coding agents and other
  automated development workflows to validate package wiring and keep internal
  expectations aligned while working through milestones.
- Live integration tests are also defined in `test/runtests.jl`, but they are
  gated by `_should_run_live_tests()` and stay inactive unless explicitly
  enabled.

Run the standard verification commands with:

```bash
julia --project=. test/runtests.jl
julia --project=. .agents/internal-smoke.jl
```

To opt into live integration tests locally:

```bash
FRED_API_KEY=your-fred-api-key RUN_LIVE_TESTS=true julia --project=. test/runtests.jl
```

The live-test gate checks `ENV["FRED_API_KEY"]` and `ENV["RUN_LIVE_TESTS"]`
directly. A local `.env` file is supported by `Fred(...)`, but `.env` alone
does not enable the live test set.

## Local FRED API Key Setup

Choose one of the following:

1. pass `api_key=...` to `Fred(...)`
2. export `FRED_API_KEY` in your shell
3. create a local `.env` file

Supported `.env` examples:

```text
FRED_API_KEY=your-fred-api-key
FRED_API_KEY="your-fred-api-key"
FRED_API_KEY='your-fred-api-key'
```

The internal parser ignores blank lines and lines beginning with `#`.

## GitHub Actions Secrets and Live CI

To enable live tests in GitHub Actions:

1. add `FRED_API_KEY` as a repository or organization secret
2. trigger the `CI` workflow manually with the `run_live_tests` input enabled
3. let the dedicated live-test job expose `FRED_API_KEY` and
   `RUN_LIVE_TESTS=true` to the Julia test process

Keep live tests separated from the default offline suite so normal CI remains
stable when secrets are unavailable.
