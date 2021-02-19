# fm launcher function (fish syntax)

function fm
    test "$argv[1]" = '-' && cd $__fm_start_dir && return 0
    set __fm_start_dir $PWD
    cd (zsh -i -c "fm $argv >/dev/tty; print -- \$PWD")
end
