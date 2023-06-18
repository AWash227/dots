# ~/.bashrc
# This file is read by every interactive non-login shell first
# As such, any aliases and bash related functions should go here

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# ⨍⨎∴☸⚘⚙✿⠝☿☮☭☫☨☢☣⌬
# Taskwarrior
TASK="task"
DUETOMORROW="→";
DUETODAY="⨀";
OVERDUE="⁉";

function task_indicator {
  if [ `$TASK +READY +OVERDUE count 2>/dev/null` -gt "0" ]; then
    echo "$OVERDUE";
  elif [ `$TASK +READY +DUETODAY count 2>/dev/null` -gt "0" ]; then
    echo "$DUETODAY"
  elif [ `$TASK +READY +TOMORROW count 2>/dev/null` -gt "0" ]; then
    echo "$DUETOMORROW"
  else
    echo "∴"
  fi
}



export PS1="[\u\h \W]\$(task_indicator) " # Alter prompt
export TERM=xterm-256color # Fix ranger crashing due to colors
export VISUAL=lvim;
export EDITOR=lvim;

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
[ -d "$HOME/school/2023/semester_1/session_4/CSCI3326/work/nand2tetris/tools" ] && export NAND2TETRIS_DIR="$HOME/school/2023/semester_1/session_4/CSCI3326/work/nand2tetris/tools"
export PATH="$NAND2TETRIS_DIR:$PATH"


(cat ~/.cache/wal/sequences &)
source ~/.cache/wal/colors-tty.sh
# Aliases
alias dots="/usr/bin/git --git-dir=$HOME/.dots/.git/ --work-tree=$HOME"
alias ls='ls --color=auto'
alias vim='lvim'
alias vi='lvim'
alias ranger='cat ~/.cache/wal/sequences & ranger'
alias t="$TASK"
alias to="taskopen"

# bit
export PATH="$PATH:/home/andrew/bin"
# bit end
