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
] {
    let project = ($url | parse-project $span)

    let package = (try {
        http get $"https://raw.githubusercontent.com/($project)/main/package.nuon"
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

    let out = (do -i {
        git clone $url (nupm-home | path join "registry" $package.name)
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
] {
    if $list {
        error make --unspanned {msg: "`--list` not supported at the time."}
    }

    if $from_file != null {
        open $from_file | transpose name url | each {|package|
            print $"installing ($package.name)"
            install-package $package.url (metadata $from_file | get span) | ignore
        }
        return
    }

    if $url == null {
        error make --unspanned {msg: "`nupm install` takes a positional URL argument."}
    }

    if $file {
        http get $url | save --force (nupm-home | path join "registry" ($url | path basename))
        return
    }

    install-package $url (metadata $url | get span)
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
        return ($activations | parse 'use {activation}' | get activation)
    }

    $activations | append (
        if $from_file != null {
            open $from_file | each { "use " ++ $in }
        } else if $source {
            $"source ($command | str join ' ')"
        } else {
            $"use ($command | str join ' ')"
        }
    ) | uniq | save --force $load
}

export def main [] { help nupm }
