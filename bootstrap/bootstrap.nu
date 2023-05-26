use std log

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

def post-bootstrap-hints [] {
    print $"add the following snippet to your ('$nu.env-path' | nu-highlight)"
    print ([
        "export-env {"
        "    let-env NUPM_HOME = ..."
        "    let-env NU_LIB_DIRS = ($env.NU_LIB_DIRS? | default [] | append ["
        "        $env.NUPM_HOME"
        "    ])"
        "}"
    ] | str join "\n" | nu-highlight)

    print ""

    print "it is also recommended to add the following to allow the use of the `--save` option on `install` and `activate`"

    print ([
        "let-env NUPM_CONFIG = {"
        "    activations: ..."
        "    packages: ..."
        "}"
    ] | str join "\n" | nu-highlight)

    print ""

    print $"add the following snippet to your ('$nu.config-path' | nu-highlight)"
    print ($"use nupm/activations (char -i 42)" | nu-highlight)
}

def main [] {
    mkdir (nupm-home)

    install-nupm "nupm/"

    [''] | dump to "nupm/activations"

    print ""

    post-bootstrap-hints
}

main
exec nu
