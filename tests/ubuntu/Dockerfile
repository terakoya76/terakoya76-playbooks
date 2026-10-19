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

# The playbook enables and starts units, which needs a real systemd as PID 1.
CMD ["/sbin/init"]
