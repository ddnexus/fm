# Try FM without installing it

You can easily try FM on your own filesystem without the need to install it, i.e. running it from a local docker container.

All the packages required will be installed and relegated in a docker image and a docker volume. The installation will not change your system at all, and when you are done with trying it, you can purge everything with a single command.

## Prerequisites

- Ensure to have [docker](https://www.docker.com) and `curl` installed on your system
- Linux works out of the box, but - on systems that use the "Docker Desktop" application (e.g. MacOS) - you should check whether the local root `/` is among the shared paths. If it is not the case, add it. (`try-fm` mounts it in order to make you try FM as it was installed in your own system).
- If you have unsolvable problems setting up your "Docker Desktop" as indicated, you can start `try-fm` with:
  - `~/try-fm start --home-mount` in order to mount only your `HOME` dir (which should work on any system)
  - `~/try-fm start --no-mount` in order to skip the mounting altogether (use only as last resort because your user experience will be quite limited)

## Quick Start

- Copy, paste and enter the following command into your terminal in order to download the `try-fm` command in your `HOME` dir:

```
sh -c "curl -fsSL https://raw.githubusercontent.com/ddnexus/fm/master/try-fm/try-fm -o ~/try-fm; chmod +x ~/try-fm; ~/try-fm"
```

- Read the small usage message and start it with `~/try-fm start` or `~/try-fm start ...` if needed (see the above docker prerequisites)
- Notice that the first run will also automatically build the docker image and setup the docker container HOME
- When you are in the docker session (green prompt) start FM by running `fm` there.

## Warnings

1. DO NOT SHARE THE BUILT IMAGE! The `try-fm` docker image that you build on your system is meant to be private and used locally. It contains information about your user that you may not want to share with others (notably: _username_, _userid_, _groupid_, and the _password_ you created). Just keep it local and don't push it anywhere or share it with anyone.

2. In order to make you try FM as it was installed in your own system, the `try-fm` docker container will bind mount your own `/` at `/$(hostname)` and cd you to your mounted host `HOME`. (unless you had to limit it with a start option explained above). As for any mounted disk that you can write to, __all the changes__ that you may make to your own filesystem from the docker session and from the FM TUI __will be made to your real files__! So don't delete anything important!

## Filesystem info

In order to allow you to experiment with FM, the `HOME` dir of the docker session (`~`) will persist your changes, so you may want to customize `~/.zshrc` or other dot-files and experiment with it.

Everything else outside your mounted host filesystem and the docker `~` can be temporarily modified, but will get restored in the next docker session (i.e. the next time you will start it `~/try-fm start`).

So to recap the behavior of the filesystem in the docker session:

- The mounted FS is your own writable filesystem, so don't do anything stupid with it :)
- `~` is the docker container HOME and is persisted between sessions, so use it to experiment with dot-files. You can reset it with `~/try-fm reset` at any time
- everything else will get restored the next session (i.e. the next time you will start it `~/try-fm start`)

## Purge

Just run `~/try-fm purge` to remove anything related to 'try-fm' and reclaim the disk space used by docker.

## Known limitation of the docker session

A few menus that work perfectly in the FM installed version don't work, or are limited, in the `try-fm` docker session:

- `Cycle Preview Mode` -> `ctrl-p` does not imediately refresh the preview after the command: you have to refresh it manually so instead of pressing `ctrl-p` you have to press `ctrl-p` `ctrl-r`
- `Open Selected Items` -> `ctrl-o` is meant to open files and dirs in your desktop and it cannot work because the docker image does not offer a desktop environment
- `Open New Shell Here` -> `ctrl-n` it may open a new shell in your regular terminal session instead of opening it in the docker session
- `Switch to FIND View` -> `alt-f` on MacOS is very slow when performed in docker bind mounted paths (i.e. your mounted filesystem)
