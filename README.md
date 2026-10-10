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
$ uv run ansible-playbook -i inventories/all.yml development.yml -e ansible_user=${USER} -K
```

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

### When failed
use `--start-at-task` opt
```bash
$ uv run ansible-playbook -i inventories/all.yml development.yml -e ansible_user=${USER} -K --start-at-task="dotfiles : Get ansible_user home directory"
```
