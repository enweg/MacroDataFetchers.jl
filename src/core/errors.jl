abstract type MacroDataFetchersError <: Exception end

struct ConfigurationError <: MacroDataFetchersError
    msg::String
end

struct ValidationError <: MacroDataFetchersError
    msg::String
end

struct RequestBuildError <: MacroDataFetchersError
    msg::String
end

struct RequestError <: MacroDataFetchersError
    msg::String
    status::Union{Nothing,Int}
    body::Union{Nothing,String}
end

struct ResponseParseError <: MacroDataFetchersError
    msg::String
    body::Union{Nothing,String}
end

function Base.showerror(io::IO, err::ConfigurationError)
    print(io, "ConfigurationError: ", err.msg)
end

function Base.showerror(io::IO, err::ValidationError)
    print(io, "ValidationError: ", err.msg)
end

function Base.showerror(io::IO, err::RequestBuildError)
    print(io, "RequestBuildError: ", err.msg)
end

function Base.showerror(io::IO, err::RequestError)
    print(io, "RequestError: ", err.msg)
    if !isnothing(err.status)
        print(io, " (status=", err.status, ")")
    end
end

function Base.showerror(io::IO, err::ResponseParseError)
    print(io, "ResponseParseError: ", err.msg)
end
