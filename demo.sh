#!/usr/bin/env bash
#
# demo.sh — master runner for Alexander Sorrell's live demo kit.
#
# Runs each project's run-<project>.sh in sequence, strongest-first, with a
# colored title card before each segment and a "press ENTER to continue"
# pause between segments so you can narrate on camera.
#
# Usage:
#   bash demo.sh            # run the full reel, pausing between segments
#   bash demo.sh <project>  # run just one segment (no pause)
#   bash demo.sh --no-pause # run the full reel without pauses (smoke test)
#
# All segments run OFFLINE — no API keys, no network, no secrets at runtime.
#
set -uo pipefail

# Force a UTF-8 locale so bash measures multibyte chars (em-dash, etc.) as one
# character — this keeps box padding aligned regardless of the inherited locale.
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$HERE"

# Right-pad a plain (ANSI-free, single-cell) string to N display cells with
# spaces, using bash's character count. Taglines here are ASCII + em-dash,
# all single display cells, so character count == display width.
pad_cells() {
  local s="$1" want="$2" n=${#1}
  (( n < want )) && printf '%*s' "$((want - n))" ''
}

# ---------------------------------------------------------------- colors
if [ -t 1 ]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; RST=$'\033[0m'
  GRN=$'\033[32m'; BGRN=$'\033[1;92m'; CYN=$'\033[36m'; BCYN=$'\033[1;96m'
  YEL=$'\033[1;93m'; RED=$'\033[1;91m'; MAG=$'\033[1;95m'; GRY=$'\033[90m'
  BWHT=$'\033[1;97m'
else
  BOLD=''; DIM=''; RST=''; GRN=''; BGRN=''; CYN=''; BCYN=''; YEL=''; RED=''; MAG=''; GRY=''; BWHT=''
fi

# ---------------------------------------------------- segment definitions
# Order: strongest-first. Each entry = "project|one-line tagline".
SEGMENTS=(
  "hexbreaker|Signed, tamper-evident evidence-of-record over an AI DFIR agent"
  "robotruth|Deterministic PR auditor — catches an agent lying about its diff"
  "sentinel|Pre-action interceptor — blocks out-of-policy agent tool calls"
)

NO_PAUSE=0
ONLY=""
for arg in "$@"; do
  case "$arg" in
    --no-pause) NO_PAUSE=1 ;;
    -*)         echo "unknown flag: $arg" >&2; exit 2 ;;
    *)          ONLY="$arg" ;;
  esac
done

pause() {
  [ "$NO_PAUSE" -eq 1 ] && { echo; return; }
  [ -n "$ONLY" ] && { echo; return; }
  echo
  printf "%s" "${YEL}    ▸ press ENTER for the next segment…${RST}"
  read -r _ || true
  echo
}

title_card() {
  local n="$1" total="$2" name="$3" tag="$4"
  # Inner content between ┃…┃ is exactly 68 display cells (border = 68 ━).
  # Line 1: 2 spaces + "SEGMENT n/total" (11) + 3 spaces + name padded to 52 = 68.
  # Line 2: 2 spaces + tag padded to 66 = 68.
  echo
  echo "${MAG}    ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${RST}"
  printf "%s    ┃%s  %sSEGMENT %s/%s%s   %s%-52s%s%s┃%s\n" \
    "$MAG" "$RST" "$DIM" "$n" "$total" "$RST" "$BWHT" "$name" "$RST" "$MAG" "$RST"
  printf "%s    ┃%s  %s%s%s%s%s┃%s\n" \
    "$MAG" "$RST" "$CYN" "$tag" "$(pad_cells "$tag" 66)" "$RST" "$MAG" "$RST"
  echo "${MAG}    ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${RST}"
  echo
}

run_segment() {
  local name="$1" tag="$2" idx="$3" total="$4"
  local script="$HERE/run-$name.sh"
  if [ ! -f "$script" ]; then
    echo "${GRY}    ⏭  skip $name — run-$name.sh not found${RST}"
    return 0
  fi
  title_card "$idx" "$total" "$name" "$tag"
  bash "$script"
}

# --------------------------------------------------------- master banner
clear 2>/dev/null || true
echo
echo "${BCYN}   █████╗ ██╗     ███████╗██╗  ██╗ █████╗ ███╗   ██╗██████╗ ███████╗██████╗ ${RST}"
echo "${BCYN} ██╔══██╗██║     ██╔════╝╚██╗██╔╝██╔══██╗████╗  ██║██╔══██╗██╔════╝██╔══██╗${RST}"
echo "${BCYN} ███████║██║     █████╗   ╚███╔╝ ███████║██╔██╗ ██║██║  ██║█████╗  ██████╔╝${RST}"
echo "${BCYN} ██╔══██║██║     ██╔══╝   ██╔██╗ ██╔══██║██║╚██╗██║██║  ██║██╔══╝  ██╔══██╗${RST}"
echo "${BCYN} ██║  ██║███████╗███████╗██╔╝ ██╗██║  ██║██║ ╚████║██████╔╝███████╗██║  ██║${RST}"
echo "${BCYN} ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ ╚══════╝╚═╝  ╚═╝${RST}"
echo
echo "                ${BWHT}SORRELL${RST}  ${DIM}·${RST}  ${BOLD}LIVE DEMO${RST}  ${DIM}·${RST}  ${CYN}AI Security & Eval${RST}"
echo "        ${GRY}Three execution-grounded tools. Every verdict is proven, not asserted.${RST}"
echo "        ${GRY}All offline — no API keys, no network, no secrets at runtime.${RST}"
echo

# --------------------------------------------------------- run segments
TOTAL="${#SEGMENTS[@]}"

if [ -n "$ONLY" ]; then
  found=0
  for entry in "${SEGMENTS[@]}"; do
    name="${entry%%|*}"; tag="${entry#*|}"
    if [ "$name" = "$ONLY" ]; then
      found=1
      run_segment "$name" "$tag" 1 1
    fi
  done
  if [ "$found" -eq 0 ]; then
    echo "${RED}    no such segment: $ONLY${RST}" >&2
    echo "${GRY}    available: hexbreaker codecrusher robotruth sentinel${RST}" >&2
    exit 2
  fi
else
  pause   # let the title slate breathe before segment 1
  i=0
  for entry in "${SEGMENTS[@]}"; do
    i=$((i+1))
    name="${entry%%|*}"; tag="${entry#*|}"
    run_segment "$name" "$tag" "$i" "$TOTAL"
    [ "$i" -lt "$TOTAL" ] && pause
  done
fi

# ----------------------------------------------------------- closing card
echo
echo "${MAG}    ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${RST}"
CLOSE_MSG="Demo complete — every tool ran live and offline."
printf "%s    ┃%s  %s%s%s%s%s┃%s\n" "$MAG" "$RST" "$BGRN" "$CLOSE_MSG" "$(pad_cells "$CLOSE_MSG" 66)" "$RST" "$MAG" "$RST"
echo "${MAG}    ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${RST}"
echo
