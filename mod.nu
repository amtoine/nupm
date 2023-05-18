use std [
    "log info"
    "log debug"
]

export-env {
    let-env PROMPT_COMMAND_RIGHT = "(nupm)"
}

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
        let repo = (nupm-home | path join $package.name)
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

def list-packages [] {
    ls (nupm-home) | where type == dir | each {|it|
        let url = (
            git -C $it.name remote -v
            | detect columns --no-headers
            | where column0 == "origin"
            | get 0.column1
        )

        let revision = ($it.name | get-revision)

        {
            name: ($it.name | path basename)
            revision: $revision
            url: $url
        }
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
    --revision: string = "main"  # specify a precise revision for a package
] {
    if $list {
        return (list-packages)
    }

    if $from_file != null {
        error make --unspanned {msg: "installation from file not permitted for now!"}

        open $from_file | transpose name url | each {|package|
            print $"installing ($package.name)"
            install-package $package.url (metadata $from_file | get span) $revision | ignore
        }
        return
    }

    if $url == null {
        error make --unspanned {msg: "`nupm install` takes a positional URL argument."}
    }

    install-package $url (metadata $url | get span) $revision
}

def list-activations [] {
    $activations | str replace '^export use ' '' | sort
}

# activate package items
#
# once a package has been installed, its items must be activated to be used
# automatically when starting a Nushell instance.
export def activate [
    ...item: string  # the item to activate from a package, e.g. `nu-git-manager gm`
    --list: bool  # list the activations and exit
    --from-file: path  # load activations from file
] {
    let load = (nupm-home | path join "nupm" "activations")

    let activations = ($load | open | lines)

    if $list {
        return (list-activations)
    }

    $activations | append (
        if $from_file != null {
            log info $"activating from file ($from_file)"
            open $from_file | each {|it|
                "export use " ++ $it
            }
        } else {
            let item = ($item| str join ' ')
            log info $"`use`ing `($item)`"
            $"export use ($item)"
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
