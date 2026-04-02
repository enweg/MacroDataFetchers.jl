"""
    fetch_data(series_id, source; start_date=nothing, end_date=nothing, on_error=:raise, kwargs...)
    fetch_data(series_ids, source; start_date=nothing, end_date=nothing, on_error=:raise, kwargs...)

Fetch one or more macroeconomic series from `source` and return a long
[`DataFrame`](https://dataframes.juliadata.org/stable/).

`series_id` may be a single string or a vector of strings. Generic keywords are
normalized before provider-specific options are applied.

# Arguments
- `start_date`: Optional observation start date as a `Date` or ISO
  `"yyyy-mm-dd"` string.
- `end_date`: Optional observation end date as a `Date` or ISO
  `"yyyy-mm-dd"` string.
- `on_error`: Multi-series error policy. Use `:raise` to stop on the first
  failure or `:skip` to warn and continue.
- `kwargs...`: Provider-specific options accepted by the concrete source.

# Returns
- A long `DataFrame` containing one row per provider observation.

# Errors
- `ValidationError` for invalid generic or provider-specific options.
- Provider-specific request or parsing errors for request failures and malformed
  responses.

# Examples
```julia
julia> fred = Fred(api_key="your-fred-api-key");

julia> df = fetch_data("GDP", fred; start_date="2020-01-01");

julia> multi = fetch_data(["GDP", "CPIAUCSL"], fred; on_error=:skip);
```
"""
function fetch_data(
    series_id::AbstractString,
    source::AbstractDataSource;
    start_date=nothing,
    end_date=nothing,
    on_error::Symbol=:raise,
    kwargs...,
)
    options = _normalize_fetch_options(;
        start_date=start_date,
        end_date=end_date,
        on_error=on_error,
        kwargs...,
    )
    provider_options = _normalize_provider_options(source, options)
    return _fetch_one_series(series_id, source, provider_options)
end

function fetch_data(
    series_ids::AbstractVector{<:AbstractString},
    source::AbstractDataSource;
    start_date=nothing,
    end_date=nothing,
    on_error::Symbol=:raise,
    kwargs...,
)
    options = _normalize_fetch_options(;
        start_date=start_date,
        end_date=end_date,
        on_error=on_error,
        kwargs...,
    )
    return _fetch_many_series(series_ids, source, options)
end

function _fetch_many_series(
    series_ids::AbstractVector{<:AbstractString},
    source::AbstractDataSource,
    options::FetchOptions,
)::DataFrame
    unique_series_ids, duplicates = _deduplicate_series_ids(series_ids)
    isempty(duplicates) || @warn "Dropped duplicate series IDs: $(join(duplicates, ", "))"

    provider_options = _normalize_provider_options(source, options)
    frames = DataFrame[]

    for series_id in unique_series_ids
        try
            push!(frames, _fetch_one_series(series_id, source, provider_options))
        catch err
            if options.on_error == :skip
                @warn "Skipping series `$(series_id)` after $(nameof(typeof(err))): $(sprint(showerror, err))"
                continue
            end
            rethrow()
        end
    end

    return isempty(frames) ? DataFrame(
        series_id=String[],
        date=Date[],
        value=Union{Missing,Float64}[],
        value_raw=String[],
        value_was_missing_marker=Bool[],
        realtime_start=Date[],
        realtime_end=Date[],
    ) : vcat(frames...)
end

function _fetch_one_series(
    series_id::AbstractString,
    source::AbstractDataSource,
    provider_options,
)::DataFrame
    throw(MethodError(_fetch_one_series, (series_id, source, provider_options)))
end

function _deduplicate_series_ids(series_ids::AbstractVector{<:AbstractString})
    seen = Set{String}()
    unique_ids = String[]
    duplicates = String[]

    for series_id in series_ids
        normalized = String(series_id)
        if normalized in seen
            push!(duplicates, normalized)
        else
            push!(seen, normalized)
            push!(unique_ids, normalized)
        end
    end

    return unique_ids, duplicates
end
