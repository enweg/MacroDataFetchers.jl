"""
    _normalize_fetch_options(; start_date=nothing, end_date=nothing, on_error=:raise, kwargs...)

Normalize generic fetch keyword arguments into a typed `FetchOptions` value.
"""
function _normalize_fetch_options(; start_date=nothing, end_date=nothing, on_error=:raise, kwargs...)
    return FetchOptions(
        _parse_date(start_date),
        _parse_date(end_date),
        _validate_on_error(on_error),
        (; kwargs...),
    )
end

"""
    _validate_on_error(on_error) -> Symbol

Validate the generic `on_error` mode.
"""
function _validate_on_error(on_error)::Symbol
    on_error isa Symbol || throw(ValidationError("`on_error` must be a Symbol with value `:raise` or `:skip`."))
    on_error in (:raise, :skip) || throw(ValidationError("`on_error` must be `:raise` or `:skip`."))
    return on_error
end

"""
    _parse_date(x) -> Union{Nothing, Date}

Normalize supported date inputs to `Date`.
"""
function _parse_date(x)::Union{Nothing,Date}
    if isnothing(x)
        return nothing
    elseif x isa Date
        return x
    elseif x isa DateTime
        throw(ValidationError("Date values must be `Date` or ISO `yyyy-mm-dd` strings, not `DateTime`."))
    elseif x isa AbstractString
        value = strip(String(x))
        occursin(r"^\d{4}-\d{2}-\d{2}$", value) ||
            throw(ValidationError("Date strings must use ISO `yyyy-mm-dd` format."))

        try
            return Date(value, dateformat"yyyy-mm-dd")
        catch _
            throw(ValidationError("Invalid ISO date string: `$(value)`."))
        end
    end

    throw(ValidationError("Date values must be `Date`, ISO `yyyy-mm-dd` strings, or `nothing`."))
end
