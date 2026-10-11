#!/usr/bin/env zsh

# Copyright (c) 2021-2026 Domizio Demichelis
# Released under GNU3 license
# https://www.gnu.org/licenses/gpl-3.0.en.html


# The fs commands and their dialogs, driven in tmux

# filter the list with a query matching one item and press the key of a command
fs_action() { # query key
	tui_query "$1" 1
	tui_send $2
}
# descend into a dir of the fixture
enter_dir() { # query dir
	tui_query "$1" 1
	tui_send Enter
	tui_wait_view DIR $2
}

test_new_file() {
	fm_load
	tui_start
	tui_wait_view DIR
	tui_query notes 1
	tui_send C-M-f
	tui_wait 'Create New File'
	tui_wait 'Enter a name for the new File>'
	tui_type new.txt
	tui_send Enter
	dialog_done '1 File created'
	assert_file new.txt
	tui_wait ' 17/17' 5 'the query is reset: the new file is shown'
	assert_contains 'new.txt' "$(tui_screen)"
	tui_send C-q
	tui_exit
}

test_new_dir() {
	fm_load
	tui_start
	tui_wait_view DIR
	tui_send C-M-d
	tui_wait 'Enter a name for the new Dir>'
	tui_type 'new dir'
	tui_send Enter
	dialog_done '1 Dir created'
	assert_dir 'new dir'
	tui_send C-q
	tui_exit
}

test_new_file_asks_before_overriding() {
	fm_load
	tui_start
	tui_wait_view DIR
	tui_send C-M-f
	tui_wait 'Enter a name for the new File>'
	tui_type README.md
	tui_send Enter
	tui_wait 'Override README.md? (y/n)>'
	tui_send n
	tui_wait 'Skipped!'
	dialog_done '0 File created'
	assert_contains 'hello world' "$(<README.md)"
	tui_send C-M-f
	tui_wait 'Enter a name for the new File>'
	tui_type README.md
	tui_send Enter
	tui_wait 'Override README.md? (y/n)>'
	tui_send y
	tui_wait 'Overridden!'
	dialog_done '1 File created'
	assert_eq '' "$(<README.md)"
	tui_send C-q
	tui_exit
}

test_new_file_can_be_cancelled_with_ctrl_c() {
	fm_load
	tui_start
	tui_wait_view DIR
	tui_send C-M-f
	tui_wait 'Enter a name for the new File>'
	tui_type cancelled.txt
	tui_send C-c
	dialog_done '[INTERRUPTED]'
	assert_missing cancelled.txt
	tui_send C-q
	tui_exit
}

test_copy_and_paste_and_paste_again_with_a_suffix() {
	fm_load
	tui_start
	tui_wait_view DIR
	fs_action 'README !link' C-M-c
	tui_wait '1 Items copied'
	enter_dir 'sub !link' $sb/fx/sub
	tui_send C-M-v
	tui_wait "Paste the Items in $sb/fx/sub? (y/n)>"
	assert_contains "1. $sb/fx/README.md" "$(tui_screen)" 'the recap'
	tui_send y
	dialog_done '1 Items pasted here' DIR $sb/fx/sub
	assert_file sub/README.md
	assert_eq "$(<README.md)" "$(<sub/README.md)"
	tui_send C-M-v
	tui_wait 'Paste the Items in'
	tui_send y
	dialog_done '1 Items pasted here' DIR $sb/fx/sub
	assert_file 'sub/README(pasted).md'
	assert_file README.md 'the source is still there'
	tui_send C-q
	tui_exit
}

test_paste_can_be_refused() {
	fm_load
	tui_start
	tui_wait_view DIR
	fs_action 'README !link' C-M-c
	tui_wait '1 Items copied'
	tui_settle
	tui_send C-M-v
	tui_wait 'Paste the Items in'
	tui_send n
	tui_wait 'Skipped!'
	dialog_done '0 Items pasted here'
	assert_missing 'README(pasted).md'
	tui_send C-q
	tui_exit
}

test_cut_and_paste_moves_and_empties_the_clipboard() {
	fm_load
	tui_start
	tui_wait_view DIR
	fs_action notes C-M-x
	tui_wait '1 Items cut'
	enter_dir 'sub !link' $sb/fx/sub
	tui_send C-M-v
	tui_wait 'Paste the Items in'
	tui_send y
	dialog_done '1 Items pasted here' DIR $sb/fx/sub
	assert_file sub/notes.txt
	assert_missing notes.txt
	local -A clipboard=( [stale]=1 )
	fm__read -tmp clipboard
	assert_eq '' "$clipboard[mode]$clipboard[sources]" 'the clipboard is empty after a cut-paste'
	tui_send C-q
	tui_exit
}

test_copy_a_dir_and_paste_it_with_its_content() {
	fm_load
	tui_start
	tui_wait_view DIR
	fs_action 'dir one' C-M-c
	tui_wait '1 Items copied'
	enter_dir empty $sb/fx/empty
	tui_send C-M-v
	tui_wait 'Paste the Items in'
	tui_send y
	dialog_done '1 Items pasted here' DIR $sb/fx/empty
	assert_file 'empty/dir one/nested.txt'
	tui_send C-q
	tui_exit
}

test_paste_several_items() {
	fm_load
	mkdir $sb/dest
	tui_start
	tui_wait_view DIR
	tui_send C-a
	tui_send C-M-c
	tui_wait '16 Items copied'
	tui_settle
	tui_send M-p
	tui_wait_view DIR $sb
	enter_dir dest $sb/dest
	tui_send C-M-v
	tui_wait 'Paste the Items in'
	assert_contains 'for a Total of 16' "$(tui_screen)" 'the recap is limited'
	tui_send y
	dialog_done '16 Items pasted here' DIR $sb/dest
	assert_file $sb/dest/README.md
	assert_file "$sb/dest/spaces  two.txt"
	assert_link $sb/dest/broken-link
	assert_file $sb/dest/sub/deep/b.md
	tui_send C-q
	tui_exit
}

test_paste_skips_the_sources_containing_the_destination() {
	fm_load
	tui_start
	tui_wait_view DIR
	tui_send C-a
	tui_send C-M-c
	tui_wait '16 Items copied'
	enter_dir empty $sb/fx/empty
	tui_send C-M-v
	tui_wait 'Paste the Items in'
	tui_send y
	tui_wait 'Skipped empty (it contains the destination)'
	dialog_done '15 Items pasted here' DIR $sb/fx/empty
	assert_dir 'empty/dir one'
	assert_file empty/README.md
	assert_missing 'empty/empty'
	tui_send C-q
	tui_exit
}

test_paste_stops_at_the_first_error() {
	# the ERR_RETURN design: the first failing command aborts the dialog, which reports the error
	fm_load
	tui_start
	tui_wait_view DIR
	fs_action notes C-M-c
	tui_wait '1 Items copied'
	tui_settle
	chmod -w . # the destination is not writable, and the harness disables sudo
	tui_send C-M-v
	tui_wait 'Paste the Items in'
	tui_send y
	dialog_done '0 Items pasted here [ERROR 1]'
	chmod +w .
	assert_missing 'notes(pasted).txt'
	tui_send C-q
	tui_exit
}

test_mark_and_link() {
	fm_load
	tui_start
	tui_wait_view DIR
	fs_action 'README !link' C-M-m
	tui_wait '1 Targets marked'
	enter_dir 'sub !link' $sb/fx/sub
	tui_send C-M-l
	tui_wait "Create the Links in $sb/fx/sub? (y/n)>"
	tui_send y
	dialog_done '1 Targets linked here' DIR $sb/fx/sub
	assert_link sub/README.md
	assert_eq $sb/fx/README.md "$(readlink sub/README.md)"
	tui_send C-M-l
	tui_wait 'Create the Links in'
	tui_send y
	dialog_done '1 Targets linked here' DIR $sb/fx/sub
	assert_link 'sub/README(linked).md'
	tui_send C-q
	tui_exit
}

test_rename() {
	fm_load
	tui_start
	tui_wait_view DIR
	fs_action notes C-M-n
	tui_wait 'Enter the new name for notes.txt (empty to skip)>'
	tui_send C-u
	tui_type renamed.txt
	tui_send Enter
	dialog_done '1 Items renamed'
	assert_file renamed.txt
	assert_missing notes.txt
	tui_wait ' 16/16' 5 'the query is reset: the renamed file is shown'
	assert_contains 'renamed.txt' "$(tui_screen)"
	tui_send C-q
	tui_exit
}

test_rename_skips_empty_and_unchanged_names() {
	fm_load
	tui_start
	tui_wait_view DIR
	fs_action notes C-M-n
	tui_wait 'Enter the new name for notes.txt'
	tui_send Enter
	tui_wait 'Skipped!'
	dialog_done '0 Items renamed'
	assert_file notes.txt
	fs_action notes C-M-n
	tui_wait 'Enter the new name for notes.txt'
	tui_send C-u
	tui_send Enter
	tui_wait 'Skipped!'
	dialog_done '0 Items renamed'
	assert_file notes.txt
	tui_send C-q
	tui_exit
}

test_rename_asks_before_overriding() {
	fm_load
	tui_start
	tui_wait_view DIR
	fs_action notes C-M-n
	tui_wait 'Enter the new name for notes.txt'
	tui_send C-u
	tui_type README.md
	tui_send Enter
	tui_wait 'Override README.md? (y/n)>'
	tui_send n
	tui_wait 'Skipped!'
	dialog_done '0 Items renamed'
	assert_contains 'hello world' "$(<README.md)"
	fs_action notes C-M-n
	tui_wait 'Enter the new name for notes.txt'
	tui_send C-u
	tui_type README.md
	tui_send Enter
	tui_wait 'Override README.md? (y/n)>'
	tui_send y
	tui_wait 'Overridden!'
	dialog_done '1 Items renamed'
	assert_contains 'TODO' "$(<README.md)"
	assert_missing notes.txt
	tui_send C-q
	tui_exit
}

test_remove_asks_for_each_item() {
	fm_load
	tui_start
	tui_wait_view DIR
	tui_query notes 1
	tui_send Tab
	tui_query 'README !link' 1
	tui_send Tab
	tui_send C-M-r
	tui_wait 'Remove Selected Items'
	tui_wait 'Remove notes.txt? (y/n)>'
	tui_send y
	tui_wait 'Removed!'
	tui_wait 'Remove README.md? (y/n)>'
	tui_send n
	tui_wait 'Skipped!'
	dialog_done '1 Items removed'
	assert_missing notes.txt
	assert_file README.md
	tui_send C-q
	tui_exit
}

test_remove_a_dir_and_a_broken_link() {
	fm_load
	tui_start
	tui_wait_view DIR
	fs_action 'dir one' C-M-r
	tui_wait 'Remove dir one? (y/n)>'
	tui_send y
	dialog_done '1 Items removed'
	assert_missing 'dir one'
	fs_action broken-link C-M-r
	tui_wait 'Remove broken-link? (y/n)>'
	tui_send y
	dialog_done '1 Items removed'
	assert_missing broken-link
	tui_send C-q
	tui_exit
}

test_remove_a_link_keeps_its_target() {
	fm_load
	tui_start
	tui_wait_view DIR
	fs_action link-dir C-M-r
	tui_wait 'Remove link-dir? (y/n)>'
	tui_send y
	dialog_done '1 Items removed'
	assert_missing link-dir
	assert_file sub/a.md
	tui_send C-q
	tui_exit
}

test_execute_bit_from_the_menu() {
	fm_load
	tui_start
	tui_wait_view DIR
	tui_send C-a
	tui_send C-Space
	tui_wait 'Toggle This Menu'
	tui_query 'Execute bit ON' 1
	tui_send Enter
	dialog_done '11 File execute bit switched to ON' # dirs, links to dirs and broken links skipped
	assert_ok test -x README.md
	assert_ok test -x notes.txt
	tui_query 'README !link' 1
	tui_send C-Space
	tui_wait 'Toggle This Menu'
	tui_query 'Execute bit OFF' 1
	tui_send Enter
	dialog_done '1 File execute bit switched to OFF'
	assert_fail test -x README.md
	tui_send C-q
	tui_exit
}

test_fs_commands_in_find_view_go_back_to_find_view() {
	fm_load
	tui_start
	tui_wait_view DIR
	tui_send M-f
	tui_wait_view FIND
	fs_action deep/b C-M-r
	tui_wait 'Remove b.md? (y/n)>'
	tui_send y
	dialog_done '1 Items removed' FIND
	assert_missing sub/deep/b.md
	tui_send C-M-f
	tui_wait 'Enter a name for the new File>'
	tui_type found.txt
	tui_send Enter
	dialog_done '1 File created' FIND
	tui_wait ' 20/20' 5 'the query is reset'
	assert_contains 'found.txt' "$(tui_screen)"
	tui_send C-q
	tui_exit
}

test_edit_runs_the_editor_on_the_selected_files_only() {
	fm_load
	print -l '#!/bin/sh' "printf '%s\n' \"\$@\" > $sb/edited" > $sb/editor; chmod +x $sb/editor
	tui_start "FM__CMD_EDIT=$sb/editor"
	tui_wait_view DIR
	tui_send C-a
	tui_send C-e
	dialog_done '11 Edited Files'
	assert_lacks "$PWD/sub" "$(<$sb/edited)" 'dirs are skipped'
	assert_lacks "$PWD/link-dir" "$(<$sb/edited)" 'links to dirs too'
	assert_lacks "$PWD/broken-link" "$(<$sb/edited)" 'broken links too'
	assert_contains "$PWD/link-file" "$(<$sb/edited)" 'links to files are edited'
	assert_contains "$PWD/file one.txt" "$(<$sb/edited)"
	tui_send C-q
	tui_exit
}

test_sudo_is_used_for_protected_items() {
	# only in the try-fm container: its user has sudo with the password fm
	[[ $TRY_FM && -n $SUDO_PROMPT ]] || skip 'needs the try-fm container'
	fm_load
	tui_start "FM__CMD_SUDO='sudo -p PASSWORD?'"
	tui_wait_view DIR
	tui_send M-/
	tui_wait_view DIR /
	tui_send C-M-d
	tui_wait 'Enter a name for the new Dir>'
	tui_type fm-sudo-test
	tui_send Enter
	tui_wait 'PASSWORD?'
	tui_type fm
	tui_send Enter
	dialog_done '1 Dir created' DIR /
	assert_dir /fm-sudo-test
	assert_eq root "$(stat -c %U /fm-sudo-test)"
	fs_action fm-sudo-test C-M-r
	tui_wait 'Remove fm-sudo-test? (y/n)>'
	tui_send y
	dialog_done '1 Items removed' DIR /
	assert_missing /fm-sudo-test
	tui_send C-q
	tui_exit
}
