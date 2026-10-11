#!/usr/bin/env zsh

# Copyright (c) 2021-2026 Domizio Demichelis
# Released under GNU3 license
# https://www.gnu.org/licenses/gpl-3.0.en.html


# fm__view-*: what each view pipes into fzf

# FM sorts with `LC_ALL=C sort -fbi`: case folded, and the non-ASCII bytes are "nonprinting" in the C locale,
# so they are ignored (ünïcödé.txt sorts as ncd.txt). The ASCII lines must be in case-insensitive order.
assert_sorted() {
	local -a ascii=( ${lines:#*[^ -~]*} )
	assert_eq "${(F)${(@oi)ascii}}" "${(F)ascii}" 'lines sorted'
}

# DIR

test_view_dir_with_eza() {
	type eza &>/dev/null || skip 'eza not installed'
	fm_load
	eval $panel_state
	view_lines
	assert_eq 16 $#lines
	assert_contains 'dir one' "${(F)lines}"
	assert_lacks '.hidden' "${(F)lines}"
	hidden=true
	view_lines
	assert_eq 18 $#lines 'hidden entries shown'
	assert_contains '.hidden-dir' "${(F)lines}"
	assert_eq '' "${(M)lines:#*[[:space:]].}" 'no . and .. entries'
}

test_view_dir_with_ls_drops_the_total_line() {
	fm_load FM__CMD_LS='ls -l'
	eval $panel_state
	view_lines
	assert_eq 16 $#lines
	assert_match '[-dl]*' "$lines[1]" 'the first line is an entry, not the total'
	hidden=true
	view_lines
	assert_eq 18 $#lines
	assert_eq '' "${(M)lines:#* ..}" 'no .. entry with -A'
}

test_view_dir_of_an_explicit_dir() {
	fm_load
	eval $panel_state
	lines=( "${(@f)$(fm__view-dir sub)}" )
	assert_eq 2 $#lines
	assert_contains 'a.md' "${(F)lines}"
}

test_view_dir_of_an_empty_dir() {
	fm_load
	eval $panel_state
	assert_eq '' "$(fm__view-dir empty)"
	cd empty
	assert_eq '' "$(fm__view-dir)"
}

test_view_dir_with_eza_and_no_tty_on_stdin() {
	# eza reads the paths from stdin when it gets none and stdin is not a tty (the widget case)
	type eza &>/dev/null || skip 'eza not installed'
	fm_load
	eval $panel_state
	assert_eq 16 $(fm__view-dir < /dev/null | wc -l)
	assert_eq 16 $(print nothing | fm__view-dir | wc -l)
}

# FIND

test_view_find_with_fd() {
	type fd &>/dev/null || skip 'fd not installed'
	fm_load
	eval $panel_state
	view=FIND
	view_lines
	assert_contains 'sub/deep/b.md' "${(F)lines}"
	assert_lacks '.hidden' "${(F)lines}"
	assert_lacks './' "${(F)lines}"
	hidden=true
	view_lines
	assert_contains '.hidden-dir/inside' "${(F)lines}"
}

test_view_find_with_find() {
	fm_load FM__CMD_FIND=find
	eval $panel_state
	view=FIND
	view_lines
	assert_contains 'sub/deep/b.md' "${(F)lines}"
	assert_lacks '.hidden' "${(F)lines}"
	assert_lacks './' "${(F)lines}"
	assert_eq '' "${(M)lines:#.}" 'no . entry'
	hidden=true
	view_lines
	assert_contains '.hidden-dir/inside' "${(F)lines}"
	assert_eq '' "${(M)lines:#.}" 'no . entry'
}

test_view_find_sorted() {
	fm_load
	eval $panel_state
	view=FIND sort=true
	view_lines
	assert_sorted
}

# GREP

test_set_grep_writes_the_matches_and_the_message() {
	fm_load
	eval $panel_state
	query=hello
	fm__set-grep
	local matches=$(plain "$(<$FM__TMP/matches)")
	assert_eq 4 $(wc -l <<< $matches)
	assert_contains 'README.md:1' "$matches"
	assert_contains 'notes.txt:2' "$matches"
	assert_eq '4 Matching files for: hello' "$rg_message"
}

test_set_grep_without_query_notifies_an_error() {
	fm_load
	eval $panel_state
	query=''
	assert_fail fm__set-grep
	assert_contains 'You must enter a query' "$header"
	assert_eq DIR "$view"
}

test_set_grep_with_no_match() {
	fm_load
	eval $panel_state
	query=nomatchatall
	fm__set-grep
	assert_eq GREP "$view"
	assert_eq '' "$(<$FM__TMP/matches)"
	assert_match '0 Matching files for: nomatchatall*' "$rg_message"
}

test_set_grep_limits_the_matching_files() {
	fm_load FM__MAX_GREP_FILES=2
	eval $panel_state
	query=hello
	fm__set-grep
	assert_eq 2 $(wc -l < $FM__TMP/matches)
	assert_match '2+ Matching files for: hello*limit exceeded*' "$rg_message"
}

test_set_grep_with_regex_and_options_in_the_query() {
	fm_load
	eval $panel_state
	query='-i HELLO.AGAIN'
	fm__set-grep
	assert_eq 'notes.txt:1' "$(plain "$(<$FM__TMP/matches)")"
}

test_set_grep_without_ripgrep_notifies() {
	fm_load
	eval $panel_state
	FM__CMD_RIPGREP=''
	query=hello
	fm__set-grep
	assert_contains 'No FM__CMD_RIPGREP' "$header"
	assert_eq DIR "$view"
}

test_view_grep_prints_the_matches_sorted_on_request() {
	fm_load
	eval $panel_state
	query=hello
	fm__set-grep
	view_lines
	assert_eq 4 $#lines
	sort=true
	view_lines
	assert_sorted
}

# REC

read_recent_dirs() { recent_dirs=(); fm__read -data recent_dirs }

test_view_rec_skips_the_current_dir_and_prunes_the_deleted_ones() {
	fm_load
	eval $panel_state
	recent_dirs=( $PWD $PWD/sub $PWD/nonexistent $HOME )
	fm__write -data recent_dirs
	view=REC
	view_lines
	assert_eq "$PWD/sub"$'\n'"$HOME" "${(F)lines}"
	read_recent_dirs
	assert_eq "$PWD $PWD/sub $HOME" "$recent_dirs" 'pruned in the data file'
}

test_view_rec_prunes_to_the_max() {
	fm_load FM__MAX_RECENT_DIRS=2
	eval $panel_state
	recent_dirs=( $PWD $PWD/sub $HOME )
	fm__write -data recent_dirs
	view=REC
	view_lines
	assert_eq "$PWD/sub" "${(F)lines}"
	read_recent_dirs
	assert_eq "$PWD $PWD/sub" "$recent_dirs"
}

test_view_rec_sorted() {
	fm_load
	eval $panel_state
	recent_dirs=( $PWD $PWD/sub $PWD/empty $HOME )
	fm__write -data recent_dirs
	view=REC sort=true
	view_lines
	assert_eq 3 $#lines
	assert_sorted
}

# FAV

add_favs() { # name=path ...
	local f
	for f; print -r -- "hash -d ${f%%=*}=${(q)${f#*=}}" >> $FM__DATA/favorites
	source $FM__DATA/favorites
}
fav_names() { print -r -- ${${(z)${(F)lines}}[2]} }

test_view_fav_lists_the_favorites_with_line_numbers_and_aligned_names() {
	fm_load
	eval $panel_state
	add_favs "d1=$PWD/dir one" "readme=$PWD/README.md"
	view=FAV
	lines=( "${(@f)$(fm__view-fav)}" ) # raw: the colors matter here
	assert_eq "1  d1      $PWD/dir one" "$(plain "$lines[1]")"
	assert_eq "2  readme  $PWD/README.md" "$(plain "$lines[2]")"
	assert_match $'\e\\[34m*' "$lines[1]" 'dirs are blue'
	assert_eq "$(plain "$lines[2]")" "$lines[2]" 'files are plain'
}

test_view_fav_removes_the_broken_favorites() {
	fm_load
	eval $panel_state
	add_favs "d1=$PWD/dir one" "gone=$PWD/nonexistent" "readme=$PWD/README.md"
	view=FAV
	view_lines
	assert_eq 2 $#lines
	assert_eq 2 $(wc -l < $FM__DATA/favorites)
	assert_lacks gone "$(<$FM__DATA/favorites)"
	assert_eq "$PWD/dir one" ~d1
}

test_view_fav_sorted_by_path() {
	fm_load
	eval $panel_state
	add_favs "zeta=$PWD/empty" "alpha=$PWD/sub" "readme=$PWD/README.md"
	view=FAV sort=true
	view_lines
	local l names=() nums=()
	for l in $lines; do names+=${${(z)l}[2]}; nums+=${${(z)l}[1]}; done
	assert_eq 'zeta readme alpha' "$names" 'sorted by path, case folded (empty < README.md < sub)'
	assert_eq '1 3 2' "$nums" 'the line numbers follow the entries'
}

test_view_fav_with_no_favorites() {
	fm_load
	eval $panel_state
	view=FAV
	assert_eq '' "$(fm__view-fav)"
}
