use std [
    "log info"
    "log debug"
]

def nupm-home [] {
    $env.NUPM_HOME? | default (
        $env.XDG_DATA_HOME?
        | default ($env.HOME | path join ".local" "share")
        | path join "nupm"
    )
}

def parse-project [
    span: record<start: int, end: int>
] {
    let project = (
        $in
        | str replace '\.git$' ''
        | str replace '^https://' ''
        | str replace '^http://' ''
        | parse "github.com/{project}"
    )
    if ($project | is-empty) {
        error make {
            msg: $"(ansi red_bold)nupm::invalid_project_name(ansi reset)"
            label: {
                text: $"not a valid project URL"
                start: $span.start
                end: $span.end
            }
        }
    }

    $project | get 0.project
}

def install-package [
    url: string
    span: record<start: int, end: int>
    revision: string
] {
    let project = ($url | parse-project $span)

    log debug $"checking package ($project)"
    let package = (try {
        http get $"https://raw.githubusercontent.com/($project)/($revision)/package.nuon"
    } catch {
        error make {
            msg: $"(ansi red_bold)nupm::not_a_package(ansi reset)"
            label: {
                text: $"($project) does not have a `package.nuon` file"
                start: $span.start
                end: $span.end
            }
        }
    })
    log info "package ok"

    let out = (do -i {
        let repo = (nupm-home | path join "registry" $package.name)
        log info $"intalling package ($project) as ($package.name)"
        git clone $url $repo
        log debug $"($project) installed in ($repo)"
        log debug $"($project) checking out on ($revision)"
        git -C $repo checkout $revision
    } | complete)
    if $out.exit_code != 0 {
        error make --unspanned {
            msg: $out.stderr
        }
    }
}

def install-file [
    file: record<repo: string, path: string>
    span: record<start: int, end: int>
    revision: string
] {
    let url = ([
        "https://raw.githubusercontent.com/"
        $file.repo
        $revision
        $file.path
    ] | str join "/")
    let local_file = (nupm-home | path join "registry" ($url | path basename))

    log info $"installing file: ($url | path basename)"
    try {
        http get $url | save --force $local_file
        {
            repo: $file.repo
            revision: $revision
            path: $file.path
        }
        | to nuon
        | save --force (nupm-home | path join "registry" ".files" ($url | path basename))
    } catch {
        error make {
            msg: $"(ansi red_bold)nupm::file_not_found(ansi reset)"
            label: {
                text: ([
                    "could not pull this file down..."
                    $"($url)"
                ] | str join "\n")
                start: $span.start
                end: $span.end
            }
        }
    }
    log debug $"($url | path basename) installed in ($local_file)"
}

def "open file-package" [] {
    let $file = $in
    nupm-home | path join "registry" ".files" $file | open | from nuon
}

def get-revision [] {
    let repo = $in

    let tag = (do -i {
        git -C $repo describe HEAD --tags
    } | complete)
    let is_tag = $tag.exit_code == 0 and (
        $tag.stdout | str trim
        | parse --regex '(?<tag>.*)-(?<n>\d+)-(?<hash>[0-9a-fg]+)'
        | is-empty
    )
    let branch = (git -C $repo branch --show-current | str trim)

    if $is_tag {
        $tag.stdout | str trim
    } else if not ($branch | is-empty) {
        $branch
    } else {
        git -C $repo rev-parse HEAD | str trim
    }
}

# install a package locally
#
# `nupm install` will look for a repository with a `package.nuon` file at
# its root.
#
# `nupm` only supports packages hosted on *GitHub* for now...
export def install [
    url?: string  # the remote path to the package
    --list: bool  # list the installed packages and exit
    --from-file: path  # install packages from a file
    --file: record<repo: string, path: string>  # install a package as a file-package
    --revision: string = "main"  # specify a precise revision for a package
] {
    if $list {
        return (
            ls (nupm-home | path join "registry") | each {|it|
                let url = if $it.type == dir {
                    git -C $it.name remote -v
                    | detect columns --no-headers
                    | where column0 == "origin"
                    | get 0.column1
                } else if $it.type == file {
                    let package = ($it.name | path basename | open file-package)

                    [
                        "https://raw.githubusercontent.com"
                        $package.repo
                        $package.revision
                        $package.path
                    ] | str join "/"
                }

                let revision = if $it.type == dir {
                    $it.name | get-revision
                } else if $it.type == file {
                    $it.name | path basename | open file-package | get revision
                }

                {
                    name: ($it.name | path basename)
                    revision: $revision
                    url: $url
                }
            }
        )
    }

    if $from_file != null {
        error make --unspanned {msg: "installation from file not permitted for now!"}

        open $from_file | transpose name url | each {|package|
            print $"installing ($package.name)"
            install-package $package.url (metadata $from_file | get span) $revision | ignore
        }
        return
    }

    if $file != null {
        mkdir (nupm-home | path join "registry" ".files")

        install-file $file (metadata $file | get span) $revision
        return
    }

    if $url == null {
        error make --unspanned {msg: "`nupm install` takes a positional URL argument."}
    }

    install-package $url (metadata $url | get span) $revision
}

# activate package items
#
# once a package has been installed, its items must be activated to be used
# automatically when starting a Nushell instance.
#
# the default activation mode is with `use`.
export def activate [
    ...item: string  # the item to activate from a package, e.g. `nu-git-manager gm`
    --list: bool  # list the activations and exit
    --from-file: path  # load activations from file
    --source: bool  # activate an item in `source` mode
] {
    let load = (nupm-home | path join "load.nu")

    let activations = ($load | open | lines)

    if $list {
        return ($activations | parse '{mode} {activation}' | sort)
    }

    $activations | append (
        if $from_file != null {
            log info $"activating from file ($from_file)"
            open $from_file | each {|it|
                $it.mode ++ " " ++ $it.activation
            }
        } else if $source {
            let item = ($item | str join ' ')
            log info $"`source`ing `($item)`"
            $"source ($item)"
        } else {
            let item = ($item| str join ' ')
            log info $"`use`ing `($item)`"
            $"use ($item)"
        }
    ) | uniq | save --force $load
}

# update a package or the package manager itself
export def update [
    --self: bool  # perform an update of `nupm` itself
] {
    if $self {
        log info "updating nupm..."
        let nupm = (nupm-home | path join "nupm")
        git -C $nupm pull origin main
        log debug $"($nupm) up-to-date"

        log info "loading new nupm!"
        exec nu -e 'use nupm/'
    }

    error make --unspanned {msg: "`nupm update` not implemented."}
}

# print the version and exit
export def version [] {
    let repo = (nupm-home | path join "nupm")

    $"($repo | get-revision) (char lparen)(git -C $repo rev-parse --short HEAD)(char rparen)"

}

# a manager for Nushell packages
export def main [] { help nupm }
