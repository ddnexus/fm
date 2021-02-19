# Copyright (c) 2020 Domizio Demichelis - dd.nexus@gmail.com - https://github/com/ddnexus

setopt LOCAL_OPTIONS NO_SH_WORD_SPLIT EXTENDED_GLOB NO_POSIX_IDENTIFIERS

_fm_version=0.1.0
_fm_root=${$(readlink -f $0):h}

zmodload zsh/param/private
autoload -Uz $_fm_root/autoload/**/*(.)

: ${FM_KEY_SELECT_ALL:=ctrl-a}

_fm_command_keys=(
# FM UI
    ${FM_KEY_MENU:=ctrl-space}
    ${FM_KEY_PREVIEW:=ctrl-p}
    #FM_KEY_SELECT_ALL bind key
    ${FM_KEY_REFRESH=ctrl-r}
    ${FM_KEY_NOTIFY_WD=ctrl-w}
    ${FM_KEY_HIDDEN=ctrl-h}
    ${FM_KEY_SORT=ctrl-s}
    ${FM_KEY_QUIT=ctrl-q}
#FM Views
    ${FM_KEY_VIEW_ITEM:=enter}
    ${FM_KEY_VIEW_DIR=alt-d}
    ${FM_KEY_VIEW_FIND=alt-f}
    ${FM_KEY_VIEW_GREP=alt-g}
    ${FM_KEY_VIEW_REC=alt-r}
    ${FM_KEY_VIEW_FAV=alt-v}
# Navigation
    ${FM_KEY_CD_HOME=alt-h}
    ${FM_KEY_CD_ROOT=alt-/}
    ${FM_KEY_CD_PARENT=alt-p}
    ${FM_KEY_CD_LAST=alt-l}
    ${FM_KEY_CD_START=alt-s}
    ${FM_KEY_CD_CONTAIN=alt-c}
# FS Commands
    ${FM_KEY_FAV_ADD_WD=ctrl-alt-w}
    ${FM_KEY_FAV_ADD=ctrl-alt-s}
    ${FM_KEY_MARK=ctrl-alt-m}
    ${FM_KEY_LINK=ctrl-alt-l}
    ${FM_KEY_NEW_FILE=ctrl-alt-f}
    ${FM_KEY_NEW_DIR=ctrl-alt-d}
    ${FM_KEY_COPY=ctrl-alt-c}
    ${FM_KEY_CUT=ctrl-alt-x}
    ${FM_KEY_PASTE=ctrl-alt-v}
    ${FM_KEY_RENAME=ctrl-alt-n}
    ${FM_KEY_REMOVE=ctrl-alt-r}
    ${FM_KEY_EXEC_ON=''}
    ${FM_KEY_EXEC_OFF=''}
# Tools
    ${FM_KEY_OPEN=ctrl-o}
    ${FM_KEY_EDIT=ctrl-e}
    ${FM_KEY_NEW_SHELL=ctrl-n}
    ${FM_KEY_COPY_PATH=ctrl-t}
# extra keys
    double-click       # default fzf alternative of accept
    esc ctrl-c ctrl-z  # exit/interrupt/suspend
)
: ${FM_CMD_CAT:=$( _fm-get-cmd 'bat -f --style=numbers --wrap=never' 'cat -n' )}
: ${FM_CMD_LS:=$( _fm-get-cmd 'exa -lbg --color=always --color-scale --group-directories-first' 'ls -lh --color --group-directories-first' )}
: ${FM_CMD_FIND:=$( _fm-get-cmd fd find )}
: ${FM_CMD_EDIT:=${EDITOR:-$( _fm-get-cmd nano vim emacs vi )}}
: ${FM_CMD_OPEN:=$( _fm-get-cmd xdg-open open )}
: ${FM_CMD_PAGER:=$( _fm-get-cmd 'less -R' )}
: ${FM_CMD_RIPGREP:=$( _fm-get-cmd rg )}
: ${FM_CMD_TERMINAL=$( _fm-get-cmd 'gnome-terminal --tab --working-directory' 'konsole --workdir' 'terminology -d' )} #  can be disabled by setting it to ''
: ${FM_CMD_SHELL:=$SHELL}
: ${FM_CMD_XCLIP:=$( _fm-get-cmd 'xclip -selection clipboard' 'xsel --clipboard -i' )}
: ${FM_CMD_SUDO=$( _fm-get-cmd sudo )} #  can be disabled by setting it to ''
: ${FM_CMD_STAT:=$( _fm-get-cmd stat )}
: ${FM_CMD_SORT:=$( _fm-get-cmd 'sort -fbi' )}

: ${FM_MAX_GREP_FILES:=100}
: ${FM_MAX_RECENT_DIRS:=100}
: ${FM_MAX_DIALOG_RECAP:=12}
: ${FM_MAX_MENU_RECAP:=4}
: ${FM_MENU_WIDTH:=38}; if [[ $FM_MENU_WIDTH -lt 34 ]] FM_MENU_WIDTH=34 # min 34 COLUMNS
: ${FM_HINTS:=true}
: ${FM_INFO_COLOR:=2} # green as understood by fzf
: ${(A)FM_PREVIEW_MODES:=${=:-rounded:right:55% rounded:bottom 0}}
: ${FM_COMMAND_FZF_OPTS:="--exact --no-sort --reverse --height=100% --info=inline --color=info:$FM_INFO_COLOR"}
if [[ ! -d ${FM_DATA:=$HOME/.fm} ]] mkdir -p $FM_DATA &>/dev/null
if [[ ! -d ${FM_TMP:=/tmp/fm} ]] mkdir -p $FM_TMP &>/dev/null

local names=( boot dev etc home opt proc sys tmp usr var )
for line in "${(@f)$($=FM_CMD_LS --color=never /)}"; do
    if [[ $line == *-\>* ]] continue
    if [[ $names[(r)${line##* }] ]]; then
        _fm_ls_fields=${=:-$(repeat $((${(w)#line} - 2)) print _) rest}
        break
    fi
done

typeset -gx _fm_root \
            _fm_ls_fields \
            FM_DATA \
            FM_TMP \
            FM_CMD_CAT \
            FM_CMD_LS \
            FM_CMD_RIPGREP \
            FM_CMD_STAT \
            FM_INFO_COLOR

local file
for file in favorites \
            recent_dirs \
            preview
    [[ -f $file ]] || touch $FM_DATA/$file

if [[ ! -s $FM_DATA/preview ]]; then
    local -A preview=( [command-panel]=1 [command-menu]=1 [widget-panel]=1 [widget-menu]=1 )
    _fm-write -data preview
fi

for file in added_menu \
            clipboard \
            matches \
            targets
    [[ -f $file ]] || touch $FM_TMP/$file
: > $FM_TMP/added_menu

for file in $_fm_root/preview/panel \
            $_fm_root/preview/menu
    [[ -x $file ]] || chmod +x $file

# load favorites
hash -df
source $FM_DATA/favorites


### WIDGET

_fm_widget_keys=(
# FM UI
    $FM_KEY_MENU
    $FM_KEY_PREVIEW
    $FM_KEY_REFRESH
    $FM_KEY_NOTIFY_WD
    $FM_KEY_HIDDEN
    $FM_KEY_SORT
    $FM_KEY_QUIT
#FM Views
    $FM_KEY_VIEW_ITEM
    $FM_KEY_VIEW_DIR
    $FM_KEY_VIEW_FIND
    $FM_KEY_VIEW_GREP
    $FM_KEY_VIEW_REC
    $FM_KEY_VIEW_FAV
# Navigation
    $FM_KEY_CD_HOME
    $FM_KEY_CD_ROOT
    $FM_KEY_CD_PARENT
    $FM_KEY_CD_LAST
    $FM_KEY_CD_START
    $FM_KEY_CD_CONTAIN
# widget
    ${FM_KEY_PICK=ctrl-k}     # widget only
    ${FM_KEY_PICK_WD=ctrl-d}  # widget only
# extra keys
    double-click       # default fzf alternative of accept
    esc ctrl-c ctrl-z  # exit/interrupt/suspend
)

: ${FM_WIDGET_FZF_OPTS:="--exact --no-sort --reverse --height=40% --info=inline --color=info:$FM_INFO_COLOR"}

zle -N fm-widget
bindkey ${FM_WIDGET_KEY:='^[f^[f'} fm-widget
