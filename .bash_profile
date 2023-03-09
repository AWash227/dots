export PATH="/home/andrew/.local/bin:$PATH"

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
