"""
    AbstractDataSource

Abstract supertype for data providers supported by `MacroDataFetchers`.
Concrete sources such as [`Fred`](@ref) subtype `AbstractDataSource` and are
passed to [`fetch_data`](@ref).

`MacroDataFetchers.jl` keeps the public interface source-agnostic by dispatching
on `AbstractDataSource`, while each concrete source is responsible for provider-
specific option normalization, request construction, and response parsing.
"""
abstract type AbstractDataSource end
