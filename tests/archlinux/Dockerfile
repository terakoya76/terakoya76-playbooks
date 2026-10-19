FROM archlinux:latest

# ansible.cfg sets module_lang to en_US.UTF-8, which the base image does not generate.
RUN pacman -Syu --noconfirm --needed base-devel git python sudo uv \
 && sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen \
 && locale-gen \
 && useradd -m tester \
 && echo 'tester ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/tester

# The playbook enables and starts units, which needs a real systemd as PID 1.
CMD ["/usr/lib/systemd/systemd"]
