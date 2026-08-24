using MultiDocumenter: MultiDocumenter, MultiDocRef, MegaDropdownNav, Column, Link

clonedir = joinpath(@__DIR__, "clones")
deploying = "deploy" in ARGS

org_link(package) = "https://github.com/JuliaImGui/$(package).jl.git"

# Helper function stolen from DynamicalSystemsDocs.jl
function multidocref(package, descr = "")
    name = "$(package).jl"
    if !isempty(descr)
        name *= " - $(descr)"
    end

    MultiDocRef(;
        upstream = joinpath(clonedir, package),
        path = lowercase(package),
        name,
        giturl = org_link(package),
    )
end

function link(package, descr = "")
    name = "$(package).jl"
    if !isempty(descr)
        name *= " - $(descr)"
    end

    Link(name, org_link(package))
end

docs = [multidocref("CImGui"),
        MegaDropdownNav("Ecosystem packages",
                        [
                            Column("Plotting",
                                   [
                                       multidocref("ImPlot"),
                                       link("ImPlotExtra"),
                                       link("ImPlot3D")
                                   ]),
                            Column("Widgets & Themes",
                                   [
                                       link("ImGuiThemes"),
                                       multidocref("ImGuiNodeEditor")
                                   ]),
                            Column("Testing",
                                   [
                                       multidocref("ImGuiTestEngine")
                                   ])
                        ])
        ]

outpath = deploying ? mktempdir() : joinpath(@__DIR__, "build")

MultiDocumenter.make(
    outpath,
    docs;
    search_engine = MultiDocumenter.SearchConfig(
        index_versions = ["stable"],
        engine = MultiDocumenter.FlexSearch
    ),
    rootpath = deploying ? "/ImGuiDocs.jl/" : "/"
)

if "deploy" in ARGS
    @info "Deploying to GitHub" ARGS
    gitroot = normpath(joinpath(@__DIR__, ".."))
    run(`git pull`)
    outbranch = "gh-pages"
    has_outbranch = true
    if !success(`git checkout $outbranch`)
        has_outbranch = false
        if !success(`git switch --orphan $outbranch`)
            @error "Cannot create new orphaned branch $outbranch."
            exit(1)
        end
    end
    for file in readdir(gitroot; join = true)
        endswith(file, ".git") && continue
        rm(file; force = true, recursive = true)
    end
    for file in readdir(outpath)
        cp(joinpath(outpath, file), joinpath(gitroot, file))
    end
    run(`git add .`)
    if success(`git commit -m 'Aggregate documentation'`)
        @info "Pushing updated documentation."
        if has_outbranch
            run(`git push`)
        else
            run(`git push -u origin $outbranch`)
        end
        run(`git checkout master`)
    else
        @info "No changes to aggregated documentation."
    end
else
    @info "Skipping deployment, 'deploy' not passed. Generated files in $(outpath)." ARGS
end
