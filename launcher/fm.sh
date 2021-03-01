# Copyright (c) 2021 Domizio Demichelis
# Released under GNU3 license
# https://www.gnu.org/licenses/gpl-3.0.en.html

# fm launcher function (POSIX syntax)

fm() {
	test "$1" = '-' && cd "$fm__start_dir" && return 0
	fm__start_dir="$PWD"
	cd "$(zsh -i -c "fm $@ >/dev/tty; print -- \$PWD")"
}
