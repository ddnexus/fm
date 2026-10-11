#!/usr/bin/env zsh

# Copyright (c) 2021-2026 Domizio Demichelis
# Released under GNU3 license
# https://www.gnu.org/licenses/gpl-3.0.en.html


# fm__set-items: from the lines selected in fzf to absolute paths, one parser per view.
# The DIR lines are fed raw (with colors and icons) as the hardest case.

# every visible fixture entry, as absolute paths, in the order used by the assertions
visible_entries=( 'arrow -> name' archive.tar binary.bin broken-link 'dir one' empty 'file one.txt' 'link -> weird' link-dir link-file notes.txt README.md script.sh 'spaces  two.txt' sub 'ünïcödé.txt' )
hidden_entries=( .hidden .hidden-dir )

sorted_items() { print -l -- ${(o)items} }
expected_paths() { local e; for e in ${(o)@}; print -r -- $PWD/$e }

check_dir_parsing() { # [FM__CMD_LS=...]
	fm_load "$@"
	eval $panel_state
	view_lines
	assert_eq $#visible_entries $#lines 'number of DIR lines'
	fm__set-items
	assert_eq "$(expected_paths $visible_entries)" "$(sorted_items)" 'DIR items (hidden off)'
	hidden=true items=()
	view_lines
	fm__set-items
	assert_eq "$(expected_paths $visible_entries $hidden_entries)" "$(sorted_items)" 'DIR items (hidden on)'
}

test_dir_items_with_eza() {
	type eza &>/dev/null || skip 'eza not installed'
	check_dir_parsing
	assert_match 'eza*' $FM__CMD_LS 'eza is the default listing'
}

test_dir_items_with_gnu_ls() {
	ls --color --group-directories-first -d / &>/dev/null || skip 'GNU ls not installed'
	check_dir_parsing FM__CMD_LS='ls -lh --color --group-directories-first'
}

test_dir_items_with_plain_ls() {
	check_dir_parsing FM__CMD_LS='ls -l'
}

test_dir_items_keep_the_link_not_its_target() {
	fm_load
	eval $panel_state
	view_lines
	lines=( ${(M)lines:#*link-file*} )
	fm__set-items
	assert_eq $PWD/link-file $items[1]
}

test_dir_items_of_an_explicit_dir_are_relative_to_pwd() {
	# the preview script lists a selected dir: the lines are the dir's content but the paths resolve from $PWD
	fm_load
	eval $panel_state
	lines=( "${(@f)$(fm__view-dir sub)}" )
	fm__set-items
	assert_eq '' "$items" 'entries of a subdir cannot be resolved from the parent'
}

test_dir_items_with_a_line_that_is_not_a_path() {
	fm_load
	eval $panel_state
	lines=( 'total 12' 'drwxr-xr-x 2 dd dd 40 Oct 11 09:27 nonexistent' )
	fm__set-items
	assert_eq '' "$items"
}

test_dir_items_strip_ansi_colors() {
	fm_load
	eval $panel_state
	lines=( $'\e[0m\e[01;34mdir one\e[0m' $'-rw-r--r-- 1 dd dd 0 Oct 11 09:27 \e[01;32mscript.sh\e[0m' )
	fm__set-items
	assert_eq "$PWD/dir one"$'\n'"$PWD/script.sh" "${(F)items}"
}

test_find_items() {
	fm_load
	eval $panel_state
	view=FIND
	view_lines
	fm__set-items
	assert_contains $PWD/sub/a.md "${(F)items}"
	assert_contains "$PWD/dir one/nested.txt" "${(F)items}"
	assert_contains $PWD/sub "${(F)items}" 'dirs (fd prints them with a trailing /)'
	assert_eq '' "${(M)items:#*/}" 'no trailing slash in the items'
	assert_lacks .hidden "${(F)items}"
	assert_eq $#lines $#items 'one item per line'
}

test_grep_items() {
	fm_load
	eval $panel_state
	query=hello
	fm__set-grep
	assert_eq GREP "$view"
	assert_eq hello $rg_query
	assert_eq '' "$query" 'the fzf query is reset'
	view_lines
	assert_match '*:*' $lines[1] 'rg -c lines are path:count'
	fm__set-items
	assert_eq "$(expected_paths README.md notes.txt 'dir one/nested.txt' sub/a.md)" "$(sorted_items)"
}

test_fav_items() {
	fm_load
	eval $panel_state
	view=FAV
	lines=( "1  home     $HOME" "2  dir-one  $PWD/dir one" )
	fm__set-items
	assert_eq "$HOME"$'\n'"$PWD/dir one" "${(F)items}"
}

test_rec_items() {
	fm_load
	eval $panel_state
	view=REC
	lines=( $HOME "$PWD/dir one" )
	fm__set-items
	assert_eq "$HOME"$'\n'"$PWD/dir one" "${(F)items}"
}

# fm__reduce-items: drop the children of selected dirs

test_reduce_items_drops_the_children_of_a_selected_dir() {
	fm_load
	local items=( $PWD/sub $PWD/sub/a.md $PWD/sub/deep/b.md $PWD/README.md $PWD/subway )
	fm__reduce-items
	assert_eq "$PWD/sub $PWD/README.md $PWD/subway" "$items"
}

# fm__dest-name: the name of a pasted/linked item that must not override an existing one

check_dest_name() { # name expected [source]
	local name=$1 source=${3:-$PWD/$1}
	fm__dest-name pasted
	assert_eq $2 $name "dest name for $1"
}

test_dest_name_is_the_name_when_free() {
	fm_load
	check_dest_name new.txt new.txt
}

test_dest_name_adds_a_suffix_before_the_extension() {
	fm_load
	check_dest_name README.md 'README(pasted).md'
}

test_dest_name_counts_up_when_the_suffixed_name_exists_too() {
	fm_load
	touch 'README(pasted).md'
	check_dest_name README.md 'README(pasted-2).md'
	touch 'README(pasted-2).md'
	check_dest_name README.md 'README(pasted-3).md'
}

test_dest_name_treats_dotfiles_and_dirs_as_a_whole() {
	fm_load
	check_dest_name .hidden '.hidden(pasted)'
	check_dest_name sub 'sub(pasted)'
	check_dest_name script.sh 'script(pasted).sh'
	check_dest_name 'dir one' 'dir one(pasted)'
}

test_dest_name_of_a_dir_source_keeps_the_dots() {
	fm_load
	mkdir dir.v2
	check_dest_name dir.v2 'dir.v2(pasted)' $PWD/dir.v2
}

# fm__sort-items / fm__toggle-hidden / fm__cd / fm__notify

test_sort_items_sets_the_flag_for_the_next_view_only() {
	fm_load
	eval $panel_state
	fm__sort-items
	assert_eq true $sort
	assert_contains 'sorted by path' "$header"
}

test_toggle_hidden_switches_and_notifies() {
	fm_load
	eval $panel_state
	fm__toggle-hidden
	assert_eq true $hidden
	assert_contains 'Hidden Visibility ON' "$header"
	fm__toggle-hidden
	assert_eq false $hidden
	assert_contains 'OFF' "$header[2]"
}

test_toggle_hidden_in_grep_view_runs_the_grep_again() {
	fm_load
	eval $panel_state
	query=hidden
	fm__set-grep
	fm__set-items
	assert_eq 0 $(wc -l < $FM__TMP/matches) 'hidden files are not grepped'
	fm__toggle-hidden
	assert_eq GREP "$view"
	assert_eq hidden "$rg_query"
	assert_eq 2 $(wc -l < $FM__TMP/matches) 'hidden files are grepped now'
}

test_cd_changes_dir_and_tracks_the_recent_dirs() {
	fm_load
	eval $panel_state
	recent_dirs=( $PWD $HOME )
	query=abc view=REC fs_view=FIND
	fm__cd sub
	assert_eq $sb/fx/sub $PWD
	assert_eq '' "$query" 'the query is reset'
	assert_eq FIND "$view" 'back to the fs view'
	assert_eq "$sb/fx/sub $sb/fx $HOME" "$recent_dirs"
	recent_dirs=()
	fm__read -data recent_dirs
	assert_eq "$sb/fx/sub $sb/fx $HOME" "$recent_dirs" 'persisted'
}

test_notify_appends_a_colored_header_line() {
	fm_load
	eval $panel_state
	fm__notify 'first'
	fm__notify 'second' 'word'
	assert_eq 2 $#header
	assert_match $'\e\\[35mfirst\e\\[39m' $header[1]
	assert_contains 'second word' $header[2]
}

# fm__select / fm__mark: the clipboard and the targets

test_select_writes_the_clipboard() {
	fm_load
	eval $panel_state
	items=( $PWD/sub $PWD/sub/a.md $PWD/README.md )
	fm__select copied
	assert_eq copied $clipboard[mode]
	assert_eq "$PWD/sub"$'\n'"$PWD/README.md" $clipboard[sources] 'reduced sources, one per line'
	assert_contains '2 Items copied' "$header"
	local -A clipboard=()
	fm__read -tmp clipboard
	assert_eq copied $clipboard[mode] 'persisted'
}

test_mark_writes_the_targets() {
	fm_load
	eval $panel_state
	items=( $PWD/sub $PWD/sub/a.md )
	fm__mark
	assert_eq "$PWD/sub" "$targets"
	assert_contains '1 Targets marked' "$header"
	targets=()
	fm__read -tmp targets
	assert_eq "$PWD/sub" "$targets" 'persisted'
}

# fm__cycle-preview, fm__get-cmd, fm__prompt, fm__print-recap

test_cycle_preview_wraps_around_the_modes() {
	fm_load
	eval $panel_state
	assert_eq 1 $preview[command-panel]
	fm__cycle-preview command-panel
	assert_eq 2 $preview[command-panel]
	fm__cycle-preview command-panel
	fm__cycle-preview command-panel
	assert_eq 1 $preview[command-panel] 'back to 1 after the last mode'
	assert_eq 1 $preview[widget-panel] 'other modes untouched'
	local -A preview=()
	fm__read -data preview
	assert_eq 1 $preview[command-panel] 'persisted'
}

test_get_cmd_returns_the_first_available_command() {
	fm_load
	assert_eq 'ls -l' "$(fm__get-cmd 'nonexistent-cmd --opt' 'ls -l' cat)"
	assert_fail fm__get-cmd nonexistent-cmd
}

test_prompt_shows_the_view_and_the_abbreviated_dir() {
	fm_load
	eval $panel_state
	view=FIND
	cd $HOME
	assert_contains ' FIND ' "$(plain "$(fm__prompt)")"
	assert_contains '~ ' "$(plain "$(fm__prompt)")"
}

test_print_recap_limits() {
	fm_load
	local -a list=( a b c d e )
	assert_eq '' "$(fm__print-recap -green list 0)" 'limit 0 prints nothing'
	assert_contains '5 Selected Elements in Total' "$(fm__print-recap -green list 1)"
	assert_eq 5 $(fm__print-recap -green list 5 | wc -l) 'limit = count prints all'
	assert_eq 3 $(fm__print-recap -green list 3 | wc -l) 'limit < count: limit-1 elements and the total line'
	assert_contains '...and 3 more, for a Total of 5' "$(fm__print-recap -green list 3)"
	assert_contains '1. a' "$(fm__print-recap -green list 3)"
}
