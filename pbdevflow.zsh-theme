#!/usr/bin/env zsh

# Set required options for the prompt substitution
setopt prompt_subst

# Load required modules for version control systems
autoload -Uz vcs_info

# Configure vcs_info parameters for Git support
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*:*' unstagedstr '!'
zstyle ':vcs_info:*:*' stagedstr '+'
zstyle ':vcs_info:*:*' formats ''
zstyle ':vcs_info:*:*' actionformats ''

# Main colors
PATH_COLOR="#808080"         # Color for the file path
BRANCH_COLOR="#f5c211"       # Color for Git branch name
DIRTY_COLOR="#ff661a"        # Orange color for "dirty" repository state
CLEAN_COLOR="#656565"        # Gray color for "clean" repository state
PROMPT_COLOR="#f5c211"       # Color for the input prompt symbol
CMD_TIME_COLOR="green"       # Color for the command execution time
USERNAME_COLOR="#fff"        # Color for the username

# Symbols
USER_ICON="\uf2be"           # Nerd Font icon for the user
GIT_BRANCH_ICON="\ueb86"     # Nerd Font icon for the Git branch
DIRTY_STATUS_ICON="●"        # Icon for the repository state
CHANGE_COUNT_SYMBOL="±"      # Symbol for the number of modified files
FOLDER_ICON="\uea83"         # Nerd Font icon for the folder

# Check if the current directory is a Git repository and display its status
git_info() {
    if command git rev-parse --is-inside-work-tree &>/dev/null; then
        local branch status_icon change_count
        branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "detached")

        # Determine the repository state and count the number of changes
        change_count=$(git status --porcelain | wc -l) # Count modified files

        if [[ $change_count -gt 0 ]]; then
            status_icon="%F{$DIRTY_COLOR}${DIRTY_STATUS_ICON}%f %F{$DIRTY_COLOR}${CHANGE_COUNT_SYMBOL}${change_count}%f" # Changes detected
        else
            status_icon="%F{$CLEAN_COLOR}${DIRTY_STATUS_ICON}%f %F{$CLEAN_COLOR}${CHANGE_COUNT_SYMBOL}0%f" # Repository is clean
        fi

        echo "%F{$BRANCH_COLOR}${GIT_BRANCH_ICON} %F{$BRANCH_COLOR}${branch} ${status_icon}%f"
    fi
}

# Display the current path, user info, and Git repository status
repo_information() {
    local git_status
    git_status=$(git_info)
    if [[ -n $git_status ]]; then
        echo "%F{$USERNAME_COLOR}${USER_ICON} $USER %F{$PATH_COLOR}${FOLDER_ICON} %~%f ${git_status}" # Username, folder path, and Git info
    else
        echo "%F{$USERNAME_COLOR}${USER_ICON} $USER %F{$PATH_COLOR}${FOLDER_ICON} %~%f" # Username and folder path without Git info
    fi
}

# Record the timestamp before the command execution
preexec() {
    cmd_timestamp=$(date +%s)
}

# Calculate and display the execution time if it exceeds 5 seconds
cmd_exec_time() {
    local stop start elapsed
    stop=$(date +%s)
    start=${cmd_timestamp:-$stop}
    ((elapsed = stop - start))
    [ $elapsed -gt 5 ] && echo "%F{$CMD_TIME_COLOR}${elapsed}s%f"
}

# Update repository information before rendering the prompt
precmd() {
    vcs_info
}

# Build the main prompt with username, path, and Git status
PROMPT='$(repo_information)
%F{$PROMPT_COLOR}❯%f '  # Color for the input prompt matches the Git branch
RPROMPT="$(cmd_exec_time)" # Displays command execution time

