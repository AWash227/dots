#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
[ -d ~/.cargo/bin ] && export PATH="~/.cargo/bin:$PATH"

# Fix Ranger color bug
export TERM=xterm-256color

# pnpm
export PNPM_HOME="/home/andrew/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
# pnpm end

# Aliases
alias dots='/usr/bin/git --git-dir=$HOME/.dots/.git/ --work-tree=$HOME'
