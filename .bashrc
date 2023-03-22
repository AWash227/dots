# ~/.bashrc
# This file is read by every interactive non-login shell first
# As such, any aliases and bash related functions should go here

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

export PS1='[\u@\h \W]\$ ' # Alter prompt
export TERM=xterm-256color # Fix ranger crashing due to colors

# pnpm
[ -d "$HOME/.local/share/pnpm" ] && export PNPM_HOME="$HOME/.local/share/pnpm";
export PATH="$PNPM_HOME:$PATH";

# cargo
[ -d $HOME/.cargo/bin ] && export CARGO_DIR="$HOME/.cargo/bin"
export PATH="$CARGO_DIR:$PATH"

# nvm
[ -d "$HOME/.nvm" ] && export NVM_DIR="$HOME/.nvm";
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh";  # setup nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion";  # setup bash completion


# Aliases
alias dots="/usr/bin/git --git-dir=$HOME/.dots/.git/ --work-tree=$HOME"
alias ls='ls --color=auto'
alias vim='lvim'
alias ranger='cat ~/.cache/wal/sequences & ranger'
