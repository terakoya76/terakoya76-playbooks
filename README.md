# terakoya76-playbooks

Setup develop environment w/ ansible

### Install/Update

```shell
# For MacOS
$ bash <(curl -s https://raw.githubusercontent.com/terakoya76/terakoya76-playbooks/master/setup.sh) mac

# For Ubuntu
$ bash <(curl -s https://raw.githubusercontent.com/terakoya76/terakoya76-playbooks/master/setup.sh) ubuntu
```

### Apply Dotfiles

```shell
$ bash <(curl -s https://raw.githubusercontent.com/terakoya76/terakoya76-playbooks/master/setup.sh) dot
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
* config-tool

### When failed
use `--start-at-task` opt
```bash
$ ansible-playbook playbooks/setup_ubuntu.yml -i inventory/ubuntu-local.yml --start-at-task="ruby : Set prefix"
```
