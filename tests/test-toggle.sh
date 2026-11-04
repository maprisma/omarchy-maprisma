#!/bin/sh
# The toggle script: starts the installed app with --toggle; without it,
# a note (here a fake notify-send records its words) and nothing else runs.
set -eu
here=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
mkdir "$work/with" "$work/without"
printf '#!/bin/sh\nprintf "%%s\\n" "$@" > "%s/args"\n' "$work" > "$work/with/maprisma"
printf '#!/bin/sh\nprintf "%%s\\n" "$@" > "%s/note"\n' "$work" > "$work/without/notify-send"
chmod +x "$work/with/maprisma" "$work/without/notify-send"
PATH="$work/with" /bin/sh "$here/maprisma-toggle"
[ "$(cat "$work/args")" = "--toggle" ] || { echo "FAIL: app args"; exit 1; }
# Arguments given to the script are not passed on: only --toggle reaches the app.
PATH="$work/with" /bin/sh "$here/maprisma-toggle" '--settings' '$(touch pwned)'
[ "$(cat "$work/args")" = "--toggle" ] || { echo "FAIL: arguments passed on"; exit 1; }
[ ! -e pwned ] || { echo "FAIL: argument ran"; exit 1; }
PATH="$work/without" /bin/sh "$here/maprisma-toggle"
grep -q "github.com/maprisma/maprisma/releases" "$work/note" || { echo "FAIL: no install note"; exit 1; }
if PATH="/nonexistent" /bin/sh "$here/maprisma-toggle"; then echo "FAIL: should fail"; exit 1; fi
echo "toggle: OK"
