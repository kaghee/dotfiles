# If not running interactively, don't do anything
[[ -z "$PROMPT" ]] && return

# Resolve DOTFILES_DIR
CURRENT_SCRIPT=$0

  # Assuming ~/.dotfiles on distros without readlink and/or $BASH_SOURCE/$0
  # REVISIT: -x doesn't seem to work for some reason
if [[ -n $CURRENT_SCRIPT && -x readlink ]]; then
  SCRIPT_PATH=$(readlink -f $CURRENT_SCRIPT)
  DOTFILES_DIR="${PWD}/$(dirname $(dirname $SCRIPT_PATH))"
elif [[ -d "$HOME/projects/.dotfiles" ]]; then
  DOTFILES_DIR="$HOME/projects/.dotfiles"
else
  echo "Unable to find dotfiles, exiting."
  return
fi

# Make utilities available
export PATH="$DOTFILES_DIR/bin:$PATH"

# Source the dotfiles (order matters)
for DOTFILE in "$DOTFILES_DIR"/system/.{function,function_*,n,path,env,exports,alias,fzf,grep,prompt,completion,fix,zoxide,plugins}; do
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
unset CURRENT_SCRIPT SCRIPT_PATH DOTFILE
export DOTFILES_DIR
