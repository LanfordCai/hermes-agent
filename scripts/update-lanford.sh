#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'EOF'
Usage: scripts/update-lanford.sh [branch]

Rebase the local branch onto upstream/main, push it to origin, and refresh the
editable local install.

Defaults:
  branch   lanford

Environment overrides:
  HERMES_UPDATE_BRANCH    Branch to update (same as positional arg)
  HERMES_ORIGIN_REMOTE    Push remote (default: origin)
  HERMES_UPSTREAM_REMOTE  Upstream remote (default: upstream)
EOF
  exit 0
fi

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "error: missing required command: $1" >&2
    exit 1
  fi
}

need_cmd git
need_cmd uv

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BRANCH="${1:-${HERMES_UPDATE_BRANCH:-lanford}}"
ORIGIN_REMOTE="${HERMES_ORIGIN_REMOTE:-origin}"
UPSTREAM_REMOTE="${HERMES_UPSTREAM_REMOTE:-upstream}"

cd "$ROOT"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "error: working tree is dirty. Commit or stash changes before updating." >&2
  git status --short
  exit 1
fi

git fetch --prune "$UPSTREAM_REMOTE" "$ORIGIN_REMOTE"
git switch "$BRANCH"
git rebase "$UPSTREAM_REMOTE/main"
git submodule update --init --recursive
git push --force-with-lease "$ORIGIN_REMOTE" "$BRANCH"

"$ROOT/scripts/install-local.sh"

cat <<EOF
Updated $BRANCH from $UPSTREAM_REMOTE/main and pushed to $ORIGIN_REMOTE/$BRANCH.

If Hermes gateway is running, restart it:
  hermes gateway restart
EOF
