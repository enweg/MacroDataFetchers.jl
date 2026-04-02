const _HTTP_REQUESTER = Ref{Function}()
const _RETRY_SLEEP = Ref{Function}()

function _get_cached_response(source::Fred, cache_key::AbstractString)::Union{Nothing,String}
    source.use_cache || return nothing
    return get(source._cache.store, String(cache_key), nothing)
end

function _set_cached_response!(source::Fred, cache_key::AbstractString, body::AbstractString)::Nothing
    source.use_cache || return nothing
    source._cache.store[String(cache_key)] = String(body)
    return nothing
end

"""
    _send_request(request, source::Fred) -> String

Send an internal FRED request with retry and cache handling.
"""
function _send_request(request, source::Fred)::String
    cache_key = _canonical_cache_key(request)
    cached_body = _get_cached_response(source, cache_key)
    !isnothing(cached_body) && return cached_body

    last_error = nothing

    for attempt in 0:source.max_retries
        try
            response = _HTTP_REQUESTER[](request, source)
            status = Int(getproperty(response, :status))
            body = String(getproperty(response, :body))

            if 200 <= status < 300
                _set_cached_response!(source, cache_key, body)
                return body
            end

            last_error = RequestError("FRED request failed.", status, body)
        catch err
            if err isa RequestError
                last_error = err
            else
                last_error = RequestError("FRED request failed: $(sprint(showerror, err))", nothing, nothing)
            end
        end

        if attempt < source.max_retries && _should_retry(last_error)
            _RETRY_SLEEP[](_retry_delay_seconds(attempt))
            continue
        end

        throw(last_error)
    end

    throw(last_error)
end

function _default_http_request(request, source::Fred)
    response = HTTP.request(
        request.method,
        request.url;
        query=request.query,
        readtimeout=ceil(Int, source.timeout_seconds),
        status_exception=false,
    )

    return (status=Int(response.status), body=response.body)
end

function _should_retry(err::RequestError)::Bool
    return isnothing(err.status) || 500 <= err.status < 600
end

function _retry_delay_seconds(attempt::Integer)::Float64
    return 0.1 * (2.0 ^ attempt)
end

_HTTP_REQUESTER[] = _default_http_request
_RETRY_SLEEP[] = sleep
