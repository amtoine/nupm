use std "log info"

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

    if ($file | path exists) {
        log info $"($file) already exists: skipping"
        return
    }

    log info $"dumping ($content | nu-highlight) to (ansi yellow)($file)(ansi reset)"
    $content | save --force $file
}

def install-nupm [directory: string] {
    let destination = (nupm-home | path join $directory)

    if ($destination | path exists) {
        log info $"($destination) already exists: updating"
        git -C $destination pull origin main
    } else {
        log info $"installing ($destination)"
        git clone https://github.com/amtoine/nupm.git $destination
    }
}

def main [] {
    mkdir (nupm-home)

    install-nupm "nupm/"

    [''] | dump to "nupm/activations"
}

main
exec nu
