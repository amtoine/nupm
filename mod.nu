use std "log warning"

def nupm-home [] {
    $env.NUPM_HOME? | default (
        $env.XDG_DATA_HOME?
        | default ($env.HOME | path join ".local" "share")
        | path join "nupm"
    )
}

def get-config-file [] {
    nupm-home | path join "default_config.nu"
}

export def "update default" [
    --init: bool
    --latest: bool
    --revision: string
    --reload: bool
    --silent: bool
] {
    let revision = if $latest {
        "main"
    } else if ($revision != null) {
        $revision
    } else {
        let v = (version)
        $v.commit_hash? | default $v.branch? | default $v.version
    }

    let default_url = (
        {
            scheme: https,
            host: raw.githubusercontent.com,
            path: $"/nushell/nushell/($revision)/crates/nu-utils/src/sample_config",
        } | url join
        | path join "default_config.nu"
    )

    if (get-config-file | path expand | path exists) {
        if not $init {
            print $"(ansi cyan)info(ansi reset): updating default config from (ansi yellow)($revision)(ansi reset)..."
            http get $default_url | save --force --raw .default_config.nu

            let diff = (diff -u --color=always (get-config-file) .default_config.nu)

            if not ($diff | is-empty) {
                print $diff
            }

            mv --force .default_config.nu (get-config-file)
        }
    } else {
        print $"(ansi red_bold)error(ansi reset): (get-config-file) does not exist..."
        print $"(ansi cyan)info(ansi reset): pulling default config file..."
        http get $default_url | save --force --raw (get-config-file)
        print $'Downloaded new default config file'
    }

    if $reload {
        exec nu
    }
    if not $silent {
        log warning "do not forget to reload your config!"
    }
}

export def "update libs" [
    --init: bool
    --reload: bool
    --silent: bool
] {
    let packages = (nupm-home | path join "packages.nuon" | open)

    for profile in ($packages | transpose name profile | get profile) {
        let directory = (nupm-home | append $profile.directory | path join)
        if not ($directory | path exists) {
            print $"(ansi red_bold)error(ansi reset): ($directory) does not exist..."
            print $"(ansi cyan)info(ansi reset): pulling the scripts from ($profile.upstream)..."
            git clone $profile.upstream $directory
        } else {
            if not $init {
                print $"(ansi cyan)info(ansi reset): updating ($directory)..."
                git -C $directory fetch origin --prune
            }
        }

        git -C $directory checkout (["origin" $profile.revision] | path join) --quiet
    }

    if $reload {
        exec nu
    }
    if not $silent {
        log warning "do not forget to reload your config!"
    }
}

export def "update all" [
    --init: bool
] {
    mkdir (nupm-home)
    if $init {
        update default --init --silent
        update libs --init --silent
    } else {
        update default --silent
        update libs --silent
    }

    log warning "reloading the config..."
    exec nu
}

export def "edit default" [] {
    ^$env.EDITOR (get-config-file)
}

def "nu-complete list-nu-libs" [] {
    ls (nupm-home | path join "**" "*" ".git")
    | get name
    | path parse
    | get parent
    | str replace (nupm-home) ""
    | str trim -c (char path_sep)
}

export def "edit lib" [lib: string@"nu-complete list-nu-libs"] {
    cd (nupm-home | path join $lib)
    ^$env.EDITOR .
}

export def "status" [] {
    nu-complete list-nu-libs | each {|lib|
        {
            name: $lib
            describe: (try {
                let tag = (git -C (nupm-home | path join $lib) describe HEAD)
                $tag
            } catch { "" })
            rev: (git -C (nupm-home | path join $lib) rev-parse HEAD)
        }
    }
}

