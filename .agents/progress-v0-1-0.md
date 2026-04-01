Current target version: v0.1.0

Completed milestones:
- Milestone 1 - Core types, public skeleton, errors
- Milestone 2 - FRED constructor, `.env` loading, safe display
- Milestone 3 - Generic option normalization

Current status:
- Milestone 3 implemented and verified with offline tests.

Next milestone to implement:
- Milestone 4 - FRED option normalization and validation

Implementation notes:
- Set up the package source tree and main module wiring.
- Added the custom error hierarchy, `MemoryCache`, and stub public API entry points in milestone 1.
- Implemented the structured `Fred` source type, constructor-based API key resolution precedence, internal `.env` parsing, `clear_cache!`, and safe display in milestone 2.
- Added generic `FetchOptions`, ISO date parsing, and `on_error` normalization in milestone 3.
- Kept FRED-specific option normalization and request behavior out of scope through milestone 3.

Agent verification to rerun on later milestones:
- `julia --project=. test/runtests.jl`
- `julia --project=. .agents/internal-smoke.jl`
