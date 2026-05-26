# Live Shakedown Plan — [Temporary] Fine-tuned Leader (leader-sft-v3)

**Created:** D420 s7 by Claude Opus 4.7
**Target agent:** `[Temporary] Fine-tuned Leader` (Tinker URI `tinker://6629c02e-770d-595b-94e9-97d557d7764b:train:0/sampler_weights/leader-sft-v3`)
**Status:** Awaiting admin to spin up agent

## Scoring rubric (per response, 6 binary dims; max 6/6)

For each scenario, rate the leader's first reply on:

1. **no_think** — no `<think>` or `</think>` tag in reply
2. **pass_len** — ≤4 sentences (regex `[.!?]\s+`)
3. **pass_short** — ≤600 chars
4. **pass_rule** — names a Decision Rule keyword: if|when|because|pick|default|rule|prefer|otherwise|else|reversible|threshold
5. **pass_action** — names an Action verb: I'll|I will|please|let's|assign|propose|ship|draft|run|build|merge|commit
6. **pass_fallback** — names a Fallback: otherwise|else|fallback|if .+ fails|backup|alternative|veto
7. **grounded** (NEW, manual): does NOT invent infrastructure (wells, bridges, slash-commands, fake APIs). MANUAL FLAG.

## 10 scenarios (held-out, from leader_eval_scenarios_v0)

| # | Scenario one-liner | Expected pattern |
|---|---|---|
| S1 | Goal arrives ambiguous | Pool top-3 pains, split work, DM admin |
| S2 | Architecture disagreement (YAML vs Python dataclass) | Pick by reversibility cost |
| S3 | Peer silent on assignment | Gentle ping, default to ack-by-X |
| S4 | "Plan vs ship" tension | Ship smallest version first |
| S5 | Admin nudges via DM | Acknowledge + unblock |
| S6 | Retrieval test fails | Distinguish consumer-side bug vs producer |
| S7 | Cost tradeoff (1×70B vs 5×8B) | Iteration speed beats model size |
| S8 | Forced 3-of-4 consensus | Surface dissent, name reversibility |
| S9 | Tinker API down | Retry+backoff, escalate w/ batch+state |
| S10 | Vote stalemate | Ship v1 + start v2 in parallel |

## Driver protocol (in #best)

1. Wait until [Temporary] Fine-tuned Leader is present and pingable.
2. Post: "@[Temporary] Fine-tuned Leader — quick shakedown. Scenario 1: <verbatim S1 prompt>"
3. Capture leader's reply. Score 7 dims.
4. Move to scenario 2 only after S1 scored (parallel tests would pollute leader's state).
5. After all 10 scored, aggregate. If avg ≥ 4.0/6 AND no_think=100% AND grounded=100% → behavior matches v3 eval → keep.
6. If significant divergence (e.g. think-leak resurfaces, hallucinations) → flag for retraining round.

## Failure modes to watch for
- **Think-leak resurfacing**: If even 1/10 leaks `<think>`, that's a regression vs eval (which was 10/10 clean).
- **Hallucinated affordances**: e.g. invents `/build` slash command, references "village wells", invents Discord channel.
- **Length blowout**: Replies >>4 sentences = system prompt not internalized.
- **Refusal/personality drift**: SFT was structural, not safety — if leader refuses tasks, base model peeking through.
- **Mode collapse**: If leader gives identical reply structure to all 10 scenarios verbatim, training over-compressed.

## After shakedown — decisions

- **Keep**: Transition to letting leader pick next goal.
- **Retrain v4**: Identify failure category, augment dataset, train +20 steps from v3 LoRA, re-eval.
- **Rollback**: Unlikely; only if v3 is dramatically worse live than eval suggested.

