```@meta
CurrentModule = MacroDataFetchers
```

# MacroDataFetchers.jl

`MacroDataFetchers.jl` provides a small, typed interface for downloading
macroeconomic data from external providers through a unified Julia API.

Version `v0.1.0` focuses on the FRED observations endpoint and returns a long
`DataFrame` with parsed values, raw source values, and realtime metadata.

## What You Can Do Today

- construct a [`Fred`](@ref) source with API key resolution from an explicit
  key, `ENV["FRED_API_KEY"]`, or a local `.env` file
- fetch one or many series with [`fetch_data`](@ref)
- use shared date keywords such as `start_date` and `end_date`
- clear the in-memory response cache with [`clear_cache!`](@ref)

## Documentation

- [Getting Started](getting-started.md)
- [FRED Usage](fred.md)
- [API Reference](api.md)
