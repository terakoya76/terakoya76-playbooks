FROM archlinux:latest

# ansible.cfg sets module_lang to en_US.UTF-8, which the base image does not generate.
# The image's pacman.conf also skips extracting locale sources other than en_*, so glibc is
# reinstalled without that filter for the playbook to generate ja_JP.UTF-8.
RUN sed -i '/^NoExtract.*\(locale\|i18n\)/d' /etc/pacman.conf \
 && pacman -Syu --noconfirm --needed base-devel git python sudo uv \
 && pacman -S --noconfirm glibc \
 && sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen \
 && locale-gen \
 && useradd -m tester \
 && echo 'tester ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/tester

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
CMD ["sh", "-c", "mount -o remount,rw /sys/fs/cgroup && exec /usr/lib/systemd/systemd"]
