FROM zshusers/zsh:5.8
LABEL maintainer="Domizio Demichelis (dd.nexus@gmail.com)"

# buster is EOL: its packages are only on the archive mirror
RUN sed -i -e 's|deb.debian.org/debian|archive.debian.org/debian|' \
		-e 's|security.debian.org/|archive.debian.org/debian-security/|' /etc/apt/sources.list && \
	install_packages -y \
	locales && \
	sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen && \
	locale-gen && \
	install_packages -y \
		ca-certificates \
		libncursesw6 \
		libncurses6 \
		ncurses-base \
		ncurses-bin \
		curl \
		git \
		nano \
		vim \
		less \
		file \
		sudo \
		fish \
		ripgrep \
		fd-find \
		poppler-utils \
		bzip2 \
		tmux \
		xsel \
		unzip \
		man

ARG user
ARG uid
ARG gid
ARG term
ARG bat_version=0.18.3
ARG arch=amd64
ARG eza_version=0.23.5
ARG eza_target=x86_64-unknown-linux-musl

ADD https://github.com/sharkdp/bat/releases/download/v${bat_version}/bat_${bat_version}_${arch}.deb /tmp/
ADD https://github.com/eza-community/eza/releases/download/v${eza_version}/eza_${eza_target}.zip /tmp/

RUN dpkg -i /tmp/bat_${bat_version}_${arch}.deb && \
	rm /tmp/bat_${bat_version}_${arch}.deb && \
	unzip /tmp/eza_${eza_target}.zip eza -d /usr/local/bin && \
	rm /tmp/eza_${eza_target}.zip && \
	ln -s /usr/bin/fdfind /usr/bin/fd && \
	groupadd --gid=$gid --force $user && \
	useradd --uid=$uid --gid=$gid -G sudo --shell=/usr/bin/zsh --create-home $user && \
	echo $user:fm | chpasswd && \
	echo root:fm | chpasswd && \
	echo "Defaults  lecture=never" >> /etc/sudoers && \
	chown -R $user:$user /home/$user

ENV TRY_FM=true \
    SUDO_PROMPT="[sudo] enter 'fm' as the password for %p: "

USER $user
WORKDIR /home/$user

COPY --chown=$user:$user .zshrc README ./

RUN env TERM="${term:-xterm-256color}" zsh -isc "@zinit-scheduler burst" && \
	echo '. $HOME/.local/share/zinit/plugins/ddnexus---fm/launcher/fm.sh\n\
	PS1="\[\033[01;32m\]\w \$\[\033[00m\] "' >> /home/$user/.bashrc && \
	mkdir -p /home/$user/.config/fish && mkdir -p /home/$user/.config/fish/functions && \
	echo 'source $HOME/.local/share/zinit/plugins/ddnexus---fm/launcher/fm.fish' >> /home/$user/.config/fish/config.fish && \
	echo 'function fish_prompt\n\
	set_color --bold green; echo -n "$PWD > "\n\
end' >> /home/$user/.config/fish/functions/fish_prompt.fish

VOLUME /home/$user
