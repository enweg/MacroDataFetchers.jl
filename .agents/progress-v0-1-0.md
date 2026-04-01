Current target version: v0.1.0

Completed milestones:
- Milestone 1 - Core types, public skeleton, errors
- Milestone 2 - FRED constructor, `.env` loading, safe display
- Milestone 3 - Generic option normalization
- Milestone 4 - FRED option normalization and validation
- Milestone 5 - Request building and cache keys
- Milestone 6 - HTTP layer, retries, cache usage
- Milestone 7 - Response parsing and DataFrame construction
- Milestone 8 - Public fetch orchestration
- Milestone 9 - Documentation and contributor guide

Current status:
- Milestone 9 implemented and verified with offline tests.

Next milestone to implement:
- Milestone 10 - Live integration tests and CI gating

Implementation notes:
- Set up the package source tree and main module wiring.
- Added the custom error hierarchy, `MemoryCache`, and stub public API entry points in milestone 1.
- Implemented the structured `Fred` source type, constructor-based API key resolution precedence, internal `.env` parsing, `clear_cache!`, and safe display in milestone 2.
- Added generic `FetchOptions`, ISO date parsing, and `on_error` normalization in milestone 3.
- Added `FredObservationsOptions`, provider kwarg validation, enum normalization, unified-to-provider date mapping, and conflict detection in milestone 4.
- Deviated slightly from the original milestone 4 sketch to use a generic `_normalize_provider_options(::AbstractDataSource, ...)` dispatch hook, so later sources can extend normalization without hard-coded type checks in `fetch_data`.
- Added FRED request construction, internal endpoint constants, JSON request enforcement, and canonical cache-key generation in milestone 5.
- Added the `HTTP.jl` dependency and implemented a mockable `_send_request` transport layer with timeout handling, exponential retry backoff, and in-memory cache read/write integration in milestone 6.
- Added the `JSON3.jl` and `DataFrames.jl` dependencies plus strict FRED response parsing, missing-value handling, and exact long-schema `DataFrame` construction in milestone 7.
- Added public `fetch_data` execution, FRED `_fetch_one_series`, multi-series orchestration, duplicate-series warnings, and `on_error = :raise` / `:skip` behavior in milestone 8.
- Added fuller public API docstrings, Documenter pages for getting started / FRED usage / API reference, and a top-level `contributors.md` guide in milestone 9.
- Kept live-test and CI gating work out of scope through milestone 9.

Agent verification to rerun on later milestones:
- `julia --project=. test/runtests.jl`
- `julia --project=. .agents/internal-smoke.jl`
