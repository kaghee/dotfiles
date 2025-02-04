# If not running interactively, don't do anything
[[ -z "$PROMPT" ]] && return

# Assuming ~/.dotfiles
DOTFILES_DIR="$HOME/.dotfiles"

if [[ -d "$DOTFILES_DIR" ]]; then
else
    echo "Unable to find dotfiles, exiting."
    return
fi

# Make utilities available
export PATH="$DOTFILES_DIR/bin:$PATH"

# Source the dotfiles (order matters)
for DOTFILE in "$DOTFILES_DIR"/system/.{function,function_*,n,path,env,exports,alias,fzf,grep,prompt,completion,fix,zoxide,python}; do
    source "$DOTFILE"
done

if [[ -n $(uname -s | grep -i Darwin) ]]; then # Check for macOS
    for DOTFILE in "$DOTFILES_DIR"/system/.{env,alias,function}.macos; do
        source "$DOTFILE"
    done
fi

# Set LSCOLORS
eval "$(dircolors -b "$DOTFILES_DIR"/system/.dir_colors)"

# Wrap up
unset DOTFILE
export DOTFILES_DIR
