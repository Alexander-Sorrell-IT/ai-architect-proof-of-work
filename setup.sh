#!/usr/bin/env bash
# Optional: pre-build the per-tool Python venvs so the demo runs instantly.
# Not required — each run-*.sh builds its own venv on first run. This just
# warms them ahead of time (needs network once for pip).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Warming venvs (one-time)…"
for tool in hexbreaker robotruth sentinel; do
  if [ -d "$HERE/$tool" ]; then
    echo "  • $tool"
    bash "$HERE/run-$tool.sh" >/dev/null 2>&1 || echo "    (first build had a hiccup — run 'bash run-$tool.sh' to see output)"
  fi
done
echo "Done. Now run:  bash demo.sh"
