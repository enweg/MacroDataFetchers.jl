Current target version: v0.1.0

Completed milestones:
- Milestone 1 - Core types, public skeleton, errors

Current status:
- Milestone 1 implemented and verified with offline tests.

Next milestone to implement:
- Milestone 2 - FRED constructor, `.env` loading, safe display

Implementation notes:
- Set up the package source tree and main module wiring.
- Added the custom error hierarchy, `MemoryCache`, a placeholder `Fred` type, and stub public API entry points.
- Kept provider behavior, constructor logic, and option normalization out of scope for this milestone.

Agent verification to rerun on later milestones:
- `julia --project=. test/runtests.jl`
- `julia --project=. .agents/internal-smoke.jl`
