# fm launcher function (fish syntax)

function fm
    test "$argv[1]" = '-' && cd $_fm_start_dir && return 0
    set _fm_start_dir $PWD
    cd (zsh -i -c "fm $argv >/dev/tty; print -- \$PWD")
end
