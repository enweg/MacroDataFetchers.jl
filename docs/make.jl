using MacroDataFetchers
using Documenter

DocMeta.setdocmeta!(MacroDataFetchers, :DocTestSetup, :(using MacroDataFetchers); recursive=true)

makedocs(;
    modules=[MacroDataFetchers],
    authors="Enrico Wegner",
    sitename="MacroDataFetchers.jl",
    format=Documenter.HTML(;
        canonical="https://enweg.github.io/MacroDataFetchers.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/enweg/MacroDataFetchers.jl",
    devbranch="main",
)
