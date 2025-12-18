#!/bin/bash
set -e

HOOKS_DIR=".git/hooks"
mkdir -p "$HOOKS_DIR"

echo ">>> [RSR] Installing Git Hooks..."

# --- PRE-COMMIT: Fast Checks & Robot Self-Healing ---
cat << 'EOF' > "$HOOKS_DIR/pre-commit"
#!/bin/bash
echo ">>> [Hook] Pre-Commit: Running Robot & Policy Check..."

# 1. Run Robot (Fixes directories, permissions, formatting)
just robot

# 2. Verify Nickel Policy (Fails if config is insecure)
just verify-policy

# Check if Robot modified files
if ! git diff --quiet; then
    echo "!!! [Robot] Modifications detected. Please stage them and commit again."
    exit 1
fi
EOF
chmod +x "$HOOKS_DIR/pre-commit"

# --- PRE-PUSH: Heavy Lifting (Build & Test) ---
cat << 'EOF' > "$HOOKS_DIR/pre-push"
#!/bin/bash
echo ">>> [Hook] Pre-Push: Running Full Build Cycle..."

# 1. Compile ReScript (No TS Allowed)
just compile

# 2. Build Container (Ensures Wolfi base is valid)
just build
EOF
chmod +x "$HOOKS_DIR/pre-push"

echo ">>> [RSR] Hooks Active. Robot will now guard your repo."
