using MacroDataFetchers
using Dates
using Test

function with_clean_fred_env(f::Function)
    withenv("FRED_API_KEY" => nothing) do
        f()
    end
end

@testset "MacroDataFetchers.jl" begin
    @testset "dotenv parsing" begin
        mktempdir() do dir
            dotenv_path = joinpath(dir, ".env")
            write(
                dotenv_path,
                """
                # comment
                FRED_API_KEY = from_dotenv
                OTHER_KEY="quoted value"
                SINGLE='single quoted'

                """,
            )

            parsed = MacroDataFetchers._load_dotenv(dotenv_path)
            @test parsed["FRED_API_KEY"] == "from_dotenv"
            @test parsed["OTHER_KEY"] == "quoted value"
            @test parsed["SINGLE"] == "single quoted"
        end

        mktempdir() do dir
            @test MacroDataFetchers._load_dotenv(joinpath(dir, ".env")) == Dict{String,String}()
        end
    end

    @testset "Fred constructor" begin
        with_clean_fred_env() do
            fred = Fred(api_key=" explicit-key ", timeout_seconds=15, max_retries=3)
            @test fred.api_key == "explicit-key"
            @test fred.use_cache === true
            @test fred.timeout_seconds == 15.0
            @test fred.max_retries == 3
            @test fred._cache isa MacroDataFetchers.MemoryCache
            @test isempty(fred._cache.store)
        end

        with_clean_fred_env() do
            withenv("FRED_API_KEY" => "env-key") do
                mktempdir() do dir
                    cd(dir) do
                        write(".env", "FRED_API_KEY=dotenv-key\n")
                        fred = Fred()
                        @test fred.api_key == "env-key"
                    end
                end
            end
        end

        with_clean_fred_env() do
            mktempdir() do dir
                cd(dir) do
                    write(".env", "FRED_API_KEY=dotenv-key\n")
                    fred = Fred()
                    @test fred.api_key == "dotenv-key"
                end
            end
        end

        with_clean_fred_env() do
            mktempdir() do dir
                cd(dir) do
                    @test_throws MacroDataFetchers.ConfigurationError Fred()
                end
            end
        end
    end

    @testset "Fred validation and display" begin
        @test_throws MacroDataFetchers.ValidationError Fred(api_key="key", timeout_seconds=0)
        @test_throws MacroDataFetchers.ValidationError Fred(api_key="key", max_retries=-1)
        @test_throws MacroDataFetchers.ConfigurationError Fred(api_key="   ")
    end

    @testset "clear_cache!" begin
        fred = Fred(api_key="cache-key")
        fred._cache.store["request"] = "response"

        result = clear_cache!(fred)

        @test result === nothing
        @test isempty(fred._cache.store)
    end

    @testset "generic option normalization" begin
        @test MacroDataFetchers._parse_date(nothing) === nothing
        @test MacroDataFetchers._parse_date(Date(2024, 1, 15)) == Date(2024, 1, 15)
        @test MacroDataFetchers._parse_date("2024-01-15") == Date(2024, 1, 15)

        @test_throws MacroDataFetchers.ValidationError MacroDataFetchers._parse_date(DateTime(2024, 1, 15))
        @test_throws MacroDataFetchers.ValidationError MacroDataFetchers._parse_date("01/15/2024")
        @test_throws MacroDataFetchers.ValidationError MacroDataFetchers._parse_date("2024-1-15")
        @test_throws MacroDataFetchers.ValidationError MacroDataFetchers._parse_date(123)

        @test MacroDataFetchers._validate_on_error(:raise) == :raise
        @test MacroDataFetchers._validate_on_error(:skip) == :skip
        @test_throws MacroDataFetchers.ValidationError MacroDataFetchers._validate_on_error(:warn)
        @test_throws MacroDataFetchers.ValidationError MacroDataFetchers._validate_on_error("raise")

        options = MacroDataFetchers._normalize_fetch_options(
            start_date="2024-01-01",
            end_date=Date(2024, 2, 1),
            on_error=:skip,
            observation_start="2020-01-01",
            limit=1000,
        )

        @test options isa MacroDataFetchers.FetchOptions
        @test options.start_date == Date(2024, 1, 1)
        @test options.end_date == Date(2024, 2, 1)
        @test options.on_error == :skip
        @test options.provider_kwargs == (observation_start="2020-01-01", limit=1000)
    end

    @testset "fetch_data generic validation" begin
        fred = Fred(api_key="fetch-key")

        @test_throws MacroDataFetchers.ValidationError fetch_data("GDP", fred; on_error=:warn)
        @test_throws MacroDataFetchers.ValidationError fetch_data("GDP", fred; start_date="01/01/2024")
        @test_throws ErrorException fetch_data("GDP", fred; start_date="2024-01-01", on_error=:skip)
    end
end
