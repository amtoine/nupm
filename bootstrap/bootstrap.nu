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

    install-nupm "nupm/"

    [''] | dump to "nupm/activations"
}

main
exec nu
