#!/usr/bin/env zsh

# Copyright (c) 2021-2026 Domizio Demichelis
# Released under GNU3 license
# https://www.gnu.org/licenses/gpl-3.0.en.html


# The favorites, driven in tmux

fav_file() { print -r -- "$(<$FM__DATA/favorites)" }

test_add_the_working_dir_as_favorite() {
	fm_load
	tui_start
	tui_wait_view DIR
	tui_send C-M-w
	tui_wait 'Add Selected Favorites'
	tui_wait 'Confirm the Favorite name (empty to skip)> fx'
	tui_send Enter
	tui_wait 'Added!'
	tui_wait '1 Favorites added'
	tui_wait_view FAV '~fx' 'the FAV view is shown, the prompt uses the new named dir'
	assert_contains "fx  $sb/fx" "$(tui_screen)"
	assert_eq "hash -d fx=$sb/fx" "$(fav_file)"
	tui_send C-q
	tui_exit
}

test_add_selected_items_with_a_space_in_the_name() {
	fm_load
	tui_start
	tui_wait_view DIR
	tui_query 'dir one' 1
	tui_send C-M-s
	tui_wait 'Confirm the Favorite name (empty to skip)> dir_one'
	tui_send Enter
	dialog_done '1 Favorites added' FAV
	assert_contains "dir_one  $sb/fx/dir one" "$(tui_screen)"
	assert_eq "hash -d dir_one=$sb/fx/dir\\ one" "$(fav_file)"
	tui_send Enter
	tui_wait_view DIR '~dir_one' 'enter on a favorite dir jumps to it'
	tui_send C-q
	tui_exit
}

test_add_a_favorite_with_an_edited_name() {
	fm_load
	tui_start
	tui_wait_view DIR
	tui_query 'README !link' 1
	tui_send C-M-s
	tui_wait 'Confirm the Favorite name (empty to skip)> README.md'
	tui_send C-u
	tui_type readme
	tui_send Enter
	dialog_done '1 Favorites added' FAV
	assert_eq "hash -d readme=$sb/fx/README.md" "$(fav_file)"
	tui_send C-q
	tui_exit
}

test_add_a_favorite_whose_name_is_taken_gets_a_suffix() {
	fm_load
	print -r -- "hash -d sub=$sb/fx/empty" > $FM__DATA/favorites
	tui_start
	tui_wait_view DIR
	tui_query 'sub !link' 1
	tui_send C-M-s
	tui_wait 'Confirm the Favorite name (empty to skip)> sub-fav2'
	tui_send Enter
	dialog_done '1 Favorites added' FAV
	assert_contains "hash -d sub-fav2=$sb/fx/sub" "$(fav_file)"
	tui_send C-q
	tui_exit
}

test_add_a_favorite_with_an_invalid_name_asks_for_a_valid_one() {
	fm_load
	touch 123
	tui_start
	tui_wait_view DIR
	tui_query 123 1
	tui_send C-M-s
	tui_wait 'The Favorite name must be alpha-numeric starting with [A-Za-z]!'
	tui_wait 'Type a valid name (empty to skip)>'
	tui_type numbers
	tui_send Enter
	dialog_done '1 Favorites added' FAV
	assert_eq "hash -d numbers=$sb/fx/123" "$(fav_file)"
	tui_send C-q
	tui_exit
}

test_skip_adding_a_favorite() {
	fm_load
	tui_start
	tui_wait_view DIR
	tui_send C-M-w
	tui_wait 'Confirm the Favorite name (empty to skip)> fx'
	tui_send C-u
	tui_send Enter
	tui_wait 'Skipped!'
	dialog_done '0 Favorites added' DIR
	assert_eq '' "$(fav_file)"
	tui_send C-q
	tui_exit
}

test_rename_a_favorite() {
	fm_load
	print -r -- "hash -d s=$sb/fx/sub" > $FM__DATA/favorites
	tui_start
	tui_wait_view DIR
	tui_send M-v
	tui_wait_view FAV
	tui_send C-M-n
	tui_wait 'Enter the new name for the Favorite s (empty to skip)> s'
	tui_send C-u
	tui_type subdir
	tui_send Enter
	tui_wait 'Confirm the Favorite name (empty to skip)> subdir'
	tui_send Enter
	dialog_done '1 Favorites renamed' FAV
	assert_contains "subdir  $sb/fx/sub" "$(tui_screen)"
	assert_eq "hash -d subdir=$sb/fx/sub" "$(fav_file)"
	tui_send C-q
	tui_exit
}

test_remove_favorites() {
	fm_load
	print -l -- "hash -d e=$sb/fx/empty" "hash -d s=$sb/fx/sub" "hash -d readme=$sb/fx/README.md" > $FM__DATA/favorites
	tui_start
	tui_wait_view DIR
	tui_send M-v
	tui_wait_view FAV
	tui_send C-a
	tui_send C-M-r
	tui_wait 'Remove Favorite e? (y/n)>'
	tui_send n
	tui_wait 'Remove Favorite s? (y/n)>'
	tui_send y
	tui_wait 'Remove Favorite readme? (y/n)>'
	tui_send y
	dialog_done '2 Favorites removed' FAV
	assert_eq "hash -d e=$sb/fx/empty" "$(fav_file)"
	tui_wait_view FAV
	assert_lacks 'readme' "$(tui_screen)"
	tui_send C-q
	tui_exit
}

test_broken_favorites_disappear_from_the_view_and_the_file() {
	fm_load
	print -l -- "hash -d s=$sb/fx/sub" "hash -d gone=$sb/nonexistent" > $FM__DATA/favorites
	tui_start
	tui_wait_view DIR
	tui_send M-v
	tui_wait_view FAV
	assert_lacks 'gone' "$(tui_screen)"
	assert_eq "hash -d s=$sb/fx/sub" "$(fav_file)"
	tui_send C-q
	tui_exit
}
