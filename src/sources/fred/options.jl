"""
    FredObservationsOptions

Normalized options for FRED observations requests.
"""
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

const _FRED_ALLOWED_PROVIDER_KWARGS = (
    :observation_start,
    :observation_end,
    :realtime_start,
    :realtime_end,
    :limit,
    :offset,
    :sort_order,
    :units,
    :frequency,
    :aggregation_method,
    :output_type,
    :vintage_dates,
)

const _FRED_SORT_ORDER_VALUES = (:asc, :desc)
const _FRED_UNITS_VALUES = (:lin, :chg, :ch1, :pch, :pc1, :pca, :cch, :cca, :log)
const _FRED_FREQUENCY_VALUES = (
    :d,
    :w,
    :bw,
    :m,
    :q,
    :sa,
    :a,
    :wef,
    :weth,
    :wew,
    :wetu,
    :wem,
    :wesu,
    :wesa,
    :bwew,
    :bwem,
)
const _FRED_AGGREGATION_METHOD_VALUES = (:avg, :sum, :eop)

"""
    _normalize_provider_options(source::Fred, options::FetchOptions) -> FredObservationsOptions

Normalize generic and FRED-specific options into typed FRED observations
request options.
"""
function _normalize_provider_options(source::Fred, options::FetchOptions)::FredObservationsOptions
    _validate_provider_kwargs(source, options.provider_kwargs)

    provider_kwargs = options.provider_kwargs
    observation_start_input = get(provider_kwargs, :observation_start, nothing)
    observation_end_input = get(provider_kwargs, :observation_end, nothing)

    observation_start, observation_end = _resolve_date_conflicts(
        options.start_date,
        options.end_date,
        _parse_date(observation_start_input),
        _parse_date(observation_end_input),
    )

    return FredObservationsOptions(
        observation_start,
        observation_end,
        _parse_date(get(provider_kwargs, :realtime_start, nothing)),
        _parse_date(get(provider_kwargs, :realtime_end, nothing)),
        _normalize_optional_int(get(provider_kwargs, :limit, nothing), :limit),
        _normalize_optional_int(get(provider_kwargs, :offset, nothing), :offset),
        _normalize_symbol_option(get(provider_kwargs, :sort_order, nothing), _FRED_SORT_ORDER_VALUES, :sort_order),
        _normalize_symbol_option(get(provider_kwargs, :units, nothing), _FRED_UNITS_VALUES, :units),
        _normalize_symbol_option(get(provider_kwargs, :frequency, nothing), _FRED_FREQUENCY_VALUES, :frequency),
        _normalize_symbol_option(
            get(provider_kwargs, :aggregation_method, nothing),
            _FRED_AGGREGATION_METHOD_VALUES,
            :aggregation_method,
        ),
        _normalize_optional_int(get(provider_kwargs, :output_type, nothing), :output_type),
        _normalize_vintage_dates(get(provider_kwargs, :vintage_dates, nothing)),
    )
end

"""
    _validate_provider_kwargs(source::Fred, kwargs::NamedTuple) -> Nothing

Validate that only supported FRED-native kwargs are provided.
"""
function _validate_provider_kwargs(::Fred, kwargs::NamedTuple)::Nothing
    unknown = [name for name in keys(kwargs) if name ∉ _FRED_ALLOWED_PROVIDER_KWARGS]

    isempty(unknown) || throw(ValidationError("Unknown FRED keyword argument(s): $(join(string.(unknown), ", "))."))
    return nothing
end

"""
    _resolve_date_conflicts(start_date, end_date, observation_start, observation_end)

Resolve generic and FRED-native observation date inputs.
"""
function _resolve_date_conflicts(
    start_date::Union{Nothing,Date},
    end_date::Union{Nothing,Date},
    observation_start::Union{Nothing,Date},
    observation_end::Union{Nothing,Date},
)::Tuple{Union{Nothing,Date},Union{Nothing,Date}}
    resolved_start = _resolve_single_date_conflict(:start_date, :observation_start, start_date, observation_start)
    resolved_end = _resolve_single_date_conflict(:end_date, :observation_end, end_date, observation_end)
    return resolved_start, resolved_end
end

function _resolve_single_date_conflict(
    generic_name::Symbol,
    provider_name::Symbol,
    generic_value::Union{Nothing,Date},
    provider_value::Union{Nothing,Date},
)::Union{Nothing,Date}
    if !isnothing(generic_value) && !isnothing(provider_value) && generic_value != provider_value
        throw(ValidationError("Conflicting values for `$(generic_name)` and `$(provider_name)`."))
    end

    return isnothing(provider_value) ? generic_value : provider_value
end

"""
    _normalize_symbol_option(x, allowed, option_name) -> Union{Nothing, Symbol}

Normalize enum-like FRED options to canonical symbols.
"""
function _normalize_symbol_option(x, allowed, option_name::Symbol)::Union{Nothing,Symbol}
    if isnothing(x)
        return nothing
    end

    value = if x isa Symbol
        x
    elseif x isa AbstractString
        Symbol(String(x))
    else
        throw(ValidationError("`$(option_name)` must be a Symbol or String."))
    end

    value in allowed || throw(ValidationError("Invalid value for `$(option_name)`: `$(value)`."))
    return value
end

function _normalize_optional_int(x, option_name::Symbol)::Union{Nothing,Int}
    if isnothing(x)
        return nothing
    elseif x isa Integer
        return Int(x)
    end

    throw(ValidationError("`$(option_name)` must be an integer or `nothing`."))
end

function _normalize_vintage_dates(x)::Union{Nothing,Vector{Date}}
    if isnothing(x)
        return nothing
    elseif x isa AbstractVector
        return [_parse_date(value) for value in x]
    end

    throw(ValidationError("`vintage_dates` must be a vector of `Date` values or ISO date strings."))
end
