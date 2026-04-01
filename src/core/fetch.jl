"""
    fetch_data(series_id, source; kwargs...)

Fetch macroeconomic data for one or more series from `source`.
"""
function fetch_data(series_id::AbstractString, source::AbstractDataSource; kwargs...)
    throw(ErrorException("`fetch_data` is not implemented for $(typeof(source)) yet."))
end

function fetch_data(
    series_ids::AbstractVector{<:AbstractString},
    source::AbstractDataSource;
    kwargs...,
)
    throw(ErrorException("`fetch_data` is not implemented for $(typeof(source)) yet."))
end
