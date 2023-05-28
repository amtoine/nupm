# nupm
A manager for Nushell packages.

# :postal_horn: this project has been archived => please refer to the [official `nupm` package manager of Nushell](https://github.com/nushell/nupm)

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
> **Note**  
> it is also recommended to add the following to allow the use of the `--save` option on `install` and `activate`
> ```nu
> let-env NUPM_CONFIG = {
>     activations: ...
>     packages: ...
> }
> ```

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

> **Note**  
> alternatively, one can define `NUPM_CONFIG` in `env.nu`, e.g.
> ```nu
> let-env NUPM_CONFIG = {
>     activations: ($nu.default-config-dir | path join "nupm" "activations.nuon")
>     packages: ($nu.default-config-dir | path join "nupm" "packages.nuon")
>     set_prompt: false
> }
> ```
> and then use the `--save` option of `nupm install` and `nupm activate` to dump
> the installed packaged and activated items to the files in `NUPM_CONFIG`, e.g.
> ```nu
> nupm install --list --save
> nupm activate --list --save
> ```

## :recycle: update `nupm`
one can use the following to update the package manager
```nu
nupm update --self
# or
nupm update nupm
```

or something like this to update all the packages
```nu
nupm install --list
| get name
| each {|pkg| nupm update $pkg --ignore}
# or
nupm update --all
```

> **Note**  
> `nupm update --self` will automagically reload itself after the update,
> no need to run `use nupm/`! :partying_face:  
> try `nupm version` before and after an `update --self`... :smirk:

## :calendar: the roadmap of `nupm`
- :red_circle: install packages from a NUON file
- :green_circle: hot-swap the version of packages once installed
- :green_circle: update packages
- :red_circle: add support for Nushell plugins, e.g. the `nu_plugin_*` in [`nushell/crates/`]
- :red_circle: list all official packages and plugins in a centralized remote store
- :red_circle: support unit and integration tests of Nushell packages

## :exclamation: some ideas of advanced (?) usage
in order to load `nupm` in the blink of an eye, i've added the following to my `$env.config.keybindings`:
```nu
{
    name: nupm
    modifier: control
    keycode: char_n
    mode: [emacs, vi_insert, vi_normal]
    event: {
        send: executehostcommand
        cmd: "overlay use --prefix nupm"
    }
}
```
which allows me to load `nupm` ***BLAZZINGLY FAST*** on `<c-n>` :muscle:

[`nu-git-manager`]: https://github.com/amtoine/nu-git-manager
[`goatfiles/nu_scripts`]: https://github.com/goatfiles/nu_scripts
[`default_config.nu`]: https://github.com/nushell/nushell/blob/main/crates/nu-utils/src/sample_config/default_config.nu
[goatfiles activations]: https://github.com/goatfiles/dotfiles/blob/nightly/.config/nushell/nupm/activations.nuon
[goatfiles packages]: https://github.com/goatfiles/dotfiles/blob/nightly/.config/nushell/nupm/packages.nuon
[`nushell/crates/`]: https://github.com/nushell/nushell/tree/main/crates
