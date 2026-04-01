module MacroDataFetchers

using Dates

include("sources/abstract_source.jl")
include("core/types.jl")
include("core/errors.jl")
include("core/cache.jl")
include("core/utils.jl")
include("core/options.jl")
include("sources/fred/fred.jl")
include("core/fetch.jl")

export AbstractDataSource, Fred, fetch_data, clear_cache!

end
