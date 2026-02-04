# FM

FM is a complete File Manager for any shell. It combines the speed of the CLI with the ease of a desktop UI, and easily integrates with your own functions and commands.

## Motivation

Navigating the file system often involves repeating basic commands like `cd`, `ls`, `cat`, or switching context to a desktop file manager. FM streamlines this workflow, providing automatic feedback and essential tools with simple shortcuts, directly in your terminal.

### Star and share!

If you find FM useful, please give it a star and share it!

## Features

FM has all the features that you would expect from a CLI but also from a Desktop File Manager... and actually some more. Here is an overview:

- **Navigation**: Mouse or keyboard support.
- **Menu**: Unobtrusive, filterable menu with customizable shortcuts.
- **Jumping**: Quick access to common directories, favorites, and history.
- **Preview**: Automatic inline syntax-highlighted preview for files and directories.
- **Search**: Filename and content search with highlighted matches.
- **Favorites**: Easy management of favorite files and directories.
- **Bulk Actions**: Copy, cut, paste, and link groups of items (even across directories).
- **Sudo**: Automatic prompt when permissions are required.
- **Extensible**: Easily add your own custom tools to the FM menu.
- **Help**: Inline documentation for all features.
- **Zsh Widget**: Integrate FM directly into your Zsh prompt to pick paths while typing commands.

## Try it

You can try FM without installation using the `try-fm` docker image.

## Installation

### Prerequisites

- **`zsh`**: The base shell (FM runs in Zsh but works from any shell).
- **`fzf`**: The core TUI engine (fzf installation).
- **`ripgrep`**: Fast grep replacement (ripgrep installation).

### Recommended

In order to get the best experience with FM you should also install the following optional packages:

- **`eza`**: Modern `ls` replacement with icons and better formatting (eza installation).
- **`fd`**: Fast `find` replacement (fd installation).
- **`bat`**: Syntax-highlighting `cat` clone (bat installation).

### Install FM

Add the relevant lines to your `$HOME/.zshrc`:

**Using zinit:**
```zsh
zinit ice depth'1' atinit'source fm.zsh' atclone'./fm__compile' atpull'%atclone'
zinit light ddnexus/fm
```

**Using zplug:**
```zsh
zplug "ddnexus/fm", hook-build:"./fm__compile"
```

**Using antigen:**
```zsh
antigen bundle ddnexus/fm
```

**Using zgen:**
```zsh
zgen load ddnexus/fm
```

**Manual Installation:**

1. Clone the repository to your preferred directory.
2. Source `fm.zsh` in your `.zshrc`:
   ```zsh
   source /path/to/fm/fm.zsh
   ```
3. (Optional) Run `fm compile` to improve startup time.

## Configuration

FM works in any shell. Configuration is always done in `~/.zshrc` via `FM__*` variables.

### Shell Setup

**Zsh:**
No extra configuration needed.

**Bash / POSIX Shells:**
Add the launcher to your config (e.g., `~/.bashrc`):
```sh
# Run this once to append the launcher
zsh -c 'print "\n. $fm__root/launcher/fm.sh" >> ~/.bashrc'
```

**Fish:**
Add the launcher to `config.fish`:
```sh
# Run this once
zsh -c 'mkdir -p ~/.config/fish; echo "\nsource $fm__root/launcher/fm.fish" >> ~/.config/fish/config.fish'
```

**Other Shells:**
Port the 3 lines from `launcher/fm.sh` to your shell's syntax.

## Usage

Type `fm` to start.
Press `ctrl-space` to open the menu, which includes usage notes and documentation.
Run `fm help` for an overview of variables and commands.

**Tip:** Alias `fm` for speed: `alias f=fm`.

### Zsh Features
The `widget` and shell favorite `aliases` are exclusive to Zsh.

## Customization

Customize FM by defining `FM__*` variables in `~/.zshrc`.
See `fm help` or the **Menu Panel** (`ctrl-space`) for details on available options.

## Add Your Own Tools

You can add custom functions or commands to the FM Menu. These tools can access selected items and internal variables.
See the **Added Tools** section in the menu for examples and documentation.

## Versioning

FM follows Semantic Versioning 2.0.0. Check the Changelog.

## License

This software is available as open source under the terms of the GPL3 License.

---

Copyright &copy; 2021-2026 Domizio Demichelis
