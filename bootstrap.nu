#!/usr/bin/env nu

def nupm-home [] {
    $env.NUPM_HOME? | default (
        $env.XDG_DATA_HOME?
        | default ($nu.home-path | path join ".local" "share")
        | path join "nupm"
    )
}

def "dump to" [file: string] {
    str join "\n" | save --force (nupm-home | path join $file)
}

def main [] {
    mkdir (nupm-home)
    [
        'export-env {'
        '    let nupm_home = ($env.NUPM_HOME? | default ('
        '        $env.XDG_DATA_HOME?'
        '        | default ($nu.home-path | path join ".local" "share")'
        '        | path join "nupm"'
        '    ))'
        ''
        '    let packages = ($nupm_home | path join "packages.nuon" | open)'
        ''
        '    let-env NU_LIB_DIRS = ($env.NU_LIB_DIRS? | default [] | append ['
        '        $nupm_home'
        '        # this line is important for the `goatfiles` modules to work'
        '        ($nupm_home | append $packages.goatfiles.directory | path join)'
        '    ])'
        '}'
    ] | dump to "env.nu"

    ['source default_config.nu'] | dump to "load.nu"
}
