# fm launcher function (fish syntax)

function fm
	test "$argv[1]" = '-' && cd $fm__start_dir && return 0
	set fm__start_dir $PWD
	cd (zsh -i -c "fm $argv >/dev/tty; print -- \$PWD")
end
