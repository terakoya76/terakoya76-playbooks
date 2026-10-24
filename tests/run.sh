#!/usr/bin/env bash
# Runs development.yml against a throwaway container of the given distro, one of the
# directories next to this script (archlinux, ubuntu).
# Extra arguments go to ansible-playbook, e.g. --tags config-base or --skip-tags config-flutter.
set -euo pipefail

if [ $# -lt 1 ] || [ ! -f "$(dirname "$0")/$1/Dockerfile" ]; then
  echo "usage: $0 <archlinux|ubuntu> [ansible-playbook args...]" >&2
  exit 2
fi
distro=$1
shift

repo=$(cd "$(dirname "$0")/.." && pwd)
image="terakoya76-playbooks-${distro}"
container="${image}-$$"

docker build -t "$image" -f "$repo/tests/$distro/Dockerfile" "$repo/tests/$distro"
trap 'docker rm -f "$container" >/dev/null 2>&1 || true' EXIT
# Not --privileged: that hands the container the host's /dev and a writable /sys, through
# which its systemd hangs up the host's VTs and replays the host's uevents, killing the
# desktop session. SYS_ADMIN lets systemd mount and manage its private cgroup namespace.
# snapd needs fuse for squashfuse, securityfs and MAC_ADMIN to load AppArmor profiles for
# snap hooks, and the rest of the file capabilities snap-confine refuses to run without.
docker run -d --name "$container" --cgroupns=private \
  --cap-add SYS_ADMIN --cap-add MAC_ADMIN --cap-add DAC_READ_SEARCH --cap-add SYS_PTRACE \
  --cap-add SYS_RESOURCE --device /dev/fuse \
  --security-opt seccomp=unconfined --security-opt apparmor=unconfined \
  --tmpfs /run --tmpfs /run/lock -v /sys/kernel/security:/sys/kernel/security \
  -v "$repo:/src:ro" "$image" >/dev/null
# Polled rather than `is-system-running --wait`, which gives up at once while D-Bus is not
# up yet. "degraded" is fine: a unit failing for lack of hardware does not matter here.
for _ in $(seq 120); do
  case $(docker exec "$container" systemctl is-system-running 2>/dev/null) in
    running | degraded) break ;;
  esac
  sleep 1
done

# Copied rather than run from /src: the host's .venv and collections are built for the
# host, and the playbook writes .venv and collections into its own directory.
docker exec -u tester -w /home/tester "$container" bash -c '
  set -euo pipefail
  mkdir playbooks
  tar -C /src --exclude=./.venv --exclude=./collections --exclude=./.git -cf - . | tar -C playbooks -xf -
  cd playbooks
  # The container holds no GitHub SSH key, so undo the https-to-ssh rewrite for the clones.
  git config --file roles/dotfiles/files/git/.gitconfig --remove-section url.git@github.com:
  uv sync -q
  uv run ansible-galaxy install -r requirements.yml >/dev/null
  uv run ansible-playbook -i inventories/all.yml development.yml -e ansible_user=tester -e ansible_become_pass= "$@"
' bash "$@"
