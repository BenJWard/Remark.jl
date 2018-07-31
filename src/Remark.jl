module Remark

import Literate
import Documenter

export slideshow

const _pkg_assets = joinpath(dirname(@__DIR__), "assets")

const deps = [
    "https://fonts.googleapis.com/css?family=Yanone+Kaffeesatz",
    "https://fonts.googleapis.com/css?family=Droid+Serif:400,700,400italic",
    "https://fonts.googleapis.com/css?family=Ubuntu+Mono:400,700,400italic",
    "http://gnab.github.io/remark/downloads/remark-latest.min.js",
    "https://cdnjs.cloudflare.com/ajax/libs/KaTeX/0.5.1/katex.min.js",
    "https://cdnjs.cloudflare.com/ajax/libs/KaTeX/0.5.1/contrib/auto-render.min.js",
    "https://cdnjs.cloudflare.com/ajax/libs/KaTeX/0.5.1/katex.min.css"
]

const depnames =  ["font1.css", "font2.css", "font3.css", "remark.min.js", "katex.min.js", "auto-render.min.js", "katex.min.css"]
const depfiles = joinpath.(_pkg_assets, depnames)
const libdepfiles = joinpath.("..", "lib", depnames)

const depkeys = ["\$font1", "\$font2", "\$font3", "\$remark", "\$katexjs", "\$auto-render", "\$katexcss"]

function slideshow(inputfile, outputdir; js = :local, documenter = true)
    inputfile = realpath(abspath(inputfile))
    outputdir = realpath(abspath(outputdir))
    mkpath.(joinpath.(outputdir, ("src", "build", "lib")))
    _create_index_md(inputfile, outputdir; js = js, documenter = documenter)
    _create_index_html(outputdir; js = js)
    return outputdir
end

function _create_index_md(inputfile, outputdir; js = :local, documenter = true)
    if ismatch(r".jl$", inputfile)
        Literate.markdown(inputfile, joinpath(outputdir, "src"), name = "index")
    else
        cp(inputfile, joinpath(outputdir, "src", "index.md"), remove_destination=true)
    end
    if js == :lib
        for (name, file) in zip(depnames, depfiles)
            cp(file, joinpath(outputdir, "lib", name))
        end
    end
    srand(123)
    s = randstring(50)
    _replace_line(joinpath(outputdir, "src", "index.md"), r"^(\s)*(--)(\s)*$", s)
    if documenter
        Documenter.makedocs(root = outputdir)
    else
        cp(joinpath(outputdir, "src", "index.md"), joinpath(outputdir, "build", "index.md"), remove_destination=true)
    end
    _replace_line(joinpath(outputdir, "build", "index.md"), Regex("^($s)\$"), "--")
    _replace_line(joinpath(outputdir, "build", "index.md"), r"^<a id=.*$", "")
end


function _create_index_html(outputdir; js = :local)

    d = (js == :local) ? depfiles :
        (js == :lib) ? libdepfiles : deps

    Base.open(joinpath(outputdir, "build", "index.html"), "w") do f
        template = Base.open(joinpath(_pkg_assets, "indextemplate.html"))
        for line in eachline(template, chomp=false)
            for (key, val) in zip(depkeys, d)
                line = replace(line, key, val)
            end
            write(f, line)
        end
        close(template)
    end
end

function openurl(url::AbstractString)
    if is_apple()
        run(`open $url`)
    elseif is_windows()
        run(`start $url`)
    elseif is_unix()
        run(`xdg-open $url`)
    end
end

function open(outputdir)
    openurl(joinpath(outputdir, "build", "index.html"))
end

function _replace_line(filename, a::Regex, b)
    f = Base.open(filename)
    (tmp, tmpstream) = mktemp()
    for line in eachline(f, chomp = true)
        write(tmpstream, ismatch(a, line) ? b : line)
        write(tmpstream, '\n')
    end
    close(f)
    close(tmpstream)
    mv(tmp, filename, remove_destination = true)
end


end # module
