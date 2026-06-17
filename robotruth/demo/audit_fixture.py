#!/usr/bin/env python3
"""Offline RoboTruth demo driver.

Loads a committed PR fixture (body + unified diff) and runs the REAL
deterministic audit engine on it. No network. No LLM in the verdict path —
the same audit_diff() the web app, MCP server, and API all import.

The fixture is a "sneaky" agent PR: it CLAIMS it only tidied logging, added
tests, and changed no dependencies. The diff says otherwise.
"""
from __future__ import annotations
import json
import sys
from pathlib import Path

from robotruth.types import PRMeta
from robotruth.engine import audit_diff

# ---- ANSI ---------------------------------------------------------------
BOLD = "\033[1m"
DIM = "\033[2m"
RED = "\033[91m"
GRN = "\033[92m"
YEL = "\033[93m"
CYN = "\033[96m"
MAG = "\033[95m"
RST = "\033[0m"

SEV_COLOR = {"critical": RED, "moderate": YEL, "minor": CYN}
GRADE_COLOR = {"A": GRN, "B": GRN, "C": YEL, "D": YEL, "F": RED}


def main() -> int:
    here = Path(__file__).resolve().parent
    meta = json.loads((here / "sneaky_pr.json").read_text())
    diff_text = (here / "sneaky_pr.diff").read_text()

    pr = PRMeta(**meta)

    # ---- the core call: REAL deterministic engine, offline -------------
    receipt = audit_diff(pr, diff_text)

    # ---- print the receipt ---------------------------------------------
    print(f"{DIM}PR  {RST}{BOLD}{pr.repo}#{pr.number}{RST}  "
          f"{DIM}by {pr.author}{RST}")
    print(f'{DIM}    "{pr.title}"{RST}\n')

    print(f"{BOLD}What the agent CLAIMED{RST} {DIM}(heuristic extraction){RST}")
    for c in receipt.parsed_claims:
        print(f"  {CYN}•{RST} {c}")
    print()

    print(f"{BOLD}What the diff ACTUALLY did{RST} "
          f"{DIM}(deterministic scanners — no model){RST}")

    if receipt.undisclosed:
        print(f"  {MAG}UNDISCLOSED — did things it never mentioned:{RST}")
        for f in receipt.undisclosed:
            col = SEV_COLOR.get(f.severity, RST)
            loc = f"{f.file}:{f.line}" if f.line else f.file
            print(f"    {col}[{f.severity.upper():<8}]{RST} {f.label}")
            print(f"               {DIM}↳ {loc}  —  {f.evidence}{RST}")

    if receipt.unhonored:
        print(f"  {MAG}UNHONORED — claimed but never delivered:{RST}")
        for f in receipt.unhonored:
            col = SEV_COLOR.get(f.severity, RST)
            print(f"    {col}[{f.severity.upper():<8}]{RST} {f.label}")

    if receipt.delivered:
        print(f"  {GRN}DELIVERED — claims that checked out:{RST}")
        for f in receipt.delivered:
            print(f"    {GRN}[OK]{RST} {f.label}")
    print()

    # ---- the grade line (the verdict) ----------------------------------
    gc = GRADE_COLOR.get(receipt.grade, RST)
    bar = "─" * 64
    print(f"{DIM}{bar}{RST}")
    print(f"{BOLD}{gc}  Grade: {receipt.grade} — {receipt.verdict}   "
          f"agent's PR claims DIVERGE from the diff{RST}")
    print(f"{DIM}  {receipt.math}{RST}")
    print(f"{DIM}{bar}{RST}")

    # sanity: this fixture must grade F/LIAR or the demo is wrong
    if receipt.grade != "F":
        print(f"{RED}FIXTURE DRIFT: expected grade F, got {receipt.grade}{RST}",
              file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
