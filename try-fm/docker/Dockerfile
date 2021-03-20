FROM zshusers/zsh:5.8
LABEL maintainer="Domizio Demichelis (dd.nexus@gmail.com)"

RUN install_packages -y \
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
		exa \
		ripgrep \
		fd-find \
		poppler-utils \
		bzip2 \
		tmux \
		xsel \
		unzip

ARG user
ARG uid
ARG gid
ARG term
ARG bat_v=0.18.0
ARG arch=amd64

ADD https://github.com/sharkdp/bat/releases/download/v${bat_v}/bat_${bat_v}_${arch}.deb /tmp/

RUN \
	dpkg -i /tmp/bat_${bat_v}_${arch}.deb && \
	rm /tmp/bat_${bat_v}_${arch}.deb && \
	ln -s /usr/bin/fdfind /usr/bin/fd && \
	groupadd --gid=$gid --force $user && \
	useradd --uid=$uid --gid=$gid -G sudo --shell=/usr/bin/zsh --create-home $user && \
	echo $user:fm | chpasswd && \
	echo root:fm | chpasswd && \
	echo "Defaults  lecture=never" >> /etc/sudoers && \
	chown -R $user:$user /home/$user

ENV TRY_FM=true SUDO_PROMPT="[sudo] enter 'fm' as the password for %p: "

USER $user
WORKDIR /home/$user

COPY --chown=$user:$user .zshrc-additions README ./

RUN \
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma/zinit/master/doc/install.sh)" && \
	echo 'source ~/.zshrc-additions' >> .zshrc && \
	env TERM="${term:-xterm-256color}" zsh -isc "@zinit-scheduler burst" && \
	echo '$HOME/.zinit/plugins/ddnexus---fm/launcher/fm.sh\n\
	PS1="\[\033[01;32m\]\w \$\[\033[00m\] "' >> /home/$user/.bashrc && \
	mkdir -p /home/$user/.config/fish && mkdir -p /home/$user/.config/fish/functions && \
	echo 'source $HOME/.zinit/plugins/ddnexus---fm/launcher/fm.fish' >> /home/$user/.config/fish/config.fish && \
	echo 'function fish_prompt\n\
	set_color --bold green; echo -n "$PWD > "\n\
end' >> /home/$user/.config/fish/functions/fish_prompt.fish

VOLUME /home/$user
