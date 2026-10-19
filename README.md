# terakoya76-playbooks

Setup develop environment with ansible

## Setup

ansible is pinned in `uv.lock` and its collections in `requirements.yml`, so a run uses
those versions rather than whatever happens to be installed on the machine. The venv is
built on a uv-managed interpreter, which keeps it independent of the Homebrew python that
this playbook itself upgrades.

```bash
$ uv sync
$ uv run ansible-galaxy install -r requirements.yml
```

## Install/Update

How to execute
```bash
$ uv run ansible-playbook -i inventories/all.yml development.yml -e ansible_user=${USER}
```

The playbook prompts for the become password instead of taking `-K`. Homebrew needs that
password to upgrade casks that hold privileged files, and a password given to `-K` only
reaches PlayContext, so it can never be templated into a task. Pass
`-e ansible_become_pass=...` to skip the prompt in a non-interactive run, and leave the
prompt empty on a host with passwordless sudo.

### Supported Platforms
* Ubuntu (apt / snap / AppImage)
* Arch Linux (pacman / AUR)
* macOS (Homebrew)

On Arch Linux, AUR packages are built with [paru](https://github.com/Morganamilo/paru) through
the `kewlfft.aur` collection. makepkg refuses to run as root, so the packages role creates a
system user `aur_builder` (override with `-e aur_builder=...`) that may run `pacman`, and only
`pacman`, without a password, and builds every AUR package as that user. The role also runs
`pacman -Syu` first, because Arch does not support partial upgrades.
Run `config-packages` (or the whole playbook) once before any narrower `--tags` run on a
fresh Arch host, since the other roles rely on the AUR build user and paru it sets up.

### Supported Tags
* config-base
  * config-dotfiles
  * config-packages
* config-language
  * config-flutter
  * config-haskell
  * config-java
  * config-rust
* config-iot
  * config-arduino
  * config-arm64-m4
  * config-esp32
  * config-raspberrypi
* config-tools
  * config-aws
  * config-gcp
  * config-kubernetes
  * config-onepassword
  * config-streamdeck
  * config-cloudflared
  * config-tailscale

### Test in a container
`tests/run.sh` runs the playbook in a throwaway Arch Linux or Ubuntu container with systemd as
PID 1, which needs Docker with `--privileged` on a cgroup v2 host. Arguments after the distro
are passed to `ansible-playbook`.
```bash
$ ./tests/run.sh archlinux --tags config-base
$ ./tests/run.sh ubuntu --tags config-base
```

### When failed
use `--start-at-task` opt
```bash
$ uv run ansible-playbook -i inventories/all.yml development.yml -e ansible_user=${USER} --start-at-task="dotfiles : Get ansible_user home directory"
```
