```@meta
CurrentModule = MacroDataFetchers
```

# FRED Usage

## Source Construction

Use [`Fred`](@ref) to configure API credentials, timeout behavior, retries, and
the per-instance in-memory cache.

## Shared Keywords

`MacroDataFetchers.jl` exposes shared provider-agnostic date keywords:

- `start_date`
- `end_date`

For FRED, these map internally to:

- `start_date -> observation_start`
- `end_date -> observation_end`

## FRED-Specific Keywords

The current FRED implementation also accepts these provider-native keywords:

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

If both a shared keyword and the corresponding FRED-native keyword are provided,
their normalized values must agree or a `ValidationError` is thrown.

## Caching

Each `Fred` instance owns its own in-memory cache of successful raw response
bodies. Disable caching with `use_cache=false` or clear the cache explicitly
with [`clear_cache!`](@ref).
