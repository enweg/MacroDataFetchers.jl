"""
    _load_dotenv(path::AbstractString = ".env") -> Dict{String,String}

Load simple `KEY=VALUE` entries from a dotenv-style file without mutating
`ENV`.
"""
function _load_dotenv(path::AbstractString = ".env")::Dict{String,String}
    if !isfile(path)
        return Dict{String,String}()
    end

    values = Dict{String,String}()

    for line in eachline(path)
        stripped = strip(line)

        if isempty(stripped) || startswith(stripped, '#')
            continue
        end

        if !contains(stripped, '=')
            continue
        end

        key_part, value_part = split(stripped, '='; limit=2)
        key = strip(key_part)
        value = strip(value_part)

        if length(value) >= 2
            first_char = first(value)
            last_char = last(value)
            if (first_char == '"' && last_char == '"') || (first_char == '\'' && last_char == '\'')
                value = value[2:(end - 1)]
            end
        end

        values[key] = value
    end

    return values
end
