# tmux adapt utf8
alias tmux="tmux -u"

# exa(ls)
alias ls=exa

# fdfind(fd)
alias fd=fdfind

# cat(bat)
export BAT_THEME="TwoDark"
alias cat=bat

# wrapper for lsec2
lssh () {
  IP=$(lsec2 "$@" | fzf-tmux -m --reverse | awk -F '\t' '{print $2}')
  if [ "$IP" != "" ] ; then
    echo "$IP"
    ssh -i $PUBKEY "hajime-terasawa@$IP"
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
alias bi="bundle install"
alias bem="bundle ex rake db:migrate"
