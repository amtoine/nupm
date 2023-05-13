def nupm-home [] {
    $env.NUPM_HOME? | default (
        $env.XDG_DATA_HOME?
        | default ($env.HOME | path join ".local" "share")
        | path join "nupm"
    )
}

export def install [
    url?: string
    --list: bool
] {
    let packages = (nupm-home | path join "packages.nuon")

    if $list {
        if ($packages | path exists) {
            return ($packages | open)
        }
        error make --unspanned {msg: "there are no packages installed with `nupm`."}
    }

    if $url == null {
        error make --unspanned {msg: "`nupm install` takes a positional URL argument."}
    }

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

    if ($packages | path exists) { $packages | open } else []
    | append {$package.name: $url}
    | save --force $packages
}

export def activate [
    ...command: string
    --list: bool
] {
    let load = (nupm-home | path join "load.nu")

    let activations = ($load | open | lines)

    if $list {
        return ($activations | parse 'use {activation}' | get activation)
    }

    $activations | append $"use ($command | str join ' ')" | uniq | save --force $load
}
