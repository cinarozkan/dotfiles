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

# ➤ Görsel bilgi
neofetch

# ➤ Powerlevel10k sessiz instant prompt
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
if command -v zoxide > /dev/null; then
  eval "$(zoxide init zsh)"
fi


