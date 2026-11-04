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
PROMPT_COLOR="#ffffff"       # Color for the input prompt arrow (white)
CMD_TIME_COLOR="green"       # Color for the command execution time
USERNAME_COLOR="#fff"        # Color for the username

# Git diff colors (the +files|rows / -files|rows counters)
GIT_ADD_COLOR="#33d17a"        # Green  - additions
GIT_DEL_COLOR="#ff661a"        # Orange - deletions
GIT_UNTRACKED_COLOR="#8a8a8a"  # Gray   - untracked files (?N)

# Dot colors -> what is the state of my working tree?
# Azure ladder for the "staged / ready" color (light -> deep):
#   #4fc3f7  |  #29b6f6  |  #2196f3  |  #1e88e5  |  #1976d2
GIT_DOT_CLEAN_COLOR="#656565"     # Gray   - nothing to commit, tree is clean
GIT_DOT_STAGED_COLOR="#2196f3"    # Azure  - everything is staged, ready to commit
GIT_DOT_UNSTAGED_COLOR="#ffffff"  # White  - there are changes not in the index
GIT_DOT_CONFLICT_COLOR="#ff3333"  # Red    - merge conflict / mid rebase-merge
                                  #          (set equal to white to keep 3 colors)

# Upstream (ahead/behind remote) colors
GIT_AHEAD_COLOR="#8a8a8a"      # Gray - local commits to push
GIT_BEHIND_COLOR="#8a8a8a"     # Gray - remote commits to pull

# Symbols (Nerd Font code points, same style as v1)
USER_ICON=$'\uf2be'           # Nerd Font icon for the user
GIT_BRANCH_ICON=$'\ueb86'     # Nerd Font icon for the Git branch
FOLDER_ICON=$'\uea83'         # Nerd Font icon for the folder
DIRTY_STATUS_ICON=$'\u25cb'   # Hollow circle - working-tree state indicator (see dot colors)
                              # alt: \u25ef \u25ef (bigger) | \u2b21 \u2b21 | filled \u25cf \u25cf | nf  \uf10c
GIT_ADD_SYMBOL="+"           # Prefix for additions
GIT_DEL_SYMBOL="-"           # Prefix for deletions
GIT_UNTRACKED_SYMBOL="?"     # Prefix for untracked files
GIT_COUNT_SEP="|"            # Separator between file count and row count
GIT_AHEAD_ICON=$'\u2191'          # Ahead of upstream  (alt: ⇡    )
GIT_BEHIND_ICON=$'\u2193'         # Behind upstream    (alt: ⇣    )

# Input prompt arrow - Nerd Font glyph. Swap the code below to taste:
#       chevron-right              (current)
#       powerline filled triangle
#       powerline thin arrow
#       fa arrow-right
#       oct arrow-right
#       fa long-arrow-right
PROMPT_ARROW=$'\uf054'

# Check if the current directory is a Git repository and display its status
git_info() {
    command git rev-parse --is-inside-work-tree &>/dev/null || return

    local branch numstat parsed porcelain line x y
    local files_add=0 rows_add=0 files_del=0 rows_del=0 untracked=0
    local has_staged=0 has_unstaged=0 has_conflict=0
    local ahead=0 behind=0 upstream counts
    local dot_color arrows segs

    branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "detached")

    # --- line/file counters: staged + unstaged vs last commit --------------
    if git rev-parse --verify --quiet HEAD >/dev/null; then
        numstat=$(git diff HEAD --numstat 2>/dev/null)
    else
        numstat=$(git diff --cached --numstat 2>/dev/null)
    fi
    if [[ -n $numstat ]]; then
        parsed=$(awk '
            $1 ~ /^[0-9]+$/ && $1 > 0 { fa++; ra += $1 }
            $2 ~ /^[0-9]+$/ && $2 > 0 { fd++; rd += $2 }
            END { printf "%d %d %d %d", fa+0, ra+0, fd+0, rd+0 }
        ' <<< "$numstat")
        files_add=${parsed[(w)1]} rows_add=${parsed[(w)2]}
        files_del=${parsed[(w)3]} rows_del=${parsed[(w)4]}
    fi

    # --- working-tree state (drives the dot color) ------------------------
    porcelain=$(git status --porcelain 2>/dev/null)
    while IFS= read -r line; do
        [[ -z $line ]] && continue
        x=${line[1]} y=${line[2]}
        if [[ $x == '?' && $y == '?' ]]; then
            (( untracked++ ))
            continue
        fi
        # conflict markers: any U, or AA / DD
        if [[ $x == 'U' || $y == 'U' || $x$y == 'AA' || $x$y == 'DD' ]]; then
            has_conflict=1
        fi
        [[ $x != ' ' ]] && has_staged=1
        [[ $y != ' ' ]] && has_unstaged=1
    done <<< "$porcelain"

    if (( has_conflict )); then
        dot_color=$GIT_DOT_CONFLICT_COLOR
    elif (( has_unstaged || untracked > 0 )); then
        dot_color=$GIT_DOT_UNSTAGED_COLOR      # something is not in the index
    elif (( has_staged )); then
        dot_color=$GIT_DOT_STAGED_COLOR        # all changes staged, ready
    else
        dot_color=$GIT_DOT_CLEAN_COLOR         # clean
    fi

    # --- upstream ahead / behind -----------------------------------------
    upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null)
    if [[ -n $upstream ]]; then
        counts=$(git rev-list --left-right --count 'HEAD...@{upstream}' 2>/dev/null)
        ahead=${counts%%[[:space:]]*}
        behind=${counts##*[[:space:]]}
        [[ $ahead  == <-> ]] || ahead=0
        [[ $behind == <-> ]] || behind=0
    fi
    arrows=""
    (( ahead  > 0 )) && arrows+=" %F{$GIT_AHEAD_COLOR}${GIT_AHEAD_ICON}${ahead}%f"
    (( behind > 0 )) && arrows+=" %F{$GIT_BEHIND_COLOR}${GIT_BEHIND_ICON}${behind}%f"

    # --- diff counters, only what actually exists ------------------------
    segs=()
    (( rows_add  > 0 )) && segs+=("%F{$GIT_ADD_COLOR}${GIT_ADD_SYMBOL}${files_add}${GIT_COUNT_SEP}${rows_add}%f")
    (( rows_del  > 0 )) && segs+=("%F{$GIT_DEL_COLOR}${GIT_DEL_SYMBOL}${files_del}${GIT_COUNT_SEP}${rows_del}%f")
    (( untracked > 0 )) && segs+=("%F{$GIT_UNTRACKED_COLOR}${GIT_UNTRACKED_SYMBOL}${untracked}%f")

    local counters=""
    (( ${#segs} > 0 )) && counters=" ${(j: :)segs}"

    echo "%F{$BRANCH_COLOR}${GIT_BRANCH_ICON} %F{$BRANCH_COLOR}${branch}%f${arrows} %F{$dot_color}${DIRTY_STATUS_ICON}%f${counters}"
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
%F{$PROMPT_COLOR}${PROMPT_ARROW}%f '  # White input arrow
RPROMPT="$(cmd_exec_time)" # Displays command execution time
