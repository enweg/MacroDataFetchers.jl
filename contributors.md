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

Run the standard verification commands with:

```bash
julia --project=. test/runtests.jl
julia --project=. .agents/internal-smoke.jl
```

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
2. expose that secret to the CI job environment
3. set `RUN_LIVE_TESTS=true` for the job or step that should run live tests

Keep live tests separated from the default offline suite so normal CI remains
stable when secrets are unavailable.
