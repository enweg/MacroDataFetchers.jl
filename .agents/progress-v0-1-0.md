Current target version: v0.1.0

Completed milestones:
- Milestone 1 - Core types, public skeleton, errors
- Milestone 2 - FRED constructor, `.env` loading, safe display
- Milestone 3 - Generic option normalization
- Milestone 4 - FRED option normalization and validation

Current status:
- Milestone 4 implemented and verified with offline tests.

Next milestone to implement:
- Milestone 5 - Request building and cache keys

Implementation notes:
- Set up the package source tree and main module wiring.
- Added the custom error hierarchy, `MemoryCache`, and stub public API entry points in milestone 1.
- Implemented the structured `Fred` source type, constructor-based API key resolution precedence, internal `.env` parsing, `clear_cache!`, and safe display in milestone 2.
- Added generic `FetchOptions`, ISO date parsing, and `on_error` normalization in milestone 3.
- Added `FredObservationsOptions`, provider kwarg validation, enum normalization, unified-to-provider date mapping, and conflict detection in milestone 4.
- Deviated slightly from the original milestone 4 sketch to use a generic `_normalize_provider_options(::AbstractDataSource, ...)` dispatch hook, so later sources can extend normalization without hard-coded type checks in `fetch_data`.
- Kept request building and transport behavior out of scope through milestone 4.

Agent verification to rerun on later milestones:
- `julia --project=. test/runtests.jl`
- `julia --project=. .agents/internal-smoke.jl`
