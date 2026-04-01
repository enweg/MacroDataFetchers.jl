Current target version: v0.1.0

Completed milestones:
- Milestone 1 - Core types, public skeleton, errors
- Milestone 2 - FRED constructor, `.env` loading, safe display

Current status:
- Milestone 2 implemented and verified with offline tests.

Next milestone to implement:
- Milestone 3 - Generic option normalization

Implementation notes:
- Set up the package source tree and main module wiring.
- Added the custom error hierarchy, `MemoryCache`, and stub public API entry points in milestone 1.
- Implemented the structured `Fred` source type, constructor-based API key resolution precedence, internal `.env` parsing, `clear_cache!`, and safe display in milestone 2.
- Kept fetch option normalization and request behavior out of scope through milestone 2.

Agent verification to rerun on later milestones:
- `julia --project=. test/runtests.jl`
- `julia --project=. .agents/internal-smoke.jl`
