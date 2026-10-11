# Try FM without installing it

`try-fm` runs FM in a container, with every tool it uses already installed. Nothing is installed on your system: the image and the session home live in the container engine, and one command removes them.

The same image runs the FM test suite (see below).

## Prerequisites

- [docker](https://www.docker.com) or [podman](https://podman.io) (rootless podman works)
- `curl`, to download the script
- A terminal with a [Nerd Font](https://www.nerdfonts.com), if you want the file icons (FM lists the files with `eza --icons`)

## Quick start

Download the script in your home dir and run it:

```sh
sh -c "curl -fsSL https://raw.githubusercontent.com/ddnexus/fm/master/try-fm/try-fm -o ~/try-fm; chmod +x ~/try-fm; ~/try-fm"
```

Then start the session (the first start builds the image, a few minutes):

```sh
~/try-fm start
```

In the session (green prompt): run `fm`, press `ctrl-space` for the menu with the usage notes, `ctrl-q` to quit. Press `alt-f` twice while typing a command to get the widget. Type `bash` or `fish` to try FM from those shells. Exit the session with `exit`.

## What is in the session

- FM installed in `/opt/fm`, sourced by `~/.zshrc`: edit that file to try the `FM__*` variables (`fm help` lists them). The home dir persists between sessions.
- `~/playground`: a tree of files and dirs with awkward names, to try the fs commands (copy, paste, rename, remove...) without risk.
- `bash` and `fish` with the FM launchers.
- `sudo`, with the password `fm`, to try the automatic sudo of the fs commands on protected items.
- Your own filesystem, mounted at `/<your-hostname>` (see the mount options below). **The changes made there are real.**

## Commands

```
~/try-fm start|s          Build the image if needed and start the session...
   [--root-mount|-r]  ...with your / mounted at /<hostname> (default)
    --home-mount|-h   ...with your home dir mounted at /<hostname>/home/<you>
      --no-mount|-n   ...with nothing of your filesystem mounted
~/try-fm test|t [ARGS]    Run the FM test suite in the container (ARGS: see tests/run -h)
~/try-fm build|b          Build the image again (e.g. to update FM)
~/try-fm reset|r          Remove the session HOME: the next start recreates it
~/try-fm purge|p          Remove the image and the session HOME
~/try-fm usage|u          Show this screen
```

`TRY_FM_ENGINE=docker|podman` forces the engine (default: docker when it is running, else podman). `TRY_FM_CONTEXT` sets the build context (default: the `master` branch on GitHub; a clone of the repo when the script runs from `try-fm/try-fm` inside it).

## Testing FM

The FM test suite (`tests/`) runs on your machine with `tests/run`, and in the container, where every tool is installed and nothing of yours is at stake, with:

```sh
tests/run -c         # from a clone: the working copy is mounted into the container
~/try-fm test        # standalone: the copy of FM in the image
```

Both accept the `tests/run` options and patterns, e.g. `tests/run -c -v items` runs the `items` tests verbosely.

## Known limitations of the session

- `Open Selected Items` (`ctrl-o`) and `Copy Selected Paths` (`ctrl-t`) need a desktop: the container has none.
- `Open New Shell Here` (`ctrl-n`) opens the new shell in the same terminal; in a `tmux` session (installed) it opens a tmux window.
- With rootless podman, the files of your filesystem that belong to other users appear as owned by `nobody`, and `sudo` in the session cannot change them (it works on the container's own files).
- Symbolic links of your filesystem pointing to absolute paths are broken in the session, since your filesystem is mounted under `/<hostname>`.

## Q&A

**The alt key prints a character instead of running the shortcut.** Your terminal must send `alt` as the meta key (`esc` prefix): MacOS Terminal: `Preferences > Profiles > Keyboard > Use Option as Meta key`; iTerm: `Preferences > Profiles > Keyboard > Option Key > Esc+`; Xterm: `echo 'XTerm*metaSendsEscape: true' >> ~/.Xresources`. Other terminals: see [Meta Key Problems](https://www.emacswiki.org/emacs/MetaKeyProblems).

**The build fails resolving a host name.** That is the DNS of your container engine, not `try-fm`: [here is the usual solution for docker](https://stackoverflow.com/questions/51034120/docker-could-not-resolve-deb-debian-org).

**How do I remember the shortcuts?** Toggle the menu with `ctrl-space`: it shows every action with its shortcut, filterable by typing; pick one with enter, or press its shortcut right there.
