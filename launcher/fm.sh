# fm launcher function (POSIX syntax)

fm() {
	test "$1" = '-' && cd "$fm__start_dir" && return 0
	fm__start_dir="$PWD"
	cd "$(zsh -i -c "fm $@ >/dev/tty; print -- \$PWD")"
}
