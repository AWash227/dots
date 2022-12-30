# ~/.bashrc
# This file is read by every interactive non-login shell first
# As such, any aliases and bash related functions should go here

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

export PS1='[\u@\h \W]\$ ' # Alter prompt
export TERM=xterm-256color # Fix ranger crashing due to colors

# pnpm
[ -d "~/.local/share/pnpm" ] && export PNPM_DIR="~/.local/share/pnpm";
export PATH="$PNPM_DIR:$PATH";

# cargo
[ -d ~/.cargo/bin ] && export CARGO_DIR="~/.cargo/bin"
export PATH="$CARGO_DIR:$PATH"

# nvm
[ -d "~/.nvm" ] && export NVM_DIR="~/.nvm";
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh";  # setup nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion";  # setup bash completion


# Aliases
alias dots='/usr/bin/git --git-dir=~/.dots/.git/ --work-tree=~'
alias ls='ls --color=auto'
