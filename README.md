# nupm
A manager for Nushell packages.

## :recycle: installation
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
6. activate items

> **Note**  
> in all the following, we assume `nupm` has been installed and loaded with `use nupm`

## :gear: install packages
#### :bulb: an example with [`nu-git-manager`]
please find intructions [here](https://github.com/amtoine/nu-git-manager/blob/main/docs/installation/nupm.md)

#### :bulb: another example with [`goatfiles/nu_scripts`]
i'm not using the `main` revision of this package, rather the `nightly` branch...
we can use `nupm install --revision` to make this happen!
```nu
nupm install https://github.com/goatfiles/nu_scripts --revision nightly
```
and then something like
```nu
nupm activate nu-goat-scripts misc back    # module import syntax
nupm activate "nu-goat-scripts misc edit"  # single-block syntax
```

#### :bulb: an example of file package: the [`default_config.nu`] of Nushell
in my config, i use the official default `$dark_theme` define in Nushell's `default_config.nu`
- install it with `--file`
```nu
nupm install --file https://raw.githubusercontent.com/nushell/nushell/main/crates/nu-utils/src/sample_config/default_config.nu
```
- activate it with `--source`
```nu
nupm activate --source default_config.nu
```

## :open_file_folder: use files
as i have the [activations above exported][goatfiles activations] with
```nu
nupm activate --list
| to nuon -i 4
| save --force ($nu.config-path | path dirname | path join "nupm" "activations.nuon")
```
i can run a simpler
```nu
nupm activate --from-file ($nu.config-path | path dirname | path join "nupm" "activations.nuon")
```

## :recycle: update `nupm`
one can use the following to update the package manager
```nu
nupm update --self
```

[`nu-git-manager`]: https://github.com/amtoine/nu-git-manager
[`goatfiles/nu_scripts`]: https://github.com/goatfiles/nu_scripts
[`default_config.nu`]: https://github.com/nushell/nushell/blob/main/crates/nu-utils/src/sample_config/default_config.nu
[goatfiles activations]: https://github.com/goatfiles/dotfiles/blob/nightly/.config/nushell/nupm/activations.nuon
