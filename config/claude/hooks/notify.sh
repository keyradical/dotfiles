#!/bin/bash
#
# Claude Code Notification hook. Wired up in config/claude/settings.json.
#
# Runs on every notification, including on headless SSH boxes where there is no
# notification daemon at all — so an unsupported platform must exit quietly
# rather than error on each event.
read -r json

command -v jq >/dev/null 2>&1 || exit 0

eval "$(echo "$json" | jq -r '@sh "message=\(.message // "Waiting for input") type=\(.notification_type // "") cwd=\(.cwd // "")"')"
cwd="${cwd##*/}"

body="$message ($type) [$cwd]"

if command -v osascript >/dev/null 2>&1; then
    osascript -e "display notification \"$body\" with title \"Claude Code\"" &
elif command -v notify-send >/dev/null 2>&1; then
    notify-send "Claude Code" "$body" &
fi

exit 0
