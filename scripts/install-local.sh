#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'EOF'
Usage: scripts/install-local.sh

Bootstrap this checkout as a local editable Hermes install.

Environment overrides:
  VENV_DIR        Virtualenv path (default: <repo>/venv)
  PYTHON_VERSION  Python version for uv venv (default: 3.11)
EOF
  exit 0
fi

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "error: missing required command: $1" >&2
    exit 1
  fi
}

need_cmd uv
need_cmd git

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
VENV_DIR="${VENV_DIR:-$ROOT/venv}"
PYTHON_VERSION="${PYTHON_VERSION:-3.11}"

mkdir -p "${HOME}/.local/bin"

cd "$ROOT"
if [[ ! -x "$VENV_DIR/bin/python" ]]; then
  uv venv "$VENV_DIR" --python "$PYTHON_VERSION"
fi
export VIRTUAL_ENV="$VENV_DIR"
uv pip install -e '.[messaging,cli,cron]' socksio

ln -sf "$VENV_DIR/bin/hermes" "${HOME}/.local/bin/hermes"

cat <<EOF
Local Hermes install is ready.

Repo:    $ROOT
Venv:    $VENV_DIR
Binary:  ${HOME}/.local/bin/hermes

If your shell doesn't see the updated binary yet, run:
  hash -r
EOF
