module MacroDataFetchers

using Dates

abstract type AbstractDataSource end
abstract type AbstractDataStandardiser end

struct Fred <: AbstractDataSource end

function fetch_data(
    series::Union{String,Vector{String}},
    source::AbstractDataSource,
    from::Date,
    to::Date;
    kwargs...,
)
    # build request
    # call API
    # parse response
    # return output
end

function _build_request(::AbstractDataSource, args...; kwargs...) end

function _parse_request(::AbstractDataSource, args...; kwargs...) end

end
