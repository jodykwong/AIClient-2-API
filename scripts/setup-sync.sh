#!/bin/bash
#
# Setup Token Sync - Interactive setup wizard
# Helps configure Git repository and cron jobs for token synchronization
#

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_msg() {
    local color="$1"
    shift
    echo -e "${color}$*${NC}"
}

print_header() {
    echo ""
    print_msg "$BLUE" "=================================================="
    print_msg "$BLUE" "$1"
    print_msg "$BLUE" "=================================================="
    echo ""
}

# Check if git is installed
if ! command -v git &> /dev/null; then
    print_msg "$RED" "Error: Git is not installed"
    echo "Please install git first:"
    echo "  Ubuntu/Debian: sudo apt-get install git"
    echo "  CentOS/RHEL:   sudo yum install git"
    echo "  macOS:         brew install git"
    exit 1
fi

print_header "AIClient2API Token Sync Setup"

# Step 1: Check if already in a git repository
if git rev-parse --git-dir > /dev/null 2>&1; then
    print_msg "$GREEN" "✓ Already in a Git repository"
    REPO_INITIALIZED=true
else
    print_msg "$YELLOW" "Git repository not initialized"
    read -p "Initialize Git repository? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git init
        print_msg "$GREEN" "✓ Git repository initialized"
        REPO_INITIALIZED=true
    else
        print_msg "$RED" "Cannot continue without Git repository"
        exit 1
    fi
fi

# Step 2: Configure Git user
print_header "Git User Configuration"

if ! git config user.name > /dev/null 2>&1; then
    read -p "Enter Git user name [Token Sync Bot]: " git_user_name
    git_user_name=${git_user_name:-"Token Sync Bot"}
    git config user.name "$git_user_name"
    print_msg "$GREEN" "✓ Set user.name: $git_user_name"
else
    current_name=$(git config user.name)
    print_msg "$GREEN" "✓ Git user.name already set: $current_name"
fi

if ! git config user.email > /dev/null 2>&1; then
    read -p "Enter Git user email [token-sync@localhost]: " git_user_email
    git_user_email=${git_user_email:-"token-sync@localhost"}
    git config user.email "$git_user_email"
    print_msg "$GREEN" "✓ Set user.email: $git_user_email"
else
    current_email=$(git config user.email)
    print_msg "$GREEN" "✓ Git user.email already set: $current_email"
fi

# Step 3: Configure Git remote
print_header "Git Remote Configuration"

if git remote get-url origin > /dev/null 2>&1; then
    remote_url=$(git remote get-url origin)
    print_msg "$GREEN" "✓ Git remote 'origin' already configured: $remote_url"
else
    print_msg "$YELLOW" "Git remote not configured"
    echo "Enter your Git repository URL (e.g., git@github.com:user/repo.git):"
    read -p "Remote URL: " remote_url

    if [ -n "$remote_url" ]; then
        git remote add origin "$remote_url"
        print_msg "$GREEN" "✓ Added remote 'origin': $remote_url"
    else
        print_msg "$YELLOW" "⚠ No remote configured - you can add it later with:"
        echo "  git remote add origin <your-repo-url>"
    fi
fi

# Step 4: Create .gitignore if needed
print_header "GitIgnore Configuration"

if [ -f .gitignore ]; then
    print_msg "$GREEN" "✓ .gitignore already exists"
else
    cat > .gitignore << 'EOF'
# Node modules
node_modules/
package-lock.json

# Logs
*.log
logs/
*.log.*

# Environment files
.env
.env.*

# Sensitive configs (DO NOT sync these)
configs/pwd
configs/config.json
configs/provider_pools.json
configs/token-store.json

# OS files
.DS_Store
Thumbs.db

# Token files (explicitly include for sync)
!configs/kiro/**/*.json
!configs/gemini/**/*.json
!configs/qwen/**/*.json
!configs/antigravity/**/*.json
EOF
    print_msg "$GREEN" "✓ Created .gitignore"
fi

# Step 5: Test sync script
print_header "Testing Sync Script"

if [ -x scripts/sync-tokens.sh ]; then
    print_msg "$GREEN" "✓ Sync script is executable"
else
    chmod +x scripts/sync-tokens.sh
    print_msg "$GREEN" "✓ Made sync script executable"
fi

# Test help command
if ./scripts/sync-tokens.sh help > /dev/null 2>&1; then
    print_msg "$GREEN" "✓ Sync script working correctly"
else
    print_msg "$RED" "✗ Sync script test failed"
fi

# Step 6: Configure automation
print_header "Automation Setup"

echo "How would you like to automate token synchronization?"
echo "  1) Cron job (traditional, works on all systems)"
echo "  2) Systemd timer (modern, better logging)"
echo "  3) Manual (I'll set it up myself)"
read -p "Choose option [1-3]: " automation_choice

case $automation_choice in
    1)
        print_msg "$BLUE" "Setting up Cron job..."

        # Check if cron entry already exists
        if crontab -l 2>/dev/null | grep -q "sync-tokens.sh"; then
            print_msg "$YELLOW" "Cron job already exists"
        else
            # Add cron job
            CRON_JOB="*/15 * * * * cd $(pwd) && ./scripts/sync-tokens.sh sync >> logs/cron-sync.log 2>&1"
            (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
            print_msg "$GREEN" "✓ Added cron job (runs every 15 minutes)"
        fi

        print_msg "$BLUE" "View cron jobs: crontab -l"
        print_msg "$BLUE" "Remove cron job: crontab -e"
        ;;
    2)
        print_msg "$BLUE" "Setting up Systemd timer..."

        if [ ! -f /etc/systemd/system/token-sync.service ]; then
            echo "Systemd setup requires root access"
            echo "Run these commands to install:"
            echo "  sudo cp scripts/systemd/token-sync.service /etc/systemd/system/"
            echo "  sudo cp scripts/systemd/token-sync.timer /etc/systemd/system/"
            echo "  sudo systemctl daemon-reload"
            echo "  sudo systemctl enable token-sync.timer"
            echo "  sudo systemctl start token-sync.timer"
            print_msg "$YELLOW" "⚠ Manual installation required (needs root)"
        else
            print_msg "$GREEN" "✓ Systemd service already installed"
        fi
        ;;
    3)
        print_msg "$YELLOW" "Manual setup selected"
        echo "You can run sync manually with:"
        echo "  ./scripts/sync-tokens.sh sync"
        ;;
    *)
        print_msg "$YELLOW" "Invalid option, skipping automation setup"
        ;;
esac

# Step 7: Summary and next steps
print_header "Setup Complete!"

echo "✓ Git repository configured"
echo "✓ Sync script ready"
echo ""
echo "Next steps:"
echo "  1. Test the sync: ./scripts/sync-tokens.sh sync"
echo "  2. Configure OAuth providers in the web UI"
echo "  3. After re-authorization, tokens will sync automatically"
echo ""
echo "Documentation:"
echo "  scripts/README.md - Detailed usage guide"
echo ""
echo "Monitoring:"
echo "  tail -f logs/token-sync.log - Watch sync logs"
echo "  git log -- configs/ - View sync history"
echo ""

print_msg "$GREEN" "Happy syncing! 🚀"
