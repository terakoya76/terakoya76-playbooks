# terakoya76-playbooks

Setup develop environment w/ ansible

## Install/Update

How to execute
```bash
$ sudo ansible-playbook -i inventories/all.yml development.yml -e ansible_user=${USER}
```

### Supported Tags
* config-base
  * config-anyenv
  * config-dotfile
  * config-packages
* config-language
  * config-flutter
  * config-go
  * config-haskell
  * config-java
  * config-nodejs
  * config-ruby
  * config-rust
  * config-arduino
  * config-arm64-m4
  * config-raspberrypi
* config-tool
  * config-aws
  * config-gcp
  * config-kubernetes
    * config-helm
  * config-1password
  * config-cloudflared
  * config-tailscale

### When failed
use `--start-at-task` opt
```bash
$ sudo ansible-playbook -i inventories/all.yml development.yml -e ansible_user=${USER} --start-at-task="ruby : Set prefix"
```
