"""
    _parse_response(body, source::Fred, series_id) -> DataFrame

Parse a FRED observations JSON response into the package's long-form schema.
"""
function _parse_response(
    body::String,
    ::Fred,
    series_id::AbstractString,
)::DataFrame
    parsed = try
        JSON3.read(body)
    catch err
        throw(ResponseParseError("Failed to parse FRED JSON response: $(sprint(showerror, err))", body))
    end

    hasproperty(parsed, :observations) ||
        throw(ResponseParseError("FRED response did not contain an `observations` array.", body))

    observations = getproperty(parsed, :observations)
    observations isa AbstractVector ||
        throw(ResponseParseError("FRED `observations` field was not an array.", body))

    n = length(observations)
    series_ids = Vector{String}(undef, n)
    dates = Vector{Date}(undef, n)
    values = Vector{Union{Missing,Float64}}(undef, n)
    raw_values = Vector{String}(undef, n)
    missing_markers = Vector{Bool}(undef, n)
    realtime_starts = Vector{Date}(undef, n)
    realtime_ends = Vector{Date}(undef, n)

    for (index, observation) in pairs(observations)
        series_ids[index] = String(series_id)
        dates[index] = _parse_required_observation_date(observation, :date, body, index)
        realtime_starts[index] = _parse_required_observation_date(observation, :realtime_start, body, index)
        realtime_ends[index] = _parse_required_observation_date(observation, :realtime_end, body, index)

        raw_value = _parse_required_observation_string(observation, :value, body, index)
        parsed_value, was_missing_marker = _parse_value(raw_value)
        values[index] = parsed_value
        raw_values[index] = raw_value
        missing_markers[index] = was_missing_marker
    end

    return _fred_observations_dataframe(
        series_id=series_ids,
        date=dates,
        value=values,
        value_raw=raw_values,
        value_was_missing_marker=missing_markers,
        realtime_start=realtime_starts,
        realtime_end=realtime_ends,
    )
end

"""
    _parse_value(raw) -> Tuple{Union{Missing,Float64}, Bool}

Parse a FRED observation value and track whether the missing marker was used.
"""
function _parse_value(raw::AbstractString)::Tuple{Union{Missing,Float64},Bool}
    raw == "." && return missing, true

    value = tryparse(Float64, raw)
    isnothing(value) && throw(ResponseParseError("FRED observation value could not be parsed as Float64: `$(raw)`.", nothing))
    return value, false
end

function _parse_required_observation_date(observation, field::Symbol, body::String, index)::Date
    raw = _parse_required_observation_string(observation, field, body, index)
    try
        return Date(raw, dateformat"yyyy-mm-dd")
    catch _
        throw(ResponseParseError("Observation $(index) field `$(field)` was not a valid ISO date: `$(raw)`.", body))
    end
end

function _parse_required_observation_string(observation, field::Symbol, body::String, index)::String
    hasproperty(observation, field) ||
        throw(ResponseParseError("Observation $(index) is missing required field `$(field)`.", body))

    raw = getproperty(observation, field)
    raw isa AbstractString ||
        throw(ResponseParseError("Observation $(index) field `$(field)` was not a string.", body))

    return String(raw)
end
