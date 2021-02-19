# fm launcher function (POSIX syntax)

fm() {
    test "$1" = '-' && cd "$_fm_start_dir" && return 0
    _fm_start_dir="$PWD"
    cd "$(zsh -i -c "fm $@ >/dev/tty; print -- \$PWD")"
}
