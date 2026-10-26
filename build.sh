#!/usr/bin/env bash
# Installs REAL COPIES (not symlinks) of agent instructions into ~/.claude/
#
# Why copies: this checkout lives under $HOME/GitHubs. On Setonix, GitHubs is
# symlinked onto /scratch which is purged every 21 days. A symlink from
# ~/.claude/ into a purged path breaks silently. GitHub is the durable source
# of truth — rerun this script after any purge to reinstall.
#
# Usage:
#   agents/build.sh
#
# Run once after cloning. After that, `git pull` reinstalls automatically
# via the post-merge hook wired up on the first run.
#
# Personalisation (export in ~/.bashrc so the post-merge hook sees them):
#   AGENT_GH_OWNER      Your GitHub username (default: N-falk)
#   AGENT_HANDOFF_REPO  Your handoff repo, e.g. N-falk/agent-handoffs
#                       If unset, handoff features are disabled.

set -euo pipefail
cd "$(dirname "$0")"

AGENT_GH_OWNER="${AGENT_GH_OWNER:-N-falk}"
AGENT_HANDOFF_REPO="${AGENT_HANDOFF_REPO:-}"

echo "Installing agent instructions for: $AGENT_GH_OWNER"
echo "Handoff repo: ${AGENT_HANDOFF_REPO:-<unset — handoffs disabled>}"

stamp=$(date +%Y%m%d-%H%M%S)

install_file() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    # Back up any existing file that differs from what we're about to install
    if [ -f "$dst" ] && ! cmp -s "$src" "$dst"; then
        cp -p "$dst" "$dst.bak.$stamp"
        echo "  backed up existing $dst -> $dst.bak.$stamp"
    fi
    cp "$src" "$dst"
    echo "  installed $dst"
}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# Build ~/.claude/CLAUDE.md = AGENTS.md (shared base, personalised)
{
    echo "<!-- INSTALLED FILE — do not edit directly."
    echo "     Source: agents/AGENTS.md in N-falk/pawsey-agents on GitHub."
    echo "     Edit that file, commit, push, then rerun agents/build.sh. -->"
    echo ""
    cat AGENTS.md
    if [ -z "$AGENT_HANDOFF_REPO" ]; then
        echo ""
        echo "## Handoffs disabled on this install"
        echo ""
        echo "AGENT_HANDOFF_REPO was not set when build.sh ran."
        echo "Handoff features (ask-chatgpt / ask-claude skills) are not installed."
        echo "Set AGENT_HANDOFF_REPO in ~/.bashrc and rerun agents/build.sh to enable."
    fi
} > "$tmp/CLAUDE.md"

install_file "$tmp/CLAUDE.md" ~/.claude/CLAUDE.md

# Wire up post-merge git hook so `git pull` reinstalls automatically
git_dir=$(git rev-parse --git-dir 2>/dev/null || true)
if [ -n "$git_dir" ]; then
    hook_path="$git_dir/hooks/post-merge"
    # Write the hook inline (no separate hooks/ directory needed)
    cat > "$hook_path" << 'HOOK'
#!/usr/bin/env bash
# Auto-reinstall agent instructions after git pull
REPO_ROOT=$(git rev-parse --show-toplevel)
exec "$REPO_ROOT/agents/build.sh"
HOOK
    chmod +x "$hook_path"
    echo "  wired post-merge hook: git pull will now reinstall automatically"
fi

echo ""
echo "Done. ~/.claude/CLAUDE.md is installed."
echo "Rerun agents/build.sh after editing AGENTS.md, or just run 'git pull' once the hook is active."
