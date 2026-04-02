using MacroDataFetchers
using DataFrames
using Dates
using Logging
using Test

function with_clean_fred_env(f::Function)
    withenv("FRED_API_KEY" => nothing) do
        f()
    end
end

function _should_run_live_tests()::Bool
    has_api_key = haskey(ENV, "FRED_API_KEY") && !isempty(strip(ENV["FRED_API_KEY"]))
    return has_api_key && get(ENV, "RUN_LIVE_TESTS", "false") == "true"
end

function with_mock_http(
    f::Function,
    requester::Function;
    sleeper::Function = (seconds -> nothing),
)
    original_requester = MacroDataFetchers._HTTP_REQUESTER[]
    original_sleeper = MacroDataFetchers._RETRY_SLEEP[]
    MacroDataFetchers._HTTP_REQUESTER[] = requester
    MacroDataFetchers._RETRY_SLEEP[] = sleeper

    try
        f()
    finally
        MacroDataFetchers._HTTP_REQUESTER[] = original_requester
        MacroDataFetchers._RETRY_SLEEP[] = original_sleeper
    end
end

function capture_request_error(f::Function)
    try
        f()
        error("expected RequestError")
    catch err
        err isa MacroDataFetchers.RequestError || rethrow()
        return err
    end
end

function capture_warnings(f::Function)
    io = IOBuffer()
    logger = SimpleLogger(io, Logging.Warn)

    with_logger(logger) do
        f()
    end

    seekstart(io)
    return String(take!(io))
end

function response_body_for(series_id, values)
    observations_json = join(["""
                              {
                                "realtime_start": "2024-01-01",
                                "realtime_end": "2024-01-01",
                                "date": "$(date)",
                                "value": "$(value)"
                              }
                              """ for (date, value) in values], ",")

    return """
    {
      "observations": [
        $(observations_json)
      ]
    }
    """
end

function with_fetch_mock(f::Function; use_cache = false)
    fred = Fred(
        api_key = "mock-fetch-key",
        use_cache = use_cache,
        timeout_seconds = 12,
        max_retries = 1,
    )

    with_mock_http(
        (req, src) -> begin
            series_id = req.query["series_id"]
            return (
                status = 200,
                body = response_body_for(series_id, [("2024-01-01", "1.0")]),
            )
        end,
    ) do
        f(fred)
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
            @test MacroDataFetchers._load_dotenv(joinpath(dir, ".env")) ==
                  Dict{String,String}()
        end
    end

    @testset "Fred constructor" begin
        with_clean_fred_env() do
            fred = Fred(api_key = " explicit-key ", timeout_seconds = 15, max_retries = 3)
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
        @test_throws MacroDataFetchers.ValidationError Fred(
            api_key = "key",
            timeout_seconds = 0,
        )
        @test_throws MacroDataFetchers.ValidationError Fred(
            api_key = "key",
            max_retries = -1,
        )
        @test_throws MacroDataFetchers.ConfigurationError Fred(api_key = "   ")
    end

    @testset "live test gating" begin
        withenv("FRED_API_KEY" => nothing, "RUN_LIVE_TESTS" => nothing) do
            @test !_should_run_live_tests()
        end

        withenv("FRED_API_KEY" => "live-key", "RUN_LIVE_TESTS" => "false") do
            @test !_should_run_live_tests()
        end

        withenv("FRED_API_KEY" => "   ", "RUN_LIVE_TESTS" => "true") do
            @test !_should_run_live_tests()
        end

        withenv("FRED_API_KEY" => nothing, "RUN_LIVE_TESTS" => "true") do
            @test !_should_run_live_tests()
        end

        withenv("FRED_API_KEY" => "live-key", "RUN_LIVE_TESTS" => "true") do
            @test _should_run_live_tests()
        end
    end

    @testset "clear_cache!" begin
        fred = Fred(api_key = "cache-key")
        fred._cache.store["request"] = "response"

        result = clear_cache!(fred)

        @test result === nothing
        @test isempty(fred._cache.store)
    end

    @testset "generic option normalization" begin
        @test MacroDataFetchers._parse_date(nothing) === nothing
        @test MacroDataFetchers._parse_date(Date(2024, 1, 15)) == Date(2024, 1, 15)
        @test MacroDataFetchers._parse_date("2024-01-15") == Date(2024, 1, 15)

        @test_throws MacroDataFetchers.ValidationError MacroDataFetchers._parse_date(
            DateTime(2024, 1, 15),
        )
        @test_throws MacroDataFetchers.ValidationError MacroDataFetchers._parse_date(
            "01/15/2024",
        )
        @test_throws MacroDataFetchers.ValidationError MacroDataFetchers._parse_date(
            "2024-1-15",
        )
        @test_throws MacroDataFetchers.ValidationError MacroDataFetchers._parse_date(123)

        @test MacroDataFetchers._validate_on_error(:raise) == :raise
        @test MacroDataFetchers._validate_on_error(:skip) == :skip
        @test_throws MacroDataFetchers.ValidationError MacroDataFetchers._validate_on_error(
            :warn,
        )
        @test_throws MacroDataFetchers.ValidationError MacroDataFetchers._validate_on_error(
            "raise",
        )

        options = MacroDataFetchers._normalize_fetch_options(
            start_date = "2024-01-01",
            end_date = Date(2024, 2, 1),
            on_error = :skip,
            observation_start = "2020-01-01",
            limit = 1000,
        )

        @test options isa MacroDataFetchers.FetchOptions
        @test options.start_date == Date(2024, 1, 1)
        @test options.end_date == Date(2024, 2, 1)
        @test options.on_error == :skip
        @test options.provider_kwargs == (observation_start = "2020-01-01", limit = 1000)
    end

    @testset "fetch_data generic validation" begin
        fred = Fred(api_key = "fetch-key")

        @test_throws MacroDataFetchers.ValidationError fetch_data(
            "GDP",
            fred;
            on_error = :warn,
        )
        @test_throws MacroDataFetchers.ValidationError fetch_data(
            "GDP",
            fred;
            start_date = "01/01/2024",
        )

        with_mock_http(
            (req, src) ->
                (status = 200, body = response_body_for("GDP", [("2024-01-01", "1.0")])),
        ) do
            df = fetch_data("GDP", fred; start_date = "2024-01-01", on_error = :skip)
            @test size(df) == (1, 7)
        end
    end

    @testset "FRED provider option normalization" begin
        fred = Fred(api_key = "options-key")

        options = MacroDataFetchers._normalize_fetch_options(
            start_date = "2020-01-01",
            end_date = Date(2020, 12, 31),
            on_error = :raise,
            realtime_start = "2019-01-01",
            realtime_end = Date(2019, 12, 31),
            limit = 1000,
            offset = 10,
            sort_order = "asc",
            units = :lin,
            frequency = "m",
            aggregation_method = :avg,
            output_type = 4,
            vintage_dates = ["2020-03-01", Date(2020, 4, 1)],
        )

        normalized = MacroDataFetchers._normalize_provider_options(fred, options)

        @test normalized isa MacroDataFetchers.FredObservationsOptions
        @test normalized.observation_start == Date(2020, 1, 1)
        @test normalized.observation_end == Date(2020, 12, 31)
        @test normalized.realtime_start == Date(2019, 1, 1)
        @test normalized.realtime_end == Date(2019, 12, 31)
        @test normalized.limit == 1000
        @test normalized.offset == 10
        @test normalized.sort_order == :asc
        @test normalized.units == :lin
        @test normalized.frequency == :m
        @test normalized.aggregation_method == :avg
        @test normalized.output_type == 4
        @test normalized.vintage_dates == [Date(2020, 3, 1), Date(2020, 4, 1)]
    end

    @testset "FRED provider validation" begin
        fred = Fred(api_key = "validation-key")

        @test_throws MacroDataFetchers.ValidationError MacroDataFetchers._validate_provider_kwargs(
            fred,
            (unknown_option = 1,),
        )

        @test_throws MacroDataFetchers.ValidationError MacroDataFetchers._normalize_symbol_option(
            "ASC",
            (:asc, :desc),
            :sort_order,
        )
        @test_throws MacroDataFetchers.ValidationError MacroDataFetchers._normalize_symbol_option(
            1,
            (:asc, :desc),
            :sort_order,
        )

        @test_throws MacroDataFetchers.ValidationError MacroDataFetchers._resolve_date_conflicts(
            Date(2020, 1, 1),
            nothing,
            Date(2021, 1, 1),
            nothing,
        )

        same_dates = MacroDataFetchers._resolve_date_conflicts(
            Date(2020, 1, 1),
            Date(2020, 12, 31),
            Date(2020, 1, 1),
            Date(2020, 12, 31),
        )
        @test same_dates == (Date(2020, 1, 1), Date(2020, 12, 31))

        @test_throws MacroDataFetchers.ValidationError MacroDataFetchers._normalize_provider_options(
            fred,
            MacroDataFetchers._normalize_fetch_options(unknown_option = 1),
        )
        @test_throws MacroDataFetchers.ValidationError MacroDataFetchers._normalize_provider_options(
            fred,
            MacroDataFetchers._normalize_fetch_options(sort_order = "ASC"),
        )
        @test_throws MacroDataFetchers.ValidationError MacroDataFetchers._normalize_provider_options(
            fred,
            MacroDataFetchers._normalize_fetch_options(
                start_date = "2020-01-01",
                observation_start = "2021-01-01",
            ),
        )

        @test_throws MacroDataFetchers.ValidationError fetch_data(
            "GDP",
            fred;
            sort_order = "ASC",
        )
        @test_throws MacroDataFetchers.ValidationError fetch_data(
            "GDP",
            fred;
            start_date = "2020-01-01",
            observation_start = "2021-01-01",
        )
    end

    @testset "FRED request building and cache keys" begin
        fred = Fred(api_key = "request-key")
        options = MacroDataFetchers.FredObservationsOptions(
            Date(2020, 1, 1),
            Date(2020, 12, 31),
            Date(2019, 1, 1),
            Date(2019, 12, 31),
            1000,
            10,
            :asc,
            :lin,
            :m,
            :avg,
            4,
            [Date(2020, 3, 1), Date(2020, 4, 1)],
        )

        request = MacroDataFetchers._build_request("GDP", fred, options)

        @test request.method == "GET"
        @test request.base_url == MacroDataFetchers._FRED_BASE_URL
        @test request.path == MacroDataFetchers._FRED_OBSERVATIONS_PATH
        @test request.url == "https://api.stlouisfed.org/fred/series/observations"
        @test request.query["api_key"] == "request-key"
        @test request.query["file_type"] == "json"
        @test request.query["series_id"] == "GDP"
        @test request.query["observation_start"] == "2020-01-01"
        @test request.query["observation_end"] == "2020-12-31"
        @test request.query["realtime_start"] == "2019-01-01"
        @test request.query["realtime_end"] == "2019-12-31"
        @test request.query["limit"] == "1000"
        @test request.query["offset"] == "10"
        @test request.query["sort_order"] == "asc"
        @test request.query["units"] == "lin"
        @test request.query["frequency"] == "m"
        @test request.query["aggregation_method"] == "avg"
        @test request.query["output_type"] == "4"
        @test request.query["vintage_dates"] == "2020-03-01,2020-04-01"

        reordered_request = (
            method = "GET",
            base_url = MacroDataFetchers._FRED_BASE_URL,
            path = MacroDataFetchers._FRED_OBSERVATIONS_PATH,
            query = Dict(
                "series_id" => "GDP",
                "file_type" => "json",
                "api_key" => "different-key",
                "limit" => "1000",
                "observation_start" => "2020-01-01",
            ),
        )
        reordered_request_same_semantics = (
            method = "GET",
            base_url = MacroDataFetchers._FRED_BASE_URL,
            path = MacroDataFetchers._FRED_OBSERVATIONS_PATH,
            query = Dict(
                "observation_start" => "2020-01-01",
                "limit" => "1000",
                "api_key" => "another-key",
                "file_type" => "json",
                "series_id" => "GDP",
            ),
        )

        @test MacroDataFetchers._canonical_cache_key(reordered_request) ==
              MacroDataFetchers._canonical_cache_key(reordered_request_same_semantics)
        @test occursin("file_type=json", MacroDataFetchers._canonical_cache_key(request))
        @test !occursin("request-key", MacroDataFetchers._canonical_cache_key(request))

        @test_throws MacroDataFetchers.RequestBuildError MacroDataFetchers._build_request(
            "   ",
            fred,
            options,
        )
    end

    @testset "FRED HTTP layer, retries, and cache" begin
        options = MacroDataFetchers.FredObservationsOptions(
            Date(2020, 1, 1),
            nothing,
            nothing,
            nothing,
            nothing,
            nothing,
            nothing,
            nothing,
            nothing,
            nothing,
            nothing,
            nothing,
        )

        @testset "successful response is cached" begin
            fred = Fred(api_key = "cache-http-key", max_retries = 2)
            request = MacroDataFetchers._build_request("GDP", fred, options)
            calls = Ref(0)

            with_mock_http(
                (req, src) -> begin
                    calls[] += 1
                    return (status = 200, body = "body-from-network")
                end,
            ) do
                body1 = MacroDataFetchers._send_request(request, fred)
                body2 = MacroDataFetchers._send_request(request, fred)

                @test body1 == "body-from-network"
                @test body2 == "body-from-network"
                @test calls[] == 1
                @test length(fred._cache.store) == 1
            end
        end

        @testset "cache disabled bypasses store" begin
            fred = Fred(api_key = "no-cache-key", use_cache = false, max_retries = 1)
            request = MacroDataFetchers._build_request("GDP", fred, options)
            calls = Ref(0)

            with_mock_http((req, src) -> begin
                calls[] += 1
                return (status = 200, body = "fresh-body")
            end) do
                @test MacroDataFetchers._send_request(request, fred) == "fresh-body"
                @test MacroDataFetchers._send_request(request, fred) == "fresh-body"
                @test calls[] == 2
                @test isempty(fred._cache.store)
            end
        end

        @testset "transient failure retries then succeeds" begin
            fred = Fred(api_key = "retry-key", max_retries = 2)
            request = MacroDataFetchers._build_request("GDP", fred, options)
            calls = Ref(0)
            sleep_calls = Float64[]

            with_mock_http(
                (req, src) -> begin
                    calls[] += 1
                    if calls[] < 3
                        throw(ErrorException("temporary outage"))
                    end
                    return (status = 200, body = "recovered")
                end,
                sleeper = (seconds -> push!(sleep_calls, seconds)),
            ) do
                @test MacroDataFetchers._send_request(request, fred) == "recovered"
                @test calls[] == 3
                @test sleep_calls == [0.1, 0.2]
            end
        end

        @testset "request errors surface and are not cached" begin
            fred = Fred(api_key = "error-key", max_retries = 1)
            request = MacroDataFetchers._build_request("GDP", fred, options)
            calls = Ref(0)

            with_mock_http(
                (req, src) -> begin
                    calls[] += 1
                    return (status = 503, body = "service unavailable")
                end,
            ) do
                err = capture_request_error() do
                    MacroDataFetchers._send_request(request, fred)
                end
                @test err.status == 503
                @test err.body == "service unavailable"
                @test calls[] == 2
                @test isempty(fred._cache.store)
            end
        end

        @testset "non-retryable request error stops immediately" begin
            fred = Fred(api_key = "client-error-key", max_retries = 3)
            request = MacroDataFetchers._build_request("GDP", fred, options)
            calls = Ref(0)

            with_mock_http((req, src) -> begin
                calls[] += 1
                return (status = 404, body = "not found")
            end) do
                err = capture_request_error() do
                    MacroDataFetchers._send_request(request, fred)
                end
                @test err.status == 404
                @test calls[] == 1
            end
        end
    end

    @testset "FRED response parsing and schema" begin
        fred = Fred(api_key = "parse-key")

        valid_body = """
        {
          "realtime_start": "2024-01-01",
          "realtime_end": "2024-01-01",
          "observation_start": "1776-07-04",
          "observation_end": "9999-12-31",
          "units": "lin",
          "output_type": 1,
          "file_type": "json",
          "order_by": "observation_date",
          "sort_order": "asc",
          "count": 2,
          "offset": 0,
          "limit": 100000,
          "observations": [
            {
              "realtime_start": "2024-01-01",
              "realtime_end": "2024-01-01",
              "date": "2024-01-01",
              "value": "123.45"
            },
            {
              "realtime_start": "2024-01-01",
              "realtime_end": "2024-01-01",
              "date": "2024-02-01",
              "value": "."
            }
          ]
        }
        """

        @test MacroDataFetchers._parse_value("123.45") == (123.45, false)
        parsed_missing, was_missing = MacroDataFetchers._parse_value(".")
        @test ismissing(parsed_missing)
        @test was_missing === true

        df = MacroDataFetchers._parse_response(valid_body, fred, "GDP")

        @test df isa DataFrame
        @test names(df) == [
            "series_id",
            "date",
            "value",
            "value_raw",
            "value_was_missing_marker",
            "realtime_start",
            "realtime_end",
        ]
        @test eltype(df.series_id) == String
        @test eltype(df.date) == Date
        @test eltype(df.value) == Union{Missing,Float64}
        @test eltype(df.value_raw) == String
        @test eltype(df.value_was_missing_marker) == Bool
        @test eltype(df.realtime_start) == Date
        @test eltype(df.realtime_end) == Date
        @test size(df) == (2, 7)
        @test df.series_id == ["GDP", "GDP"]
        @test df.date == [Date(2024, 1, 1), Date(2024, 2, 1)]
        @test df.value[1] == 123.45
        @test ismissing(df.value[2])
        @test df.value_raw == ["123.45", "."]
        @test df.value_was_missing_marker == [false, true]
        @test df.realtime_start == [Date(2024, 1, 1), Date(2024, 1, 1)]
        @test df.realtime_end == [Date(2024, 1, 1), Date(2024, 1, 1)]

        malformed_json = "{not valid json"
        err = try
            MacroDataFetchers._parse_response(malformed_json, fred, "GDP")
            nothing
        catch caught
            caught
        end
        @test err isa MacroDataFetchers.ResponseParseError
        @test err.body == malformed_json

        missing_observations_body = """{"realtime_start":"2024-01-01"}"""
        err = try
            MacroDataFetchers._parse_response(missing_observations_body, fred, "GDP")
            nothing
        catch caught
            caught
        end
        @test err isa MacroDataFetchers.ResponseParseError

        invalid_value_err = try
            MacroDataFetchers._parse_value("not-a-number")
            nothing
        catch caught
            caught
        end
        @test invalid_value_err isa MacroDataFetchers.ResponseParseError
        @test invalid_value_err.body === nothing

        invalid_observation_body = """
        {
          "observations": [
            {
              "realtime_start": "2024-01-01",
              "realtime_end": "2024-01-01",
              "date": "bad-date",
              "value": "1.0"
            }
          ]
        }
        """
        err = try
            MacroDataFetchers._parse_response(invalid_observation_body, fred, "GDP")
            nothing
        catch caught
            caught
        end
        @test err isa MacroDataFetchers.ResponseParseError
        @test err.body == invalid_observation_body
    end

    @testset "public fetch orchestration" begin
        @testset "single-series fetch" begin
            fred = Fred(api_key = "single-fetch-key", use_cache = false)

            with_mock_http(
                (req, src) -> begin
                    @test req.query["series_id"] == "GDP"
                    return (
                        status = 200,
                        body = response_body_for("GDP", [("2024-01-01", "10.0")]),
                    )
                end,
            ) do
                df = fetch_data("GDP", fred; start_date = "2024-01-01")
                @test size(df) == (1, 7)
                @test df.series_id == ["GDP"]
                @test df.value == [10.0]
            end
        end

        @testset "multi-series dedup, order, and skip handling" begin
            fred = Fred(api_key = "multi-fetch-key", use_cache = false, max_retries = 0)
            calls = String[]

            warnings = capture_warnings() do
                with_mock_http(
                    (req, src) -> begin
                        series_id = req.query["series_id"]
                        push!(calls, series_id)

                        if series_id == "BAD"
                            return (status = 503, body = "temporary failure")
                        elseif series_id == "GDP"
                            return (
                                status = 200,
                                body = response_body_for(
                                    "GDP",
                                    [("2024-01-01", "1.0"), ("2024-02-01", "2.0")],
                                ),
                            )
                        elseif series_id == "CPI"
                            return (
                                status = 200,
                                body = response_body_for("CPI", [("2024-01-01", "3.0")]),
                            )
                        end

                        error("unexpected series")
                    end,
                ) do
                    df = fetch_data(["GDP", "BAD", "GDP", "CPI"], fred; on_error = :skip)
                    @test calls == ["GDP", "BAD", "CPI"]
                    @test df.series_id == ["GDP", "GDP", "CPI"]
                    @test df.value == [1.0, 2.0, 3.0]
                end
            end

            @test occursin("Dropped duplicate series IDs: GDP", warnings)
            @test occursin("Skipping series `BAD` after RequestError", warnings)
        end

        @testset "multi-series raise behavior" begin
            fred = Fred(api_key = "raise-fetch-key", use_cache = false, max_retries = 0)
            calls = String[]

            err = capture_request_error() do
                with_mock_http(
                    (req, src) -> begin
                        series_id = req.query["series_id"]
                        push!(calls, series_id)

                        if series_id == "BAD"
                            return (status = 503, body = "temporary failure")
                        end

                        return (
                            status = 200,
                            body = response_body_for(series_id, [("2024-01-01", "1.0")]),
                        )
                    end,
                ) do
                    fetch_data(["GDP", "BAD", "CPI"], fred; on_error = :raise)
                end
            end

            @test err.status == 503
            @test calls == ["GDP", "BAD"]
        end
    end

    @testset "live FRED integration" begin
        if !_should_run_live_tests()
            @info "Skipping live FRED integration tests. Set FRED_API_KEY in ENV and RUN_LIVE_TESTS=true to enable."
        else
            @info "Running live FRED integration tests."
            fred = Fred(
                api_key = ENV["FRED_API_KEY"],
                use_cache = false,
                timeout_seconds = 30,
                max_retries = 2,
            )

            df = fetch_data("GDP", fred; start_date = "2023-07-01", end_date = "2023-12-31")

            @test df isa DataFrame
            @test names(df) == [
                "series_id",
                "date",
                "value",
                "value_raw",
                "value_was_missing_marker",
                "realtime_start",
                "realtime_end",
            ]
            @test !isempty(df)
            @test all(series_id -> series_id == "GDP", df.series_id)
            @test all(date -> Date(2023, 7, 1) <= date <= Date(2023, 12, 31), df.date)
            @test all(value -> ismissing(value) || value isa Float64, df.value)
            @test all(raw_value -> raw_value isa String, df.value_raw)
            @test all(flag -> flag isa Bool, df.value_was_missing_marker)
            @test all(date -> date isa Date, df.realtime_start)
            @test all(date -> date isa Date, df.realtime_end)
        end
    end
end
