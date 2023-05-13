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

### an example with [`nu-git-manager`]
```nu
use nupm
nupm install https://github.com/amtoine/nu-git-manager.git
```
```nu
nupm activate nu-git-manager gm
nupm activate nu-git-manager sugar git
nupm activate nu-git-manager sugar gh
nupm activate nu-git-manager sugar gist
nupm activate nu-git-manager sugar completions git *
nupm activate nu-git-manager sugar dotfiles
```

[`nu-git-manager`]: https://github.com/amtoine/nu-git-manager
