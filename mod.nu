def nupm-home [] {
    $env.NUPM_HOME? | default (
        $env.XDG_DATA_HOME?
        | default ($env.HOME | path join ".local" "share")
        | path join "nupm"
    )
}

export def install [
    url: string
] {
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

    let packages = (nupm-home | path join "packages.nuon")
    if ($packages | path exists) { $packages | open } else []
    | append {$package.name: $url}
    | save --force $packages
}

export def activate [
    ...command: string
] {
    let load = (nupm-home | path join "load.nu")

    $load | open | lines | append $"use ($command | str join ' ')" | uniq | save --force $load
}
