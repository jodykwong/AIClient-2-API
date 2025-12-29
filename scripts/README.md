# Token Synchronization Script

This directory contains scripts for automating token synchronization via Git.

## Overview

The `sync-tokens.sh` script enables automatic synchronization of OAuth token files between multiple instances of AIClient-2-API using Git as a central repository. This is useful for:

- **Multi-node deployments**: Keep tokens in sync across multiple servers
- **Backup and recovery**: Automatically backup tokens to Git
- **Re-authorization workflows**: After user re-authorizes, sync tokens to other instances

## Prerequisites

1. **Git installed** on your system
2. **Git repository** initialized in your project directory
3. **Git remote** configured (e.g., GitHub, GitLab, private Git server)
4. **SSH keys or credentials** configured for Git authentication

## Quick Start

### 1. Initialize Git Repository (if not already done)

```bash
cd /path/to/AIClient-2-API
git init
git remote add origin <your-git-repo-url>
```

### 2. Configure Git User

```bash
git config user.name "Token Sync Bot"
git config user.email "token-sync@yourdomain.com"
```

### 3. Test the Script

```bash
# Pull latest tokens
./scripts/sync-tokens.sh pull

# Push local changes
./scripts/sync-tokens.sh push

# Full sync (pull + push)
./scripts/sync-tokens.sh sync
```

## Usage

### Commands

#### Pull Tokens from Git

```bash
./scripts/sync-tokens.sh pull
```

Downloads the latest token files from the Git repository. Uses rebase to avoid merge commits.

#### Push Tokens to Git

```bash
./scripts/sync-tokens.sh push
```

Commits and pushes local token changes to Git. Only commits files in configured sync paths.

#### Full Sync

```bash
./scripts/sync-tokens.sh sync
```

Performs a complete synchronization:
1. Pulls latest changes from Git
2. Commits local changes (if any)
3. Pushes commits to Git

## Configuration

The script can be configured via environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `TOKEN_SYNC_REPO` | Git repository path | Current directory |
| `TOKEN_SYNC_BRANCH` | Git branch name | `main` |
| `TOKEN_SYNC_REMOTE` | Git remote name | `origin` |
| `TOKEN_SYNC_PATHS` | Paths to sync (space-separated) | `configs/kiro configs/gemini` |
| `TOKEN_SYNC_LOG` | Log file path | `logs/token-sync.log` |

### Example with Custom Configuration

```bash
TOKEN_SYNC_BRANCH=tokens \
TOKEN_SYNC_REMOTE=upstream \
TOKEN_SYNC_PATHS="configs/kiro configs/gemini configs/qwen" \
./scripts/sync-tokens.sh sync
```

## Automation with Cron

### Automatic Pull (every 5 minutes)

Add to crontab to automatically pull token updates:

```bash
# Edit crontab
crontab -e

# Add this line to pull tokens every 5 minutes
*/5 * * * * cd /path/to/AIClient-2-API && ./scripts/sync-tokens.sh pull >> logs/cron-sync.log 2>&1
```

### Automatic Push (every 10 minutes)

Push local changes periodically:

```bash
*/10 * * * * cd /path/to/AIClient-2-API && ./scripts/sync-tokens.sh push >> logs/cron-sync.log 2>&1
```

### Full Sync (every 15 minutes)

Recommended for most use cases:

```bash
*/15 * * * * cd /path/to/AIClient-2-API && ./scripts/sync-tokens.sh sync >> logs/cron-sync.log 2>&1
```

### Example Crontab Configuration

```cron
# Token Sync - Full sync every 15 minutes
*/15 * * * * cd /home/user/AIClient-2-API && ./scripts/sync-tokens.sh sync >> logs/cron-sync.log 2>&1

# Alternative: Separate pull/push schedule
# Pull every 5 minutes (get updates from other nodes)
*/5 * * * * cd /home/user/AIClient-2-API && ./scripts/sync-tokens.sh pull >> logs/cron-sync.log 2>&1

# Push every 10 minutes (send local updates)
*/10 * * * * cd /home/user/AIClient-2-API && ./scripts/sync-tokens.sh push >> logs/cron-sync.log 2>&1
```

## Integration with Token Refresh Workflow

### Workflow Example

1. **User receives token expiry notification** in web UI
2. **User completes re-authorization** via OAuth popup
3. **New token is saved** to `configs/kiro/` or `configs/gemini/`
4. **Cron job runs** `sync-tokens.sh push`
5. **Token is pushed** to Git repository
6. **Other nodes run** `sync-tokens.sh pull` via cron
7. **All nodes updated** with new token

### Manual Trigger After Re-authorization

You can also trigger sync manually after token update:

```bash
# After re-authorization completes
./scripts/sync-tokens.sh push
```

Or set up a webhook/trigger in your application code:

```javascript
// In your Node.js application after successful OAuth
const { exec } = require('child_process');

async function syncTokensAfterReauth() {
    exec('./scripts/sync-tokens.sh push', (error, stdout, stderr) => {
        if (error) {
            console.error('Token sync failed:', error);
        } else {
            console.log('Tokens synced to Git:', stdout);
        }
    });
}
```

## Security Considerations

### 1. Git Repository Security

⚠️ **IMPORTANT**: Token files contain sensitive OAuth credentials.

**Recommendations:**
- Use a **private Git repository** (not public)
- Use **encrypted Git hosting** (GitHub private repo, self-hosted GitLab)
- Consider **Git-crypt** or **git-secret** for additional encryption
- Restrict repository access to authorized users only

### 2. Git Credentials

**Recommended Setup:**
- Use **SSH keys** instead of HTTPS passwords
- Use **deploy keys** with read/write access
- Store SSH keys securely with proper permissions (600)

### 3. Log File Security

Logs are stored in `logs/token-sync.log`:
- Review log permissions: `chmod 600 logs/token-sync.log`
- Rotate logs regularly (script auto-rotates at 10MB)
- Exclude logs from Git: Add `logs/` to `.gitignore`

### 4. .gitignore Configuration

Ensure your `.gitignore` excludes sensitive files that should NOT be synced:

```gitignore
# Exclude these from Git
node_modules/
*.log
.env
configs/pwd
configs/config.json
configs/provider_pools.json
configs/token-store.json

# Only include token files
!configs/kiro/**/*.json
!configs/gemini/**/*.json
!configs/qwen/**/*.json
!configs/antigravity/**/*.json
```

## Troubleshooting

### Conflict Resolution

If you encounter merge conflicts:

```bash
# The script will abort and show error
# Manually resolve conflicts:
git status
git diff

# After resolving:
git add .
git rebase --continue

# Or abort and restart:
git rebase --abort
```

### Stash Issues

If stash pop fails:

```bash
# List stashes
git stash list

# View stash content
git stash show

# Apply specific stash
git stash apply stash@{0}

# Drop stash after applying
git stash drop stash@{0}
```

### Permission Errors

If script fails with permission errors:

```bash
# Make script executable
chmod +x scripts/sync-tokens.sh

# Fix log directory permissions
mkdir -p logs
chmod 755 logs
```

### Git Authentication Errors

If Git authentication fails:

```bash
# Test SSH connection
ssh -T git@github.com

# Or configure credential helper for HTTPS
git config credential.helper store
```

## Monitoring

### Check Sync Status

```bash
# View recent sync logs
tail -f logs/token-sync.log

# Check last sync time
ls -lt configs/kiro/

# View Git sync history
git log --oneline --graph --all -- configs/
```

### Log Rotation

Logs automatically rotate when they exceed 10MB. Old logs are saved as `token-sync.log.old`.

To manually clear logs:

```bash
# Clear log file
> logs/token-sync.log

# Or remove old logs
rm logs/token-sync.log.old
```

## Advanced Usage

### Sync Specific Paths Only

```bash
# Sync only Kiro tokens
TOKEN_SYNC_PATHS="configs/kiro" ./scripts/sync-tokens.sh sync

# Sync multiple specific providers
TOKEN_SYNC_PATHS="configs/kiro configs/gemini" ./scripts/sync-tokens.sh push
```

### Use Different Branch for Tokens

```bash
# Create and switch to tokens branch
git checkout -b tokens

# Configure script to use tokens branch
TOKEN_SYNC_BRANCH=tokens ./scripts/sync-tokens.sh sync
```

### Dry Run (Testing)

To test without actually pushing:

```bash
# Check what would be committed
git add configs/kiro configs/gemini
git status
git diff --cached

# Unstage changes
git reset
```

## Best Practices

1. **Use dedicated Git branch** for tokens (e.g., `tokens` branch)
2. **Run sync after re-authorization** to immediately share new tokens
3. **Monitor sync logs** regularly for errors
4. **Test sync workflow** before production deployment
5. **Use cron for automation** but also support manual triggers
6. **Backup your Git repository** separately
7. **Document your sync schedule** for team awareness

## Support

For issues or questions about token synchronization:
- Check logs: `logs/token-sync.log`
- Review Git status: `git status`
- Test script manually: `./scripts/sync-tokens.sh sync`
- Consult Git documentation: https://git-scm.com/doc
