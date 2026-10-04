# =============================================================================
# ~/.zshrc — Ultimate Modern Zsh with FZF-Tab Intellisense, Zoxide & Eye Candy
# =============================================================================

# ── Environment & Paths ───────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
export EDITOR="nvim"
export VISUAL="nvim"
export TERMINAL="ghostty"
export QT_QPA_PLATFORMTHEME="qt6ct"
export QT_STYLE_OVERRIDE="breeze"
export QT_PLUGIN_PATH="$HOME/.local/lib/qt6/plugins"
export XDG_DATA_HOME="$HOME/.local/share:$XDG_DATA_HOME"

# ── History Settings ─────────────────────────────────────────────────────────
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

setopt EXTENDED_HISTORY          # Record timestamp in history
setopt INC_APPEND_HISTORY        # Immediately append to history file
setopt SHARE_HISTORY             # Share history across all active terminals
setopt NO_HUP                    # Do not kill child jobs on shell exit
trap '' HUP                      # Ignore SIGHUP so scratchpad terminal never exits when hidden
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming
setopt HIST_IGNORE_DUPS          # Don't record duplicate entry
setopt HIST_IGNORE_ALL_DUPS      # Delete older duplicate entry if a new one is typed
setopt HIST_FIND_NO_DUPS         # Do not display duplicates when searching history
setopt HIST_IGNORE_SPACE         # Do not record entries starting with a space
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in history file
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording
setopt HIST_VERIFY               # Don't execute immediately upon history expansion

# ── FZF Styling & Settings (Material You Dark) ──────────────────────────────
export FZF_DEFAULT_OPTS=" \
--color=bg+:#282a2f,bg:#111318,spinner:#e5c07b,hl:#ffb4ab \
--color=fg:#e1e2e9,header:#ffb4ab,info:#dbbde2,pointer:#a6c8ff \
--color=marker:#a6c8ff,fg+:#e1e2e9,prompt:#a6c8ff,hl+:#ffb4ab \
--prompt='❯ ' \
--pointer='◆ ' \
--marker='✓ ' \
--layout=reverse \
--border=rounded \
--height=45% \
--inline-info"

export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range :50 {} 2>/dev/null || eza --tree --level=2 --color=always {} 2>/dev/null'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --color=always {} 2>/dev/null'"

# ── Interactive Tab Completion (Compinit) ───────────────────────────────────
autoload -Uz compinit
if [[ -n "${ZDOTDIR:-$HOME}/.zcompdump(#qN.m-1)" ]]; then
    compinit -C
else
    compinit
fi

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*:*:*:*:descriptions' format '%F{#a6c8ff}-- %d --%f'
zstyle ':completion:*:messages' format ' %F{#ffb4ab} -- %d --%f'
zstyle ':completion:*:warnings' format ' %F{#ffb4ab}-- No matches found --%f'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:*:-command-:*:*' group-order alias builtins functions commands

# ── FZF-Tab (Floating interactive popup completion with live previews) ──────
PLUGIN_DIR="$HOME/.zsh/plugins"

if [[ -f "$PLUGIN_DIR/fzf-tab/fzf-tab.plugin.zsh" ]]; then
    source "$PLUGIN_DIR/fzf-tab/fzf-tab.plugin.zsh"
    # Preview directory content with eza when completing cd or z
    zstyle ':fzf-tab:complete:(cd|z):*' fzf-preview 'eza -1 --color=always --icons=auto $realpath'
    # Preview file content with bat when completing file-reading commands
    zstyle ':fzf-tab:complete:(cat|bat|nvim|nano|less):*' fzf-preview 'bat --color=always --line-range :50 $realpath 2>/dev/null || cat $realpath'
    # Preview process details for kill / pkill
    zstyle ':fzf-tab:complete:(kill|pkill):*' fzf-preview 'ps --pid=$word -o cmd --no-headers -w -w'
    zstyle ':fzf-tab:complete:(kill|pkill):*' fzf-flags '--preview-window=down:3:wrap'
    # Switch groups using `<` and `>`
    zstyle ':fzf-tab:*' switch-group '<' '>'
fi

# ── Keybindings & Navigation ─────────────────────────────────────────────────
bindkey -e
bindkey '^[[H'  beginning-of-line
bindkey '^[[F'  end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^H' backward-kill-word
bindkey '^?' backward-delete-char

# ── Plugins: Autosuggestions & History Substring Search ─────────────────────
# 1. zsh-autosuggestions (fish-like real-time suggestions)
if [[ -f "$PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "$PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#555860'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
bindkey '^[[C' forward-char
bindkey '^F'   autosuggest-accept
bindkey '^E'   end-of-line

# 2. zsh-history-substring-search (Prefix search: type 'op' + Up searches 'op...')
if [[ -f "$PLUGIN_DIR/zsh-history-substring-search/zsh-history-substring-search.zsh" ]]; then
    source "$PLUGIN_DIR/zsh-history-substring-search/zsh-history-substring-search.zsh"
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
    bindkey '^[OA' history-substring-search-up
    bindkey '^[OB' history-substring-search-down
    bindkey '^P'   history-substring-search-up
    bindkey '^N'   history-substring-search-down
fi

# 3. zsh-syntax-highlighting (Must be sourced LAST)
if [[ -f "$PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    source "$PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# ── FZF Keybindings (Ctrl+R history, Ctrl+T file) ───────────────────────────
if [[ -f "$HOME/.fzf/shell/completion.zsh" ]]; then
    source "$HOME/.fzf/shell/completion.zsh"
fi
if [[ -f "$HOME/.fzf/shell/key-bindings.zsh" ]]; then
    source "$HOME/.fzf/shell/key-bindings.zsh"
fi

# ── Zoxide (Smart directory jumping: z <folder>, zi for interactive) ─────────
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# ── Modern Aliases & Functions ───────────────────────────────────────────────
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --icons=auto --group-directories-first'
    alias ll='eza -la --icons=auto --group-directories-first --git'
    alias l='eza -l --icons=auto --group-directories-first'
    alias la='eza -a --icons=auto --group-directories-first'
    alias lt='eza --tree --level=2 --icons=auto'
else
    alias ls='ls --color=auto'
    alias ll='ls -la'
fi

if command -v bat >/dev/null 2>&1; then
    alias cat='bat --paging=never'
fi

alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias c='clear'
alias q='exit'
alias nf='fastfetch'
alias ff='fastfetch -s'
alias nfs='fastfetch -s'

# Fastfetch wrapper: -s / -m / --mini / --compact for cute bare-metal layout
fastfetch() {
    for arg in "$@"; do
        if [[ "$arg" == "-s" || "$arg" == "--small" || "$arg" == "-m" || "$arg" == "--mini" || "$arg" == "--compact" ]]; then
            command fastfetch -c "$HOME/.config/fastfetch/compact.jsonc" "${@:#$arg}"
            return $?
        fi
    done
    command fastfetch "$@"
}

# Interactive Fuzzy Process Killer: fkill
fkill() {
    local pid
    pid=$(ps -ef | sed 1d | fzf -m --prompt="Kill Process ❯ " | awk '{print $2}')
    if [ -n "$pid" ]; then
        echo "$pid" | xargs kill -${1:-9}
        echo "Killed PID(s): $pid"
    fi
}

# ── Fastfetch on interactive shell launch ────────────────────────────────────
if [[ -o interactive ]] && [[ -z "$FASTFETCH_SHOWN" ]] && command -v fastfetch >/dev/null 2>&1; then
    export FASTFETCH_SHOWN=1
    fastfetch
fi

# ── Starship Prompt ──────────────────────────────────────────────────────────
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
else
    PROMPT='%F{#a6c8ff}%~%f %F{#e5c07b}❯%f '
fi
alias killsteam="steam -shutdown"
alias killdis="pkill -9 -f Discord"
