# bash completion
source <(kubectl completion bash)

# load kube-ps1 hook
source "/usr/local/opt/kube-ps1/share/kube-ps1.sh"

# fzf k8s describe
# $1 = resource, $2 = namespace
fkd() {
  bin/kubectl get "$1" -n "$2" | sed 1d | fzf-tmux -m --reverse | awk '{print $1}' | xargs bin/kubectl describe "$1"
}
fskd() {
  bin/stkubectl get "$1" -n "$2" | sed 1d | fzf-tmux -m --reverse | awk '{print $1}' | xargs bin/stkubectl describe "$1"
}

# fzf k8s logs pod
# $1 = namespace
fkl() {
  bin/kubectl get po -n "$1" | sed 1d | fzf-tmux -m --reverse | awk '{print $1}' | xargs bin/kubectl logs
}
fskl() {
  bin/stkubectl get po -n "$1" | sed 1d | fzf-tmux -m --reverse | awk '{print $1}' | xargs bin/stkubectl logs
}

# kubectl
alias k="kubectl"

# staging kubectl
alias sk="stkubectl"
