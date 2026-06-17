# AI Security & Eval — Live Demo

Reproducible demos of tools I built for AI-security, model-evaluation, and agent-reliability work. **Every verdict is proven by execution, not asserted** — there is no LLM in any verdict path. Run them yourself: no API keys, no network at runtime.

**Alexander Sorrell** · [github.com/Alexander-Sorrell-IT](https://github.com/Alexander-Sorrell-IT)

```bash
bash demo.sh                # full reel (pauses between tools)
bash demo.sh hexbreaker     # one tool
```
Each tool builds its own Python venv on first run (one-time, needs network once), then runs fully offline.

> **Honest framing up front:** these are hackathon / solo builds — working, tested code, not production systems run at scale. Results shown are committed and reproducible. Scope caveats are stated per tool below and on-screen in the demo.

---

## 1. hexbreaker — adversarial multi-LLM forensic evaluator

![hexbreaker](recordings/hexbreaker.png)

Five adversarial LLM roles (Prosecutor / Defender / Witness / Provocateur) argue a case; a **deterministic Python judge** decides. Every transcript is HMAC-signed and hash-chained, so any result is independently re-verifiable.

- **What it proves:** validated on the genuine **NIST CFReDS "Hacking Case"** disk image — recovered all 4 deleted recycle-bin executables, **F1 = 1.0 across 5 independently signed runs**. `hexbreaker verify` re-checks the whole chain live.
- **Honest scope:** this is NIST **Q28** (the recycle-bin question), ~1 of ~31 question families — *not* a full 31-question NIST F1. An earlier higher number was **withdrawn** after I found it leaked the answer key; a unit test now enforces the key never reaches the agent.
- **Source:** [github.com/Alexander-Sorrell-IT/hexbreaker](https://github.com/Alexander-Sorrell-IT/hexbreaker) · `bash run-hexbreaker.sh`

## 2. robotruth — deterministic PR auditor (no LLM in the verdict path)

![robotruth](recordings/robotruth.png)

Reads what an AI agent **claimed** in a PR vs. what the diff **actually did**, and grades the divergence — cited at `file:line`.

- **What it proves:** on a fixture PR that claims "only tidies logging" but actually removes an auth guard, adds `eval()`, and adds a dependency, it returns **Grade: F — LIAR**. `grep` confirms zero `openai/anthropic/llm` in the verdict path; the grade is a pure deterministic function. 81 engine tests pass.
- **Source:** [github.com/Alexander-Sorrell-IT/robotruth](https://github.com/Alexander-Sorrell-IT/robotruth) · `bash run-robotruth.sh`

## 3. sentinel — pre-action interceptor for agents

![sentinel](recordings/sentinel.png)

Rules **ALLOW / BLOCK** on every tool call an AI agent attempts, *before* it executes, against a pydantic policy contract.

- **What it proves:** blocks a forbidden tool, a missing-human-approval call, and an out-of-scope wire transfer (all as critical/high), while letting the two legitimate calls through — **3/3 out-of-policy actions blocked.** ~47 tests pass.
- **Source:** [github.com/Alexander-Sorrell-IT/sentinel](https://github.com/Alexander-Sorrell-IT/sentinel) · `bash run-sentinel.sh`

## 4. codecrusher — proof-carrying smart-contract exploit synthesis *(private)*

![codecrusher](recordings/codecrusher.png)

A static scanner flags a reentrancy/CEI bug → a deterministic synthesizer generates a self-contained **Foundry** PoC → `forge` runs it. **CONFIRMED is minted only behind a real `[PASS]`** — and the *same* synthesizer **REJECTS** the CEI-safe patched twin, so it never rubber-stamps. *(The on-screen `liveness=internal` label honestly means the exploit ran in a local EVM, not a mainnet fork.)*

- **Source is private** (this is the one tool I keep closed) — **available on request.** The screenshot above is a real run; ~9.3k LOC, 188 tests.

---

## Run it yourself
- **Prereqs:** `python3`. For the codecrusher *source* you'd need access (private) + [Foundry](https://getfoundry.sh); the other three are fully self-contained here.
- **Offline:** after the one-time venv build, no tool makes a network call or needs an API key.

## The thesis
The model proposes; **execution disposes.** A static flag is a hypothesis — a `forge [PASS]`, a signed transcript, or a deterministic grade is proof. That principle runs through all four tools.
