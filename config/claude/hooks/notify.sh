#!/bin/bash
read -r json
eval "$(echo "$json" | jq -r '@sh "message=\(.message // "Waiting for input") type=\(.notification_type // "") cwd=\(.cwd // "")"')"
cwd="${cwd##*/}"

osascript -e "display notification \"$message ($type) [$cwd]\" with title \"Claude Code\"" &
