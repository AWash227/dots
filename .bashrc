# ~/.bashrc
# If not running interactively, don't do anything
[[ $- != *i* ]] && return
PS1='[\u@\h \W]\$ '

# Aliases
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias dots='git --git-dir=$HOME/.dots --work-tree=$HOME'

# Redshift helpers
red() {
  pkill -9 redshift 2>/dev/null
  while pgrep -x redshift >/dev/null; do sleep 0.1; done
  redshift -P -O 1000
}

blue() {
  redshift -x
  redshift &
}

# Environment
export EDITOR="nvim"
export CUDA_HOME=/opt/cuda
export PYENV_ROOT="$HOME/.pyenv"
export PNPM_HOME="$HOME/.local/share/pnpm"
export BUN_INSTALL="$HOME/.bun"
export NVM_DIR="$HOME/.nvm"
export OLLAMA_API_BASE=http://127.0.0.1:11434
export PATH="$CUDA_HOME/bin:$PYENV_ROOT/bin:$PNPM_HOME:$BUN_INSTALL/bin:$PATH"
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH
export OLLAMA_CONTEXT_LENGTH=64000

[ -f "$HOME/.env" ] && source "$HOME/.env"

# pyenv
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

# NVM - lazy load for faster shell startup
for cmd in nvm node npm npx; do
  eval "${cmd}() { unset -f nvm node npm npx; [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"; ${cmd} \"\$@\"; }"
done
