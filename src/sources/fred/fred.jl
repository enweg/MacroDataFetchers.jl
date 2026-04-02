const _FRED_API_KEY_ENV = "FRED_API_KEY"

"""
    Fred
    Fred(; api_key=nothing, use_cache=true, timeout_seconds=30, max_retries=2)

Data source for the Federal Reserve Economic Data (FRED) API.

# Arguments
- `api_key`: Optional FRED API key. Resolution order is the explicit keyword,
  `ENV["FRED_API_KEY"]`, and then a local `.env` file.
- `use_cache`: When `true`, successful raw HTTP responses are cached in memory
  on the `Fred` instance for the current Julia session.
- `timeout_seconds`: Request timeout passed to the HTTP layer.
- `max_retries`: Number of retry attempts for transient request failures.

# Errors
- `ConfigurationError` if no API key can be resolved.
- `ValidationError` if `timeout_seconds <= 0` or `max_retries < 0`.

# Examples
```julia
julia> fred = Fred(api_key="your-fred-api-key", use_cache=true)
Fred(api_key=present, use_cache=true, timeout_seconds=30.0, max_retries=2, cache_entries=0)
```
"""
struct Fred <: AbstractDataSource
    api_key::String
    use_cache::Bool
    timeout_seconds::Float64
    max_retries::Int
    _cache::MemoryCache
end

function Fred(; api_key=nothing, use_cache::Bool=true, timeout_seconds=30, max_retries=2)
    resolved_api_key = _resolve_fred_api_key(api_key)
    resolved_timeout = Float64(timeout_seconds)
    resolved_timeout > 0 || throw(ValidationError("`timeout_seconds` must be greater than 0."))

    resolved_retries = Int(max_retries)
    resolved_retries >= 0 || throw(ValidationError("`max_retries` must be greater than or equal to 0."))

    return Fred(
        resolved_api_key,
        use_cache,
        resolved_timeout,
        resolved_retries,
        MemoryCache(),
    )
end

function _resolve_fred_api_key(api_key)::String
    if !isnothing(api_key)
        return _normalize_fred_api_key(api_key)
    end

    env_api_key = get(ENV, _FRED_API_KEY_ENV, nothing)
    if !isnothing(env_api_key)
        return _normalize_fred_api_key(env_api_key)
    end

    dotenv_api_key = get(_load_dotenv(), _FRED_API_KEY_ENV, nothing)
    if !isnothing(dotenv_api_key)
        return _normalize_fred_api_key(dotenv_api_key)
    end

    throw(ConfigurationError("FRED API key not found. Set `api_key`, `ENV[\"FRED_API_KEY\"]`, or provide it in `.env`."))
end

function _normalize_fred_api_key(api_key)::String
    value = api_key isa AbstractString ? String(api_key) : string(api_key)
    stripped = strip(value)

    if isempty(stripped)
        throw(ConfigurationError("FRED API key must not be empty."))
    end

    return stripped
end

"""
    clear_cache!(source::Fred) -> Nothing

Remove all cached raw HTTP responses stored on `source`.
"""
function clear_cache!(source::Fred)::Nothing
    empty!(source._cache.store)
    return nothing
end

function Base.show(io::IO, fred::Fred)
    print(
        io,
        "Fred(",
        "api_key=present, ",
        "use_cache=", fred.use_cache, ", ",
        "timeout_seconds=", fred.timeout_seconds, ", ",
        "max_retries=", fred.max_retries, ", ",
        "cache_entries=", length(fred._cache.store),
        ")",
    )
end
