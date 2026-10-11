# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

FM is a terminal file manager written entirely in zsh, with `fzf` as its TUI engine and `ripgrep` for content search (`eza`, `fd`, `bat` are optional, with `ls`/`find`/`cat` fallbacks). It is installed by sourcing `fm.zsh` from `~/.zshrc`, usually through a plugin manager. `launcher/fm.sh` and `launcher/fm.fish` let other shells use it by spawning `zsh -i`.

## Commands

There is no build step or linter. CI (`.github/workflows/test.yml`) runs `try-fm/try-fm test` on every push to `master` and on pull requests (not on `dev`: pushes there may be untested work in progress). What exists:

```zsh
tests/run                 # the test suite (TAP output), ~3 min; `tests/run -l` lists the tests
tests/run items views     # only the tests whose file/name matches a pattern; -v shows the output of passing tests too
tests/run -c              # the same suite inside the try-fm container, with the working copy mounted (needs podman or docker)
try-fm/try-fm build       # (re)build the container image from the working copy; `try-fm/try-fm start` runs the demo

# Syntax-check every source file
zsh -fc 'setopt extended_glob; for f in fm.zsh fm__compile added-tools-examples {autoload/**,preview}/^*.zwc(.); do zsh -n $f || print "FAIL $f"; done'

# Optional startup speed-up: zcompile every function to a .zwc file next to its source
fm compile        # wrapper around ./fm__compile
```

### Tests

`tests/run` runs every `test_*` function of `tests/*.zsh` in its own subshell and sandbox (`FM__DATA`/`FM__TMP` redirected, cwd in a fixture tree with awkward names, see `fixture` in `tests/lib`); a failing assertion exits the subshell, `skip` exits 77. Two layers:

- Headless tests (`items`, `views`, `env`, `cat`): call the functions directly after `fm_load [VAR=value ...]` and `eval $panel_state` (which declares the dynamically scoped session state like `fm__cmd-run` does). `view_lines` fills `lines` as fzf would return them (colors stripped).
- TUI tests (`tui-*`): drive `fm` in a tmux pane (`tui_start`, `tui_send`, `tui_query`, `tui_wait`, `dialog_done`, `tui_exit`; the widget and the launchers through `tui_zsh`/`tui_run`). Rules learned the hard way: fzf filters asynchronously, so pass the expected match count to `tui_query` before acting on the current item; keys sent while fzf restarts (after every action, and during the 1 s sleep of the dialogs) are flushed, so wait for the new screen (`dialog_done`, `tui_wait_view`, or `tui_settle` when nothing visible changes); an `Escape` followed quickly by a key is read as an alt-chord; the menu and the dialogs reuse the panel prompt line, so wait for a text that only the new screen has. The harness sets `FM__CMD_SUDO=''`: never let a test reach the real sudo.

The panel is an interactive fzf session, so it needs a real terminal: it cannot be driven from a non-interactive tool shell. To try a change by hand, open a new zsh (functions already called in a running shell keep their old body) and run `fm`.

Everything that does not need the TUI can be exercised headless. Always redirect the data dirs, otherwise the run reads and writes the real `~/.fm` and `/tmp/fm`:

```zsh
d=$(mktemp -d); FM__DATA=$d/data FM__TMP=$d/tmp zsh -fc 'source ./fm.zsh
fm env                                             # subcommands
view=DIR hidden=false sort=false
lines=( "${(@f)$(fm__view-dir .)}" ); items=(); fm__set-items; print -l -- $items   # a view and its line -> path parsing
FZF_PREVIEW_COLUMNS=80 ./preview/panel README.md FIND false                         # file/dir preview script
./preview/menu "COPY  Copy Selected Items  ctrl-alt-c"'                             # menu usage note
```

Gotchas:

- `fm.zsh` exports `fm__root`, and `fm__compile` compiles `$fm__root` when it is set, not its own directory. In a shell that already loaded FM from another path, use `env -u fm__root ./fm__compile`.
- `.zwc` files are not ignored by git: never commit them. zsh loads whichever of source and `.zwc` is newer, so stale ones are harmless.
- `try-fm/` (container demo and test environment, Fedora image, docker or podman): `try-fm/Dockerfile` is built with the repo root as context and copies FM to `/opt/fm`; run from a clone, `try-fm/try-fm` builds from the working copy and `try-fm/try-fm test` mounts it over `/opt/fm`. The standalone script (downloaded with curl) builds from the `master` branch on GitHub; development happens on `dev`. The container `~/.zshrc` is `try-fm/zshrc`; `TRY_FM=true` in the image makes `preview/menu` show the session caveats.
- The version lives in `fm__version` (`fm.zsh`) and `CHANGELOG.md`.
- History is kept linear, with no merge commits: rebase `dev` on `master`, then fast-forward `master`.

## Architecture

### Loading

`fm.zsh` sets every default (`FM__KEY_*`, `FM__CMD_*`, limits, fzf options), builds the `fm__command_keys` and `fm__widget_keys` arrays, autoloads every file under `autoload/`, creates the data files and registers the zle widget. Defaults written `${VAR:=x}` cannot be emptied by the user; those written `${VAR=x}` can be disabled by setting them to `''`.

Each file under `autoload/` is one function: the file name is the function name and the file body is the function body, with no `name() { }` wrapper. The subdirectories (`cmd`, `panel`, `view`, `fs`, `fav`, `ui`) only group files; all of them are autoloaded by one glob. `fm <cmd>` dispatches to `fm__cmd-<cmd>`, so adding a subcommand means adding `autoload/cmd/fm__cmd-<name>` (`fm` alone is `fm__cmd-run`, `fm -` is `fm__cmd--`).

### The panel loop

`fm__panel-start` → `fm__panel` → `fm__panel-start` → … is the main loop, written as mutual recursion. One iteration:

1. `fm__view-<view>` (DIR, FIND, GREP, REC, FAV) prints the list, piped into fzf with `--expect=<all bound keys>`. fzf therefore exits on every shortcut and returns the query, the pressed key and the selected lines.
2. `fm__set-items` turns the selected `lines` into absolute paths in `items`, with one parser per view. DIR lines are `ls -l`/`eza -l` output, so the parser strips the colors and tries shorter and shorter suffixes of the line until one is an existing path.
3. If the key is the menu key, `fm__menu` runs a second fzf and replaces `key` with the id of the picked entry (e.g. `COPY`). This is why every branch of the dispatch `case` in `fm__panel` has the form `$FM__KEY_X|X)`.
4. The `case` runs the action, then calls `fm__panel-start` again. Quitting is a plain `return 0`. An unknown key falls through to `fm__run-added` (user tools).

`fm__notify` appends to the `header` array, which becomes the fzf `--header` of the next iteration: that is how actions report their result.

### State is shared through dynamic scoping

`fm__cmd-run` (and `fm__widget`) declare the session state as plain `local` variables (`view`, `fs_view`, `fm_mode`, `hidden`, `sort`, `rg_query`, `header`, `clipboard`, `preview`, `recent_dirs`, …) and every function called below them reads and writes those variables directly. Nothing is passed as arguments or kept in globals.

This makes the two declaration forms meaningful, so pick deliberately:

- `local x`: visible to callees, part of the contract. E.g. fs commands declare `local num message` because `fm__close-dialog` prints them, and `name` because `fm__dest-name` rewrites it.
- `local -P x` (`zsh/param/private`): invisible to callees. Use it for everything that is not meant to be shared.

`fm__read`/`fm__write` persist a variable by name with `typeset -p` and `source`, into `$FM__DATA` (`-data`: `favorites`, `recent_dirs`, `preview`) or `$FM__TMP` (`-tmp`: `clipboard`, `targets`, `added_menu`, `matches`). `typeset -p` emits `typeset -g`, so a read assigns the caller's dynamically scoped variable. `favorites` is different: it is a file of `hash -d name=path` lines that gets sourced, so favorites are zsh named directories (`~name`), and `fm__fav-*` address entries by line number.

### Two modes

`fm_mode` is `command` (the `fm` command) or `widget` (the zle widget, which replaces the word at the cursor with the picked paths, like a completion). The mode selects `FM__<MODE>_FZF_OPTS`, the `fm__<mode>_keys` array and the `preview[<mode>-panel|menu]` setting. The widget runs the panel in a subshell (`$( … 3>&1 >/dev/tty )`): stdout goes to the terminal as in command mode, PICK/PICK_WD print the paths to fd 3 and `fm__widget` formats them (relative to the prompt dir, `~`, quoted). The subshell also means no `vared`/zle there (`fm__fav-accept-name` skips the name confirmation in widget mode) and no lasting `cd`. Menu rows in `fm__menu` are flagged `cw`, `c-` or `-w` to say which mode shows them.

### Preview scripts run in separate processes

`preview/panel` and `preview/menu` are executed by fzf, not called as functions. They see only what `fm.zsh` exports with `typeset -gx` plus their arguments (`{} $view $hidden $rg_query`), and they autoload the functions again. Anything a preview needs must be exported or passed that way.

`preview/menu` is also the user documentation: one usage note per menu id, shown in the Menu Panel. The README defers to it and to `fm help`.

### Adding a built-in action

An action is wired in several places, all keyed by the same id (`COPY`, `VIEW_GREP`, …):

- `fm.zsh`: the `FM__KEY_<ID>` default in `fm__command_keys` (and `fm__widget_keys` if it applies to the widget)
- `autoload/panel/fm__panel`: the dispatch branch
- `autoload/panel/fm__menu`: the menu row
- `preview/menu`: the usage note
- `autoload/cmd/fm__cmd-env`: the variable list (and `fm__cmd-help` for non-key options)

`tests/env.zsh` checks this wiring for every `FM__KEY_*` and `FM__CMD_*` of `fm.zsh`, and `tests/cat.zsh` that every menu row has a usage note.

### Dialog pattern for fs commands

Commands that modify the filesystem (`autoload/fs`, `autoload/fav`) share one shape: `setopt LOCAL_OPTIONS ERR_RETURN`, `fm__open-dialog -<color> '<Title>' <array name>` (alternate screen with a recap), the work inside `{ … } always { fm__close-dialog }`, counting successes in `num`. The first failing command aborts the body, and `fm__close-dialog` reports `$num $message` plus `[ERROR n]` or `[INTERRUPTED]`. `$FM__CMD_SUDO` is prepended automatically when the target is not writable. In widget mode (only `fm__fav-add` gets there, with the automatic name) there is no dialog: `fm__open-dialog` returns at once, `fm__close-dialog` only notifies, and the prints meant for the dialog are skipped.

### Added tools

`fm add --tool … --title … [--key …] [--usage …]` appends a tab-separated record to `$FM__TMP/added_menu`. The tool is `eval`ed inside the panel's scope, so it sees `items`, `lines`, `view` and `query`. `fm.zsh` truncates `added_menu` every time it is sourced, so `fm add` calls belong after it in `~/.zshrc`. See `added-tools-examples`.

## Conventions

- Indent with tabs. The many `<<-` heredocs depend on it.
- The code uses zsh short forms throughout: `if [[ … ]] cmd`, `for x in $list; cmd`, `{ … } always { … }`.
- `NO_SH_WORD_SPLIT` is set, and commands with their options are stored in strings (`FM__CMD_*`, `sudo`), so they are run as `$=FM__CMD_CAT`, `$=sudo`.
- Do not declare a `local` inside a loop body: zsh prints `name=value` to stdout when an already set local is declared again without a value.
- Every file starts with the shebang and the copyright/GPL3 header.
