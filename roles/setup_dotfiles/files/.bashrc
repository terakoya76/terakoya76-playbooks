# direnv
eval "$(direnv hook bash)"

# share history with each tab
function share_history {
  history -a
  history -c
  history -r
}
PROMPT_COMMAND='share_history'

# wrapper for lsec2
lssh () {
  IP=$(lsec2 $@ | peco | awk -F '\t' '{print $2}')
  if [ "$?" -eq 0 ] && [ "$IP" != "" ]
  then
    ssh st-step
    ssh "$IP"
  fi
}

# wrapper for history
export HISTCONTROL="ignoredups"
function peco-select-history() {
  READLINE_LINE=$(history | tail -r | sed -e 's/^\s*[0-9]\+\s\+//' | awk '!a[$0]++' | peco --query "$READLINE_LINE" | awk '{$1=""; print}')
  if [ -n "$READLINE_LINE" ] ; then
    echo "$READLINE_LINE" >&2
    eval "$READLINE_LINE"
    history -d $((HISTCMD-1))
    history -s "$READLINE_LINE"
  fi
}
alias psh="peco-select-history"

# wrapper for ps aux
function peco-pkill() {
  for pid in $(ps aux | peco | awk '{ print $2 }')
  do
    kill "$pid"
    echo "Killed ${pid}"
  done
}
alias pk="peco-pkill"
