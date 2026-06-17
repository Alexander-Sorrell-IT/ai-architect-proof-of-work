#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  RoboTruth — offline demo
#  Deterministic PR auditor: "did the robot lie?"  NO model in the verdict path.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# colors
B=$'\033[1m'; DIM=$'\033[2m'; R=$'\033[91m'; G=$'\033[92m'; Y=$'\033[93m'
C=$'\033[96m'; M=$'\033[95m'; RST=$'\033[0m'

ROOT="/Users/broodierchip-m1air/Desktop/demo_kit/robotruth"
ENGINE="$ROOT/robotruth"
VENV="$ENGINE/.venv"
PY="$VENV/bin/python"

# ── banner ───────────────────────────────────────────────────────────────────
printf '%s\n' "${M}    ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${RST}"
printf '%s\n' "${M}    ┃${RST}  ${B}RoboTruth — The Receipts Protocol${RST}   ${DIM}did the robot lie?${RST}            ${M}┃${RST}"
printf '%s\n' "${M}    ┃${RST}  ${C}WHAT THIS SHOWS${RST}  deterministic PR auditor catches an agent        ${M}┃${RST}"
printf '%s\n' "${M}    ┃${RST}                    whose claims DIVERGE from its diff — no LLM.    ${M}┃${RST}"
printf '%s\n' "${M}    ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${RST}"
echo

# ── ensure venv (idempotent, offline once built) ─────────────────────────────
if [ ! -x "$PY" ]; then
  printf '%s\n' "${DIM}· building one-time venv (needs network once)…${RST}"
  python3 -m venv "$VENV" >/dev/null 2>&1 || { printf '%s\n' "${R}venv setup failed${RST}"; exit 1; }
  "$VENV/bin/pip" install -q -e "$ENGINE[dev]" >/dev/null 2>&1 \
    || { printf '%s\n' "${R}one-time pip install needs network — re-run online once${RST}"; exit 1; }
fi

# ── 1) primary demo: audit a sneaky agent PR fixture, fully offline ───────────
printf '%s\n' "${B}${C}── Auditing a committed 'sneaky agent' PR fixture (offline) ──${RST}"
echo
PYTHONPATH="$ENGINE/src" "$PY" "$ROOT/demo/audit_fixture.py"
echo

# ── 2) fallback / proof: the deterministic engine's own 81 tests ─────────────
printf '%s\n' "${B}${C}── Proof the verdict engine is deterministic: its own test suite ──${RST}"
TESTS=$(cd "$ENGINE" && PYTHONPATH="$ENGINE/src" "$PY" -m pytest -q 2>&1 | tail -1)
if printf '%s' "$TESTS" | grep -q "passed"; then
  printf '   %s%s✅ engine tests: %s%s\n' "$B" "$G" "$TESTS" "$RST"
else
  printf '   %s%s%s%s\n' "$B" "$R" "$TESTS" "$RST"
fi
echo
printf '%s\n' "${DIM}Same audit_diff() engine is imported by the web app, MCP server & API.${RST}"
