def nupm-home [] {
    $env.NUPM_HOME? | default (
        $env.XDG_DATA_HOME?
        | default ($env.HOME | path join ".local" "share")
        | path join "nupm"
    )
}

def install-package [url: string] {
    let project = (
        $url
        | str replace '\.git$' ''
        | str replace '^https://' ''
        | str replace '^http://' ''
        | parse "github.com/{project}"
    )
    if ($project | is-empty) {
        error make --unspanned {msg: "not a valid project"}
    }

    let project = ($project | get 0.project)

    let package = (http get $"https://raw.githubusercontent.com/($project)/main/package.nuon")
    git clone $url (nupm-home | path join "registry" $package.name)

    return $package
}

export def install [
    url?: string
    --list: bool
    --file: path
] {
    let packages = (nupm-home | path join "packages.nuon")

    if $list {
        if ($packages | path exists) {
            return ($packages | open)
        }
        error make --unspanned {msg: "there are no packages installed with `nupm`."}
    }

    if $file != null {
        if ($packages | path exists) { $packages | open } else []
        | append (
            open $file | transpose name url | each {|package|
                print $"installing ($package.name)"
                let _ = (install-package $package.url)
                {$package.name: $package.url}
            }
        ) | save --force $packages
        return
    }

    if $url == null {
        error make --unspanned {msg: "`nupm install` takes a positional URL argument."}
    }

    let package = (install-package $url)

    if ($packages | path exists) { $packages | open } else []
    | append {$package.name: $url}
    | save --force $packages
}

export def activate [
    ...command: string
    --list: bool
    --file: path
] {
    let load = (nupm-home | path join "load.nu")

    let activations = ($load | open | lines)

    if $list {
        return ($activations | parse 'use {activation}' | get activation)
    }

    $activations | append (
        if $file != null {
            open $file | each { "use " ++ $in }
        } else {
            $"use ($command | str join ' ')"
        }
    ) | uniq | save --force $load
}

export def main [] { help nupm }
