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
