#!/usr/bin/env zsh

# Copyright (c) 2021-2026 Domizio Demichelis
# Released under GNU3 license
# https://www.gnu.org/licenses/gpl-3.0.en.html


# The zsh widget, driven in tmux in an interactive zsh (see tui_zsh in tests/lib)

widget() { tui_send M-f M-f }

test_widget_picks_the_selected_item_relative_to_the_prompt_dir() {
	fm_load
	tui_zsh
	tui_type 'vim '
	widget
	tui_wait_view DIR
	tui_query 'README !link' 1
	tui_send C-k
	tui_wait_gone ' DIR '
	assert_eq 'vim README.md ' "$(tui_buffer)"
}

test_widget_starts_from_the_word_at_the_cursor() {
	fm_load
	tui_zsh
	tui_type 'vim sub/a'
	widget
	tui_wait " DIR $sb/fx/sub a " 5 'the rest of the word is the query'
	tui_send C-k
	tui_wait_gone ' DIR '
	assert_eq 'vim sub/a.md ' "$(tui_buffer)"
}

test_widget_picks_a_dir_with_a_trailing_slash_and_no_space() {
	fm_load
	tui_zsh
	tui_type 'cd '
	widget
	tui_wait_view DIR
	tui_query 'sub !link' 1
	tui_send C-k
	tui_wait_gone ' DIR '
	assert_eq 'cd sub/' "$(tui_buffer)"
}

test_widget_picks_the_working_dir() {
	fm_load
	tui_zsh
	tui_type 'ls '
	widget
	tui_wait_view DIR
	tui_send C-d
	tui_wait_gone ' DIR '
	assert_eq 'ls . ' "$(tui_buffer)"
	tui_type 'ls '
	widget
	tui_wait_view DIR
	tui_query 'sub !link' 1
	tui_send Enter
	tui_wait_view DIR $sb/fx/sub
	tui_send C-d
	tui_wait_gone ' DIR '
	assert_eq 'ls sub/' "$(tui_buffer)"
}

test_widget_abbreviates_with_the_named_dirs() {
	fm_load
	tui_zsh
	tui_type 'ls '
	widget
	tui_wait_view DIR
	tui_send M-h
	tui_wait_view DIR '~'
	tui_send C-d
	tui_wait_gone ' DIR '
	assert_eq 'ls ~/' "$(tui_buffer)"
	tui_type 'ls '
	widget
	tui_wait_view DIR
	tui_send M-p
	tui_wait_view DIR $sb
	tui_send C-d
	tui_wait_gone ' DIR '
	assert_eq "ls $sb/" "$(tui_buffer)" 'outside the prompt dir and not under a named dir: absolute'
}

test_widget_quotes_the_picked_paths() {
	fm_load
	tui_zsh
	tui_type 'cat '
	widget
	tui_wait_view DIR
	tui_query 'file one' 1
	tui_send C-k
	tui_wait_gone ' DIR '
	assert_eq 'cat file\ one.txt ' "$(tui_buffer)"
}

test_widget_picks_several_items() {
	fm_load
	tui_zsh
	tui_type 'cp '
	widget
	tui_wait_view DIR
	tui_query notes 1
	tui_send Tab
	tui_query 'README !link' 1
	tui_send Tab
	tui_send C-k
	tui_wait_gone ' DIR '
	assert_eq 'cp notes.txt README.md ' "$(tui_buffer)"
}

test_widget_esc_leaves_the_line_untouched() {
	fm_load
	tui_zsh
	tui_type 'vim abc'
	widget
	tui_wait_view DIR
	tui_send Escape
	tui_wait_gone ' DIR '
	assert_eq 'vim abc' "$(tui_buffer)"
}

test_widget_starts_in_a_named_dir_and_in_an_absolute_dir() {
	fm_load
	print -r -- "hash -d fxsub=$sb/fx/sub" > $FM__DATA/favorites
	tui_zsh "source $FM__DATA/favorites"
	tui_type 'vim ~fxsub/'
	widget
	tui_wait_view DIR '~fxsub'
	tui_query a.md 1
	tui_send C-k
	tui_wait_gone ' DIR '
	assert_eq 'vim sub/a.md ' "$(tui_buffer)" 'the relative path is shorter than ~fxsub/a.md'
	tui_type "vim $sb/fx/sub/deep/"
	widget
	tui_wait_view DIR '~fxsub/deep'
	tui_send C-k
	tui_wait_gone ' DIR '
	assert_eq 'vim sub/deep/b.md ' "$(tui_buffer)"
}

test_widget_prefers_the_abbreviated_path_when_shorter() {
	fm_load
	print -r -- "hash -d d=$sb/fx/sub/deep" > $FM__DATA/favorites
	tui_zsh "source $FM__DATA/favorites"
	tui_type 'vim '
	widget
	tui_wait_view DIR
	tui_send M-f
	tui_wait_view FIND
	tui_query b.md 1
	tui_send C-k
	tui_wait_gone ' FIND '
	assert_eq 'vim ~d/b.md ' "$(tui_buffer)"
}

test_widget_views_and_navigation() {
	fm_load
	tui_zsh
	tui_type 'vim '
	widget
	tui_wait_view DIR
	tui_send M-f
	tui_wait_view FIND
	tui_query hello
	tui_send M-g
	tui_wait_view GREP
	tui_wait 'Matching files for: hello'
	tui_query a.md 1
	tui_send C-k
	tui_wait_gone ' GREP '
	assert_eq 'vim sub/a.md ' "$(tui_buffer)"
}

test_widget_menu_shows_only_the_widget_rows() {
	fm_load
	tui_zsh
	widget
	tui_wait_view DIR
	tui_send C-Space
	tui_wait 'Pick a menu or press a shortcut'
	tui_query Pick 2
	assert_contains 'Pick Selected Items' "$(tui_screen)"
	assert_contains 'Pick Working Dir' "$(tui_screen)"
	tui_query 'Add Working Dir' 1
	tui_query 'Copy Selected' 0
	tui_query 'Edit Selected' 0
	tui_send Escape
	tui_wait_gone 'Pick a menu'
	tui_send Escape
	tui_wait_gone ' DIR '
}

test_widget_adds_favorites_with_the_automatic_name() {
	fm_load
	tui_zsh
	widget
	tui_wait_view DIR
	tui_send C-M-w
	tui_wait '1 Favorites added'
	tui_wait_view FAV '~fx'
	tui_send Escape
	tui_wait_gone ' FAV '
	assert_eq "hash -d fx=$sb/fx" "$(<$FM__DATA/favorites)"
	tui_type "print -r -- ~fx > $sb/expanded"
	tui_send Enter
	local -P i; for ((i=0; i<40; i++)); do [[ -s $sb/expanded ]] && break; sleep 0.05; done
	assert_eq $sb/fx "$(<$sb/expanded)" 'the named dir is available in the shell right away'
}

test_widget_does_not_leave_the_shell_in_another_dir() {
	fm_load
	tui_zsh
	widget
	tui_wait_view DIR
	tui_send M-p
	tui_wait_view DIR $sb
	tui_send Escape
	tui_wait_gone ' DIR '
	tui_type "print -r -- \$PWD > $sb/pwd"
	tui_send Enter
	sleep 0.3
	assert_eq $sb/fx "$(<$sb/pwd)"
}
