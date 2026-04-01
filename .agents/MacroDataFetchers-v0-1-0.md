# MacroDataFetchers.jl — v0.1 implementation spec for Codex

You are implementing `MacroDataFetchers.jl`, a Julia package for downloading macroeconomic data from multiple providers through a unified API.

## Very important workflow rule

You must implement this package **milestone by milestone**.

After completing **one milestone**, you must:

1. stop immediately,
2. summarize what you implemented,
3. list the files you created or changed,
4. list the tests you added,
5. mention any design assumptions you had to make,
6. wait for the user to explicitly tell you to continue.

Do **not** start the next milestone automatically.

Do **not** bundle multiple milestones into one step.

If a milestone reveals an issue in an earlier milestone, fix only what is necessary for correctness, explain it clearly, and then stop again.

---

# 1. Package goal

Implement a Julia package `MacroDataFetchers.jl` with:

- a provider abstraction via `AbstractDataSource`,
- a first concrete provider `Fred <: AbstractDataSource`,
- a unified public function `fetch_data`,
- internal request building and response parsing helpers,
- in-memory caching for the session,
- professional Julia-style documentation,
- offline and live tests,
- contributor documentation.

For v0.1, only the FRED `series/observations` endpoint needs to be supported.

---

# 2. Design principles

## 2.1 Public API philosophy

The public API should be minimal and clean.

Public exports for v0.1:

- `AbstractDataSource`
- `Fred`
- `fetch_data`
- `clear_cache!`

The public unified interface is:

```julia
fetch_data(series_id, source; kwargs...) -> DataFrame
```

where `series_id` can be a single `AbstractString` or an `AbstractVector{<:AbstractString}`.

## 2.2 Internal naming convention

All internal helper functions must be prefixed with `_`.

Examples:

- `_normalize_fetch_options`
- `_build_request`
- `_send_request`
- `_parse_response`

These functions are not part of the public API.

## 2.3 Scope discipline

Do not implement extra providers yet.

Do not implement wide-format helpers yet.

Do not implement disk caching yet.

Do not implement provider metadata tables yet.

Keep v0.1 focused on a correct, clean, extensible FRED implementation.

---

# 3. Public API specification

## 3.1 Abstract data source

```julia
abstract type AbstractDataSource end
```

## 3.2 FRED source type

```julia
mutable struct MemoryCache
    store::Dict{String,String}
end

struct Fred <: AbstractDataSource
    api_key::String
    use_cache::Bool
    timeout_seconds::Float64
    max_retries::Int
    _cache::MemoryCache
end
```

## 3.3 FRED constructor

Public constructor:

```julia
Fred(; api_key=nothing, use_cache=true, timeout_seconds=30, max_retries=2)
```

### Constructor rules

- `api_key` resolution order:
  1. explicit `api_key`
  2. `ENV["FRED_API_KEY"]`
  3. `.env` file read by an internal lightweight parser
- if no API key is found, throw `ConfigurationError`
- validate:
  - `timeout_seconds > 0`
  - `max_retries >= 0`
- initialize `_cache = MemoryCache(Dict{String,String}())`
- the FRED base URL is internal and constant, not user-configurable

## 3.4 Public fetch methods

```julia
fetch_data(
    series_id::AbstractString,
    source::AbstractDataSource;
    start_date=nothing,
    end_date=nothing,
    on_error::Symbol=:raise,
    kwargs...,
)::DataFrame
```

```julia
fetch_data(
    series_ids::AbstractVector{<:AbstractString},
    source::AbstractDataSource;
    start_date=nothing,
    end_date=nothing,
    on_error::Symbol=:raise,
    kwargs...,
)::DataFrame
```

## 3.5 Public cache clearing

```julia
clear_cache!(source::AbstractDataSource)::Nothing
```

Define a generic interface with a `Fred` method.

## 3.6 Safe display

Define a custom `Base.show(io::IO, fred::Fred)`.

Requirements:

- never print the raw API key
- print useful user-facing config
- it is acceptable to indicate that a key is present, but not its value

---

# 4. Unified keyword interface

## 4.1 Cross-provider keywords

The unified keywords for v0.1 are:

- `start_date`
- `end_date`

These should mean the same across providers.

For FRED:

- `start_date` maps to `observation_start`
- `end_date` maps to `observation_end`

## 4.2 FRED-native keywords

The FRED implementation should also support provider-native keywords, validated and normalized internally.

Support these FRED-native options in the internal typed options layer:

- `observation_start`
- `observation_end`
- `realtime_start`
- `realtime_end`
- `limit`
- `offset`
- `sort_order`
- `units`
- `frequency`
- `aggregation_method`
- `output_type`
- `vintage_dates`

For the very first implementation pass, it is acceptable for the public examples and early tests to focus mainly on `observation_start` and `observation_end`, but the option normalization layer should be designed for the full set above.

## 4.3 Conflict rules

If the user passes both a unified keyword and its provider-native equivalent, and the resolved values conflict, throw `ValidationError`.

Example:

```julia
fetch_data(
    "GDP",
    fred;
    start_date=Date(2000,1,1),
    observation_start=Date(2001,1,1),
)
```

This must throw.

If both are given and they normalize to the same value, accept them.

## 4.4 Unknown keyword rule

Unknown provider-specific keywords must error immediately with `ValidationError`.

Do not pass unknown keywords through to the API.

---

# 5. Input normalization rules

## 5.1 Series IDs

Accept:

- `AbstractString`
- `AbstractVector{<:AbstractString}`

Do not accept arbitrary iterables in v0.1.

## 5.2 Duplicate series IDs

For multi-series requests:

- detect duplicate series IDs,
- deduplicate them,
- preserve first-seen order,
- emit a warning,
- warning must list the dropped duplicates.

## 5.3 Date input types

Accept for date-like public options:

- `Date`
- ISO date strings

Do **not** accept `DateTime` in v0.1.

Do **not** accept ambiguous date strings.

Normalize early to `Date`.

## 5.4 Enum-like option values

For FRED enum-like options such as:

- `sort_order`
- `units`
- `frequency`
- `aggregation_method`

accept:

- `Symbol`
- `AbstractString`

Normalize internally to canonical `Symbol`.

Validation must be **case-sensitive**.

Examples:

- `:lin` valid
- `"lin"` valid
- `:LIN` invalid
- `"LIN"` invalid

Invalid values must throw `ValidationError` before any request is sent.

---

# 6. Internal typed options layer

## 6.1 Generic normalized options

```julia
struct FetchOptions
    start_date::Union{Nothing,Date}
    end_date::Union{Nothing,Date}
    on_error::Symbol
    provider_kwargs::NamedTuple
end
```

## 6.2 FRED-specific normalized options

```julia
struct FredObservationsOptions
    observation_start::Union{Nothing,Date}
    observation_end::Union{Nothing,Date}
    realtime_start::Union{Nothing,Date}
    realtime_end::Union{Nothing,Date}
    limit::Union{Nothing,Int}
    offset::Union{Nothing,Int}
    sort_order::Union{Nothing,Symbol}
    units::Union{Nothing,Symbol}
    frequency::Union{Nothing,Symbol}
    aggregation_method::Union{Nothing,Symbol}
    output_type::Union{Nothing,Int}
    vintage_dates::Union{Nothing,Vector{Date}}
end
```

## 6.3 Internal normalization philosophy

Keep the public interface keyword-based.

Internally, always normalize into typed option structs before building requests.

---

# 7. FRED request/response behaviour

## 7.1 Endpoint scope

For v0.1, support only the FRED observations endpoint.

Internally define constants such as:

```julia
const _FRED_BASE_URL = "https://api.stlouisfed.org/fred"
const _FRED_OBSERVATIONS_PATH = "/series/observations"
const _FRED_API_KEY_ENV = "FRED_API_KEY"
```

## 7.2 Request format

Always request JSON internally.

Do not expose output format choice to the user in v0.1.

## 7.3 Multi-series fetching

For FRED, fetch one series per request, then row-bind results.

This is required because the observations endpoint is treated as one-series-per-request for this package.

## 7.4 Retry behaviour

Implement internal retries for transient request failures.

Rules:

- retries are internal, not part of the public `fetch_data` API
- use the `Fred.max_retries` field
- use a simple retry policy with exponential backoff
- keep this implementation simple and readable

## 7.5 Timeout behaviour

Use `Fred.timeout_seconds` in the HTTP layer.

---

# 8. Returned data format

Return a long `DataFrame`.

For FRED v0.1, the returned `DataFrame` must contain these columns:

```julia
series_id::String
date::Date
value::Union{Missing,Float64}
value_raw::String
value_was_missing_marker::Bool
realtime_start::Date
realtime_end::Date
```

## 8.1 Value parsing rule

- parse numeric observation values strictly to `Float64`
- if the provider returns `"."`, parse `value` as `missing`
- preserve the raw source value in `value_raw`
- set `value_was_missing_marker = true` if and only if the raw value was `"."`

Do not add request-level metadata columns in v0.1.

## 8.2 Row ordering

For multi-series results:

- preserve user-requested series order after deduplication
- keep rows grouped by series
- within each series, preserve provider response order

Do not globally sort by date unless the provider response already does so.

---

# 9. Caching specification

## 9.1 Cache scope

Cache only in memory for the current Julia session.

Cache state is attached to each `Fred` instance through `_cache`.

## 9.2 Cached object

Cache the raw HTTP response body as `String`.

Do not cache parsed JSON objects.

Do not cache final `DataFrame`s.

## 9.3 Cache key

Use a canonical request signature, not raw ad hoc string equality.

The cache key must depend on semantically relevant request content, such as:

- HTTP method
- canonicalized base URL/path
- normalized query parameters

Equivalent requests with different query parameter order must map to the same cache key.

## 9.4 Cache write policy

Cache only successful responses.

## 9.5 Public cache clearing

`clear_cache!(source)` must empty the in-memory cache for that source.

---

# 10. Error and warning design

## 10.1 Custom exception hierarchy

Define custom exceptions:

```julia
abstract type MacroDataFetchersError <: Exception end

struct ConfigurationError <: MacroDataFetchersError
    msg::String
end

struct ValidationError <: MacroDataFetchersError
    msg::String
end

struct RequestBuildError <: MacroDataFetchersError
    msg::String
end

struct RequestError <: MacroDataFetchersError
    msg::String
    status::Union{Nothing,Int}
    body::Union{Nothing,String}
end

struct ResponseParseError <: MacroDataFetchersError
    msg::String
    body::Union{Nothing,String}
end
```

Implement useful `showerror` methods if appropriate.

## 10.2 `on_error` behaviour for multi-series calls

Support:

- `on_error = :raise`
- `on_error = :skip`

Rules:

- `:raise`: fail the full call on the first failure
- `:skip`: emit a warning and continue with the remaining series

For `:skip`, warnings must include:

- the failed `series_id`
- the exception type
- the exception message

## 10.3 Logging/warnings

Use standard Julia warnings/logging.

Do not build a custom warning system.

---

# 11. Internal `.env` reader specification

Implement a lightweight internal parser.

Suggested internal function:

```julia
_load_dotenv(path::AbstractString = ".env")::Dict{String,String}
```

Rules:

- support `KEY=VALUE`
- ignore blank lines
- ignore lines starting with `#`
- trim surrounding whitespace around keys and unquoted values
- support full-line quoted values:
  - `KEY="value"`
  - `KEY='value'`
- no interpolation
- no multiline values
- no `export`
- if the file is absent, return an empty dictionary
- do not mutate global `ENV`

The constructor may use the parsed dictionary to resolve missing keys.

---

# 12. Package structure

All package source files must live under `src/`.

Use provider-specific subfolders.

Recommended structure:

```text
src/
├── MacroDataFetchers.jl
├── core/
│   ├── types.jl
│   ├── options.jl
│   ├── errors.jl
│   ├── cache.jl
│   ├── http.jl
│   ├── fetch.jl
│   └── utils.jl
└── sources/
    ├── abstract_source.jl
    └── fred/
        ├── fred.jl
        ├── options.jl
        ├── request.jl
        ├── parse.jl
        └── schema.jl
```

## 12.1 File responsibilities

### `src/MacroDataFetchers.jl`
- main module
- includes files
- exports public API

### `src/sources/abstract_source.jl`
- `AbstractDataSource`

### `src/core/types.jl`
- `MemoryCache`
- `FetchOptions`

### `src/core/errors.jl`
- custom exception types
- optional `showerror` methods

### `src/core/options.jl`
- `_normalize_fetch_options`
- `_parse_date`
- generic option validation helpers

### `src/core/cache.jl`
- `clear_cache!`
- cache read/write helpers
- canonical key helpers if not provider-specific

### `src/core/http.jl`
- `_send_request`
- retry logic
- timeout handling
- request error handling

### `src/core/fetch.jl`
- public `fetch_data`
- single-series and multi-series orchestration
- deduplication logic
- `on_error` handling

### `src/sources/fred/fred.jl`
- `Fred`
- constructor
- `show` method
- provider dispatch hooks

### `src/sources/fred/options.jl`
- `FredObservationsOptions`
- provider kwarg validation
- enum normalization
- generic-to-provider mapping
- conflict detection

### `src/sources/fred/request.jl`
- `_build_request`
- `_canonical_cache_key`

### `src/sources/fred/parse.jl`
- `_parse_response`
- `_parse_value`

### `src/sources/fred/schema.jl`
- helper for constructing the typed `DataFrame`

---

# 13. Internal function list

The exact signatures may be adapted slightly if needed, but the architecture should remain close to this.

## 13.1 Generic core

```julia
_normalize_fetch_options(; start_date=nothing, end_date=nothing, on_error=:raise, kwargs...)::FetchOptions
_validate_on_error(on_error::Symbol)::Symbol
_parse_date(x)::Union{Nothing,Date}
```

## 13.2 Generic orchestration

```julia
_fetch_many_series(
    series_ids::AbstractVector{<:AbstractString},
    source::AbstractDataSource,
    options::FetchOptions,
)::DataFrame
```

## 13.3 FRED-specific option normalization

```julia
_normalize_provider_options(source::Fred, options::FetchOptions)::FredObservationsOptions
_validate_provider_kwargs(source::Fred, kwargs::NamedTuple)::Nothing
_resolve_date_conflicts(
    start_date::Union{Nothing,Date},
    end_date::Union{Nothing,Date},
    observation_start::Union{Nothing,Date},
    observation_end::Union{Nothing,Date},
)::Tuple{Union{Nothing,Date},Union{Nothing,Date}}

_normalize_symbol_option(
    x,
    allowed,
    option_name::Symbol,
)::Union{Nothing,Symbol}
```

## 13.4 FRED transport layer

```julia
_build_request(
    series_id::AbstractString,
    source::Fred,
    options::FredObservationsOptions,
)

_canonical_cache_key(request)::String
_send_request(request, source::Fred)::String
```

## 13.5 FRED parsing layer

```julia
_parse_response(
    body::String,
    source::Fred,
    series_id::AbstractString,
)::DataFrame

_parse_value(raw::AbstractString)::Tuple{Union{Missing,Float64},Bool}
```

## 13.6 FRED per-series orchestration

```julia
_fetch_one_series(
    series_id::AbstractString,
    source::Fred,
    options::FredObservationsOptions,
)::DataFrame
```

---

# 14. Dependencies

Use a minimal, standard Julia stack.

Expected dependencies:

- `HTTP.jl`
- `JSON3.jl`
- `DataFrames.jl`

Standard library usage:

- `Dates`
- `Logging`
- `Test`

Avoid unnecessary extra dependencies.

Do not add a dotenv package; implement a lightweight internal parser.

---

# 15. Documentation requirements

Use Julia-style professional docstrings compatible with Documenter.jl.

## 15.1 Public docstrings

All public functions and public types must be documented:

- `AbstractDataSource`
- `Fred`
- `fetch_data`
- `clear_cache!`

## 15.2 Internal docstrings

Important internal functions should also have docstrings, especially those that define architecture or normalization behaviour.

## 15.3 Style

Follow standard Julia documentation style:

- docstring immediately above the documented object
- start with the signature
- describe arguments, behaviour, return type, and errors where useful
- include examples when stable and concise

## 15.4 Documenter integration

Add or update documentation pages so that the package has at least:

- a getting started page
- a FRED usage page
- an API reference page

Keep examples stable enough for doctests where practical.

---

# 16. Testing requirements

Implement both offline and live tests.

## 16.1 Offline tests

Offline tests are the default and must be robust enough for CI without secrets.

Test at least:

- constructor validation
- API key resolution precedence
- `.env` parsing
- date parsing and date conflict detection
- `on_error` validation
- provider kwarg validation
- enum normalization
- request construction
- cache key canonicalization
- caching behaviour
- parsing of valid FRED JSON
- parsing of missing values `"."`
- malformed JSON handling
- FRED error response handling
- duplicate series deduplication
- multi-series orchestration
- `clear_cache!`
- safe `show` for `Fred`

Where possible, use mocked HTTP responses rather than live network calls.

## 16.2 Live tests

Live tests must be separated and gated.

Define a helper such as:

```julia
_should_run_live_tests()::Bool
```

It should return `true` only if both conditions hold:

- `FRED_API_KEY` exists in `ENV`
- `RUN_LIVE_TESTS=true`

Live tests should verify a small number of real endpoint interactions, for example:

- fetching one known series
- date filtering works
- returned schema matches expectations

Live tests should run in CI only when the relevant secret is present and the workflow opts in.

---

# 17. Contributor documentation

Create `contributors.md`.

It must describe:

- package purpose
- source tree overview
- milestone-oriented development approach
- internal naming conventions
- underscore-prefixed internal functions
- documentation conventions
- testing structure
- offline vs live tests
- how to set `FRED_API_KEY` locally
- supported `.env` format
- how to run tests locally
- how to add `FRED_API_KEY` as a GitHub Actions secret
- how to opt into live tests in CI

Be explicit and practical.

---

# 18. GitHub Actions and CI expectations

Assume the package already has GitHub Actions set up, but update workflows if needed.

CI expectations:

- normal CI path runs offline tests only
- live tests run only if:
  - a FRED API key secret is present
  - the workflow sets `RUN_LIVE_TESTS=true`

Explain this in `contributors.md`.

If a workflow file must be adjusted to support this, do it in the relevant milestone and document the change.

---

# 19. Milestone plan

You must implement **one milestone at a time** and stop after each one.

## Milestone 1 — Core types, public skeleton, errors

Implement:

- `AbstractDataSource`
- `MemoryCache`
- custom error hierarchy
- public API stubs
- `clear_cache!` generic interface
- main module wiring
- initial docstrings for public objects

Acceptance criteria:

- package loads
- exports are correct
- core types compile
- basic tests for type construction and module loading pass

Then stop.

## Milestone 2 — FRED constructor, `.env` loading, safe display

Implement:

- `Fred` type
- `Fred` constructor
- API key resolution precedence
- internal `.env` reader
- validation of `timeout_seconds` and `max_retries`
- safe `show` method

Acceptance criteria:

- constructor behaves correctly for explicit key, `ENV`, `.env`, and missing key
- API key is never shown in REPL display
- tests cover all constructor branches

Then stop.

## Milestone 3 — Generic option normalization

Implement:

- `FetchOptions`
- `_normalize_fetch_options`
- `_parse_date`
- `_validate_on_error`

Acceptance criteria:

- accept `Date` and ISO date strings
- reject invalid/ambiguous values
- support `on_error = :raise` and `:skip`
- tests pass

Then stop.

## Milestone 4 — FRED option normalization and validation

Implement:

- `FredObservationsOptions`
- FRED provider kwarg validation
- enum normalization
- mapping `start_date -> observation_start`
- mapping `end_date -> observation_end`
- conflict detection

Acceptance criteria:

- unknown kwargs fail
- invalid enum values fail
- conflicting date inputs fail
- normalized internal options are correct

Then stop.

## Milestone 5 — Request building and cache keys

Implement:

- `_build_request`
- `_canonical_cache_key`
- internal FRED constants
- JSON request enforcement

Acceptance criteria:

- request construction is deterministic
- equivalent query parameter order produces the same cache key
- tests cover request contents and cache keys

Then stop.

## Milestone 6 — HTTP layer, retries, cache usage

Implement:

- `_send_request`
- timeout handling
- retry logic
- read/write cache integration
- cache only successful responses

Acceptance criteria:

- mocked transport tests cover retry paths
- cache hits bypass duplicate network calls
- errors are surfaced as `RequestError`

Then stop.

## Milestone 7 — Response parsing and DataFrame construction

Implement:

- `_parse_response`
- `_parse_value`
- `schema.jl` helper(s)
- construction of the agreed FRED `DataFrame`

Acceptance criteria:

- values parse to `Union{Missing,Float64}`
- `"."` is handled correctly
- malformed or unexpected responses throw `ResponseParseError`
- returned schema matches spec exactly

Then stop.

## Milestone 8 — Public fetch orchestration

Implement:

- public `fetch_data` methods
- `_fetch_one_series`
- multi-series fetch orchestration
- deduplication with warning
- `on_error = :raise`
- `on_error = :skip`

Acceptance criteria:

- single-series fetch works
- multi-series fetch preserves first-seen order
- duplicates are dropped with warning
- skip mode warns with series ID and error details
- tests pass

Then stop.

## Milestone 9 — Documentation and contributor guide

Implement:

- improve docstrings
- add/update Documenter pages
- create `contributors.md`

Acceptance criteria:

- public API is documented
- docs have a usable getting-started path
- contributor guide clearly explains setup, tests, and CI secrets

Then stop.

## Milestone 10 — Live integration tests and CI gating

Implement:

- gated live tests
- `_should_run_live_tests()` helper in test code
- CI adjustments if needed to support secret-based live tests

Acceptance criteria:

- live tests are skipped unless both `FRED_API_KEY` and `RUN_LIVE_TESTS=true` are present
- offline CI remains stable
- contributor documentation explains the setup clearly

Then stop.

---

# 20. Final implementation discipline

When implementing each milestone:

- keep the code idiomatic Julia
- prefer clarity over cleverness
- do not introduce unnecessary abstraction
- do not add features outside the milestone scope
- write tests together with the implementation
- stop after the milestone is complete and wait for approval

At the end of each milestone response, always include:

1. `Completed milestone: ...`
2. `Files changed: ...`
3. `Tests added/updated: ...`
4. `Notes / assumptions: ...`
5. `Waiting for approval to continue.`
