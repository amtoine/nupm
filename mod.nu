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

export def install [
    url?: string
    --list: bool
    --from-file: path
    --file: bool
    --revision: string = "main"
] {
    if $list {
        error make --unspanned {msg: "`--list` not supported at the time."}
    }

    if $from_file != null {
        open $from_file | transpose name url | each {|package|
            print $"installing ($package.name)"
            install-package $package.url (metadata $from_file | get span) $revision | ignore
        }
        return
    }

    if $url == null {
        error make --unspanned {msg: "`nupm install` takes a positional URL argument."}
    }

    if $file {
        log info $"installing file: ($url | path basename)"
        let local_file = (nupm-home | path join "registry" ($url | path basename))
        http get $url | save --force $local_file
        log debug $"($url | path basename) installed in ($local_file)"
        return
    }

    install-package $url (metadata $url | get span) $revision
}

export def activate [
    ...command: string
    --list: bool
    --from-file: path
    --source: bool
] {
    let load = (nupm-home | path join "load.nu")

    let activations = ($load | open | lines)

    if $list {
        return ($activations | parse '{mode} {activation}')
    }

    $activations | append (
        if $from_file != null {
            log info $"activating from file ($from_file)"
            open $from_file | each {|it|
                $it.mode ++ " " ++ $it.activation
            }
        } else if $source {
            let item = ($command | str join ' ')
            log info $"`source`ing `($item)`"
            $"source ($item)"
        } else {
            let item = ($command | str join ' ')
            log info $"`use`ing `($item)`"
            $"use ($item)"
        }
    ) | uniq | save --force $load
}

export def update [
    --self: bool
] {
    if $self {
        log info "updating nupm..."
        let nupm = (nupm-home | path join "nupm")
        git -C $nupm pull origin main
        log debug $"($nupm) up-to-date"
        return
    }

    error make --unspanned {msg: "`nupm update` not implemented."}
}

export def main [] { help nupm }
