def nupm-home [] {
    $env.NUPM_HOME? | default (
        $env.XDG_DATA_HOME?
        | default ($env.HOME | path join ".local" "share")
        | path join "nupm"
    )
}

def install-package [
    url: string
    span: record<start: int, end: int>
] {
    let project = (
        $url
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

    let project = ($project | get 0.project)

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

    print $out.stdout

    return $package
}

export def install [
    url?: string
    --list: bool
    --from-file: path
] {
    let packages = (nupm-home | path join "packages.nuon")

    if $list {
        if ($packages | path exists) {
            return ($packages | open)
        }
        error make --unspanned {msg: "there are no packages installed with `nupm`."}
    }

    if $from_file != null {
        if ($packages | path exists) { $packages | open } else []
        | append (
            open $from_file | transpose name url | each {|package|
                print $"installing ($package.name)"
                let span = (metadata $from_file | get span)
                let _ = (install-package $package.url $span)
                {$package.name: $package.url}
            }
        ) | save --force $packages
        return
    }

    if $url == null {
        error make --unspanned {msg: "`nupm install` takes a positional URL argument."}
    }

    let span = (metadata $url | get span)
    let package = (install-package $url $span)

    if ($packages | path exists) { $packages | open } else []
    | append {$package.name: $url}
    | save --force $packages
}

export def activate [
    ...command: string
    --list: bool
    --from-file: path
] {
    let load = (nupm-home | path join "load.nu")

    let activations = ($load | open | lines)

    if $list {
        return ($activations | parse 'use {activation}' | get activation)
    }

    $activations | append (
        if $from_file != null {
            open $from_file | each { "use " ++ $in }
        } else {
            $"use ($command | str join ' ')"
        }
    ) | uniq | save --force $load
}

export def main [] { help nupm }
