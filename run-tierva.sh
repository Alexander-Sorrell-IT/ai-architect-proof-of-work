#!/usr/bin/env bash
#
# run-tierva.sh — self-contained, offline demo of Tierva's Pacto.sol
# adversarial Foundry suite (parametric climate-insurance escrow).
#
# No API keys, no RPC, no network. Compiles the contracts locally and runs
# the full adversarial `forge test` suite, then highlights the security
# invariants it proves on-chain.
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
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/tierva" && pwd)"
CONTRACTS="$REPO/contracts"
SUITE="contracts/test/Pacto.t.sol"
cd "$CONTRACTS"

# ------------------------------------------------------------- foundry setup
# Idempotent: just put the vendored foundry toolchain on PATH (forge-std is
# already committed under contracts/lib — no install, no download).
export PATH="$HOME/.foundry/bin:$PATH"
if ! command -v forge >/dev/null 2>&1; then
  echo "${RED}forge not found on PATH (expected ~/.foundry/bin). Install foundry first.${RST}"
  exit 1
fi

# ------------------------------------------------------------ banner
echo
echo "${BCYN}    ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${RST}"
echo "${BCYN}    ┃${RST}  ${BOLD}TIERVA${RST} ${DIM}— parametric climate-insurance escrow, proven adversarial${RST}  ${BCYN}┃${RST}"
echo "${BCYN}    ┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${RST}"
echo "${BCYN}    ┃${RST}  ${BOLD}WHAT THIS SHOWS${RST}  Pacto.sol holds real USDC escrow that pays       ${BCYN}┃${RST}"
echo "${BCYN}    ┃${RST}  drought victims only when 2 sensors agree for 20 days. The        ${BCYN}┃${RST}"
echo "${BCYN}    ┃${RST}  adversarial Foundry suite proves a rogue oracle can't redirect,   ${BCYN}┃${RST}"
echo "${BCYN}    ┃${RST}  double-pay, or drain a single dollar of it.                       ${BCYN}┃${RST}"
echo "${BCYN}    ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${RST}"
echo

# ----------------------------------------------------- 1. the contract under test
echo "${BOLD}${MAG}[1/3]${RST} ${BOLD}The contract under attack${RST}"
echo "${GRY}      Pacto.sol — pull-payment USDC escrow; only the oracle reports sensor${RST}"
echo "${GRY}      readings, beneficiaries claim, governance may sweep only FREE balance.${RST}"
echo "${GRY}      adversarial suite : ${RST}${CYN}${SUITE}${RST}"
echo

# --------------------------------------- 2. run the real adversarial suite
echo "${BOLD}${MAG}[2/3]${RST} ${BOLD}Run the adversarial suite${RST}  ${DIM}(local EVM, no RPC)${RST}"
echo "${DIM}\$ forge test${RST}"
echo
OUT="$(forge test 2>&1)"

# Total / pass / fail straight from forge's own summary line.
SUMMARY="$(printf '%s\n' "$OUT" | grep -E 'tests passed' | tail -1)"
PASS="$(printf '%s\n' "$SUMMARY" | grep -oE '[0-9]+ tests passed' | grep -oE '^[0-9]+')"
FAIL="$(printf '%s\n' "$SUMMARY" | grep -oE '[0-9]+ failed'       | grep -oE '^[0-9]+')"
TOTAL="$(printf '%s\n' "$SUMMARY" | grep -oE '[0-9]+ total'        | grep -oE '^[0-9]+')"
PASS="${PASS:-0}"; FAIL="${FAIL:-?}"; TOTAL="${TOTAL:-?}"

# Echo three of the marquee adversarial PASS lines, pulled live from output.
echo "${GRY}      (three of the marquee adversarial cases, straight from forge):${RST}"
for t in test_oracleCannotRedirectFunds test_noDoublePay_sameCycle test_withdrawOnlyFreeNotReserved; do
  LINE="$(printf '%s\n' "$OUT" | grep -E "\[PASS\] ${t}\(" | head -1 | sed -E 's/^[[:space:]]+//')"
  if [ -n "$LINE" ]; then
    echo "      ${BGRN}✅  ${LINE}${RST}"
  else
    echo "      ${RED}🛑  ${t} did not pass${RST}"
  fi
done
echo

# ------------------------------------------------ 3. the money shot
echo "${BOLD}${MAG}[3/3]${RST} ${BOLD}What the green suite attests to${RST}"
echo "${GRY}      oracle can't redirect funds · no double-pay in a cycle · governance${RST}"
echo "${GRY}      can never touch USDC reserved for beneficiaries.${RST}"
echo
if [ "$FAIL" = "0" ] && [ "$PASS" = "$TOTAL" ] && [ "$PASS" != "0" ]; then
  echo "      ${BGRN}${BOLD}${PASS}/${TOTAL} adversarial tests pass — oracle can't redirect funds, no double-pay, governance can't touch reserved payouts.${RST}"
  echo "      ${GRN}└─ proven in Solidity on a local EVM — no RPC, no keys, no network${RST}"
else
  echo "      ${RED}${BOLD}suite not fully green: ${PASS}/${TOTAL} passed, ${FAIL} failed${RST}"
  printf '%s\n' "$OUT" | tail -20
  exit 1
fi
echo
echo "${BCYN}══════════════════════════════════════════════════════════════════════${RST}"
echo "${DIM}Fully offline. No API key, no RPC, no network. The contracts and their${RST}"
echo "${DIM}adversarial suite are committed artifacts — reproducible by anyone.${RST}"
echo
