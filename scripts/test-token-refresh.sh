#!/bin/bash
#
# Token Refresh Flow Test Script
# Tests the complete token automation workflow
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

print_msg() {
    local color="$1"
    shift
    echo -e "${color}$*${NC}"
}

print_header() {
    echo ""
    print_msg "$BLUE" "=========================================="
    print_msg "$BLUE" "$1"
    print_msg "$BLUE" "=========================================="
}

print_test() {
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    print_msg "$CYAN" "[TEST $TESTS_TOTAL] $1"
}

pass() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    print_msg "$GREEN" "  ✓ PASS: $1"
}

fail() {
    TESTS_FAILED=$((TESTS_FAILED + 1))
    print_msg "$RED" "  ✗ FAIL: $1"
}

warn() {
    print_msg "$YELLOW" "  ⚠ WARN: $1"
}

info() {
    print_msg "$BLUE" "  ℹ INFO: $1"
}

# Start testing
print_header "Token Refresh Flow - Integration Test"

# Test 1: Check file structure
print_test "Checking project file structure"

if [ ! -f "src/claude/claude-kiro.js" ]; then
    fail "claude-kiro.js not found"
else
    pass "claude-kiro.js exists"
fi

if [ ! -f "src/adapter.js" ]; then
    fail "adapter.js not found"
else
    pass "adapter.js exists"
fi

if [ ! -f "src/provider-pool-manager.js" ]; then
    fail "provider-pool-manager.js not found"
else
    pass "provider-pool-manager.js exists"
fi

if [ ! -f "src/ui-manager.js" ]; then
    fail "ui-manager.js not found"
else
    pass "ui-manager.js exists"
fi

if [ ! -f "static/index.html" ]; then
    fail "index.html not found"
else
    pass "index.html exists"
fi

if [ ! -f "scripts/sync-tokens.sh" ]; then
    fail "sync-tokens.sh not found"
else
    pass "sync-tokens.sh exists"
fi

# Test 2: Check Phase 1.1 implementation
print_test "Verifying Phase 1.1: claude-kiro.js modifications"

if grep -q "refreshTokenExpiresAt" src/claude/claude-kiro.js; then
    pass "refreshTokenExpiresAt field added"
else
    fail "refreshTokenExpiresAt field not found"
fi

if grep -q "refreshTokenFailedAt" src/claude/claude-kiro.js; then
    pass "refreshTokenFailedAt field added"
else
    fail "refreshTokenFailedAt field not found"
fi

if grep -q "isRefreshTokenNearExpiry" src/claude/claude-kiro.js; then
    pass "isRefreshTokenNearExpiry method added"
else
    fail "isRefreshTokenNearExpiry method not found"
fi

if grep -q "error.response?.status === 400" src/claude/claude-kiro.js; then
    pass "400 error detection implemented"
else
    fail "400 error detection not found"
fi

# Test 3: Check Phase 1.2 implementation
print_test "Verifying Phase 1.2: adapter.js modifications"

if grep -q "EventEmitter" src/adapter.js; then
    pass "EventEmitter imported"
else
    fail "EventEmitter not imported"
fi

if grep -q "eventEmitter" src/adapter.js; then
    pass "eventEmitter instance created"
else
    fail "eventEmitter instance not found"
fi

if grep -q "_handleTokenError" src/adapter.js; then
    pass "_handleTokenError method added"
else
    fail "_handleTokenError method not found"
fi

if grep -q "onRefreshTokenExpiry" src/adapter.js; then
    pass "onRefreshTokenExpiry method added"
else
    fail "onRefreshTokenExpiry method not found"
fi

# Test 4: Check Phase 2 implementation
print_test "Verifying Phase 2: provider-pool-manager.js modifications"

if grep -q "needsReauth" src/provider-pool-manager.js; then
    pass "needsReauth field added"
else
    fail "needsReauth field not found"
fi

if grep -q "markProviderNeedsReauth" src/provider-pool-manager.js; then
    pass "markProviderNeedsReauth method added"
else
    fail "markProviderNeedsReauth method not found"
fi

if grep -q "getProvidersNeedingReauth" src/provider-pool-manager.js; then
    pass "getProvidersNeedingReauth method added"
else
    fail "getProvidersNeedingReauth method not found"
fi

if grep -q "_subscribeToAdapterEvents" src/provider-pool-manager.js; then
    pass "_subscribeToAdapterEvents method added"
else
    fail "_subscribeToAdapterEvents method not found"
fi

if grep -q "setBroadcastEventHandler" src/provider-pool-manager.js; then
    pass "setBroadcastEventHandler function added"
else
    fail "setBroadcastEventHandler function not found"
fi

# Filter out needsReauth providers
if grep -q "!p.config.needsReauth" src/provider-pool-manager.js; then
    pass "Provider selection filters out needsReauth providers"
else
    fail "Provider selection does not filter needsReauth"
fi

# Test 5: Check Phase 3.1 implementation
print_test "Verifying Phase 3.1: ui-manager.js API endpoints"

if grep -q "/api/providers-needing-reauth" src/ui-manager.js; then
    pass "/api/providers-needing-reauth endpoint added"
else
    fail "/api/providers-needing-reauth endpoint not found"
fi

if grep -q "/api/provider-reauth-complete" src/ui-manager.js; then
    pass "/api/provider-reauth-complete endpoint added"
else
    fail "/api/provider-reauth-complete endpoint not found"
fi

if grep -q "setBroadcastEventHandler" src/service-manager.js; then
    pass "Broadcast handler configured in service-manager.js"
else
    fail "Broadcast handler not configured in service-manager.js"
fi

# Test 6: Check Phase 3.2 implementation
print_test "Verifying Phase 3.2: Frontend UI components"

if grep -q "tokenExpiryModal" static/index.html; then
    pass "Token expiry modal HTML added"
else
    fail "Token expiry modal HTML not found"
fi

if grep -q "token_expiry" static/index.html; then
    pass "SSE token_expiry event listener added"
else
    fail "SSE token_expiry event listener not found"
fi

if grep -q "reauth_complete" static/index.html; then
    pass "SSE reauth_complete event listener added"
else
    fail "SSE reauth_complete event listener not found"
fi

if grep -q "handleReauth" static/index.html; then
    pass "Re-authorization handler added"
else
    fail "Re-authorization handler not found"
fi

if [ -f "static/app/styles.css" ]; then
    if grep -q "modal-content" static/app/styles.css; then
        pass "Modal CSS styles added"
    else
        fail "Modal CSS styles not found"
    fi
else
    warn "styles.css not found"
fi

# Test 7: Check Phase 4 implementation
print_test "Verifying Phase 4: Git sync scripts"

if [ -x "scripts/sync-tokens.sh" ]; then
    pass "sync-tokens.sh is executable"
else
    fail "sync-tokens.sh is not executable"
fi

if [ -f "scripts/README.md" ]; then
    pass "Documentation README.md exists"
else
    fail "Documentation README.md not found"
fi

if [ -f "scripts/token-sync.env.example" ]; then
    pass "Environment template exists"
else
    fail "Environment template not found"
fi

if [ -f "scripts/systemd/token-sync.service" ]; then
    pass "Systemd service file exists"
else
    fail "Systemd service file not found"
fi

if [ -f "scripts/systemd/token-sync.timer" ]; then
    pass "Systemd timer file exists"
else
    fail "Systemd timer file not found"
fi

# Test sync script functionality
if ./scripts/sync-tokens.sh help > /dev/null 2>&1; then
    pass "sync-tokens.sh help command works"
else
    fail "sync-tokens.sh help command failed"
fi

# Test 8: Check configuration compatibility
print_test "Checking configuration file compatibility"

if [ -f "configs/config.json" ]; then
    info "Config file exists, checking structure..."

    if command -v jq &> /dev/null; then
        if jq -e . configs/config.json > /dev/null 2>&1; then
            pass "config.json is valid JSON"
        else
            fail "config.json is invalid JSON"
        fi
    else
        warn "jq not installed, skipping JSON validation"
    fi
else
    warn "configs/config.json not found (may not be initialized yet)"
fi

# Test 9: Check Node.js dependencies
print_test "Checking Node.js environment"

if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    pass "Node.js installed: $NODE_VERSION"
else
    fail "Node.js not installed"
fi

if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    pass "npm installed: $NPM_VERSION"
else
    fail "npm not installed"
fi

if [ -f "package.json" ]; then
    pass "package.json exists"

    if [ -d "node_modules" ]; then
        pass "node_modules exists (dependencies installed)"
    else
        warn "node_modules not found (run npm install)"
    fi
else
    fail "package.json not found"
fi

# Test 10: Check Git configuration
print_test "Checking Git environment"

if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version)
    pass "Git installed: $GIT_VERSION"
else
    fail "Git not installed"
fi

if git rev-parse --git-dir > /dev/null 2>&1; then
    pass "Git repository initialized"

    if git config user.name > /dev/null 2>&1; then
        GIT_USER=$(git config user.name)
        pass "Git user.name configured: $GIT_USER"
    else
        warn "Git user.name not configured"
    fi

    if git config user.email > /dev/null 2>&1; then
        GIT_EMAIL=$(git config user.email)
        pass "Git user.email configured: $GIT_EMAIL"
    else
        warn "Git user.email not configured"
    fi

    if git remote get-url origin > /dev/null 2>&1; then
        GIT_REMOTE=$(git remote get-url origin)
        pass "Git remote configured: $GIT_REMOTE"
    else
        warn "Git remote not configured"
    fi
else
    warn "Git repository not initialized"
fi

# Test 11: Check directory structure
print_test "Checking directory structure"

REQUIRED_DIRS=(
    "src"
    "static"
    "static/app"
    "scripts"
    "configs"
    "logs"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        pass "Directory exists: $dir"
    else
        fail "Directory missing: $dir"
    fi
done

# Test 12: Check log files
print_test "Checking log configuration"

if [ -d "logs" ]; then
    if [ -w "logs" ]; then
        pass "logs directory is writable"
    else
        fail "logs directory is not writable"
    fi
else
    warn "logs directory does not exist (will be created automatically)"
fi

# Test 13: Security check
print_test "Security configuration check"

if [ -f ".gitignore" ]; then
    pass ".gitignore exists"

    if grep -q "\.env" .gitignore; then
        pass ".env excluded from Git"
    else
        warn ".env not excluded from Git (security risk)"
    fi

    if grep -q "configs/pwd" .gitignore; then
        pass "configs/pwd excluded from Git"
    else
        warn "configs/pwd not excluded from Git (security risk)"
    fi
else
    fail ".gitignore not found"
fi

# Summary
print_header "Test Summary"

echo ""
print_msg "$CYAN" "Total Tests: $TESTS_TOTAL"
print_msg "$GREEN" "Passed:      $TESTS_PASSED"
print_msg "$RED" "Failed:      $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    print_msg "$GREEN" "=========================================="
    print_msg "$GREEN" "ALL TESTS PASSED! ✓"
    print_msg "$GREEN" "=========================================="
    echo ""
    print_msg "$BLUE" "Next Steps:"
    echo "  1. Start the server: npm start"
    echo "  2. Access UI: http://localhost:3000"
    echo "  3. Configure OAuth providers"
    echo "  4. Test token refresh workflow"
    echo "  5. Setup Git sync: ./scripts/setup-sync.sh"
    echo ""
    exit 0
else
    print_msg "$RED" "=========================================="
    print_msg "$RED" "SOME TESTS FAILED! ✗"
    print_msg "$RED" "=========================================="
    echo ""
    print_msg "$YELLOW" "Please review failed tests above and fix issues."
    echo ""
    exit 1
fi
