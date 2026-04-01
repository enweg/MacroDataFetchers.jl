using MacroDataFetchers
using Test

@testset "internal smoke checks" begin
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
        original_requester = MacroDataFetchers._HTTP_REQUESTER[]
        MacroDataFetchers._HTTP_REQUESTER[] = (request, source) -> (
            status=200,
            body="""
            {
              "observations": [
                {
                  "realtime_start": "2024-01-01",
                  "realtime_end": "2024-01-01",
                  "date": "2024-01-01",
                  "value": "1.0"
                }
              ]
            }
            """,
        )

        try
            fred = MacroDataFetchers.Fred(
                api_key="smoke-key",
                use_cache=false,
                timeout_seconds=12,
                max_retries=1,
            )

            single = fetch_data("GDP", fred)
            multi = fetch_data(["GDP", "CPI"], fred; on_error=:skip)

            @test size(single) == (1, 7)
            @test single.series_id == ["GDP"]
            @test multi.series_id == ["GDP", "CPI"]
            @test clear_cache!(fred) === nothing

            display_text = sprint(show, fred)
            @test occursin("Fred(", display_text)
            @test occursin("api_key=present", display_text)
            @test occursin("use_cache=false", display_text)
            @test occursin("timeout_seconds=12.0", display_text)
            @test !occursin("smoke-key", display_text)
        finally
            MacroDataFetchers._HTTP_REQUESTER[] = original_requester
        end
    end
end
