# FM

FM is a complete File Manager for any shell. As fast as a CLI and as easy as a desktop UI, it easily integrates also with your own functions/commands.

### Motivation

Whether you are comfortable with the terminal or not, you spend a lot of time and effort just repeating basic commands like `cd`, `ls`, `cat`, `cp`, `mv`, `ln`, `find`, `grep`, `mkdir`, `touch`... or maybe you are switching back and forth from the Desktop File Manager to the terminal just to avoid it...

FM saves you all that repeated typing and switching, providing automatic feedback and all that basic tools at the press of a shortcut... and it can also integrate your own tools.

### Star and share!

If you like FM, please, give it a star and share it with friends and collegues!

## Features

FM has all the features that you would expect from a CLI but also from a Desktop File Manager... and actually some more. Here is an overview:

- Navigation with mouse or keyboard
- Unobstrusive, filterable menu with customizable shortcuts
- Jump to common dirs, saved favorites and recent visited dirs
- Automatic inline syntax-highlighted content preview of file/dir/results
- Search file names and/or file content with context and highlighted matches
- Easy management of favorite files and dirs in any shell
- Copy, cut, paste and link groups of files and dirs in one go (even from different locations)
- Automatic sudo prompt when needed
- Easy integration of your own functions/commands in the FM own menu
- Inline contextual help/documentation for each menu and section
- Zsh-widget: you can also get FM while typing commands in the zsh prompt: navigate, preview and automatically place the seleced paths to complete your command.

## Try it without installing it

You can try FM on your system with the [`try-fm`](https://github.com/ddnexus/fm/tree/master/try-fm) docker image. It's a very quick and clean way to try it on your own filesystem without the need of installing it.

## Installation

### Install Prerequisites

- [`zsh`](https://www.zsh.org): The base shell scripting. **Notice** that you just need `zsh` installed with the default config, but you can use FM with any shell. Use your package manager to install it (e.g. for Ubuntu: `sudo apt-get install zsh`)
- [`fzf`](https://github.com/junegunn/fzf): Fundamental part of the TUI ([fzf installation](https://github.com/junegunn/fzf#installation))
- [`ripgrep`](https://github.com/BurntSushi/ripgrep): Faster replacement for grep ([ripgrep installation](https://github.com/BurntSushi/ripgrep#installation))

### Install recommended packages

In order to get the best experience with FM you should also install the following optional packages:

- [`exa`](https://github.com/ogham/exa): Modern replacementy for `ls` with better feedback ([exa installation](https://the.exa.website/install))
- [`fd` / `fd-find`](https://github.com/sharkdp/fd): Faster replacement for `find` ([fd installation](https://github.com/sharkdp/fd#installation))
- [`bat`](https://github.com/sharkdp/bat): _"A `cat` clone with wings"_ for syntax-highlighted preview ([bat installation](https://github.com/sharkdp/bat#installation))

### Install FM

- with [zinit](https://github.com/zdharma/zinit)(zplugin):
  ```zsh
  zinit ice --depth'1' atinit'source fm.zsh' atclone'./fm__compile' atpull'%atclone'
  zinit light ddnexus/fm
  ```
- with [zplug](https://github.com/zplug/zplug): `zplug "ddnexus/fm", hook-build:"./fm__compile"`
- with [antigen](https//github.com/zsh-users/antigen): `antigen bundle ddnexus/fm`
- with [zgen](https://github.com/tarjoilija/zgen): `zgen load ddnexus/fm`
- manually:
  - Clone or download the repo in your preferred `<FM-DIR-PATH>`
  - Replace the following `<FM-DIR-PATH>` placeholder with the actual path  and run:

  ```sh
  echo "source <FM-DIR-PATH>/fm.zsh" >> $HOME/.zshrc
  ```
  In this case, remember to pull the repo periodically.

#### Compile after install

To make it run faster, FM can be compiled with a simple command.
Run `fm compile` only once, every time you update the repo.

**Notice**: the `zinit` and `zplug` installation commands shown above, compile FM automatically, so you don't need to do it manually.

## Configuration

- **Zsh shell**
  - No need for any configuration

- **POSIX compatible shells**: `bash`, `sh`, etc.:
  - Replace the following `<RC-FILE-PATH>` placeholder with the actual path for your shell (e.g. for `bash` it would be `$HOME/.bashrc`), and run:

  ```sh
  zsh -c 'print "\n. $fm__root/launcher/fm.sh" >> <RC-FILE-PATH>'
  ```
  - Restart your shell

- **Fish shell**

  ```sh
  zsh -c 'mkdir -p $HOME/.config/fish; echo "\nsource $fm__root/launcher/fm.fish" >> $HOME/.config/fish/config.fish'
  ```
  - Restart your shell

- **Other shells**
  - If you use some exotic shell that is not compatible with any of the launchers, you can port the 3 simple lines of the `fm.sh` launcher to your shell syntax and source it as indicated above. If you do so, please, submit a PR with your function, so it will be added. Thanks.

## Usage

### In any shell

Just type `fm` from any dir in any shell. You should be able to figure it out from there by taking a look at the menu (`ctrl-space`), which offers also the inline usage notes and documentation.

The `fm help` command will give you an overview about the FM environment and the variables that you can customize.

**Suggestion**: FM is designed to be easy to run and quit. You can make it a bit easier with an alias like `alias f=fm`.

### Zsh-only features

The FM favorites are working in any shell, however the favorite `widget` and the shell favorite `aliases` are available only in the `zsh` shell.

## Customization

All the FM customizations consist in redefining some `FM__*` variable in the `~/.zshrc` file _regardless the shell you use_. You can read the `fm help` and the inline documentation in the FM menu (`ctrl-space`) for details.

## Add your own tools

You can easily add your own functions/commands to the FM Menu and execute them as any other FM menu. Your tool will have access to the selected items and the other FM variables and functions.

You can read the inline documentation in the FM menu section `Added Tools` and try the provided working examples for more details.

## Q&A

See [Q&A](https://github.com/ddnexus/fm/tree/master/try-fm#qa)

## Caveats

- The `exa --git ...` option is not fully git compliant nor consistent between platforms and OSs to be considered useful at this time, so it is not supported by FM. Specifically: if you add it to the `FM__CMD_LS` variable it will break the `DIR` view if the current dir is inside a working tree.

## Contributions

- If you like FM, please, give it a star and share it with friends and collegues. That's the most needed contribution ATM.
- Publish a review or a tutorial to help others
- Please, open an Issue if the documentation is not clear or if you find any bug.
- Pull requests are welcome! Before starting you may want to confirm whether your proposed changes are going to be useful for most users.
- Your feedback, suggestions, requests, bug-reports are welcome and also count as contributions!

## Branches

 The `master` branch is the latest published release. It also contains docs and comment changes that don't affect the published code.

Expect any other branch to be experimental, force-rebased and/or deleted even without merging.

## Versioning

 FM follows the [Semantic Versioning 2.0.0](https://semver.org/). Please, check the [Changelog](https://github.com/ddnexus/fm/blob/master/CHANGELOG.md) for breaking changes introduced by mayor versions.

## License

This software is available as open source under the terms of the [GPS3 License](https://www.gnu.org/licenses/gpl-3.0.en.html).

---

Copyright &copy; 2021 Domizio Demichelis
