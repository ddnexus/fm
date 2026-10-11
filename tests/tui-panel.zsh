#!/usr/bin/env zsh

# Copyright (c) 2021-2026 Domizio Demichelis
# Released under GNU3 license
# https://www.gnu.org/licenses/gpl-3.0.en.html


# The FM Panel driven in tmux: views, navigation, menu, tools

test_panel_starts_in_dir_view_and_quits_with_ctrl_q() {
	fm_load
	tui_start
	tui_wait_view DIR
	local screen=$(tui_screen)
	assert_contains "FM $fm__version" "$screen"
	assert_contains 'Press a shortcut or ctrl-space for the menu' "$screen"
	assert_contains 'dir one' "$screen"
	assert_contains 'dir one: directory' "$screen" 'the preview of the first item'
	tui_send C-q
	tui_exit
	assert_eq 0 "$tui_status"
	assert_eq $sb/fx "$tui_pwd"
}

test_esc_quits_silently() {
	fm_load
	tui_start
	tui_wait_view DIR
	tui_send Escape
	tui_exit
	assert_lacks 'FM ERROR' "$(tui_screen)"
	assert_eq 0 "$tui_status"
}

test_ctrl_c_quits_silently() {
	fm_load
	tui_start
	tui_wait_view DIR
	tui_send C-c
	tui_exit
	assert_lacks 'FM ERROR' "$(tui_screen)"
	assert_eq 0 "$tui_status"
}

test_views_switch_with_their_keys() {
	fm_load
	tui_start
	tui_wait_view DIR
	tui_send M-f
	tui_wait_view FIND
	assert_contains 'sub/deep/b.md' "$(tui_screen)"
	tui_query hello
	tui_send M-g
	tui_wait_view GREP
	tui_wait '4 Matching files for: hello'
	assert_contains 'notes.txt:2' "$(tui_screen)"
	tui_send M-r
	tui_wait_view REC
	tui_send M-r
	tui_wait_view FIND $PWD 'the REC view toggles back to the fs view (DIR or FIND)'
	tui_send M-v
	tui_wait_view FAV
	tui_send M-d
	tui_wait_view DIR
	tui_send C-q
	tui_exit
}

test_grep_without_query_notifies() {
	fm_load
	tui_start
	tui_wait_view DIR
	tui_send M-g
	tui_wait 'You must enter a query to GREP'
	tui_wait_view DIR
	tui_send C-q
	tui_exit
}

test_hidden_and_sort_toggles() {
	fm_load
	tui_start
	tui_wait_view DIR
	assert_lacks '.hidden' "$(tui_screen)"
	tui_send C-h
	tui_wait 'Hidden Visibility ON'
	assert_contains '.hidden-dir' "$(tui_screen)"
	tui_settle
	tui_send C-h
	tui_wait 'Hidden Visibility OFF'
	assert_lacks '.hidden' "$(tui_screen)"
	tui_settle
	tui_send C-s
	tui_wait 'Items temporarily sorted by path'
	tui_settle
	tui_send C-q
	tui_exit
}

test_notify_working_dir() {
	fm_load
	tui_start
	tui_wait_view DIR
	tui_send C-w
	tui_wait "Working Dir: $PWD"
	tui_settle
	tui_send C-q
	tui_exit
}

test_navigation_keys() {
	fm_load
	tui_start
	tui_wait_view DIR
	tui_send M-p
	tui_wait_view DIR $sb
	tui_send M-l
	tui_wait_view DIR $sb/fx
	tui_send M-h
	tui_wait_view DIR '~'
	tui_send M-/
	tui_wait_view DIR /
	tui_send M-s
	tui_wait_view DIR $sb/fx
	tui_send C-q
	tui_exit
	assert_eq $sb/fx "$tui_pwd"
}

test_quit_leaves_the_shell_in_the_last_dir() {
	fm_load
	tui_start
	tui_wait_view DIR
	tui_send M-p
	tui_wait_view DIR $sb
	tui_send C-q
	tui_exit
	assert_eq $sb "$tui_pwd"
}

test_enter_on_a_dir_descends_and_cd_contain_jumps_to_the_dir_of_the_item() {
	fm_load
	tui_start
	tui_wait_view DIR
	tui_query 'sub !link' 1
	tui_send Enter
	tui_wait_view DIR $sb/fx/sub
	assert_contains 'a.md' "$(tui_screen)"
	tui_send M-f
	tui_wait_view FIND $sb/fx/sub
	tui_query deep/b 1
	tui_send M-c
	tui_wait_view FIND $sb/fx/sub/deep 'CD_CONTAIN keeps the fs view'
	tui_send C-q
	tui_exit
	assert_eq $sb/fx/sub/deep "$tui_pwd"
}

test_enter_on_a_file_opens_the_pager() {
	fm_load
	tui_start 'FM__CMD_PAGER="less -R"'
	tui_wait_view DIR
	tui_query 'README !link' 1
	tui_send Enter
	tui_wait 'README.md (press h for help or q to quit)'
	assert_contains 'hello world' "$(tui_screen)"
	tui_send q
	tui_wait_view DIR
	tui_send C-q
	tui_exit
}

test_the_query_survives_a_refresh_and_is_reset_by_cd() {
	fm_load
	tui_start
	tui_wait_view DIR
	tui_query notes 1
	tui_send C-r
	tui_wait " DIR $PWD notes "
	tui_send M-p
	tui_wait_view DIR $sb
	assert_lacks 'notes ' "$(tui_screen)"
	tui_send C-q
	tui_exit
}

test_preview_cycle_is_persisted() {
	fm_load
	tui_start
	tui_wait_view DIR
	tui_send C-p
	tui_wait_view DIR
	local -A preview
	fm__read -data preview
	assert_eq 2 "$preview[command-panel]"
	tui_send C-p
	sleep 0.3
	tui_send C-p
	tui_wait_view DIR
	sleep 0.3
	fm__read -data preview
	assert_eq 1 "$preview[command-panel]"
	tui_send C-q
	tui_exit
}

# the Menu Panel

test_menu_opens_filters_and_runs_the_picked_entry() {
	fm_load
	tui_start
	tui_wait_view DIR
	tui_send C-Space
	tui_wait 'Toggle This Menu'
	assert_contains 'Pick a menu or press a shortcut' "$(tui_screen)"
	assert_contains 'FM UI' "$(tui_screen)" 'the usage note of the first row'
	tui_query 'Notify Working' 1
	tui_send Enter
	tui_wait "Working Dir: $PWD"
	tui_send C-q
	tui_exit
}

test_menu_toggles_back_with_its_key_and_esc() {
	fm_load
	tui_start
	tui_wait_view DIR
	tui_send C-Space
	tui_wait 'Toggle This Menu'
	tui_send C-Space
	tui_wait_gone 'Toggle This Menu'
	tui_wait_view DIR
	tui_send C-Space
	tui_wait 'Toggle This Menu'
	tui_send Escape
	tui_wait_gone 'Toggle This Menu'
	tui_wait_view DIR
	tui_send C-q
	tui_exit
}

test_menu_shows_the_selected_items_recap() {
	fm_load
	tui_start
	tui_wait_view DIR
	tui_send C-a
	tui_send C-Space
	tui_wait 'Selected Items:'
	assert_contains 'for a Total of 16' "$(tui_screen)"
	tui_send Escape
	tui_wait_gone 'Selected Items:'
	tui_send C-q
	tui_exit
}

test_menu_shortcut_pressed_in_the_menu_runs_the_action() {
	fm_load
	tui_start
	tui_wait_view DIR
	tui_send C-Space
	tui_wait 'Toggle This Menu'
	tui_send C-w
	tui_wait "Working Dir: $PWD"
	tui_settle
	tui_send C-q
	tui_exit
}

test_menu_category_rows_reload_the_menu() {
	fm_load
	tui_start
	tui_wait_view DIR
	tui_send C-Space
	tui_wait 'Toggle This Menu'
	tui_query 'FS Navigation' 1
	tui_send Enter
	sleep 0.3
	tui_wait 'Pick a menu or press a shortcut' 5 'still in the menu, with the same query'
	assert_contains 'FS Navigation' "$(tui_screen)"
	tui_send Escape
	tui_wait_gone 'Pick a menu'
	tui_send C-q
	tui_exit
}

# added tools

test_added_tool_runs_with_its_key_and_sees_the_panel_variables() {
	fm_load
	tui_start '' "source $fm__root/added-tools-examples"
	tui_wait_view DIR
	tui_query 'README !link' 1
	tui_send F6
	tui_wait 'view: DIR'
	assert_contains 'query: README' "$(tui_screen)"
	assert_contains "$PWD/README.md" "$(tui_screen)"
	tui_send q
	tui_wait "The 'show-variable' function works!"
	tui_send C-q
	tui_exit
}

test_added_tool_without_key_runs_from_the_menu_and_reports_failures() {
	fm_load
	tui_start '' "source $fm__root/added-tools-examples"
	tui_wait_view DIR
	tui_send C-Space
	tui_wait 'Toggle This Menu'
	tui_query 'Will Fail' 1
	tui_send Enter
	tui_wait 'Added Tool failed [ERROR 2]'
	tui_send C-q
	tui_exit
}

test_added_tool_menu_row_shows_its_usage() {
	fm_load
	tui_start '' "source $fm__root/added-tools-examples"
	tui_wait_view DIR
	tui_send C-Space
	tui_wait 'Toggle This Menu'
	tui_query 'Direct Command' 1
	tui_wait 'paginated with less'
	tui_send Escape
	tui_wait_gone 'Direct Command Example'
	tui_send C-q
	tui_exit
}

# tools

test_copy_paths_runs_the_clipboard_command() {
	fm_load
	print -l '#!/bin/sh' "cat > $sb/clip" > $sb/xclip; chmod +x $sb/xclip
	tui_start "FM__CMD_XCLIP=$sb/xclip"
	tui_wait_view DIR
	tui_query 'file one' 1
	tui_send C-t
	tui_wait '1 Paths copied to x-clipboard'
	assert_eq "\"$PWD/file one.txt\"" "$(<$sb/clip)"
	tui_send C-q
	tui_exit
}

test_open_runs_the_open_command_in_the_background() {
	fm_load
	print -l '#!/bin/sh' "printf '%s\n' \"\$@\" >> $sb/opened" > $sb/opener; chmod +x $sb/opener
	tui_start "FM__CMD_OPEN=$sb/opener"
	tui_wait_view DIR
	tui_query 'README !link' 1
	tui_send C-o
	local -P i; for ((i=0; i<40; i++)); do [[ -s $sb/opened ]] && break; sleep 0.05; done
	assert_eq "$PWD/README.md" "$(<$sb/opened)"
	tui_settle
	tui_send C-q
	tui_exit
}

test_new_shell_opens_a_shell_in_the_working_dir() {
	fm_load
	tui_start "FM__CMD_TERMINAL='' FM__CMD_SHELL=zsh"
	tui_wait_view DIR
	tui_query 'sub !link' 1
	tui_send Enter
	tui_wait_view DIR $sb/fx/sub
	tui_send C-n
	tui_wait "Opening a new 'zsh' session here"
	tui_wait $'\n% '
	tui_type 'touch from-shell'
	tui_send Enter
	tui_type exit
	tui_send Enter
	tui_wait_view DIR $sb/fx/sub
	assert_file $sb/fx/sub/from-shell
	tui_settle
	tui_send C-q
	tui_exit
}

test_tools_without_command_notify() {
	fm_load
	tui_start "FM__CMD_TERMINAL='' FM__CMD_SHELL='' FM__CMD_OPEN=''" "FM__CMD_OPEN=''; FM__CMD_XCLIP=''"
	tui_wait_view DIR
	tui_send C-o
	tui_wait 'No FM__CMD_OPEN command found'
	tui_settle
	tui_send C-t
	tui_wait 'No FM__CMD_XCLIP command found'
	tui_settle
	tui_send C-n
	tui_wait 'No suitable command for opening a new shell found'
	tui_settle
	tui_send C-q
	tui_exit
}

# ls fallback in the panel

test_panel_with_the_ls_fallback() {
	fm_load
	tui_start 'FM__CMD_LS="ls -lh"' # the portable fallback (BSD ls has no --color/--group-directories-first)
	tui_wait_view DIR
	assert_lacks 'total ' "$(tui_screen)"
	tui_query 'dir one' 1
	tui_send Enter
	tui_wait_view DIR "$sb/fx/dir one"
	assert_contains 'nested.txt' "$(tui_screen)"
	tui_send C-q
	tui_exit
}
