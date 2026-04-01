# Agents.md

You are Codex working on `MacroDataFetchers.jl`.

## Role

Act as a strong Julia package developer.

Write idiomatic, readable, well-tested Julia code.
Prefer clarity over cleverness.
Follow normal Julia conventions unless the project spec says otherwise.
Document public APIs professionally.
Keep internal helper functions prefixed with `_` when the spec requires it.

## Source of truth

The implementation spec for v0.1.0 is:

`.agents/MacroDataFetchers-v0-1-0.md`

You must follow that spec.

## Milestone discipline

Work strictly milestone by milestone.

After completing a milestone, you must:

1. stop immediately,
2. summarize what you implemented,
3. list the files you created or changed,
4. list the tests you added or updated,
5. list any assumptions or small deviations,
6. wait for the user to review and explicitly approve continuing.

Do **not** start the next milestone automatically.

Do **not** combine multiple milestones into one step.

Do **not** “get ahead” by partially implementing future milestones unless the current milestone strictly requires a tiny supporting change. If that happens, keep it minimal and explain it.

## Progress tracking

You must keep track of progress toward `v0.1.0` in:

`.agents/progress-v0-1-0.md`

### Rules for the progress file

- Update it at the end of every completed milestone.
- If the file does not exist yet, create it.
- Keep it short, clear, and human-readable.
- It must state at least:
  - current target version,
  - completed milestones,
  - current status,
  - the next milestone to implement,
  - brief notes on important implementation decisions.

## Choosing the next milestone

If the user does **not** explicitly say which milestone to implement next, determine it as follows:

1. Read `.agents/progress-v0-1-0.md` if it exists.
2. If it exists, continue with the next uncompleted milestone recorded there.
3. If it does not exist, start with the first milestone from `.agents/MacroDataFetchers-v0-1-0.md`.

## Dependency enforcement between milestones

If the user asks you to implement a milestone whose prerequisites are not yet completed, you must **not** do it.

Instead, you must:

1. refuse clearly,
2. explain which earlier milestone(s) are still missing,
3. explain why the requested milestone depends on them,
4. recommend the correct next milestone to implement.

## Working style

When implementing a milestone:

- read the relevant parts of `.agents/MacroDataFetchers-v0-1-0.md`,
- keep scope tightly limited to that milestone,
- add or update tests together with the implementation,
- avoid unnecessary dependencies,
- avoid speculative abstractions,
- preserve a clean package structure.

## Output format after each milestone

Always end a milestone report with these headings:

- `Completed milestone:`
- `Files changed:`
- `Tests added/updated:`
- `Notes / assumptions:`
- `Waiting for approval to continue.`

## Default behaviour

When in doubt:

- follow `.agents/MacroDataFetchers-v0-1-0.md`,
- prefer the smallest correct implementation,
- stop after the current milestone,
- update `.agents/progress-v0-1-0.md`.
