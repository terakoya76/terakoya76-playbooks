bes() {
  bundle ex rails s -b 0.0.0.0 -p "$1"
}

fbet() {
  bundle ex rake -T | fzf-tmux -m --reverse | xargs bundle ex
}

alias be="bundle ex"
alias bec="bundle ex rails c"
alias bi="bundle install"
alias bem="bundle ex rake db:migrate"
