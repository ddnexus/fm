#!/usr/bin/env zsh

# Copyright (c) 2021 Domizio Demichelis
# Released under GNU3 license
# https://www.gnu.org/licenses/gpl-3.0.en.html


### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

### End of Zinit's installer chunk

############# options #############
setopt AUTO_CD
setopt CDABLE_VARS
setopt EXTENDED_GLOB
setopt NO_NOMATCH
setopt NUMERIC_GLOB_SORT


############# binding #############

# Use emacs keybindings even if our EDITOR is set to vi
bindkey -e

# Ctrl-arrow keys
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

# Alt-arrow keys
bindkey "^[[1;3C" forward-word
bindkey "^[[1;3D" backward-word

# Home-End keys
bindkey "^[[H"    beginning-of-line
bindkey "^[[F"    end-of-line


############# exa #############
export EXA_ICON_SPACING=2
alias x='exa -l'
alias xx='exa -laF --git'


############# bat #############
export BAT_THEME=TwoDark


############# misc #############
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export TERM=xterm-256color
export EDITOR=nano
export PROMPT=$'%F{green}%B%~ %#%b%f '


############# zsh-autosuggestions #############
zinit wait lucid depth:1 atload:_zsh_autosuggest_start for \
		light-mode zsh-users/zsh-autosuggestions

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE=fg=240
ZSH_AUTOSUGGEST_USE_ASYNC=true
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=30
ZSH_AUTOSUGGEST_STRATEGY=(history completion)


############# completion #############
zinit ice wait lucid depth:1 blockf atpull:'zinit creinstall -q .'
zinit light zsh-users/zsh-completions
zinit wait lucid depth:1 for light-mode Aloxaf/fzf-tab

# If a completion is performed with the cursor within a word, and a full
# completion is inserted, the cursor is moved to the end of the word
setopt ALWAYS_TO_END

# Automatically use menu completion after the second consecutive request for
# completion
setopt AUTO_MENU

# Try to make the completion list smaller (occupying less lines) by printing
# the matches in columns with different widths
setopt LIST_PACKED

# Prevents aliases on the command line from being internally substituted before completion
# is attempted. The effect is to make the alias a distinct command for completion purposes.
setopt COMPLETE_ALIASES

# Don't show types in completion lists
#setopt nolisttypes

eval "$(dircolors -b)"

zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true

zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

autoload -U compinit compdef && compinit


############# history #############
zinit depth:1 for light-mode zsh-users/zsh-history-substring-search

# Keep 1000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=2000
SAVEHIST=1500
HISTFILE=~/.zsh_history

# If the internal history needs to be trimmed to add the current command line,
# setting this option will cause the oldest history event that has a duplicate
# to be lost before losing a unique event from the list.
setopt HIST_EXPIRE_DUPS_FIRST

# Remove command lines from the history list when the first character on the
# line is a space, or when one of the expanded aliases contains a leading space
setopt HIST_IGNORE_SPACE

# When searching for history entries in the line editor, do not display duplicates
# of a line previously found, even if the duplicates are not contiguous.
setopt HIST_FIND_NO_DUPS

# If a new command line being added to the history list duplicates an older one,
# the older command is removed from the list (even if it is not the previous event).
setopt HIST_IGNORE_ALL_DUPS

# Do not enter command lines into the history list if they are duplicates of the previous event.
setopt HIST_IGNORE_DUPS

# Whenever the user enters a line with history expansion, don’t execute the line directly;
# instead, perform history expansion and reload the line into the editing buffer.
setopt HIST_VERIFY

# Share the history between shell instances
setopt SHARE_HISTORY

# Remove function definitions from the history list. Note that the function lingers
# in the internal history until the next command is entered before it vanishes,
# allowing you to briefly reuse or edit the definition.
setopt HIST_NO_FUNCTIONS

# Remove superfluous blanks from each command line being added to the history list
setopt HIST_REDUCE_BLANKS

# enable up and down arrows for history navigation
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

bindkey "$terminfo[kcuu1]" history-substring-search-up
bindkey "$terminfo[kcud1]" history-substring-search-down


############# colored man pages #############
zinit ice wait lucid depth:1
zinit light ael-code/zsh-colored-man-pages


############# fzf #############
zinit ice wait lucid depth:1 \
		as:command \
		atclone:'./install --all' \
		atpull:'%atclone'
zinit light junegunn/fzf

export FZF_DEFAULT_COMMAND="fdfind --type file --color=always"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS="--height 50% --reverse --ansi --exact --info=inline --color=info:2,dark,fg+:#959595,bg+:#000000"


############# fm #############
zinit ice wait lucid depth:1 \
		atinit:'source fm.zsh' \
		atload:'source added-tools-examples' \
		atclone:'./fm__compile; rm -rf ./try-fm' \
		atpull:%atclone
zinit light ddnexus/fm
alias f=fm


############# syntax highlighting #############
zinit ice wait lucid depth:1 \
		atinit'zpcompinit; zpcdreplay'
zinit light zdharma-continuum/fast-syntax-highlighting
