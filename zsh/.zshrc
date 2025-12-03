autoload -Uz compinit && compinit

if [[ "$TERM_PROGRAM" == "ghostty" ]]; then
    export TERM=xterm-256color
fi

# Eza
alias l="eza -l --icons --git -a"
alias lt="eza --tree --level=2 --long --icons --git"
alias ltree="eza --tree --level=2  --icons --git"

alias v="nvim"
alias c="bat"
alias la="tree"

alias lgt="lazygit"

alias df="duf"
alias gpt="tgpt"
alias top="btop"


# Git
alias gc="git commit -m"
alias gp="git push -u origin"
alias gst="git status"
alias gdiff="git diff"
alias gco="git checkout"
alias gb='git branch'
alias gba='git branch -a'
alias gadd='git add'
alias gr='git remote'
alias gre='git reset'
alias gs='git status'

# Docker
alias dco="docker compose"
alias dps="docker ps"
alias dpa="docker ps -a"
alias dl="docker ps -l -q"
alias dx="docker exec -it"

# Dirs
alias ..="cd .."
alias ...="cd ../.."
