using MacroDataFetchers
using Test

@testset "milestone 1 internal smoke checks" begin
    @testset "public exports" begin
        for name in (:AbstractDataSource, :Fred, :fetch_data, :clear_cache!)
            @test name in names(MacroDataFetchers)
            @test isdefined(MacroDataFetchers, name)
        end
    end

    @testset "core types" begin
        @test MacroDataFetchers.Fred <: MacroDataFetchers.AbstractDataSource

        cache = MacroDataFetchers.MemoryCache()
        @test cache.store == Dict{String,String}()
        @test isempty(cache.store)
    end

    @testset "custom errors" begin
        err = MacroDataFetchers.ConfigurationError("missing API key")
        @test err isa Exception
        @test sprint(showerror, err) == "ConfigurationError: missing API key"
    end

    @testset "public stubs" begin
        fred = MacroDataFetchers.Fred()

        @test_throws ErrorException fetch_data("GDP", fred)
        @test_throws ErrorException fetch_data(["GDP"], fred)
        @test_throws MethodError clear_cache!(fred)
    end
end
