"""
    clear_cache!(source::AbstractDataSource) -> Nothing

Clear any in-memory cache attached to `source`.
Concrete source implementations add the provider-specific behavior.
"""
function clear_cache!(source::AbstractDataSource)::Nothing
    throw(MethodError(clear_cache!, (source,)))
end
