def nupm-home [] {
    $env.NUPM_HOME? | default (
        $env.XDG_DATA_HOME?
        | default ($nu.home-path | path join ".local" "share")
        | path join "nupm"
    )
}

def "dump to" [file: string] {
    let content = ($in | str join "\n")
    let file = (nupm-home | path join $file)

    print $"dumping (ansi green)($content)(ansi reset) to (ansi yellow)($file)(ansi reset)"
    $content | save --force $file
}

def install-nupm [directory: string] {
    git clone https://github.com/amtoine/nupm.git (nupm-home | path join $directory)
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
        '    let-env NU_LIB_DIRS = ($env.NU_LIB_DIRS? | default [] | append ['
        '        $nupm_home'
        '        ($nupm_home | path join "registry")'
        '    ])'
        '}'
    ] | dump to "env.nu"

    [''] | dump to "load.nu"

    install-nupm "nupm/"
}

main
exec nu
