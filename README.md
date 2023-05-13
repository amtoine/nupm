# nupm
A manager for Nushell packages.

## installation
1. run
```nu
http get https://raw.githubusercontent.com/amtoine/nupm/main/bootstrap/bootstrap.nu | save --force ($nu.temp-path | path join "nupm-bootstrap"); nu ($nu.temp-path | path join "nupm-bootstrap")
```
to have a look at the bootstrap script (**HIGHLY RECOMMENDED IN ALL CASES**) or
```nu
nu --commands (http get https://raw.githubusercontent.com/amtoine/nupm/main/bootstrap/bootstrap.nu)
```
to run the bootstrap script directly.

2. add `source ~/.local/share/nupm/env.nu` to `env.nu`
3. add `source ~/.local/share/nupm/load.nu` to `config.nu`
4. (optional) define `NUPM_HOME` in `env.nu` with `let-env NUPM_HOME = ($env.XDG_DATA_HOME | path join "nupm")`
5. install packages

> **Note**  
> in all the following, we assume `nupm` has been installed an loaded with `use nupm`

## install packages
### an example with [`nu-git-manager`]
i use the `nu-git-manager` tool to manage all my `git` projects
- install with
```nu
nupm install https://github.com/amtoine/nu-git-manager.git
```
- activate commands with
```nu
nupm activate nu-git-manager gm
nupm activate nu-git-manager sugar git
nupm activate nu-git-manager sugar gh
nupm activate nu-git-manager sugar gist
nupm activate nu-git-manager sugar completions git *
nupm activate nu-git-manager sugar dotfiles
```
or, as i have these [activations exported][goatfiles activations] with
```nu
nupm activate --list
| to nuon -i 4
| save --force ($nu.config-path | path dirname | path join "nupm" "activations.nuon")
```
i can run a simpler
```nu
nupm activate --from-file ($nu.config-path | path dirname | path join "nupm" "activations.nuon")
```

### an example of file package: the [`default_config.nu`] of Nushell
in my config, i use the official default `$dark_theme` define in Nushell's `default_config.nu`
- install it with `--file`
```nu
nupm install --file https://raw.githubusercontent.com/nushell/nushell/main/crates/nu-utils/src/sample_config/default_config.nu
```
- activate it with `--source`
```nu
nupm activate --source default_config.nu
```

[`nu-git-manager`]: https://github.com/amtoine/nu-git-manager
[`default_config.nu`]: https://github.com/nushell/nushell/blob/main/crates/nu-utils/src/sample_config/default_config.nu
[goatfiles activations]: https://github.com/goatfiles/dotfiles/blob/nightly/.config/nushell/nupm/activations.nuon
