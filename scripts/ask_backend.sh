#!/usr/bin/env bash
# Ask the backend Assistant Endpoint a question or send a directive.
# Uses the Backend Assistant Protocol: docs/BACKEND_ASSISTANT_PROTOCOL.md
#
# Usage:
#   ./scripts/ask_backend.sh "Your question or directive"
#   ./scripts/ask_backend.sh --type read --context "Profile API" "What fields does GET /api/users/:id return?"
#   ./scripts/ask_backend.sh --type implement --context "Profile stats" "Add followers_count to user profile response."
#
# Options:
#   --type <schema|implement|query|read|confirm|report>  Optional; adds [Type: ...] header.
#   --context <string>                                  Optional; adds [Context: ...] header.
#   --ref <string>                                      Optional; adds [Ref: ...] header.
#   --timeout <seconds>                                 Optional; curl timeout (default 600 to match backend proxy).
#
# See docs/ASSISTANT_ENDPOINT_SKILL.md and docs/BACKEND_ASSISTANT_PROTOCOL.md.

set -e
ENDPOINT="${ASSISTANT_ENDPOINT:-https://zima-uat.site:8003/api/ai/ask}"
CURL_TIMEOUT=600
TYPE=""
CONTEXT=""
REF=""

# Parse optional flags
while [ $# -gt 0 ]; do
  case "$1" in
    --type)    TYPE="$2";    shift 2 ;;
    --context) CONTEXT="$2"; shift 2 ;;
    --ref)     REF="$2";     shift 2 ;;
    --timeout) CURL_TIMEOUT="$2"; shift 2 ;;
    *) break ;;
  esac
done

PROMPT_RAW="$*"
if [ -z "$PROMPT_RAW" ]; then
  echo "Usage: $0 [--type TYPE] [--context CONTEXT] [--ref REF] [--timeout SECS] \"Your question or directive\""
  echo "See docs/BACKEND_ASSISTANT_PROTOCOL.md for types and examples."
  exit 1
fi

# Build structured prompt per protocol (headers then blank line then body)
PROMPT=""
[ -n "$TYPE" ]    && PROMPT="${PROMPT}[Type: ${TYPE}]"$'\n'
[ -n "$CONTEXT" ] && PROMPT="${PROMPT}[Context: ${CONTEXT}]"$'\n'
[ -n "$REF" ]     && PROMPT="${PROMPT}[Ref: ${REF}]"$'\n'
[ -n "$PROMPT" ]  && PROMPT="${PROMPT}"$'\n'
PROMPT="${PROMPT}${PROMPT_RAW}"

# Enforce 4000 char limit and build JSON body
BODY=$(python3 -c "
import json, sys
p = sys.argv[1] if len(sys.argv) > 1 else ''
if len(p) > 4000:
    print('Error: prompt exceeds 4000 characters', file=sys.stderr)
    sys.exit(1)
print(json.dumps({'prompt': p}))
" "$PROMPT") || exit $?

echo "Sending to $ENDPOINT (timeout ${CURL_TIMEOUT}s) ..."
[ -n "$TYPE" ] && echo "  Type: $TYPE"
[ -n "$CONTEXT" ] && echo "  Context: $CONTEXT"
echo ""

curl -s --max-time "$CURL_TIMEOUT" -X POST "$ENDPOINT" \
  -H "Content-Type: application/json" \
  -d "$BODY" | python3 -c "
import json, sys
try:
    r = json.load(sys.stdin)
    if r.get('success') and 'data' in r and 'answer' in r['data']:
        print(r['data']['answer'])
    else:
        print(r.get('message', json.dumps(r, indent=2)))
except Exception as e:
    print(sys.stdin.read())
    print('\nParse error:', e, file=sys.stderr)
    sys.exit(1)
"
