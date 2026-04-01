"""
    fetch_data(series_id, source; start_date=nothing, end_date=nothing, on_error=:raise, kwargs...)

Fetch macroeconomic data for one or more series from `source`.
"""
function fetch_data(
    series_id::AbstractString,
    source::AbstractDataSource;
    start_date=nothing,
    end_date=nothing,
    on_error::Symbol=:raise,
    kwargs...,
)
    _ = _normalize_fetch_options(;
        start_date=start_date,
        end_date=end_date,
        on_error=on_error,
        kwargs...,
    )
    throw(ErrorException("`fetch_data` is not implemented for $(typeof(source)) yet."))
end

function fetch_data(
    series_ids::AbstractVector{<:AbstractString},
    source::AbstractDataSource;
    start_date=nothing,
    end_date=nothing,
    on_error::Symbol=:raise,
    kwargs...,
)
    _ = _normalize_fetch_options(;
        start_date=start_date,
        end_date=end_date,
        on_error=on_error,
        kwargs...,
    )
    throw(ErrorException("`fetch_data` is not implemented for $(typeof(source)) yet."))
end
