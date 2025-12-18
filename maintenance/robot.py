#!/usr/bin/env python3
"""
robot-repo-bot: Automated Repository Maintenance
Stack: SaltStack (Local)
Constraint: Python Only
"""

import sys
import os

# Try to import salt, fail gracefully if this is a raw container without it yet
try:
    import salt.client
    import salt.config
    import salt.runner
except ImportError:
    print(">>> [Robot] SaltStack not found. Please run 'just bootstrap' first.")
    sys.exit(1)

def run_maintenance():
    print(">>> [Robot] Starting Local Maintenance Cycle...")
    
    # Initialize Local Client
    caller = salt.client.Caller()

    # 1. Enforce Directory Structure (State: file.directory)
    print("    - Verifying directory integrity...")
    dirs = ['dist/installers', 'config', 'container', 'scripts']
    for d in dirs:
        ret = caller.cmd('file.directory', [d], {'user': os.environ.get('USER'), 'makedirs': True})
        if not ret:
            print(f"      [!] Failed to create {d}")

    # 2. Prune Whitespace (State: file.replace)
    # Using 'ack' logic equivalent via Salt
    print("    - Pruning trailing whitespace in .adoc files...")
    caller.cmd('cmd.run', ["find . -name '*.adoc' -type f -exec sed -i 's/[ \t]*$//' {} +"])

    # 3. Check Permissions
    print("    - Enforcing executable permissions on scripts...")
    caller.cmd('file.set_mode', ['just'], {'mode': '0755'})
    
    print(">>> [Robot] Maintenance Complete. All systems nominal.")

if __name__ == "__main__":
    run_maintenance()
