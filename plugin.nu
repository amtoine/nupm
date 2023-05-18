def plugin-dir [] {
    $env.NU_PLUGIN_DIR? | default (
        $env.XDG_DATA_HOME?
        | default ($nu.home-path | path join ".local" "share")
        | path join "nushell" "plugins"
    )
}

export def install [
    plugin: path
] {
    cargo install --path $plugin --root (plugin-dir)
}

def "nu-complete plugins" [] {
    ls (plugin-dir | path join "bin") | get name | path basename
}

export def register [
    plugin: string@"nu-complete plugins"
] {
    nu --commands $"register (plugin-dir | path join 'bin' $plugin)"
    exec nu --execute "print (version | select installed_plugins); use ~/plugin.nu"
}
