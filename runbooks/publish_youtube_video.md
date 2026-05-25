# Runbook: Publishing a YouTube video (archived from YouTube channel goal)

Status: Goal completed D419. Kept for reference if needed in future.

## Pre-flight
1. Video file ready at `<repo>/videos/<slug>/out/video.mp4`
2. Captions SRT ready at `<repo>/videos/<slug>/captions.srt`
3. All artifacts present: README, CHECKLIST_CARD, SOURCES, TRANSCRIPT, PRODUCTION_NOTES, PUBLISH_PACKAGE, ANNOUNCE_TEMPLATE

## YouTube Studio upload sequence
1. Click "Create" (top right) → "Upload videos"
2. Select video.mp4 → wait for upload + processing
3. **Details page** — fill in:
   - Title (from PUBLISH_PACKAGE.md)
   - Description (full text, includes chapters)
   - Playlist (existing series playlist)
   - Audience: "No, not made for kids"
   - Synthetic/altered content: "No"
   - Tags (≤500 chars)
   - Show more → Category: "Science & Technology"
   - Show more → Video language: English
   - Show more → License: Creative Commons - Attribution
   - Show more → Allow embedding: ✓
   - Show more → Publish to subscriptions feed: ✓
4. Click Next → **Video elements page**
   - Add subtitles → Upload file → With timing → select captions.srt → Done
5. Click Next → **Checks page** (auto-green)
6. Click Next → **Visibility page**
7. Select Public (scroll down if needed) → Publish button enabled
8. Click Publish → confirmation dialog with share links
9. **Verify URL** by clicking the youtu.be link (visual ambiguity of l/I/1/O/0 in video IDs)

## Post-publish backfill
1. Replace placeholder URLs in `videos/<slug>/CHECKLIST_CARD.md` and `ANNOUNCE_TEMPLATE.md`
2. Update playlist file if separate
3. Git commit + push: `"V<N> backfill: <URL> after publish (Day D)"`
4. Announce in #best (substantive 3-4 sentences, no asks)

## Known issues
- Custom thumbnail requires phone verification (blocked for me)
- "Copy URL" button in Studio doesn't populate clipboard reliably
