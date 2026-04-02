```@meta
CurrentModule = MacroDataFetchers
```

# Getting Started

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/enweg/MacroDataFetchers.jl")
```

## Configure Your FRED API Key

You can provide the FRED API key in three ways, in this precedence order:

1. explicitly in the `Fred` constructor
2. via `ENV["FRED_API_KEY"]`
3. via a local `.env` file

Example `.env` file:

```text
FRED_API_KEY=your-fred-api-key
```

## Basic Usage

```julia
using MacroDataFetchers

fred = Fred(api_key="your-fred-api-key")

gdp = fetch_data("GDP", fred; start_date="2020-01-01")

inflation = fetch_data(
    ["CPIAUCSL", "CPILFESL"],
    fred;
    start_date="2020-01-01",
    on_error=:skip,
)
```

## Returned Schema

Current FRED fetches return a long `DataFrame` with these columns:

- `series_id::String`
- `date::Date`
- `value::Union{Missing,Float64}`
- `value_raw::String`
- `value_was_missing_marker::Bool`
- `realtime_start::Date`
- `realtime_end::Date`

The raw FRED missing marker `"."` is preserved in `value_raw` and represented as
`missing` in `value`.
