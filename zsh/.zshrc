# ➤ Skip if not running interactively.
[[ $- != *i* ]] && return

# ➤ Powerlevel10k Instant Prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ➤Powerlevel10k Prompt
source ~/powerlevel10k/powerlevel10k.zsh-theme
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# ➤ Eklentiler
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /home/cinar/zsh-auto-notify/auto-notify.plugin.zsh
source /usr/share/zsh/plugins/zsh-you-should-use/you-should-use.plugin.zsh

# FZF ayarları
[ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh
[ -f /usr/share/fzf/completion.zsh ] && source /usr/share/fzf/completion.zsh

# FZF ayarları
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d'
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"

# ➤ FZF Theme, edit this directly by going to this link: https://vitormv.github.io/fzf-themes#eyJib3JkZXJTdHlsZSI6InJvdW5kZWQiLCJib3JkZXJMYWJlbCI6IkZaRiBGdXp6eSBGaW5kZXIg75KJIiwiYm9yZGVyTGFiZWxQb3NpdGlvbiI6MCwicHJldmlld0JvcmRlclN0eWxlIjoicm91bmRlZCIsInBhZGRpbmciOiIwIiwibWFyZ2luIjoiMCIsInByb21wdCI6Ij4gIiwibWFya2VyIjoiPiIsInBvaW50ZXIiOiLil4YiLCJzZXBhcmF0b3IiOiI9Iiwic2Nyb2xsYmFyIjoifCIsImxheW91dCI6ImRlZmF1bHQiLCJpbmZvIjoiZGVmYXVsdCIsImNvbG9ycyI6ImZnOiNkMGQwZDAsZmcrOiNkMGQwZDAsYmc6IzEyMTIxMixiZys6IzI2MjYyNixobDojYmE2YzI0LGhsKzojNWZkN2ZmLGluZm86I2FmYWY4NyxtYXJrZXI6Izg3ZmYwMCxwcm9tcHQ6I2ZmMDAwMCxzcGlubmVyOiMxOTAwZmYscG9pbnRlcjojMTkwMGZmLGhlYWRlcjojMTM4ZThlLGJvcmRlcjojMjYyNjI2LGxhYmVsOiNhZWFlYWUscXVlcnk6I2Q5ZDlkOSJ9
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
  --color=fg:#d0d0d0,fg+:#d0d0d0,bg:#121212,bg+:#262626
  --color=hl:#ba6c24,hl+:#5fd7ff,info:#afaf87,marker:#87ff00
  --color=prompt:#ff0000,spinner:#1900ff,pointer:#1900ff,header:#138e8e
  --color=border:#262626,label:#aeaeae,query:#d9d9d9
  --border="rounded" --border-label="FZF Fuzzy Finder " --border-label-pos="0" --preview-window="border-rounded"
  --prompt="> " --marker=">" --pointer="◆" --separator="="
  --scrollbar="|"'

bindkey '^T' fzf-file-widget
bindkey '^[c' fzf-cd-widget

# ➤ Tab Completion Sistemi
autoload -U compinit; compinit
source ~/fzf-tab/fzf-tab.plugin.zsh
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git --max-depth 1'

# ➤ Gelişmiş Kullanım Ayarları
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

# ➤ History
HISTSIZE=1000000
SAVEHIST=1000000
HISTFILE=~/.zsh_history

setopt EXTENDED_HISTORY
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt HIST_VERIFY
setopt AUTO_CD

export QT_QPA_PLATFORM=wayland
export QT_QPA_PLATFORMTHEME=qt5ct
export MOZ_ENABLE_WAYLAND=1
export XDG_SESSION_TYPE=wayland

# ➤ Aliaslar
alias ZSH='source ~/.zshrc'
alias la='ls -a'
alias S=sudo
alias pacman.conf='nano /etc/pacman.conf'
alias zshrc='kate ~/.zshrc'
alias cat='bat --paging=never'
alias ls='eza -x --icons -a'
alias nv=nvim
alias calc='python3 -q'
alias konsave='cd ~/KonUI && ./launch.sh'
alias q=exit

# ➤ Powerlevel10k quiet instant prompt
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
if command -v zoxide > /dev/null; then
  eval "$(zoxide init zsh)"
fi

# ➤ Shell Sage Hook
shell_sage_prompt() {
    local EXIT=$?
    local CMD=$(fc -ln -1 | awk '{$1=$1}1' | sed 's/\/\\/g')
    [ $EXIT -ne 0 ] && shellsage run --analyze "$CMD" --exit-code $EXIT
    history -s "$CMD"  # Force into session history
}
PROMPT_COMMAND="shell_sage_prompt"

# ➤ Shellsage alias for help
function help() {
    if [[ -z "$VIRTUAL_ENV" || "$VIRTUAL_ENV" != *shellsage_env* ]]; then
        source ~/Terminal_assistant/shellsage_env/bin/activate
    fi

    shellsage ask "$@"
}

# ➤ Display neofetch on startup
neofetch
