#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

fail() {
  echo "[preflight] ERROR: $1" >&2
  exit 1
}

echo "[preflight] Repo: $ROOT_DIR"
echo "[preflight] Date: $(date '+%Y-%m-%d %H:%M:%S %z')"
echo "[preflight] Branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"

[[ -f "PLAN.md" ]] || fail "Missing PLAN.md"
[[ -f "TASKS.md" ]] || fail "Missing TASKS.md"

echo "[preflight] Required files: PLAN.md, TASKS.md (ok)"

echo "[preflight] Working tree status:"
git status --short --branch

echo "[preflight] Done"
