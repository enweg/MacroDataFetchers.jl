function _fred_observations_dataframe(;
    series_id::Vector{String},
    date::Vector{Date},
    value::Vector{Union{Missing,Float64}},
    value_raw::Vector{String},
    value_was_missing_marker::Vector{Bool},
    realtime_start::Vector{Date},
    realtime_end::Vector{Date},
)::DataFrame
    return DataFrame(
        series_id=series_id,
        date=date,
        value=value,
        value_raw=value_raw,
        value_was_missing_marker=value_was_missing_marker,
        realtime_start=realtime_start,
        realtime_end=realtime_end,
    )
end
