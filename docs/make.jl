using Pkg

Pkg.develop(PackageSpec(path=joinpath(@__DIR__, "..")))

using MacroDataFetchers
using Documenter

DocMeta.setdocmeta!(MacroDataFetchers, :DocTestSetup, :(using MacroDataFetchers); recursive=true)

makedocs(;
    modules=[MacroDataFetchers],
    checkdocs=:exports,
    authors="Enrico Wegner",
    sitename="MacroDataFetchers.jl",
    format=Documenter.HTML(;
        canonical="https://enweg.github.io/MacroDataFetchers.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Getting Started" => "getting-started.md",
        "FRED Usage" => "fred.md",
        "API Reference" => "api.md",
    ],
)

deploydocs(;
    repo="github.com/enweg/MacroDataFetchers.jl",
    devbranch="main",
)
