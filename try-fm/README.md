# Try FM without installing it

You can easily try FM on your own filesystem without the need to install it, i.e. running it from a local docker container.

All the packages required will be installed and relegated in a docker image and a docker volume. The installation will not change your system at all, and when you are done with trying it, you can purge everything with a single command.

## Prerequisites

- Ensure to have [docker](https://www.docker.com) and `curl` installed on your system
- Linux systems work out of the box, but - on systems that use the "Docker Desktop" application (e.g. MacOS) - you should check whether the local root `/` is among the shared paths. If it is not the case, add it. (`try-fm` mounts it in order to make you try FM as it was installed in your own system: see below for details)
- If you have unsolvable problems setting up your "Docker Desktop" as indicated, you can start `try-fm` with one of the following mount restrictions:
  - `~/try-fm start --home-mount` in order to mount only your `HOME` dir (which should work on any system)
  - `~/try-fm start --no-mount` in order to skip the mounting altogether. Use this option only if nothing else works or if you are paranoid about messing up your own filesystem by mistake. However keep in mind that your user experience will be limited to the container filesystem.

## Quick Start

- Copy, paste and enter the following command into your terminal in order to download the `try-fm` command in your `HOME` dir:

```
sh -c "curl -fsSL https://raw.githubusercontent.com/ddnexus/fm/master/try-fm/try-fm -o ~/try-fm; chmod +x ~/try-fm; ~/try-fm"
```

- Read the small usage message and start it with `~/try-fm start` or `~/try-fm start ...` if needed (see the above docker prerequisites)
- Notice that the first run will also automatically build the docker image and setup the docker container HOME (that will install a lot of stuff in the docker space and you can purge it completely with `~/try-fm purge` when you are done)
- When you are in the docker session (green prompt) start FM by running `fm` there.

## Warnings

1. DO NOT SHARE THE BUILT IMAGE! The `try-fm` docker image that you build on your system is meant to be private and used locally. It contains information about your user that you may not want to share with others (notably: _username_, _userid_, _groupid_, and the _password_ you created). Just keep it local and don't push it anywhere or share it with anyone.

2. In order to make you try FM as it was installed in your own system, the `try-fm` script will usually bind mount your own filesystem to the docker container. Notice that as for any mounted disk that you can write to, __all the changes__ that you may make to your own filesystem from the docker session and from the FM TUI __will be made to your real files__! So don't delete anything important!

## Filesystem info

In order to allow you to experiment with FM, the `HOME` dir of the docker session (`~`) will persist your changes, so you may want to customize `~/.zshrc` or other dot-files and experiment with it.

Everything else outside your mounted host filesystem and the docker `~` can be temporarily modified, but will get restored in the next docker session (i.e. the next time you will start it `~/try-fm start`).

So to recap the behavior of the filesystem in the docker session:

- The mounted FS is your own writable filesystem, so don't do anything stupid with it :)
- `~` is the docker container HOME and is persisted between sessions, so use it to experiment with dot-files. You can reset it with `~/try-fm reset` at any time
- everything else will get restored the next session (i.e. the next time you will start it with `~/try-fm start`)

## Purge

Just run `~/try-fm purge` to remove anything related to 'try-fm' and reclaim the disk space used by docker.

## Known limitations of the docker session

A few menus that __work perfectly in the FM installed version__ don't work, or are limited, in the `try-fm` docker session:

- `Cycle Preview Mode` -> `ctrl-p` does not imediately refresh the preview after the command: you have to refresh it manually so instead of pressing `ctrl-p` you have to press `ctrl-p` `ctrl-r`
- `Open Selected Items` -> `ctrl-o` is meant to open files and dirs in your desktop and it cannot work because the docker image does not offer a desktop environment
- `Open New Shell Here` -> `ctrl-n` if you are not in a `tmux` session, it may open a new terminal session in your host instead of opening it in the docker session
- `Switch to FIND View` -> `alt-f` on MacOS is very slow when performed in docker bind mounted paths (i.e. your mounted filesystem)
- `Copy Selected Path` -> `ctrl-t` may not work in non-linux hosts
- The existing symbolic links to absolute paths pointing to your filesystem are broken (your filesystem is mounted in a different container path)

## Q&A

### 1. The docker build process fails. What's wrong?

While running the `~/try-fm start` for the first time, you may find a `Failed to fetch http://deb.debian.org/... Temporary failure resolving 'deb.debian.org'` in the output. That is your host or your docker DNS problem, and it's not related to `try-fm`. [Here is the solution](https://stackoverflow.com/questions/51034120/docker-could-not-resolve-deb-debian-org)

### 2. The alt key does not work in my terminal app. How can I fix it?

FM uses the `alt` key as a default shortcut modifier in many of its menu items. If you get some weird character printed in the filter area instead of getting the action related to the shortcut, then you need to enable a specific preference in your terminal app. Here are a few examples:

- MacOS Terminal: `Preferences`>`Profiles`>`Keyboard`> `Use Option as Meta key`
- MacOS iTerm: `Preferences`>`Profiles`>`Keyboard`>`Option Key`>`Esc+`
- Xterm: `echo 'XTerm*metaSendsEscape: true' >> ~/.Xresources`

For different apps and platforms, please read: [Meta Key Problems](https://www.emacswiki.org/emacs/MetaKeyProblems).

### 3. How can I remember all that shortcuts?

Quickly toggle the FM Menu ON/OFF with `ctrl-space` in order to peek the shortcut that you need. You can also filter the list by typing some letter if that helps. Then you can select the menu (with arrows keys or mouse) or press its shortcut right from the Menu Panel itself or go back to the FM Panel and press it from there. When you will remember everything it will be super fast.
