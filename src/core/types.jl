"""
    MemoryCache()
    MemoryCache(store)

In-memory cache container for response bodies stored during the current Julia
session.
"""
mutable struct MemoryCache
    store::Dict{String,String}
end

MemoryCache() = MemoryCache(Dict{String,String}())

"""
    FetchOptions

Normalized generic fetch options shared across data sources.
"""
struct FetchOptions
    start_date::Union{Nothing,Date}
    end_date::Union{Nothing,Date}
    on_error::Symbol
    provider_kwargs::NamedTuple
end
