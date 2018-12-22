# exa(ls)
alias ls=exa

# fdfind(fd)
alias fd=fdfind

# cat(bat)
export BAT_THEME="TwoDark"
alias cat=bat

# grpcurl
docker pull terakoya76/grpcurl
alias grpcurl='docker run -it --rm terakoya76/grpcurl'

# mitmproxy
docker pull mitmproxy/mitmproxy
alias mitmproxy='docker run -it --rm -v ~/.mitmproxy:/home/mitmproxy/.mitmproxy -p 8080:8080 mitmproxy/mitmproxy'

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

fbet() {
  bundle ex rake -T | fzf-tmux -m --reverse | xargs bundle ex
}

alias be="bundle ex"
