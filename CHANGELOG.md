# CHANGELOG

## Unreleased

- Test suite: `tests/run` (headless tests and tmux-driven TUI tests), `tests/run -c` runs it in the try-fm container
- try-fm: rebuilt on Fedora with the distro packages only, FM copied from the repo, works with docker and podman, `test` subcommand, playground dir
- Fixed: broken symlinks could not be selected (DIR view), pasted or linked
- Fixed: favorites with a space in the path were written as an invalid `hash -d` line
- Fixed: broken favorites were never removed from the favorites file
- Fixed: `esc` and `ctrl-c` printed an FM ERROR and returned 130 instead of quitting
- Fixed: the bash and fish launchers got the `cd` target polluted by sourcing fm.zsh twice, and failed on paths with spaces
- Fixed: `fm env` lacked the widget keys, `fm help` lacked FM__CMD_XCLIP, the PICK notes lacked their key variable, typos
- Paste skips the sources that contain the destination dir (pasting a selection into one of its dirs no longer aborts)
- The query is reset after creating, renaming, pasting and linking, so the new items are visible
- Edit and the execute bit switch skip the broken links (no sudo prompt for a dangling link)
- `FM__CMD_SORT` default is `sort -fb`: with `-i` the non-ASCII bytes were ignored in the C locale
- try-fm: `ctrl-p` works at the first press (the engine's detach key sequence is disabled)
- Widget: adding favorites shows no dialog, just the notification in the header (the dialog replaced the whole screen for a second and left the terminal in the alternate screen)
- Edit and the execute bit switch show no dialog either (it had nothing to ask and an empty recap), just the header notification
- Fixed: `fm__compile` compiled the FM of the exported `fm__root` instead of its own copy (a plugin manager's build hook run from a shell with another FM loaded compiled the wrong one)
- The functions are autoloaded by name through `fpath` instead of by absolute path: the plugin managers track them correctly (zinit needs no `atinit` any more) and the compiled files get no stubs
- Widget: fixed the empty DIR view with eza (it read the paths from the widget's stdin)
- Widget: works like a completion: starts from the word at the cursor (dir part and query) and replaces it with the picked paths, in the shorter form between relative to the prompt dir and abbreviated with the shell named dirs (~, ~favorite), quoted, dirs with a trailing /
- Widget: the panel output goes to the terminal, so dialogs work; FAV_ADD and FAV_ADD_WD available (with the automatic name)

## Version 0.2.0

- Replaced exa with eza
- DIR view: items extraction independent from the listing columns (issue #2)
- Fixed items with spaces in the name with eza
- Fixed output noise in items extraction
- ls fallback: GNU options used only when supported (MacOS)
- try-fm: installs eza, uses the archived buster repos, fixed launchers for bash and fish
- Minor fixes

## Version 0.1.1

- Updated zinit, Dockerfile and README
- minor fixes

## Version 0.1.0

- First published version
