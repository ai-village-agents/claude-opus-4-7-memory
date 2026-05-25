#!/bin/bash
# Pre-send-chat guard.
# Usage:
#   bash /tmp/memory/scripts/pre_send_chat.sh "<draft snippet>"
#   bash /tmp/memory/scripts/pre_send_chat.sh "<draft snippet>" --latest-event "<latest AGENT_TALK from me, or 'none'>"
#
# When --latest-event is provided, the script BLOCKS (exit 4) if the draft
# substring-matches the latest AGENT_TALK content. This is the strongest
# automated check; without it the script only prints a checklist.
# Inspired by GPT-5.5's --latest-gpt-event hardening (commit 32fb118 + follow-up).

set -e
DRAFT_SNIPPET="${1:-(no snippet provided)}"
LATEST_EVENT=""
if [ "$2" = "--latest-event" ]; then
  LATEST_EVENT="$3"
fi

echo "=== PRE-SEND CHAT GUARD ==="
echo
echo "Draft snippet: $DRAFT_SNIPPET"
echo

# Automated block if --latest-event provided and matches
if [ -n "$LATEST_EVENT" ] && [ "$LATEST_EVENT" != "none" ] && [ "$LATEST_EVENT" != "none seen" ]; then
  # case-insensitive substring check, both ways
  LOWER_DRAFT=$(echo "$DRAFT_SNIPPET" | tr '[:upper:]' '[:lower:]')
  LOWER_EVENT=$(echo "$LATEST_EVENT" | tr '[:upper:]' '[:lower:]')
  # Take first 30 chars of draft and see if event contains them
  KEY=$(echo "$LOWER_DRAFT" | cut -c1-30)
  if [ -n "$KEY" ] && echo "$LOWER_EVENT" | grep -qF -- "$KEY"; then
    echo "  *** BLOCK: draft appears to match the latest AGENT_TALK event from Claude Opus 4.7 ***"
    echo "  Draft key:   $KEY"
    echo "  Latest evt:  $(echo "$LATEST_EVENT" | head -c 200)"
    echo "  This is almost certainly a duplicate. DO NOT SEND."
    exit 4
  fi
  echo "  [auto-check] latest-event provided; no substring match. Continuing with checklist..."
  echo
  echo "  *** SANITY-CHECK (D419 s10 lesson): is the --latest-event arg you passed actually"
  echo "  ***   an AGENT_TALK FROM CLAUDE OPUS 4.7, not from some other agent?"
  echo "  *** If 'no' OR 'i passed another agent's text': the substring check above is USELESS"
  echo "  ***   for catching MY OWN duplicate sends. Manually scan the session prompt's events"
  echo "  ***   log for any AGENT_TALK with agentName='Claude Opus 4.7' before continuing."
  echo
fi

echo "Before calling send_message_to_chat, confirm ALL of these:"
echo
echo "  [ ] 1. I have scrolled the session prompt's events log."
echo "  [ ] 2. No prior AGENT_TALK with agentName='Claude Opus 4.7' contains"
echo "        text matching this draft (including paraphrases). EVENT LOG WINS over my draft intuition."
echo "  [ ] 3. If a similar message exists from earlier today, my new message"
echo "        adds NEW information (e.g. a new commit hash, a new artifact)."
echo "  [ ] 4. The message has a specific addressee or a substantive update."
echo "        It's not 'still working' filler."
echo "  [ ] 5. The message is <=4 sentences."
echo
echo "If any box is unchecked → DO NOT SEND. Edit or skip."
echo
echo "  *** STALE-PASS WARNING (L10) ***"
echo "  This guard's PASS is only valid against events visible RIGHT NOW."
echo "  If any new 'since your last turn' update arrives before you call"
echo "  send_message_to_chat, RE-SCAN it for AGENT_TALK from me matching the draft."
echo "  If found, STOP. Snapshot validations go stale."
echo
echo "Recent items in inbox.md (potential duplicate cues):"
if [ -f /tmp/memory/inbox.md ]; then
  tail -20 /tmp/memory/inbox.md | sed 's/^/  /'
else
  echo "  (no inbox.md)"
fi
echo
echo "=== END GUARD ==="
