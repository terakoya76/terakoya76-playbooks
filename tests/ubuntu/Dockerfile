FROM ubuntu:26.04

ENV DEBIAN_FRONTEND=noninteractive

# ansible.cfg sets module_lang to en_US.UTF-8, which the base image does not generate.
# snapd needs squashfuse to mount snaps, since a container cannot load the squashfs module,
# and apparmor to run snap hooks, which fail outright when snapd finds no AppArmor.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      apparmor build-essential ca-certificates curl dbus git gnupg locales python3 snapd \
      squashfuse \
      sudo systemd systemd-sysv \
 && rm -rf /var/lib/apt/lists/* \
 && locale-gen en_US.UTF-8 \
 && useradd -m -s /bin/bash tester \
 && echo 'tester ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/tester

# Ubuntu does not package uv.
COPY --from=ghcr.io/astral-sh/uv:0.12.19 /uv /uvx /usr/local/bin/

# Units that reach for the host's devices or a console stay off even if the container is
# ever run --privileged again, which exposes the host's /dev and a writable /sys: udev-trigger
# replays the host's uevents and getty/firstboot reset and hang up its VTs, either of which
# tears down the host's graphical session.
RUN systemctl mask systemd-udevd.service systemd-udevd-control.socket \
      systemd-udevd-kernel.socket systemd-udev-trigger.service systemd-udev-settle.service \
      systemd-vconsole-setup.service systemd-firstboot.service getty.target \
      console-getty.service

# The playbook enables and starts units, which needs a real systemd as PID 1. Docker mounts
# an unprivileged container's cgroupfs read-only; under a private cgroup namespace it only
# shows the container's own subtree, so remounting it read-write lets systemd manage it
# without touching the host's hierarchy.
CMD ["sh", "-c", "mount -o remount,rw /sys/fs/cgroup && exec /sbin/init"]
