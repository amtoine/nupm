# nupm
A manager for Nushell packages.

## installation
1. run
```nu
http get https://raw.githubusercontent.com/amtoine/nupm/main/bootstrap.nu | save --force ($nu.temp-path | path join "nupm-bootstrap"); nu ($nu.temp-path | path join "nupm-bootstrap")
```
or
```nu
nu --commands (http get https://raw.githubusercontent.com/amtoine/nupm/main/bootstrap.nu)
```

2. had to add the following manually to the files in the first comment
```nuon
# ~/.local/share/nupm/packages.nuon
{
    nushell: {
       upstream: "https://github.com/nushell/nu_scripts.git"
       directory: ["nushell" "nu_scripts"]
       revision: "main"
    }
    goatfiles: {
       upstream: "https://github.com/goatfiles/nu_scripts.git"
       directory: ["goatfiles" "nu_scripts"]
       revision: "nightly"
    }
    nu-git-manager: {
       upstream: "https://github.com/amtoine/nu-git-manager.git"
       directory: ["nu-git-manager"]
       revision: "main"
    }
}
```
and
```nu
# ~/.local/share/nupm/load.nu
use goatfiles/nu_scripts/scripts/misc.nu [
    back
    "cargo list"
    "cargo info full"
    edit
    "youtube share"
]

use goatfiles/nu_scripts/scripts/gf.nu
use goatfiles/nu_scripts/scripts/gpg.nu
use goatfiles/nu_scripts/scripts/sys.nu
use goatfiles/nu_scripts/scripts/downloads.nu
use goatfiles/nu_scripts/scripts/ssh.nu
use goatfiles/nu_scripts/scripts/trash.nu
use goatfiles/nu_scripts/scripts/xdg.nu

use nushell/nu_scripts/custom-completions/cargo/cargo-completions.nu *

use nu-git-manager gm
use nu-git-manager sugar git
use nu-git-manager sugar gh
use nu-git-manager sugar gist
use nu-git-manager sugar completions git *
use nu-git-manager sugar dotfiles
```
3. add `source ~/.local/share/nupm/load.nu` to `config.nu`
4. add `source ~/.local/share/nupm/env.nu` to `env.nu`
5. (optional) define `NUPM_HOME` in `env.nu` with `let-env NUPM_HOME = ($env.XDG_DATA_HOME | path join "nupm")`
6. install the packages with `use mod.nu` and then `mod update all`
