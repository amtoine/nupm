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

2. add
```nu
export-env {
    let-env NUPM_HOME = ...
    let-env NU_LIB_DIRS = ($env.NU_LIB_DIRS? | default [] | append [
        $env.NUPM_HOME
    ])
}
```
to `env.nu`

3. add `use nupm/activations *` to `config.nu`
4. install packages
5. activate items

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

one can also export the [packages installed][goatfiles packages] with
```nu
nupm install --list
| to nuon -i 4
| save --force ($nu.config-path | path dirname | path join "nupm" "packages.nuon")
```

## :recycle: update `nupm`
one can use the following to update the package manager
```nu
nupm update --self
```

> **Note**  
> `nupm update --self` will automagically reload itself after the update,
> no need to run `use nupm/`! :partying_face:  
> try `nupm version` before and after an `update --self`... :smirk:

## :calendar: the roadmap of `nupm`
- [ ] install packages from a NUON file
- [ ] hot-swap the version of packages once installed
- [ ] update packages
- [ ] add support for Nushell plugins, e.g. the `nu_plugin_*` in [`nushell/crates/`]
- [ ] list all official packages and plugins in a centralized remote store

[`nu-git-manager`]: https://github.com/amtoine/nu-git-manager
[`goatfiles/nu_scripts`]: https://github.com/goatfiles/nu_scripts
[`default_config.nu`]: https://github.com/nushell/nushell/blob/main/crates/nu-utils/src/sample_config/default_config.nu
[goatfiles activations]: https://github.com/goatfiles/dotfiles/blob/nightly/.config/nushell/nupm/activations.nuon
[goatfiles packages]: https://github.com/goatfiles/dotfiles/blob/nightly/.config/nushell/nupm/packages.nuon
[`nushell/crates/`]: https://github.com/nushell/nushell/tree/main/crates
