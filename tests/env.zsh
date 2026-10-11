#!/usr/bin/env zsh

# Copyright (c) 2021-2026 Domizio Demichelis
# Released under GNU3 license
# https://www.gnu.org/licenses/gpl-3.0.en.html


# fm.zsh loading, defaults, data files, the fm subcommands and the consistency of the wiring of the actions

keys_in_fm_zsh() { grep -oE 'FM__KEY_[A-Z_]+' $fm__root/fm.zsh | sort -u }

test_every_source_file_parses() {
	local f failed=()
	for f in $fm__root/fm.zsh $fm__root/fm__compile $fm__root/added-tools-examples $fm__root/tests/run $fm__root/tests/lib $fm__root/tests/*.zsh $fm__root/{autoload/**,preview}/^*.zwc(.); do
		zsh -n $f 2>/dev/null || failed+=$f
	done
	for f in $fm__root/launcher/fm.sh $fm__root/try-fm/try-fm; do
		sh -n $f 2>/dev/null || failed+=$f
	done
	assert_eq '' "${(F)failed}" 'files with syntax errors'
}

test_loading_sets_the_defaults_and_creates_the_data_files() {
	fm_load
	assert_eq ctrl-space "$FM__KEY_MENU"
	assert_eq 0.2.0 "$fm__version"
	assert_match 'eza*|ls*' "$FM__CMD_LS"
	assert_match 'rg*' "$FM__CMD_RIPGREP"
	local f
	for f in favorites recent_dirs preview; assert_file $FM__DATA/$f
	for f in added_menu clipboard matches targets; assert_file $FM__TMP/$f
	local -A preview
	fm__read -data preview
	assert_eq '1 1 1 1' "$preview[command-panel] $preview[command-menu] $preview[widget-panel] $preview[widget-menu]"
}

test_loading_leaves_the_shell_options_and_variables_alone() {
	local out=$(zsh -fc "source $fm__root/fm.zsh
		[[ -o extendedglob ]] && print 'EXTENDED_GLOB leaked'
		[[ -o shwordsplit ]] && print 'SH_WORD_SPLIT changed'
		setopt shwordsplit; source $fm__root/fm.zsh
		[[ -o shwordsplit ]] || print 'SH_WORD_SPLIT reset'
		(( \$+parameters[file] )) && print 'file is a global'
		(( \$+parameters[preview] )) && print 'preview is a global'
		print -r -- \"keys=\$#fm__command_keys modes=\$#FM__PREVIEW_MODES version=\$fm__version\"")
	assert_eq 'keys=36 modes=3 version=0.2.0' "$out"
}

test_loading_registers_the_functions_by_name_through_fpath() {
	fm_load
	local -a dirs=( ${(M)fpath:#$fm__root/autoload/*} )
	assert_eq 6 $#dirs 'the autoload/* dirs are in fpath'
	assert_eq $fm__root/autoload/cmd "$fpath[1]" 'first, so nothing shadows them' # (o) sorted glob: cmd fav fs panel ui view
	source $fm__root/fm.zsh
	dirs=( ${(M)fpath:#$fm__root/autoload/*} )
	assert_eq 6 $#dirs 'not duplicated by a second source'
	assert_eq 'fm__panel: function' "$(whence -w fm__panel)"
	local -a stubs=( ${(k)functions[(I)fm__*]} )
	assert_eq $(print -l $fm__root/autoload/**/*(.) | grep -vc '\.zwc$') $(( $#stubs + 1 )) 'one stub per function file (plus fm)'
	cp -r $fm__root $sb/copy && $sb/copy/fm__compile # a compiled copy: the .zwc files get no stubs
	assert_eq '' "$(zsh -fc "source $sb/copy/fm.zsh; functions -u | grep '\.zwc'")" 'no stubs for the compiled files'
}

test_an_optional_key_can_be_disabled() {
	fm_load FM__KEY_QUIT=''
	assert_eq '' "$FM__KEY_QUIT"
	assert_not_in ctrl-q fm__command_keys
	assert_not_in '' fm__command_keys 'no empty element in the keys'
}

test_an_essential_key_cannot_be_disabled() {
	fm_load FM__KEY_MENU='' FM__KEY_VIEW_ITEM='' FM__KEY_PREVIEW='' FM__KEY_SELECT_ALL=''
	assert_eq ctrl-space "$FM__KEY_MENU"
	assert_eq enter "$FM__KEY_VIEW_ITEM"
	assert_eq ctrl-p "$FM__KEY_PREVIEW"
	assert_eq ctrl-a "$FM__KEY_SELECT_ALL"
}

test_a_key_can_be_changed() {
	fm_load FM__KEY_COPY=f10 FM__KEY_PICK=f9
	assert_in f10 fm__command_keys
	assert_not_in ctrl-alt-c fm__command_keys
	assert_in f9 fm__widget_keys
	assert_not_in f10 fm__widget_keys 'COPY is not a widget key'
}

test_the_widget_keys_are_the_navigation_subset_plus_the_picks() {
	fm_load
	local k
	for k in ctrl-k ctrl-d alt-d alt-f alt-g alt-r alt-v alt-h ctrl-alt-s ctrl-alt-w; assert_in $k fm__widget_keys
	for k in ctrl-alt-c ctrl-alt-v ctrl-alt-r ctrl-e ctrl-o ctrl-n ctrl-t; assert_not_in $k fm__widget_keys "$k is not a widget key"
	assert_not_in ctrl-k fm__command_keys 'PICK is not a command key'
}

test_commands_can_be_overridden_and_disabled() {
	fm_load FM__CMD_CAT='cat -n' FM__CMD_TERMINAL='' FM__CMD_SUDO=''
	assert_eq 'cat -n' "$FM__CMD_CAT"
	assert_eq '' "$FM__CMD_TERMINAL"
	assert_eq '' "$FM__CMD_SUDO"
}

test_the_menu_width_has_a_minimum() {
	fm_load FM__MENU_WIDTH=10
	assert_eq 34 "$FM__MENU_WIDTH"
}

test_the_added_menu_is_truncated_on_load() {
	fm_load
	print 'stale' > $FM__TMP/added_menu
	source $fm__root/fm.zsh
	assert_eq '' "$(<$FM__TMP/added_menu)"
}

test_the_preview_script_variables_are_exported() {
	fm_load
	local v
	for v in fm__root FM__DATA FM__TMP FM__CMD_CAT FM__CMD_LS FM__CMD_RIPGREP FM__CMD_STAT FM__INFO_COLOR
		assert_eq "${(P)v}" "$(zsh -fc "print -r -- \$$v")" "$v is exported"
}

# the wiring of the actions: fm.zsh keys, fm__panel dispatch, fm__menu rows, preview/menu notes, fm env

test_every_key_is_dispatched_listed_in_the_menu_documented_and_in_env() {
	fm_load
	local key id missing=()
	for key in $(keys_in_fm_zsh); do
		id=${key#FM__KEY_}
		[[ $id == SELECT_ALL ]] && continue # an fzf bind, not an expect key
		grep -q "\$$key" $fm__root/autoload/panel/fm__panel || missing+="$id: key not used in fm__panel"
		grep -qE "(\||^\s*)$id(\||\))" $fm__root/autoload/panel/fm__panel || missing+="$id: menu id not dispatched in fm__panel"
		grep -qE "^\s+[cw-]{2}\s+\w+\s+$id\s" $fm__root/autoload/panel/fm__menu || missing+="$id: fm__menu row"
		grep -qE "^\s*$id\)" $fm__root/preview/menu || missing+="$id: preview/menu note"
		grep -q "^\s*$key$" $fm__root/autoload/cmd/fm__cmd-env || missing+="$id: fm env list"
	done
	assert_eq '' "${(F)missing}"
}

test_every_menu_row_has_a_key_variable_or_is_a_category() {
	fm_load
	local id missing=()
	for id in $(grep -oE '^\s+[cw-]{2}\s+\w+\s+\S+' $fm__root/autoload/panel/fm__menu | awk '{print $3}'); do
		[[ $id == -* ]] && continue
		[[ $(keys_in_fm_zsh) == *FM__KEY_$id* ]] || missing+=$id
	done
	assert_eq '' "${(F)missing}"
}

test_every_cmd_variable_is_in_env_and_help() {
	fm_load
	local var missing=()
	for var in $(grep -oE 'FM__(CMD|MAX)_[A-Z_]+' $fm__root/fm.zsh | sort -u); do
		grep -q "^\s*$var$" $fm__root/autoload/cmd/fm__cmd-env || missing+="$var: fm env"
		grep -q "^\s*$var " $fm__root/autoload/cmd/fm__cmd-help || missing+="$var: fm help"
	done
	assert_eq '' "${(F)missing}"
}

# fm subcommands

test_fm_env_prints_every_variable_with_its_value() {
	fm_load
	local out=$(fm env)
	assert_contains "FM__KEY_MENU          ctrl-space" "$out"
	assert_contains "FM__DATA              $FM__DATA" "$out"
	assert_contains "fm__root              $fm__root" "$out"
	assert_eq $(grep -c '^\s*FM__\|^\s*fm__' $fm__root/autoload/cmd/fm__cmd-env) $(print -r -- $out | wc -l)
}

test_fm_help_shows_the_usage_and_the_environment() {
	fm_load
	local out=$(fm help)
	assert_contains "FM $fm__version" "$out"
	assert_contains 'USAGE' "$out"
	assert_contains 'FM__CMD_LS ' "$out"
	assert_contains "FM__DATA              $FM__DATA" "$out" 'the env is included'
}

test_fm_unknown_command_fails_with_the_help() {
	fm_load
	local out
	out=$(fm bogus 2>$sb/err)
	assert_eq 1 $?
	assert_contains "Unknown fm command 'bogus'" "$(<$sb/err)"
	assert_contains 'USAGE' "$out"
}

test_fm_dash_jumps_back_to_the_start_dir() {
	fm_load
	fm__start_dir=$PWD
	cd sub
	fm -
	assert_eq $sb/fx "$PWD"
}

test_fm_compile_creates_a_zwc_for_every_function_file() {
	fm_load
	cp -r $fm__root $sb/copy
	rm -f $sb/copy/**/*.zwc(N)
	fm__root=$sb/copy fm compile
	local src=( $sb/copy/{autoload/**,preview}/^*.zwc(.) )
	local expected=( ${^src}.zwc )
	local zwc=( $sb/copy/{autoload/**,preview}/*.zwc(.N) )
	assert_eq "${(F)${(@o)expected}}" "${(F)${(@o)zwc}}"
	assert_contains 'FM__KEY_MENU' "$(zsh -fc "source $sb/copy/fm.zsh; fm env")" 'the compiled functions work'
}

test_fm_compile_compiles_its_own_copy_whatever_fm_root_says() {
	# a build hook may run in a shell that loaded another FM (fm__root is exported)
	fm_load
	cp -r $fm__root $sb/copy
	rm -f $sb/copy/**/*.zwc(N)
	fm__root=/elsewhere $sb/copy/fm__compile
	assert_file $sb/copy/autoload/panel/fm__panel.zwc
}

# fm add

read_added_menu() { added_menu=(); fm__read -tmp added_menu }

test_fm_add_appends_a_record_to_the_added_menu() {
	fm_load
	local -a added_menu
	fm add --tool 'ls -l $items[1]' --title 'List It' --key f6 --usage 'Lists the item'
	fm add --tool 'return 2' --title 'Fails'
	read_added_menu
	assert_eq 2 $#added_menu
	assert_eq $'Lists the item\tls -l $items[1]\t1\tList It\tf6' "$added_menu[1]"
	assert_eq $'\treturn 2\t2\tFails\t' "$added_menu[2]"
	assert_in f6 fm__command_keys
}

test_fm_add_converts_tabs_in_the_arguments() {
	fm_load
	local -a added_menu
	fm add --tool 'print' --title $'Tab\tTitle' --usage $'a\tb'
	read_added_menu
	assert_eq $'a  b\tprint\t1\tTab  Title\t' "$added_menu[1]"
}

test_fm_add_rejects_an_unknown_tool() {
	fm_load
	assert_fail fm add --tool 'no-such-command-here' --title 'X' 2>$sb/err
	assert_contains 'is not a defined command or function' "$(<$sb/err)"
	assert_eq '' "$(<$FM__TMP/added_menu)"
}

test_fm_add_refuses_an_already_assigned_key() {
	fm_load
	local -a added_menu
	fm add --tool 'print' --title 'X' --key ctrl-q 2>$sb/err
	assert_contains "The key 'ctrl-q' is already assigned" "$(<$sb/err)"
	assert_eq 1 ${#${(M)fm__command_keys:#ctrl-q}} 'not added twice'
	read_added_menu
	assert_eq 1 $#added_menu 'the tool is added anyway'
	assert_eq ctrl-q "${added_menu[1]##*$'\t'}" 'with the key: the Menu Panel shows it, the panel dispatches it to QUIT'
}

test_fm_add_examples_load() {
	fm_load
	local -a added_menu
	source $fm__root/added-tools-examples
	read_added_menu
	assert_eq 3 $#added_menu
	assert_in f6 fm__command_keys
}

# fm__read / fm__write

test_read_write_round_trip() {
	fm_load
	local -a targets=( "$PWD/dir one" $PWD/ünïcödé.txt "it's \"quoted\"" )
	local -A clipboard=( [mode]=cut [sources]=$'one\ntwo' )
	fm__write -tmp targets
	fm__write -tmp clipboard
	local -a targets=()
	local -A clipboard=()
	fm__read -tmp targets
	fm__read -tmp clipboard
	assert_eq "$PWD/dir one|$PWD/ünïcödé.txt|it's \"quoted\"" "${(j:|:)targets}"
	assert_eq $'cut|one\ntwo' "$clipboard[mode]|$clipboard[sources]"
}

test_read_of_an_empty_file_leaves_the_variable_untouched() {
	fm_load
	local -a targets=( stale )
	: > $FM__TMP/targets
	fm__read -tmp targets
	assert_eq stale "$targets"
}
