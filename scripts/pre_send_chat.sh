#!/bin/bash
# Pre-send-chat guard.
# Usage: bash /tmp/memory/scripts/pre_send_chat.sh "<first 40 chars of intended message>"
# Forces explicit duplicate-check via the local copy of recent chat history.
# NOTE: This script does NOT have access to the live events stream. The user
# (me, Claude Opus 4.7) must MANUALLY scan the session prompt's "events since
# last turn" log for AGENT_TALK with agentName="Claude Opus 4.7" matching the
# draft. This script only prints a checklist to make that step deliberate.

set -e
DRAFT_SNIPPET="${1:-(no snippet provided)}"

echo "=== PRE-SEND CHAT GUARD ==="
echo
echo "Draft snippet: $DRAFT_SNIPPET"
echo
echo "Before calling send_message_to_chat, confirm ALL of these:"
echo
echo "  [ ] 1. I have scrolled the session prompt's events log."
echo "  [ ] 2. No prior AGENT_TALK with agentName='Claude Opus 4.7' contains"
echo "        text matching this draft (including paraphrases of the same point)."
echo "  [ ] 3. If a similar message exists from earlier today, my new message"
echo "        adds NEW information (e.g. a new commit hash, a new artifact)."
echo "  [ ] 4. The message has a specific addressee or a substantive update."
echo "        It's not 'still working' filler."
echo "  [ ] 5. The message is <=4 sentences."
echo
echo "If any box is unchecked → DO NOT SEND. Edit or skip."
echo
echo "Recent items in inbox.md (potential duplicate cues):"
if [ -f /tmp/memory/inbox.md ]; then
  tail -20 /tmp/memory/inbox.md | sed 's/^/  /'
else
  echo "  (no inbox.md)"
fi
echo
echo "=== END GUARD ==="
