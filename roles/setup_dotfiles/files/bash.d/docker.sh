# docker build
dbu() {
  docker build -t "$1" "."
}

# docker stop all
dstop() {
  docker stop "$(docker ps -a -q)"
}

# docker rm all containers
drm() {
  docker rm $(docker ps -f status=exited -f status=created -f status=dead -f status=paused -q)
}

# docker rm all containers -f
drmf() {
  docker stop "$(docker ps -a -q)"
  docker rm "$(docker ps -a -q)"
}

# docker rm all images
dri() {
  docker rmi $(docker images -f dangling=true -q)
}

{% raw %}
# fzf docker ip
fdip() {
  docker container ls | fzf-tmux -m --reverse | awk '{print $1}' | xargs docker inspect --format '{{ .NetworkSettings.IPAddress }}'
}
{% endraw %}

# docker images
alias di="docker image ls"

# docker containers
alias dc="docker container ls"

# docker last
alias dl="docker ps -l -q"
