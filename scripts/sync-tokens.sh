#!/bin/bash
#
# Token Synchronization Script
# Automatically syncs token files to/from Git repository
#
# Usage:
#   ./sync-tokens.sh pull    # Pull latest tokens from Git
#   ./sync-tokens.sh push    # Push local tokens to Git
#   ./sync-tokens.sh sync    # Full sync (pull, then push if changes)
#
# Environment Variables:
#   TOKEN_SYNC_REPO     - Git repository path (default: current directory)
#   TOKEN_SYNC_BRANCH   - Git branch name (default: main)
#   TOKEN_SYNC_REMOTE   - Git remote name (default: origin)
#   TOKEN_SYNC_PATHS    - Paths to sync (default: configs/kiro configs/gemini)
#   TOKEN_SYNC_LOG      - Log file path (default: logs/token-sync.log)
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration with defaults
REPO_PATH="${TOKEN_SYNC_REPO:-$(pwd)}"
BRANCH="${TOKEN_SYNC_BRANCH:-main}"
REMOTE="${TOKEN_SYNC_REMOTE:-origin}"
SYNC_PATHS="${TOKEN_SYNC_PATHS:-configs/kiro configs/gemini configs/qwen configs/antigravity}"
LOG_FILE="${TOKEN_SYNC_LOG:-logs/token-sync.log}"
MAX_LOG_SIZE=10485760  # 10MB

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" | tee -a "$LOG_FILE"
}

# Rotate log if too large
rotate_log_if_needed() {
    if [ -f "$LOG_FILE" ]; then
        local size=$(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)
        if [ "$size" -gt "$MAX_LOG_SIZE" ]; then
            log "INFO" "Rotating log file (size: ${size} bytes)"
            mv "$LOG_FILE" "${LOG_FILE}.old"
            touch "$LOG_FILE"
        fi
    fi
}

# Print colored message
print_msg() {
    local color="$1"
    shift
    echo -e "${color}$*${NC}"
}

# Error handler
error_exit() {
    log "ERROR" "$1"
    print_msg "$RED" "ERROR: $1"
    exit 1
}

# Check if git is installed
check_git() {
    if ! command -v git &> /dev/null; then
        error_exit "Git is not installed. Please install git first."
    fi
}

# Check if we're in a git repository
check_git_repo() {
    cd "$REPO_PATH" || error_exit "Repository path does not exist: $REPO_PATH"

    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        error_exit "Not a git repository: $REPO_PATH"
    fi
}

# Configure git if needed
configure_git() {
    # Check if user.name and user.email are set
    if ! git config user.name > /dev/null 2>&1; then
        log "WARN" "Git user.name not set, configuring default"
        git config user.name "Token Sync Bot"
    fi

    if ! git config user.email > /dev/null 2>&1; then
        log "WARN" "Git user.email not set, configuring default"
        git config user.email "token-sync@localhost"
    fi
}

# Check if paths exist
check_sync_paths() {
    local missing_paths=()

    for path in $SYNC_PATHS; do
        if [ ! -e "$path" ]; then
            missing_paths+=("$path")
        fi
    done

    if [ ${#missing_paths[@]} -gt 0 ]; then
        log "WARN" "Some sync paths do not exist: ${missing_paths[*]}"
        print_msg "$YELLOW" "Warning: Some paths do not exist yet: ${missing_paths[*]}"
    fi
}

# Stash local changes
stash_changes() {
    log "INFO" "Stashing local changes..."

    if git diff --quiet && git diff --cached --quiet; then
        log "INFO" "No local changes to stash"
        echo "0"
        return 0
    fi

    git stash push -m "token-sync: auto-stash $(date '+%Y-%m-%d %H:%M:%S')" > /dev/null 2>&1
    echo "1"
}

# Pop stashed changes
pop_stash() {
    local had_stash="$1"

    if [ "$had_stash" = "1" ]; then
        log "INFO" "Restoring stashed changes..."
        if ! git stash pop > /dev/null 2>&1; then
            log "WARN" "Failed to pop stash, conflicts may exist"
            print_msg "$YELLOW" "Warning: Stash pop failed, you may need to resolve conflicts manually"
        fi
    fi
}

# Pull latest changes from remote
pull_tokens() {
    log "INFO" "Pulling latest token changes from $REMOTE/$BRANCH..."
    print_msg "$BLUE" "Pulling latest changes from Git..."

    # Fetch latest changes
    if ! git fetch "$REMOTE" "$BRANCH" 2>&1 | tee -a "$LOG_FILE"; then
        error_exit "Failed to fetch from remote: $REMOTE/$BRANCH"
    fi

    # Check if we're behind
    LOCAL=$(git rev-parse @ 2>/dev/null || echo "")
    REMOTE_REV=$(git rev-parse "$REMOTE/$BRANCH" 2>/dev/null || echo "")

    if [ "$LOCAL" = "$REMOTE_REV" ]; then
        log "INFO" "Already up to date"
        print_msg "$GREEN" "✓ Already up to date"
        return 0
    fi

    # Stash local changes
    had_stash=$(stash_changes)

    # Pull with rebase to avoid merge commits
    log "INFO" "Rebasing local changes on top of remote..."
    if ! git pull --rebase "$REMOTE" "$BRANCH" 2>&1 | tee -a "$LOG_FILE"; then
        log "ERROR" "Pull failed, attempting abort..."
        git rebase --abort 2>/dev/null || true
        pop_stash "$had_stash"
        error_exit "Failed to pull changes. Please resolve conflicts manually."
    fi

    # Restore stashed changes
    pop_stash "$had_stash"

    log "INFO" "Successfully pulled latest changes"
    print_msg "$GREEN" "✓ Successfully pulled latest changes"
}

# Check if there are changes to commit
has_changes() {
    # Check only the specified sync paths
    for path in $SYNC_PATHS; do
        if [ -e "$path" ]; then
            if ! git diff --quiet -- "$path" 2>/dev/null || \
               ! git diff --cached --quiet -- "$path" 2>/dev/null || \
               [ -n "$(git ls-files --others --exclude-standard -- "$path" 2>/dev/null)" ]; then
                return 0
            fi
        fi
    done
    return 1
}

# Commit local changes
commit_changes() {
    local commit_msg="$1"

    log "INFO" "Staging changes in: $SYNC_PATHS"

    # Add only the specified paths
    for path in $SYNC_PATHS; do
        if [ -e "$path" ]; then
            git add "$path" 2>&1 | tee -a "$LOG_FILE" || true
        fi
    done

    # Check if there are staged changes
    if git diff --cached --quiet; then
        log "INFO" "No changes to commit"
        return 1
    fi

    # Create commit
    log "INFO" "Creating commit: $commit_msg"
    if ! git commit -m "$commit_msg" 2>&1 | tee -a "$LOG_FILE"; then
        error_exit "Failed to create commit"
    fi

    return 0
}

# Push changes to remote
push_tokens() {
    log "INFO" "Pushing token changes to $REMOTE/$BRANCH..."
    print_msg "$BLUE" "Checking for local changes..."

    # Check for changes
    if ! has_changes; then
        log "INFO" "No changes to push"
        print_msg "$GREEN" "✓ No changes to push"
        return 0
    fi

    # Commit changes
    local commit_msg="chore: update tokens - $(date '+%Y-%m-%d %H:%M:%S')"
    if commit_changes "$commit_msg"; then
        print_msg "$GREEN" "✓ Changes committed"
    else
        log "INFO" "No new commits created"
        print_msg "$GREEN" "✓ No new commits needed"
        return 0
    fi

    # Push to remote
    log "INFO" "Pushing to $REMOTE/$BRANCH..."
    print_msg "$BLUE" "Pushing changes to Git..."

    if ! git push "$REMOTE" "$BRANCH" 2>&1 | tee -a "$LOG_FILE"; then
        error_exit "Failed to push to remote: $REMOTE/$BRANCH"
    fi

    log "INFO" "Successfully pushed changes"
    print_msg "$GREEN" "✓ Successfully pushed changes to Git"
}

# Full sync: pull then push
sync_tokens() {
    log "INFO" "Starting full token sync..."
    print_msg "$BLUE" "=== Starting Full Token Sync ==="

    # Pull first
    pull_tokens

    # Then push if there are changes
    push_tokens

    log "INFO" "Full sync completed"
    print_msg "$GREEN" "=== Sync Completed Successfully ==="
}

# Show usage
show_usage() {
    cat << EOF
Token Synchronization Script

Usage: $0 <command>

Commands:
  pull    Pull latest token files from Git repository
  push    Commit and push local token changes to Git repository
  sync    Full synchronization (pull, then push if changes exist)
  help    Show this help message

Environment Variables:
  TOKEN_SYNC_REPO     Git repository path (default: current directory)
  TOKEN_SYNC_BRANCH   Git branch name (default: main)
  TOKEN_SYNC_REMOTE   Git remote name (default: origin)
  TOKEN_SYNC_PATHS    Paths to sync (default: configs/kiro configs/gemini)
  TOKEN_SYNC_LOG      Log file path (default: logs/token-sync.log)

Examples:
  # Pull latest tokens
  $0 pull

  # Push local changes
  $0 push

  # Full sync
  $0 sync

  # Custom configuration
  TOKEN_SYNC_BRANCH=tokens TOKEN_SYNC_REMOTE=upstream $0 sync

EOF
}

# Main execution
main() {
    local command="${1:-help}"

    # Rotate log if needed
    rotate_log_if_needed

    log "INFO" "========================================="
    log "INFO" "Token Sync Script Started - Command: $command"
    log "INFO" "Repository: $REPO_PATH"
    log "INFO" "Branch: $BRANCH"
    log "INFO" "Remote: $REMOTE"
    log "INFO" "Sync Paths: $SYNC_PATHS"
    log "INFO" "========================================="

    case "$command" in
        pull)
            check_git
            check_git_repo
            configure_git
            check_sync_paths
            pull_tokens
            ;;
        push)
            check_git
            check_git_repo
            configure_git
            check_sync_paths
            push_tokens
            ;;
        sync)
            check_git
            check_git_repo
            configure_git
            check_sync_paths
            sync_tokens
            ;;
        help|--help|-h)
            show_usage
            exit 0
            ;;
        *)
            print_msg "$RED" "Unknown command: $command"
            echo ""
            show_usage
            exit 1
            ;;
    esac

    log "INFO" "Token Sync Script Completed Successfully"
}

# Run main function
main "$@"
