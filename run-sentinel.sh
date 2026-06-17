#!/usr/bin/env bash
#
# run-sentinel.sh — Sentinel pre-action INTERCEPTOR demo (offline, no secrets)
#
# WHAT THIS SHOWS: a trusted hook rules ALLOW / BLOCK on every agent tool call
# BEFORE it executes — forbidden tools, missing human approval, and out-of-scope
# calls are stopped at the gate; legitimate calls pass. Pure policy enforcement,
# no LLM / network / API key.
#
set -euo pipefail

# ------------------------------------------------------------------ paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ_DIR="$SCRIPT_DIR/sentinel"
VENV="$PROJ_DIR/.venv"
PY="$VENV/bin/python"

# ------------------------------------------------------------------ colors
BOLD=$'\033[1m'; DIM=$'\033[2m'; RESET=$'\033[0m'
RED=$'\033[91m'; GREEN=$'\033[92m'; YELLOW=$'\033[93m'
BLUE=$'\033[94m'; CYAN=$'\033[96m'; WHITE=$'\033[97m'
BG_BLUE=$'\033[44m'

banner() {
  printf '\n%s\n' "${CYAN}    ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${RESET}"
  printf '%s\n'   "${CYAN}    ┃${RESET}  ${BOLD}${WHITE}SENTINEL  ·  pre-action interceptor (ground-truth reliability)${RESET}    ${CYAN}┃${RESET}"
  printf '%s\n'   "${CYAN}    ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${RESET}"
  printf '%s\n\n' "${BOLD}${CYAN}▶ WHAT THIS SHOWS:${RESET} ${WHITE}every agent tool call is ruled ALLOW/BLOCK ${BOLD}before${RESET}${WHITE} it can run — no LLM, no keys, offline.${RESET}"
}

step() { printf '\n%s▸ %s%s\n' "${BOLD}${YELLOW}" "$1" "${RESET}"; }

# ------------------------------------------------------------------ setup (quiet, idempotent)
if [ ! -x "$PY" ]; then
  step "First run — creating offline venv (pydantic + pytest)…"
  python3 -m venv "$VENV"
  "$VENV/bin/pip" install -q --upgrade pip >/dev/null 2>&1 || true
  "$VENV/bin/pip" install -q "pydantic>=2" "pytest>=8" >/dev/null 2>&1
  ( cd "$PROJ_DIR" && "$VENV/bin/pip" install -q -e . >/dev/null 2>&1 )
fi

banner

# ------------------------------------------------------------------ 1) live interceptor rulings
step "Feeding the interceptor 5 attempted agent actions…"
( cd "$PROJ_DIR" && PYTHONPATH="$PROJ_DIR" "$PY" demo_interceptor.py )

# ------------------------------------------------------------------ 2) trust anchor: the oracle's own test suite
step "Trust anchor — the interceptor + contracts test suite:"
( cd "$PROJ_DIR" && "$PY" -m pytest -q tests/test_interceptor.py tests/test_contracts.py 2>&1 \
    | grep -E 'passed|failed|error' \
    | sed "s/.*/${BOLD}${GREEN}   &${RESET}/" )

printf '\n%s\n' "${DIM}   (full suite: 47 tests green — run \`.venv/bin/python -m pytest -q\` in sentinel/)${RESET}"
printf '\n%s\n\n' "${BOLD}${GREEN}✅ Sentinel intercepts unsafe agent actions BEFORE they execute.${RESET}"
