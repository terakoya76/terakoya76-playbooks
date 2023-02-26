# terakoya76-playbooks

Setup develop environment w/ ansible

### Install/Update

```shell
# $1 is ansible_user name
$ bash <(curl -s https://raw.githubusercontent.com/terakoya76/terakoya76-playbooks/master/setup.sh) terakoya76
```

### Supported Tags
* config-base
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
* config-tool
  * config-aws
  * config-gcp
  * config-kubernetes

### When failed
use `--start-at-task` opt
```bash
$ ansible-playbook playbooks/development.yml -i inventory/all.yml --start-at-task="ruby : Set prefix"
```
