# git fetch pull request
# $1 = remote_branch, $2 = pr_number
gpr() {
  git fetch "$1" pull/"$2"/head:"$2"
}

# git setup remote repository
# $1 = path, $2 = forked-user, $3 = owner-user, $4 = repo
gsu() {
  mkdir -p "$1"
  git clone "git@github.com:$2/$4.git" "$1/$4"
  cd "$1/$4" || exit 1
  git remote add upstream "git@github.com:$3/$4.git"
  git remote set-url upstream --push no-pushing
}

# fzf git checkout
fgco() {
  git branch | fzf-tmux -m --reverse | xargs git checkout
}

# fzf git branch -D
fgbd() {
  git branch | fzf-tmux -m --reverse | xargs git branch -D
}

# fzf git add
fga() {
  git status -s | grep -e '^ M ' | sed -e 's/^ M //' | fzf-tmux -m --reverse | xargs git add
  git status
}

# fzf git reset
fgr() {
  git status -s | grep -e '^M ' | sed -e 's/^M //' | fzf-tmux -m --reverse | xargs git reset
  git status
}

# fshow - git commit browser
fshow() {
  git log --graph --color=always \
      --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
  fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
      --bind "ctrl-m:execute:
                (grep -o '[a-f0-9]\{7\}' | head -1 |
                xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
                {}
FZF-EOF"
}

alias ga="git add"
alias gs="git status"
alias gb="git branch"
alias gc="git commit"
alias gco="git checkout"
alias gd="git diff"
alias gl="git log"
