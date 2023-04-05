# terakoya76-playbooks

Setup develop environment w/ ansible

### Install/Update

```shell
$ bash <(curl -s https://raw.githubusercontent.com/terakoya76/terakoya76-playbooks/master/setup.sh)
```

### Supported Tags
* config-base
  * config-anyenv
  * config-dotfile
  * config-packages
* config-language
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
$ sudo ansible-playbook -i inventory/all.yml development.yml -e ansible_user=${USER} --start-at-task="ruby : Set prefix"
```
