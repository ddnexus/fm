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
    unzip

ADD https://github.com/sharkdp/bat/releases/download/v0.17.1/bat-musl_0.17.1_amd64.deb /tmp/

RUN dpkg -i /tmp/bat-musl_0.17.1_amd64.deb \
    && ln -s /usr/bin/fdfind /usr/bin/fd \
    && sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
    && locale-gen

ARG password
ARG user
ARG uid
ARG gid

RUN groupadd --gid=$gid --force $user \
    && useradd --uid=$uid --gid=$gid -G sudo --shell=/usr/bin/zsh --create-home $user \
    && echo $user:$password | chpasswd \
    && echo root:$password | chpasswd \
    && echo "Defaults  lecture=never" >> /etc/sudoers \
    && chown -R $user:$user /home/$user

ENV TRY_FM=true

USER $user
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma/zinit/master/doc/install.sh)"

COPY zshrc-additions /tmp/
RUN cat /tmp/zshrc-additions >> /home/$user/.zshrc
COPY README /home/$user/

VOLUME /home/$user
WORKDIR /home/$user
