#!/usr/bin/env zsh

# Copyright (c) 2021-2026 Domizio Demichelis
# Released under GNU3 license
# https://www.gnu.org/licenses/gpl-3.0.en.html


# fm__cat and the preview scripts (run by fzf as separate processes)

panel_preview() { FZF_PREVIEW_COLUMNS=80 FZF_PREVIEW_LINES=30 $fm__root/preview/panel "$@" }
menu_preview()  { FZF_PREVIEW_COLUMNS=80 FZF_PREVIEW_LINES=30 $fm__root/preview/menu "$@" }

test_cat_a_text_file() {
	fm_load FM__CMD_CAT='cat -n'
	assert_eq $'     1\t# Title\n     2\thello world\n     3\tsecond line' "$(fm__cat README.md)"
}

test_cat_a_binary_file_prints_a_notice_and_the_stat() {
	fm_load
	local out=$(fm__cat binary.bin)
	assert_contains '> Binary content <' "$out"
	assert_contains 'binary.bin' "$out" 'stat output'
}

test_cat_a_broken_link_prints_nothing() {
	fm_load
	assert_eq '' "$(fm__cat broken-link)"
}

test_cat_a_link_follows_it() {
	fm_load FM__CMD_CAT=cat
	assert_eq "$(<README.md)" "$(fm__cat link-file)"
}

test_cat_an_empty_file() {
	fm_load FM__CMD_CAT=cat
	touch empty.txt
	assert_eq '' "$(fm__cat empty.txt)"
}

test_cat_an_archive_lists_its_content() {
	fm_load FM__CMD_CAT=cat
	assert_contains 'sub/a.md' "$(fm__cat archive.tar)"
	type zip &>/dev/null || return 0
	zip -q archive.zip sub/a.md
	assert_contains 'sub/a.md' "$(fm__cat archive.zip)"
}

test_cat_with_bat() {
	type bat &>/dev/null || skip 'bat not installed'
	fm_load
	assert_match 'bat*' "$FM__CMD_CAT"
	assert_contains 'hello world' "$(plain "$(fm__cat README.md)")"
}

# preview/panel

test_panel_preview_of_a_dir_line_lists_the_dir() {
	fm_load
	eval $panel_state
	view_lines
	local out=$(panel_preview "$(line_of sub)" DIR false)
	assert_contains 'sub: directory' "$out"
	assert_contains 'a.md' "$out"
	assert_contains 'deep' "$out"
}

test_panel_preview_of_a_file_line_shows_its_content() {
	fm_load FM__CMD_CAT='cat -n'
	eval $panel_state
	view_lines
	local out=$(panel_preview "$(line_of README.md)" DIR false)
	assert_contains 'README.md: ' "$out"
	assert_contains 'hello world' "$out"
}

test_panel_preview_in_find_and_rec_views() {
	fm_load FM__CMD_CAT='cat'
	eval $panel_state
	assert_contains 'hello from a' "$(panel_preview sub/a.md FIND false)"
	assert_contains 'nested.txt' "$(panel_preview "$PWD/dir one" REC false)"
}

test_panel_preview_in_grep_view_shows_the_matches_with_context() {
	fm_load
	eval $panel_state
	local out=$(plain "$(panel_preview notes.txt:2 GREP false hello)")
	assert_contains 'TODO: hello again' "$out"
	assert_contains 'bye' "$out" 'context line'
	out=$(plain "$(panel_preview .hidden:1 GREP true hidden)")
	assert_contains 'hidden' "$out"
}

test_panel_preview_of_a_broken_link_shows_only_the_file_type() {
	fm_load
	eval $panel_state
	local out=$(plain "$(panel_preview broken-link FIND false)")
	assert_contains 'broken-link: broken symbolic link' "$out"
	assert_eq 1 $(print -r -- $out | wc -l)
}

test_panel_preview_without_item() {
	fm_load
	eval $panel_state
	assert_contains 'No item to display' "$(panel_preview 'total 0' DIR false)"
	assert_contains 'No item to display' "$(panel_preview '' DIR false)"
}

# preview/menu: the usage notes

menu_rows() { grep -E '^\s+[cw-]{2}\s+\w+\s+\S+' $fm__root/autoload/panel/fm__menu | awk '{ $1=""; $2=""; print }' | sed 's/^ *//' }

test_menu_preview_has_a_note_for_every_row() {
	fm_load
	local row id out missing=()
	menu_rows | while read id row; do
		out=$(menu_preview "$id  $row  key" 2>&1)
		[[ $? -eq 0 && $out == *${row//_/}* ]] || missing+="$id: $out"
		if [[ $id != -* ]] [[ $out == *FM__KEY_$id* ]] || missing+="$id: no key variable in the note"
	done
	assert_eq '' "${(F)missing}"
}

test_menu_preview_of_an_added_tool_shows_its_usage() {
	fm_load
	source $fm__root/added-tools-examples
	local out=$(menu_preview "1  Show Variables Example  f6")
	assert_contains 'Show Variables Example' "$out"
	assert_contains 'internal variables' "$out"
	out=$(menu_preview "3  Will Fail Command Example  ")
	assert_contains 'Will Fail Command Example' "$out"
}

test_menu_preview_mentions_the_try_fm_caveats_only_in_the_demo() {
	fm_load
	assert_lacks 'TRY-FM' "$(TRY_FM= menu_preview 'OPEN  Open Selected Items  ctrl-o')"
	assert_contains 'TRY-FM' "$(TRY_FM=true menu_preview 'OPEN  Open Selected Items  ctrl-o')"
}
