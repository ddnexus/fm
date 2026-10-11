#!/usr/bin/env zsh

# Copyright (c) 2021-2026 Domizio Demichelis
# Released under GNU3 license
# https://www.gnu.org/licenses/gpl-3.0.en.html


# The launchers for the other shells: fm runs in a zsh -i that must source fm.zsh from its ~/.zshrc

launcher_zdot() {
	mkdir -p $sb/zdot
	print -r -- "source $fm__root/fm.zsh" > $sb/zdot/.zshrc
	tui_env+=ZDOTDIR=$sb/zdot
}

check_launcher() { # the shell is running in the pane with the launcher sourced
	tui_type fm
	tui_send Enter
	tui_wait_view DIR
	tui_send M-p
	tui_wait_view DIR $sb
	tui_send C-q
	tui_wait_gone ' DIR '
	tui_type "pwd > $sb/pwd"
	tui_send Enter
	sleep 0.3
	assert_eq $sb "$(<$sb/pwd)" 'the shell follows the last dir of the panel'
	tui_type 'fm -'
	tui_send Enter
	tui_type "pwd > $sb/pwd"
	tui_send Enter
	sleep 0.3
	assert_eq $sb/fx "$(<$sb/pwd)" 'fm - jumps back to the start dir'
	tui_type 'fm env'
	tui_send Enter
	tui_wait "fm__root              $fm__root" 5 'fm env through the launcher'
}

test_bash_launcher() {
	type bash &>/dev/null || skip 'bash not installed'
	fm_load
	launcher_zdot
	print -l ". $fm__root/launcher/fm.sh" "PS1='bash\$ '" > $sb/bashrc
	tui_run "bash --noprofile --rcfile $sb/bashrc"
	tui_wait 'bash$'
	check_launcher
}

test_fish_launcher() {
	type fish &>/dev/null || skip 'fish not installed'
	fm_load
	launcher_zdot
	tui_run "fish --no-config -C 'source $fm__root/launcher/fm.fish; function fish_prompt; echo \"fish> \"; end'"
	tui_wait 'fish>'
	check_launcher
}

test_sh_launcher_syntax_is_posix() {
	fm_load
	assert_ok sh -n $fm__root/launcher/fm.sh
	type dash &>/dev/null && assert_ok dash -n $fm__root/launcher/fm.sh
	return 0
}
