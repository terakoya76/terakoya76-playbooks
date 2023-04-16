# add a blank line after each output
add_line () {
  if [ -z "${PS1_NEWLINE_LOGIN}" ]; then
    PS1_NEWLINE_LOGIN=true
  else
    printf '\n'
  fi
}
PROMPT_COMMAND='add_line'

# bash-completions
source /usr/local/etc/bash_completion

# NOTE: need Menlo-for-Powerline
#   https://github.com/abertsch/Menlo-for-Powerline
# change prompt
source "$HOME/.git-prompt.sh"

# aws-ps1
source "$HOME/awscli-ext/awscli.ext.sh"

# kube-ps1
source "$HOME/kube-ps1/kube-ps1.sh"

# for bash
__ps1_set_blue () {
  tput setaf 4
}
__ps1_set_magenta () {
  tput setaf 5
}
__ps1_set_cyan () {
  tput setaf 6
}
__ps1_set_white () {
  tput setaf 7
}

# for bash
__aws_ps1_cache_dir=/tmp/__aws_ps1_cache
mkdir -p ${__aws_ps1_cache_dir}
echo "${AWS_PROFILE:-<empty>}" > ${__aws_ps1_cache_dir}/profile
echo "$(aws sts get-caller-identity --no-cli-auto-prompt --query 'Arn' 2> /dev/null || echo '<empty>')" > ${__aws_ps1_cache_dir}/caller_identity
__aws_ps1 () {
  local profile="$(cat ${__aws_ps1_cache_dir}/profile)"
  local caller_identity="$(cat ${__aws_ps1_cache_dir}/caller_identity)"

  local new_profile="${AWS_PROFILE:-<empty>}"
  if [[ "${profile}" != "${new_profile}" ]]; then
    profile="${new_profile}"
    caller_identity="$(aws sts get-caller-identity --no-cli-auto-prompt --query 'Arn' 2> /dev/null || echo '<empty>')"
    echo "${profile}" > ${__aws_ps1_cache_dir}/profile
    echo "${caller_identity}" > ${__aws_ps1_cache_dir}/caller_identity
  fi

  echo -e "$(__ps1_set_magenta)[aws:${profile}]$(__ps1_set_cyan)[${caller_identity}]$(__ps1_set_white)"
}

# for bash
__ps1_suffix () {
  local suffix="$(tput setaf 7) \$ "
  echo "${suffix}"
}

export PS1='$(__ps1_set_magenta)[\t]$(__ps1_set_blue)[jobs:\j]$(__ps1_set_cyan)[\u@\w]$(__ps1_set_white)$(__git_ps1 "[ %s]")
$(__aws_ps1)
$(kube_ps1)$(__ps1_suffix)'
