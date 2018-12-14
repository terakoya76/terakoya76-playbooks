# exa(ls)
alias ls=exa

# fdfind(fd)
alias fd=fdfind

# cat(bat)
docker pull danlynn/bat
export BAT_THEME="TwoDark"
alias cat='docker run -it --rm -e BAT_THEME -e BAT_STYLE -e BAT_TABS -v "$(pwd):/myapp" danlynn/bat'

# grpcurl
docker pull terakoya76/grpcurl
alias grpcurl='docker run -it --rm terakoya76/grpcurl'

# wrapper for lsec2
lssh () {
  IP=$(lsec2 "$@" | fzf-tmux -m --reverse | awk -F '\t' '{print $2}')
  if [ "$IP" != "" ] ; then
    echo "$IP"
    ssh "$IP"
  fi
}

# rails
bes() {
  bundle ex rails s -b 0.0.0.0 -p "$1"
}
alias be="bundle ex"
