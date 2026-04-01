"""
    AbstractDataSource

Abstract supertype for data providers supported by `MacroDataFetchers`.
Concrete sources such as [`Fred`](@ref) subtype `AbstractDataSource` and are
passed to [`fetch_data`](@ref).
"""
abstract type AbstractDataSource end
