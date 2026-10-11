# The try-fm image: FM and its tools on Fedora, for the demo (try-fm start) and the test suite (try-fm test).
# Build context: the FM repo root, e.g.  podman build -f try-fm/Dockerfile --build-arg user=$USER --build-arg uid=$(id -u) --build-arg gid=$(id -g) .

FROM fedora:44
LABEL maintainer="Domizio Demichelis (dd.nexus@gmail.com)"

RUN dnf -y --setopt=install_weak_deps=False install \
		zsh fzf ripgrep eza fd-find bat \
		bash fish nano less sudo tmux ncurses file tar shadow-utils && \
	dnf clean all

# the container user mirrors the host user, so the mounted host files are writable; sudo password: fm
ARG user=fm
ARG uid=1000
ARG gid=1000
RUN groupadd --gid=$gid --force $user && \
	useradd --uid=$uid --gid=$gid -G wheel --shell=/usr/bin/zsh --create-home $user && \
	echo "$user:fm" | chpasswd && echo 'root:fm' | chpasswd && \
	echo 'Defaults lecture=never' > /etc/sudoers.d/try-fm

COPY --chown=$user:$user . /opt/fm
COPY --chown=$user:$user try-fm/zshrc /home/$user/.zshrc

ENV LANG=C.UTF-8 \
    TRY_FM=true \
    SUDO_PROMPT="[sudo] enter 'fm' as the password for %p: "

USER $user
WORKDIR /home/$user

# bash and fish get FM through the launchers; the playground is the tree the tests use, to try the fs commands safely
RUN zsh /opt/fm/fm__compile && \
	printf '\n. /opt/fm/launcher/fm.sh\nPS1="\\[\\033[01;32m\\]\\w \\$\\[\\033[00m\\] "\n' >> .bashrc && \
	mkdir -p .config/fish/functions && \
	printf 'source /opt/fm/launcher/fm.fish\n' >> .config/fish/config.fish && \
	printf 'function fish_prompt\n\tset_color --bold green; echo -n "$PWD > "\nend\n' > .config/fish/functions/fish_prompt.fish && \
	zsh -c 'source /opt/fm/tests/lib; fixture ~/playground' && \
	cp /opt/fm/try-fm/README-home README

VOLUME /home/$user

CMD ["zsh", "-l"]
