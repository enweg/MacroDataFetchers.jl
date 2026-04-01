const _FRED_BASE_URL = "https://api.stlouisfed.org/fred"
const _FRED_OBSERVATIONS_PATH = "/series/observations"

"""
    _build_request(series_id, source::Fred, options::FredObservationsOptions)

Build a deterministic internal request description for the FRED observations
endpoint.
"""
function _build_request(
    series_id::AbstractString,
    source::Fred,
    options::FredObservationsOptions,
)
    isempty(strip(series_id)) && throw(RequestBuildError("`series_id` must not be empty."))

    query = Dict{String,String}(
        "api_key" => source.api_key,
        "file_type" => "json",
        "series_id" => String(series_id),
    )

    _set_query_param!(query, "observation_start", options.observation_start)
    _set_query_param!(query, "observation_end", options.observation_end)
    _set_query_param!(query, "realtime_start", options.realtime_start)
    _set_query_param!(query, "realtime_end", options.realtime_end)
    _set_query_param!(query, "limit", options.limit)
    _set_query_param!(query, "offset", options.offset)
    _set_query_param!(query, "sort_order", options.sort_order)
    _set_query_param!(query, "units", options.units)
    _set_query_param!(query, "frequency", options.frequency)
    _set_query_param!(query, "aggregation_method", options.aggregation_method)
    _set_query_param!(query, "output_type", options.output_type)
    _set_query_param!(query, "vintage_dates", options.vintage_dates)

    return (
        method="GET",
        base_url=_FRED_BASE_URL,
        path=_FRED_OBSERVATIONS_PATH,
        url=string(_FRED_BASE_URL, _FRED_OBSERVATIONS_PATH),
        query=query,
    )
end

"""
    _canonical_cache_key(request) -> String

Create a deterministic cache key for an internal request description.
"""
function _canonical_cache_key(request)::String
    method = getproperty(request, :method)
    base_url = getproperty(request, :base_url)
    path = getproperty(request, :path)
    query = getproperty(request, :query)

    pairs = String[]
    for key in sort!(collect(keys(query)))
        value = key == "api_key" ? "<redacted>" : query[key]
        push!(pairs, string(key, "=", value))
    end

    return string(method, "|", base_url, "|", path, "|", join(pairs, "&"))
end

function _set_query_param!(query::Dict{String,String}, key::AbstractString, value)
    isnothing(value) && return query
    query[String(key)] = _serialize_request_value(value)
    return query
end

function _serialize_request_value(value::Date)::String
    return Dates.format(value, dateformat"yyyy-mm-dd")
end

function _serialize_request_value(value::Symbol)::String
    return string(value)
end

function _serialize_request_value(value::AbstractVector{<:Date})::String
    return join((_serialize_request_value(item) for item in value), ",")
end

function _serialize_request_value(value)::String
    return string(value)
end

function _fetch_one_series(
    series_id::AbstractString,
    source::Fred,
    options::FredObservationsOptions,
)::DataFrame
    request = _build_request(series_id, source, options)
    body = _send_request(request, source)
    return _parse_response(body, source, series_id)
end
