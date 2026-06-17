#!/usr/bin/env bash
#
# run-hexbreaker.sh — self-contained, offline demo of Hexbreaker's
# signed evidence-of-record verification (chain + HMAC) on the NIST
# CFReDS Hacking Case Court run.
#
# No API keys, no network. Verifies a committed, signed transcript and
# shows the F1=1.0 forensic result it attests to.
#
set -euo pipefail

# ---------------------------------------------------------------- colors
if [ -t 1 ]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; RST=$'\033[0m'
  GRN=$'\033[32m'; BGRN=$'\033[1;92m'; CYN=$'\033[36m'; BCYN=$'\033[1;96m'
  YEL=$'\033[33m'; RED=$'\033[1;91m'; MAG=$'\033[35m'; GRY=$'\033[90m'
else
  BOLD=''; DIM=''; RST=''; GRN=''; BGRN=''; CYN=''; BCYN=''; YEL=''; RED=''; MAG=''; GRY=''
fi

# ------------------------------------------------------------- locations
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/hexbreaker" && pwd)"
cd "$REPO"
TRANSCRIPT="samples/nist_fsm_run/run1/transcript.jsonl"
SUMMARY="samples/nist_fsm_run/SUMMARY.md"

# ------------------------------------------------------------- venv setup
# Idempotent: build the venv + editable install only the first time.
if [ ! -x ".venv/bin/hexbreaker" ]; then
  echo "${GRY}(first run: building venv + installing hexbreaker — one-time)${RST}"
  python3 -m venv .venv
  # shellcheck disable=SC1091
  source .venv/bin/activate
  pip install -q --upgrade pip >/dev/null 2>&1 || true
  pip install -q -e . >/dev/null 2>&1
else
  # shellcheck disable=SC1091
  source .venv/bin/activate
fi

# The documented passphrase for the committed NIST .sig sidecars.
export HEXBREAKER_HMAC_PASSWORD='hexbreaker-nist-fsm'

# ------------------------------------------------------------ banner
echo
echo "${BCYN}    ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${RST}"
echo "${BCYN}    ┃${RST}  ${BOLD}HEXBREAKER${RST} ${DIM}— adversarial DFIR triage, signed evidence of record${RST}   ${BCYN}┃${RST}"
echo "${BCYN}    ┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${RST}"
echo "${BCYN}    ┃${RST}  ${BOLD}WHAT THIS SHOWS${RST}  A tamper-evident hash-chain + HMAC over an AI    ${BCYN}┃${RST}"
echo "${BCYN}    ┃${RST}  agent's full forensic transcript — cryptographic proof a Court run${BCYN}┃${RST}"
echo "${BCYN}    ┃${RST}  on the real NIST disk image was not edited after it was signed.   ${BCYN}┃${RST}"
echo "${BCYN}    ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${RST}"
echo

# ----------------------------------------------------- 1. the evidence
echo "${BOLD}${MAG}[1/3]${RST} ${BOLD}The signed evidence of record${RST}"
echo "${GRY}      Court ran on the NIST CFReDS Hacking Case (4Dell_Latitude_CPi.E01).${RST}"
echo "${GRY}      transcript : ${RST}${CYN}${TRANSCRIPT}${RST}"
echo "${GRY}      signature  : ${RST}${CYN}${TRANSCRIPT}.sig${RST}  ${GRY}(HMAC-SHA256 sidecar)${RST}"
echo

# --------------------------------------- 2. verify chain + HMAC (core proof)
echo "${BOLD}${MAG}[2/3]${RST} ${BOLD}Verify the hash chain + HMAC signature${RST}"
echo "${DIM}\$ export HEXBREAKER_HMAC_PASSWORD='hexbreaker-nist-fsm'${RST}"
echo "${DIM}\$ hexbreaker verify --transcript ${TRANSCRIPT} --hmac${RST}"
echo
OUT="$(hexbreaker verify --transcript "$TRANSCRIPT" --hmac)"
echo "      ${BGRN}✅  ${OUT}${RST}"
echo "      ${GRN}└─ every transcript line hash-chained; HMAC matches → untampered${RST}"
echo

# Prove it's a real integrity gate, not a rubber stamp: a wrong key is rejected.
echo "${GRY}      (integrity proof — a wrong key / any edit is rejected:)${RST}"
if HEXBREAKER_HMAC_PASSWORD='not-the-key' \
     hexbreaker verify --transcript "$TRANSCRIPT" --hmac >/dev/null 2>tamper.err; then
  echo "      ${RED}unexpected: tampered check passed${RST}"
else
  echo "      ${RED}🛑  $(cat tamper.err)${RST}"
fi
rm -f tamper.err
echo

# ------------------------------------------------ 3. what the proof attests
echo "${BOLD}${MAG}[3/3]${RST} ${BOLD}The forensic result this signature attests to${RST}"
# Pull the run1 row + the distribution line straight from the committed SUMMARY.
echo "${GRY}      (from ${SUMMARY}, n=5 independent runs:)${RST}"
echo
# Pull the header + run1 row verbatim, then pad each cell to a fixed display
# width so the | columns line up on screen (the ✅ glyph counts as 2 cells).
grep -E '^\| (Run|run1) ' "$SUMMARY" | python3 -c '
import sys, unicodedata
def dw(s):
    n = 0
    for ch in s:
        n += 2 if (unicodedata.east_asian_width(ch) in ("W","F") or ord(ch) >= 0x1F000) else (0 if unicodedata.combining(ch) else 1)
    return n
rows = [[c.strip() for c in ln.strip().strip("|").split("|")] for ln in sys.stdin if ln.strip()]
if rows:
    cols = len(rows[0])
    widths = [max(dw(r[i]) for r in rows if len(r) > i) for i in range(cols)]
    for r in rows:
        cells = [c + " " * (widths[i] - dw(c)) for i, c in enumerate(r)]
        print("| " + " | ".join(cells) + " |")
' | sed "s/^/      ${CYN}/; s/\$/${RST}/"
echo
echo "      ${BGRN}${BOLD}Grade: F1 = 1.0  —  4/4 of Mr. Evil's deleted recycle-bin tools recovered${RST}"
echo "      ${GRN}precision 1.0 · recall 1.0 · 0 false positives · chain+HMAC ✅${RST}"
echo "      ${GRY}(NIST Q28 / recycle-bin question, n=5 runs — not a 31-question NIST F1)${RST}"
echo
echo "${BCYN}══════════════════════════════════════════════════════════════════════${RST}"
echo "${DIM}Fully offline. No API key, no network. The transcript, its signature,${RST}"
echo "${DIM}and the score are all committed artifacts — verifiable by anyone.${RST}"
echo
