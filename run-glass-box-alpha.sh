#!/usr/bin/env bash
#
# run-glass-box-alpha.sh — Glass-Box Alpha green-test demo (offline, no keys/RPC)
#
# WHAT THIS SHOWS: the cross-stack test suite runs green — Foundry (Solidity contract
# suite) + pytest (Python multi-agent backend) — and the Python suite pins the
# reasoning-receipt keccak byte-for-byte (the frozen golden receipt vector the deployed
# anchor's verify() recomputes). No API keys, no LLM, no live RPC call.
#
set -euo pipefail

# ------------------------------------------------------------------ paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ_DIR="$SCRIPT_DIR/glass-box-alpha"
CONTRACTS="$PROJ_DIR/contracts"
VENV="$PROJ_DIR/agents/.venv"
PY="$VENV/bin/python"
export PATH="$HOME/.foundry/bin:$PATH"

# ------------------------------------------------------------------ colors
BOLD=$'\033[1m'; DIM=$'\033[2m'; RESET=$'\033[0m'
RED=$'\033[91m'; GREEN=$'\033[92m'; YELLOW=$'\033[93m'
BLUE=$'\033[94m'; CYAN=$'\033[96m'; WHITE=$'\033[97m'

banner() {
  printf '\n%s\n' "${CYAN}    ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${RESET}"
  printf '%s\n'   "${CYAN}    ┃${RESET}  ${BOLD}${WHITE}GLASS-BOX ALPHA  ·  the AI that hands you a receipt, not a story${RESET}  ${CYAN}┃${RESET}"
  printf '%s\n'   "${CYAN}    ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${RESET}"
  printf '%s\n\n' "${BOLD}${CYAN}▶ WHAT THIS SHOWS:${RESET} ${WHITE}the cross-stack suite runs green — ${BOLD}Foundry + pytest${RESET}${WHITE} — and pytest pins the reasoning-receipt keccak byte-for-byte. No keys, no RPC, offline.${RESET}"
}

step() { printf '\n%s▸ %s%s\n' "${BOLD}${YELLOW}" "$1" "${RESET}"; }

# ------------------------------------------------------------------ setup (quiet, idempotent)
# forge-std vendored lib (pinned v1.16.1 per contracts/foundry.lock) — first run only.
if [ ! -f "$CONTRACTS/lib/forge-std/src/Test.sol" ]; then
  step "First run — vendoring forge-std v1.16.1 (one-time)…"
  rm -rf "$CONTRACTS/lib/forge-std"
  git clone -q --depth 1 --branch v1.16.1 \
    https://github.com/foundry-rs/forge-std.git "$CONTRACTS/lib/forge-std" >/dev/null 2>&1
fi

# Python venv + deps — first run only.
if [ ! -x "$PY" ]; then
  step "First run — creating offline venv (agents/requirements.txt + pytest)…"
  python3 -m venv "$VENV"
  "$VENV/bin/pip" install -q --upgrade pip >/dev/null 2>&1 || true
  "$VENV/bin/pip" install -q -r "$PROJ_DIR/agents/requirements.txt" pytest >/dev/null 2>&1
fi

banner

# ------------------------------------------------------------------ 1) Foundry (Solidity) suite
# forge test also populates contracts/out/ — REQUIRED before pytest, whose ABI test
# reads contracts/out/ and otherwise skips (giving 75 passed + 1 skipped, not 76).
step "Foundry — Solidity contract suite (forge test)…"
FORGE_OUT="$(cd "$CONTRACTS" && forge test 2>&1)" || { printf '%s\n' "$FORGE_OUT"; exit 1; }
FORGE_LINE="$(printf '%s\n' "$FORGE_OUT" | grep -E 'tests passed' | tail -1 || true)"
printf '%s\n' "${BOLD}${GREEN}   ${FORGE_LINE}${RESET}"
FORGE_N="$(printf '%s' "$FORGE_LINE" | grep -oE '[0-9]+ tests passed' | grep -oE '^[0-9]+' || echo '?')"

# ------------------------------------------------------------------ 2) Python (pytest) suite
step "Python — multi-agent backend suite (PYTHONPATH=. pytest agents)…"
PYTEST_OUT="$(cd "$PROJ_DIR" && PYTHONPATH=. "$PY" -m pytest agents -q 2>&1)" \
  || { printf '%s\n' "$PYTEST_OUT"; exit 1; }
PYTEST_LINE="$(printf '%s\n' "$PYTEST_OUT" | grep -E '[0-9]+ passed' | tail -1 || true)"
printf '%s\n' "${BOLD}${GREEN}   ${PYTEST_LINE}${RESET}"
PYTEST_N="$(printf '%s' "$PYTEST_LINE" | grep -oE '[0-9]+ passed' | grep -oE '^[0-9]+' || echo '?')"

# ------------------------------------------------------------------ 3) on-chain status (stated, not called)
step "On-chain status (from docs/claims-ledger.md — no live RPC call):"
printf '%s\n' "${WHITE}   5 contracts deployed + source-verified ${BOLD}(Exact Match)${RESET}${WHITE} on Mantle Sepolia${RESET}"
printf '%s\n' "${DIM}   anchor · registry · round-state · GBRR reputation · human-arena${RESET}"
printf '%s\n' "${DIM}   Sepolia testnet (chain 5003) — pre-launch; mainnet deploy is post-hackathon.${RESET}"

# ------------------------------------------------------------------ money shot
TOTAL=$(( FORGE_N + PYTEST_N ))
printf '\n%s\n' "${BOLD}${GREEN}✅ ${TOTAL} tests pass (${FORGE_N} Foundry + ${PYTEST_N} pytest) — 5 contracts source-verified on Mantle Sepolia${RESET}"
printf '%s\n\n' "${DIM}   Fully offline: no API key, no LLM, no live RPC. (First run only: pip + forge-std fetch.)${RESET}"
