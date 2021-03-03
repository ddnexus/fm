FROM zshusers/zsh:5.8
LABEL maintainer="Domizio Demichelis (dd.nexus@gmail.com)"

RUN install_packages -y \
		locales \
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
		exa \
		ripgrep \
		fd-find \
		poppler-utils \
		bzip2 \
		tmux \
		xsel \
		unzip

ADD https://github.com/sharkdp/bat/releases/download/v0.17.1/bat-musl_0.17.1_amd64.deb /tmp/

RUN \
	dpkg -i /tmp/bat-musl_0.17.1_amd64.deb && \
	rm /tmp/bat-musl_0.17.1_amd64.deb && \
	ln -s /usr/bin/fdfind /usr/bin/fd && \
	sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen && \
	locale-gen

ARG user
ARG uid
ARG gid
ARG term

RUN \
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
	env TERM="${term:-xterm-256color}" zsh -isc "@zinit-scheduler burst"

VOLUME /home/$user
