# Copyright (c) 2020 Domizio Demichelis - dd.nexus@gmail.com - https://github/com/ddnexus

setopt LOCAL_OPTIONS NO_SH_WORD_SPLIT EXTENDED_GLOB NO_POSIX_IDENTIFIERS

fm__version=0.1.0
fm__root=$0:A:h

zmodload zsh/param/private
autoload -Uz $fm__root/autoload/**/*(.)

: ${FM__KEY_SELECT_ALL:=ctrl-a}

fm__command_keys=(
# FM UI
	${FM__KEY_MENU:=ctrl-space}
	${FM__KEY_PREVIEW:=ctrl-p}
	#FM__KEY_SELECT_ALL bind key
	${FM__KEY_REFRESH=ctrl-r}
	${FM__KEY_NOTIFY_WD=ctrl-w}
	${FM__KEY_HIDDEN=ctrl-h}
	${FM__KEY_SORT=ctrl-s}
	${FM__KEY_QUIT=ctrl-q}
#FM Views
	${FM__KEY_VIEW_ITEM:=enter}
	${FM__KEY_VIEW_DIR=alt-d}
	${FM__KEY_VIEW_FIND=alt-f}
	${FM__KEY_VIEW_GREP=alt-g}
	${FM__KEY_VIEW_REC=alt-r}
	${FM__KEY_VIEW_FAV=alt-v}
# Navigation
	${FM__KEY_CD_HOME=alt-h}
	${FM__KEY_CD_ROOT=alt-/}
	${FM__KEY_CD_PARENT=alt-p}
	${FM__KEY_CD_LAST=alt-l}
	${FM__KEY_CD_START=alt-s}
	${FM__KEY_CD_CONTAIN=alt-c}
# FS Commands
	${FM__KEY_FAV_ADD_WD=ctrl-alt-w}
	${FM__KEY_FAV_ADD=ctrl-alt-s}
	${FM__KEY_MARK=ctrl-alt-m}
	${FM__KEY_LINK=ctrl-alt-l}
	${FM__KEY_NEW_FILE=ctrl-alt-f}
	${FM__KEY_NEW_DIR=ctrl-alt-d}
	${FM__KEY_COPY=ctrl-alt-c}
	${FM__KEY_CUT=ctrl-alt-x}
	${FM__KEY_PASTE=ctrl-alt-v}
	${FM__KEY_RENAME=ctrl-alt-n}
	${FM__KEY_REMOVE=ctrl-alt-r}
	${FM__KEY_EXEC_ON=''}
	${FM__KEY_EXEC_OFF=''}
# Tools
	${FM__KEY_OPEN=ctrl-o}
	${FM__KEY_EDIT=ctrl-e}
	${FM__KEY_NEW_SHELL=ctrl-n}
	${FM__KEY_COPY_PATH=ctrl-t}
# extra keys
	double-click       # default fzf alternative of accept
	esc ctrl-c ctrl-z  # exit/interrupt/suspend
)
: ${FM__CMD_CAT:=$( fm__get-cmd 'bat -f --style=numbers --wrap=never' 'cat -n' )}
: ${FM__CMD_LS:=$( fm__get-cmd 'exa -lbg --color=always --color-scale --group-directories-first' 'ls -lh --color --group-directories-first' )}
: ${FM__CMD_FIND:=$( fm__get-cmd fd find )}
: ${FM__CMD_EDIT:=${EDITOR:-$( fm__get-cmd nano vim emacs vi )}}
: ${FM__CMD_OPEN:=$( fm__get-cmd xdg-open open )}
: ${FM__CMD_PAGER:=$( fm__get-cmd 'less -R' )}
: ${FM__CMD_RIPGREP:=$( fm__get-cmd rg )}
: ${FM__CMD_TERMINAL=$( fm__get-cmd 'gnome-terminal --tab --working-directory' 'konsole --workdir' 'terminology -d' )} #  can be disabled by setting it to ''
: ${FM__CMD_SHELL:=$SHELL}
: ${FM__CMD_XCLIP:=$( fm__get-cmd 'xclip -selection clipboard' 'xsel --clipboard -i' )}
: ${FM__CMD_SUDO=$( fm__get-cmd sudo )} #  can be disabled by setting it to ''
: ${FM__CMD_STAT:=$( fm__get-cmd stat )}
: ${FM__CMD_SORT:=$( fm__get-cmd 'sort -fbi' )}

: ${FM__MAX_GREP_FILES:=100}
: ${FM__MAX_RECENT_DIRS:=100}
: ${FM__MAX_DIALOG_RECAP:=12}
: ${FM__MAX_MENU_RECAP:=4}
: ${FM__MENU_WIDTH:=38}; if [[ $FM__MENU_WIDTH -lt 34 ]] FM__MENU_WIDTH=34 # min 34 COLUMNS
: ${FM__HINTS:=true}
: ${FM__INFO_COLOR:=2} # green as understood by fzf
: ${(A)FM__PREVIEW_MODES:=${=:-rounded:right:55% rounded:bottom 0}}
: ${FM__COMMAND_FZF_OPTS:="--exact --no-sort --reverse --height=100% --info=inline --color=info:$FM__INFO_COLOR"}
if [[ ! -d ${FM__DATA:=$HOME/.fm} ]] mkdir -p $FM__DATA &>/dev/null
if [[ ! -d ${FM__TMP:=/tmp/fm} ]] mkdir -p $FM__TMP &>/dev/null

local names=( boot dev etc home opt proc sys tmp usr var )
for line in "${(@f)$($=FM__CMD_LS --color=never /)}"; do
	if [[ $line == *-\>* ]] continue
	if [[ $names[(r)${line##* }] ]]; then
		fm__ls_fields=${=:-$(repeat $((${(w)#line} - 2)) print _) rest}
		break
	fi
done

typeset -gx \
		fm__root \
		fm__ls_fields \
		FM__DATA \
		FM__TMP \
		FM__CMD_CAT \
		FM__CMD_LS \
		FM__CMD_RIPGREP \
		FM__CMD_STAT \
		FM__INFO_COLOR

local file
for file in \
		favorites \
		recent_dirs \
		preview
	[[ -f $file ]] || touch $FM__DATA/$file

if [[ ! -s $FM__DATA/preview ]]; then
	local -A preview=( [command-panel]=1 [command-menu]=1 [widget-panel]=1 [widget-menu]=1 )
	fm__write -data preview
fi

for file in \
		added_menu \
		clipboard \
		matches \
		targets
	[[ -f $file ]] || touch $FM__TMP/$file
: > $FM__TMP/added_menu

for file in \
		$fm__root/preview/panel \
		$fm__root/preview/menu
	[[ -x $file ]] || chmod +x $file

# load favorites
hash -df
source $FM__DATA/favorites


### WIDGET

fm__widget_keys=(
# FM UI
	$FM__KEY_MENU
	$FM__KEY_PREVIEW
	$FM__KEY_REFRESH
	$FM__KEY_NOTIFY_WD
	$FM__KEY_HIDDEN
	$FM__KEY_SORT
	$FM__KEY_QUIT
#FM Views
	$FM__KEY_VIEW_ITEM
	$FM__KEY_VIEW_DIR
	$FM__KEY_VIEW_FIND
	$FM__KEY_VIEW_GREP
	$FM__KEY_VIEW_REC
	$FM__KEY_VIEW_FAV
# Navigation
	$FM__KEY_CD_HOME
	$FM__KEY_CD_ROOT
	$FM__KEY_CD_PARENT
	$FM__KEY_CD_LAST
	$FM__KEY_CD_START
	$FM__KEY_CD_CONTAIN
# widget
	${FM__KEY_PICK=ctrl-k}     # widget only
	${FM__KEY_PICK_WD=ctrl-d}  # widget only
# extra keys
	double-click       # default fzf alternative of accept
	esc ctrl-c ctrl-z  # exit/interrupt/suspend
)

: ${FM__WIDGET_FZF_OPTS:="--exact --no-sort --reverse --height=40% --info=inline --color=info:$FM__INFO_COLOR"}

zle -N fm__widget
bindkey ${FM__WIDGET_KEY:='^[f^[f'} fm__widget
