# Copyright (c) 2021-2026 Domizio Demichelis
# Released under GNU3 license
# https://www.gnu.org/licenses/gpl-3.0.en.html

# fm launcher function (fish syntax)

function fm
	test "$argv[1]" = '-' && cd $fm__start_dir && return 0
	set -g fm__start_dir $PWD
	cd (zsh -i -c 'type fm >/dev/null || . $fm__root/fm.zsh; fm "$@" >/dev/tty; print -r -- $PWD' fm $argv)
end
