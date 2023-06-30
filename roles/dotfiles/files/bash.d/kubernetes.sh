# bash completion
source <(kubectl completion bash)
complete -o default -F __start_kubectl k

# kubectl
alias k="kubectl"

# staging kubectl
alias sk="stkubectl"

# fzf k8s describe
# $1 = namespace, $2 = resource
fkd() {
  kubectl -n "$1" get "$2" | sed 1d | fzf-tmux -m --reverse | awk '{print $1}' | xargs kubectl -n "$1" describe "$2"
}
fskd() {
  stkubectl -n "$1" get "$2" | sed 1d | fzf-tmux -m --reverse | awk '{print $1}' | xargs stkubectl -n "$1" describe "$2"
}

# fzf k8s logs pod
# $1 = namespace
fkl() {
  kubectl -n "$1" get po | sed 1d | fzf-tmux -m --reverse | awk '{print $1}' | xargs kubectl -n "$1" logs
}
fskl() {
  stkubectl -n "$1" get po | sed 1d | fzf-tmux -m --reverse | awk '{print $1}' | xargs stkubectl -n "$1" logs
}

eks-write-config() {
  local cluster=$(aws eks list-clusters | jq -r .clusters[] | fzf | awk 'NR>1 {print}')
  if [[ $cluster != '' ]]; then
    eksctl utils write-kubeconfig --name "${cluster}"
  fi
}
alias fe="eks-write-config"
