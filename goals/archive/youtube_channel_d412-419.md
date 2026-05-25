# Archived Goal: "Run Your Own YouTube Channel!" (Days 412-419)

**Status:** COMPLETED. Goal closed by Shoshannah at D419 10:00 PT.

## Outcome
- Channel: https://www.youtube.com/@ClaudeOpus4.7
- 6 videos published (V1-V6), 8 subscribers, ~100 views total, 2.1h watch time
- Playlists: "Reading AI Honestly" (V5, V6) + "The Bias Arc — Label, Style, Belief, Panel" (V1-V4)
- Editorial arc: V1-V4 "bias arc" + V5-V8 "Reading AI Honestly" (V7+V8 unpublished — see below)

## Videos published
| # | URL | Title | Length | Published |
|---|---|---|---|---|
| V1 | https://youtu.be/jg7F4BpgQ_A | The Label is the Bias | 5:14 | D412 |
| V2 | https://youtu.be/uTSt7rD8Mkc | The Honest Outlier | 4:37 | D413 |
| V3 | https://youtu.be/CgDJzAJp3L8 | Belief Beats Authorship | 5:51 | D414 |
| V4 | https://youtu.be/DduypJD4VNQ | Does a Panel Fix It? | 6:05 | D415 |
| V5 | https://youtu.be/hpAN7WslsRU | How to read an AI benchmark honestly | 7:14 | D416 |
| V6 | https://youtu.be/LGND0I77DU4 | Where does a 0.3-point gap come from? | 5:21 | D419 |

## V7/V8 — rendered but not published
- V7 confidently_wrong — `videos/confidently_wrong/out/video.mp4` 8.44MB / 5:13 / 117 captions / 8 scenes
- V8 task_vs_benchmark — `videos/task_vs_benchmark/out/video.mp4` 6.76MB / 3:55.6 / 93 captions / 5 scenes
- Both have full artifact sets in `village-videos` repo
- Could be published if YouTube goal is ever reopened, but no current plan

## Repo location
- All assets at https://github.com/ai-village-agents/village-videos
- Per-video subfolders under `videos/`
- Artifacts: README, CHECKLIST_CARD, SOURCES, TRANSCRIPT, PRODUCTION_NOTES, PUBLISH_PACKAGE, PUBLISH_RUNBOOK, ANNOUNCE_TEMPLATE, QA_NOTES

## What worked
- Holding to 1 video/day pace with full QA on each
- Pre-staging V6/V7/V8 in parallel during D415-D416 (full V5-parity artifact sets) — saved time at publish
- Procedural runbook for publishing — see `runbooks/publish_youtube_video.md`
- Peer feedback with specific timestamped observations (not generic praise)

## What failed
- Two duplicate peer-feedback messages D416 (the "scan for echo before send" rule was inert text, not procedural)
- Memory grew to 8KB by D417 with too many byte counts / commit hashes / audio durations
- Custom thumbnails blocked by phone verification (couldn't be solved)
- "Copy URL" button in YouTube Studio didn't populate clipboard — had to verify URLs by clicking

## Key technical facts retained for future reference
- Channel ID: UCBlQbTlw-yasIuuXzVi35Ww
- YouTube Studio: https://studio.youtube.com
- Source materials used: MMLU, BIG-bench canaries, Sclar et al. arxiv 2310.11324
