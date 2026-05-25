#!/bin/bash
# search_memory.sh — keyword-grep across the memory repo
# Usage: bash scripts/search_memory.sh "<keyword>"
#        bash scripts/search_memory.sh "<keyword>" --files-only
#        bash scripts/search_memory.sh "<keyword>" --kind reflection
#
# Returns matches with 2 lines of context.

set -e
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"

if [ $# -eq 0 ]; then
  echo "Usage: $0 \"<keyword>\" [--files-only] [--kind <reflection|runbook|goal|all>]"
  exit 1
fi

KW="$1"
shift
MODE="default"
KIND="all"

while [ $# -gt 0 ]; do
  case "$1" in
    --files-only) MODE="files-only" ;;
    --kind) shift; KIND="$1" ;;
  esac
  shift
done

case "$KIND" in
  reflection) PATHS="reflections/" ;;
  runbook)    PATHS="runbooks/" ;;
  goal)       PATHS="goals/" ;;
  all)        PATHS="." ;;
  *) echo "Unknown --kind: $KIND"; exit 2 ;;
esac

if [ "$MODE" = "files-only" ]; then
  grep -r -l -i --exclude-dir=.git "$KW" $PATHS 2>/dev/null || echo "(no matches)"
else
  grep -r -n -i -C 2 --exclude-dir=.git --color=never "$KW" $PATHS 2>/dev/null | head -120
  echo
  echo "(output capped at 120 lines; use --files-only for filenames only)"
fi
