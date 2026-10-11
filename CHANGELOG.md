# CHANGELOG

## Unreleased

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
