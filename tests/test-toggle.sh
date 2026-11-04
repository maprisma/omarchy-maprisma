#!/bin/sh
# Fixture-only: never reaches GitHub or a real terminal.
set -eu
here=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT HUP INT TERM
mkdir -p "$work/bin" "$work/with" "$work/release" "$work/tmp" "$work/home"
for tool in dirname uname jq sha256sum awk mktemp mkdir install ln wc rm cp flock setsid sleep stat id; do
  ln -s "$(command -v "$tool")" "$work/bin/$tool"
done
cat > "$work/bin/xdg-terminal-exec" <<'SH'
#!/bin/sh
while [ "$#" -gt 0 ] && [ "$1" != -- ]; do shift; done
[ "$#" -gt 0 ] || exit 2
shift
exec "$@"
SH
cat > "$work/bin/curl" <<'SH'
#!/bin/sh
url= destination=
while [ "$#" -gt 0 ]; do
  case "$1" in
    -o) destination=$2; shift 2 ;;
    https://*) url=$1; shift ;;
    *) shift ;;
  esac
done
case "$url" in
  https://api.github.com/repos/maprisma/maprisma/releases/latest)
    [ "${MAPRISMA_TEST_NO_RELEASE:-0}" != 1 ] || exit 22
    cp "$MAPRISMA_TEST_RELEASE/release.json" "$destination" ;;
  */Maprisma-1.0.0-x86_64.AppImage)
    # A directory appearing at the target while the download runs (the race ln -T must catch).
    [ -z "${MAPRISMA_TEST_MKDIR_TARGET:-}" ] || mkdir -p "$MAPRISMA_TEST_MKDIR_TARGET"
    cp "$MAPRISMA_TEST_RELEASE/image" "$destination" ;;
  */Maprisma-1.0.0-x86_64.AppImage.sha256)
    cp "$MAPRISMA_TEST_RELEASE/checksum" "$destination" ;;
  *) exit 22 ;;
esac
SH
cat > "$work/with/maprisma" <<'SH'
#!/bin/sh
printf '%s\n' "$*" > "$MAPRISMA_TEST_LOG"
SH
cat > "$work/release/image" <<'SH'
#!/bin/sh
printf '%s\n' "$*" > "$HOME/launched"
SH
chmod +x "$work/bin/xdg-terminal-exec" "$work/bin/curl" "$work/with/maprisma" "$work/release/image"
asset=Maprisma-1.0.0-x86_64.AppImage
digest=$(sha256sum "$work/release/image")
printf '%s  %s\n' "${digest%% *}" "$asset" > "$work/release/checksum"
cat > "$work/release/release.json" <<EOF
{"tag_name":"v1.0.0","assets":[
  {"name":"$asset","browser_download_url":"https://github.com/maprisma/maprisma/releases/download/v1.0.0/$asset"},
  {"name":"$asset.sha256","browser_download_url":"https://github.com/maprisma/maprisma/releases/download/v1.0.0/$asset.sha256"}
]}
EOF
export MAPRISMA_TEST_LOG="$work/dialog" MAPRISMA_TEST_RELEASE="$work/release"
export TMPDIR="$work/tmp" HOME="$work/home" XDG_RUNTIME_DIR="$work/tmp"

PATH="$work/with:$work/bin" /bin/sh "$here/maprisma-toggle"
[ "$(cat "$work/dialog")" = '--toggle' ] || { echo 'FAIL: installed app args'; exit 1; }
[ ! -e pwned ] || { echo 'FAIL: input was executed'; exit 1; }
if PATH="$work/with:$work/bin" /bin/sh "$here/maprisma-toggle" '--settings' '$(touch pwned)'; then
  echo 'FAIL: unexpected args accepted'; exit 1
fi
[ ! -e pwned ] || { echo 'FAIL: input was executed'; exit 1; }
PATH="$work/with:$work/bin" /bin/sh "$here/maprisma-toggle" --probe
if PATH="$work/bin" /bin/sh "$here/maprisma-toggle" --probe; then
  echo 'FAIL: missing app was detected'; exit 1
fi
[ ! -e "$HOME/.local/bin/maprisma" ] || { echo 'FAIL: probe installed'; exit 1; }
grep -q 'KeyboardPanel' "$here/BarWidget.qml" || { echo 'FAIL: install dialog missing'; exit 1; }
grep -q 'Install AppImage' "$here/I18n.js" || { echo 'FAIL: install action missing'; exit 1; }
# QML loads I18n.js only with ".pragma library"; without the dot the bar icon fails.
[ "$(head -n 1 "$here/I18n.js")" = '.pragma library' ] || { echo 'FAIL: I18n.js must start with .pragma library'; exit 1; }
if command -v node >/dev/null 2>&1; then
  tail -n +2 "$here/I18n.js" | node --check - 2>/dev/null || { echo 'FAIL: I18n.js is not valid JavaScript'; exit 1; }
fi
for language in en de es fr it nl pl pt; do
  grep -q "  $language:" "$here/I18n.js" || { echo "FAIL: missing $language text"; exit 1; }
done

PATH="$work/bin" /bin/sh "$here/maprisma-toggle" --install
[ -x "$HOME/.local/bin/maprisma" ] || { echo 'FAIL: app not installed'; exit 1; }
for n in 1 2 3 4 5 6 7 8 9 10; do
  [ -e "$HOME/launched" ] && break
  sleep .1
done
[ "$(cat "$HOME/launched")" = '--toggle' ] || { echo 'FAIL: app not opened'; exit 1; }
PATH="$work/bin" /bin/sh "$here/maprisma-toggle"
[ "$(cat "$HOME/launched")" = '--toggle' ] || { echo 'FAIL: second click'; exit 1; }

# A missing terminal launcher is said in a notification, not silently ignored.
mkdir -p "$work/noterm" "$work/notify-home"
for tool in dirname; do ln -s "$(command -v "$tool")" "$work/noterm/$tool"; done
cat > "$work/noterm/notify-send" <<'SH'
#!/bin/sh
printf '%s\n' "$*" > "$HOME/notified"
SH
chmod +x "$work/noterm/notify-send"
HOME="$work/notify-home" PATH="$work/noterm" /bin/sh "$here/maprisma-toggle" --install \
  && { echo 'FAIL: install without a terminal succeeded'; exit 1; }
grep -q 'xdg-terminal-exec' "$work/notify-home/notified" || { echo 'FAIL: no notice without a terminal'; exit 1; }

# A second install while one runs is refused and leaves nothing behind.
mkdir "$work/busy-home"
mkdir -p -m 700 "$work/tmp/maprisma-install"
exec 8<"$work/tmp/maprisma-install"
flock -n 8
HOME="$work/busy-home" PATH="$work/bin" /bin/sh "$here/install-appimage" > "$work/failure" 2>&1 \
  && { echo 'FAIL: second install ran'; exit 1; }
grep -q 'already being installed' "$work/failure" || { echo 'FAIL: second install not explained'; exit 1; }
[ ! -e "$work/busy-home/.local/bin/maprisma" ] || { echo 'FAIL: second install installed'; exit 1; }
exec 8>&-

# Without XDG_RUNTIME_DIR the lock goes to the user's own ~/.cache, never a shared folder; a symlink
# planted at the lock's name is refused and its target stays as it was.
mkdir -p "$work/nolock-home"
( unset XDG_RUNTIME_DIR; HOME="$work/nolock-home" MAPRISMA_TEST_NO_RELEASE=1 PATH="$work/bin" \
  /bin/sh "$here/install-appimage" > "$work/failure" 2>&1 ) && { echo 'FAIL: no-runtime-dir run succeeded'; exit 1; }
[ -d "$work/nolock-home/.cache/maprisma-install" ] || { echo 'FAIL: lock not in ~/.cache'; exit 1; }
mkdir -p "$work/planted-home/.cache"
printf 'keep\n' > "$work/victim"
ln -s "$work/victim" "$work/planted-home/.cache/maprisma-install"
( unset XDG_RUNTIME_DIR; HOME="$work/planted-home" PATH="$work/bin" \
  /bin/sh "$here/install-appimage" > "$work/failure" 2>&1 ) && { echo 'FAIL: planted lock accepted'; exit 1; }
[ "$(cat "$work/victim")" = keep ] || { echo 'FAIL: planted lock truncated its target'; exit 1; }
[ ! -e "$work/planted-home/.local/bin/maprisma" ] || { echo 'FAIL: planted lock installed'; exit 1; }
# Hostile lock paths: a runtime folder others may write to, a FIFO (must not block), a regular file
# with contents (refused and untouched).
timeout=$(command -v timeout)
hostile() {  # name, then the setup run in the lock's parent folder
  name=$1; shift
  h=$work/hostile-$name; mkdir -p "$h/home" "$h/run"; chmod 700 "$h/run"
  ( cd "$h/run" && eval "$*" )
  ( HOME="$h/home" XDG_RUNTIME_DIR="$h/run" PATH="$work/bin" "$timeout" 20 \
    /bin/sh "$here/install-appimage" < /dev/null > "$work/failure" 2>&1 ) && status=0 || status=$?
  [ "$status" -ne 0 ] && [ "$status" -ne 124 ] || { echo "FAIL: hostile lock $name (exit $status)"; exit 1; }
  [ ! -e "$h/home/.local/bin/maprisma" ] || { echo "FAIL: hostile lock $name installed"; exit 1; }
}
hostile permissive 'chmod 777 .'
grep -q 'may be changed by others' "$work/failure" || { echo 'FAIL: permissive folder not explained'; exit 1; }
hostile fifo 'mkfifo maprisma-install'
# A runtime folder given with a trailing slash, a relative one, and one with a dot part: refused
# before any use (a trailing slash would look through a symlink; a relative one could loop).
for odd in "$work/tmp/" . "$work/./tmp"; do
  ( HOME="$work/odd-home" XDG_RUNTIME_DIR="$odd" PATH="$work/bin" "$timeout" 20 \
    /bin/sh "$here/install-appimage" < /dev/null > "$work/failure" 2>&1 ) && status=0 || status=$?
  [ "$status" -ne 0 ] && [ "$status" -ne 124 ] || { echo "FAIL: odd runtime folder $odd (exit $status)"; exit 1; }
  grep -q 'may be changed by others' "$work/failure" || { echo "FAIL: odd runtime folder $odd not explained"; exit 1; }
done
hostile file 'printf "keep\n" > maprisma-install'
[ "$(cat "$work/hostile-file/run/maprisma-install")" = keep ] || { echo 'FAIL: lock file contents changed'; exit 1; }
# ~/.local/bin that others may write to: refused before any stage file is made there.
mkdir -p "$work/shared-bin-home/.local/bin"; chmod 777 "$work/shared-bin-home/.local/bin"
HOME="$work/shared-bin-home" PATH="$work/bin" /bin/sh "$here/install-appimage" > "$work/failure" 2>&1 \
  && { echo 'FAIL: shared ~/.local/bin accepted'; exit 1; }
[ -z "$(ls -A "$work/shared-bin-home/.local/bin")" ] || { echo 'FAIL: shared ~/.local/bin got files'; exit 1; }
[ "$(stat -c %a "$work/shared-bin-home/.local/bin")" = 777 ] || { echo 'FAIL: installer changed the mode of ~/.local/bin'; exit 1; }
# A private ~/.local/bin (700) keeps its mode after an install.
mkdir -p "$work/private-bin-home/.local/bin"; chmod 700 "$work/private-bin-home/.local/bin"
HOME="$work/private-bin-home" PATH="$work/bin" /bin/sh "$here/install-appimage" > "$work/failure" 2>&1 \
  || { echo 'FAIL: install into a private ~/.local/bin'; cat "$work/failure"; exit 1; }
[ "$(stat -c %a "$work/private-bin-home/.local/bin")" = 700 ] || { echo 'FAIL: private ~/.local/bin opened up'; exit 1; }
# ~/.local that others may write to (they could swap bin after the check): refused, nothing written.
mkdir -p "$work/shared-local-home/.local/bin"; chmod 777 "$work/shared-local-home/.local"
HOME="$work/shared-local-home" PATH="$work/bin" /bin/sh "$here/install-appimage" > "$work/failure" 2>&1 \
  && { echo 'FAIL: shared ~/.local accepted'; exit 1; }
[ -z "$(ls -A "$work/shared-local-home/.local/bin")" ] || { echo 'FAIL: shared ~/.local got files'; exit 1; }
# $TMPDIR is never used: an unsafe one (writable by all, not sticky) changes nothing and stays empty.
mkdir -p "$work/open-tmp" "$work/tmpdir-home"; chmod 777 "$work/open-tmp"
HOME="$work/tmpdir-home" TMPDIR="$work/open-tmp" PATH="$work/bin" /bin/sh "$here/install-appimage" > "$work/failure" 2>&1 \
  || { echo 'FAIL: install with an unsafe TMPDIR'; cat "$work/failure"; exit 1; }
[ -z "$(ls -A "$work/open-tmp")" ] || { echo 'FAIL: installer wrote into TMPDIR'; exit 1; }
# A directory appearing at the target during the download: ln -T fails, nothing lands inside it.
mkdir -p "$work/race-home"
HOME="$work/race-home" MAPRISMA_TEST_MKDIR_TARGET="$work/race-home/.local/bin/maprisma" PATH="$work/bin" \
  /bin/sh "$here/install-appimage" > "$work/failure" 2>&1 && { echo 'FAIL: directory at target accepted'; exit 1; }
[ -z "$(ls -A "$work/race-home/.local/bin/maprisma")" ] || { echo 'FAIL: app linked into the directory'; exit 1; }
set -- "$work/race-home/.local/bin"/.maprisma-install.*
[ ! -e "$1" ] || { echo 'FAIL: race left a stage'; exit 1; }

mkdir "$work/failed-home"
HOME="$work/failed-home" MAPRISMA_TEST_NO_RELEASE=1 \
  PATH="$work/bin" /bin/sh "$here/maprisma-toggle" --install > "$work/failure" 2>&1 \
  && { echo 'FAIL: missing release succeeded'; exit 1; }
[ ! -e "$work/failed-home/.local/bin/maprisma" ] || { echo 'FAIL: missing release installed'; exit 1; }
# A signal after the final hard link is made must remove our target and stage.
mv "$work/bin/ln" "$work/bin/ln.real"
cat > "$work/bin/ln" <<'SH'
#!/bin/sh
"$MAPRISMA_TEST_REAL_LN" "$@" || exit
kill -"${MAPRISMA_TEST_SIGNAL:-TERM}" "$PPID"
SH
chmod +x "$work/bin/ln"
MAPRISMA_TEST_REAL_LN=$(command -v ln)
export MAPRISMA_TEST_REAL_LN
for signal in TERM INT; do
  signal_home=$work/signal-$signal
  mkdir "$signal_home"
  HOME="$signal_home" MAPRISMA_TEST_SIGNAL="$signal" PATH="$work/bin" \
    /bin/sh "$here/install-appimage" > "$work/failure" 2>&1 \
    && { echo "FAIL: $signal install succeeded"; exit 1; }
  [ ! -e "$signal_home/.local/bin/maprisma" ] || { echo "FAIL: $signal left an app"; exit 1; }
  set -- "$signal_home/.local/bin"/.maprisma-install.*
  [ ! -e "$1" ] || { echo "FAIL: $signal left a stage"; exit 1; }
  if [ "$signal" = INT ]; then
    grep -q 'Cancelled. Nothing was installed.' "$work/failure" \
      || { echo 'FAIL: INT cancellation was not explained'; exit 1; }
  fi
done
rm "$work/bin/ln"
mv "$work/bin/ln.real" "$work/bin/ln"
# Once committed, interruption keeps the app but still removes the stage.
mv "$work/bin/rm" "$work/bin/rm.real"
cat > "$work/bin/rm" <<'SH'
#!/bin/sh
"$MAPRISMA_TEST_REAL_RM" "$@" || exit
case "$*" in *'/.maprisma-install.'*) kill -TERM "$PPID" ;; esac
SH
chmod +x "$work/bin/rm"
MAPRISMA_TEST_REAL_RM=$(command -v rm)
export MAPRISMA_TEST_REAL_RM
mkdir "$work/committed-home"
HOME="$work/committed-home" PATH="$work/bin" \
  /bin/sh "$here/install-appimage" > "$work/failure" 2>&1 \
  && { echo 'FAIL: signal after commit was ignored'; exit 1; }
[ -x "$work/committed-home/.local/bin/maprisma" ] || { echo 'FAIL: committed app was removed'; exit 1; }
set -- "$work/committed-home/.local/bin"/.maprisma-install.*
[ ! -e "$1" ] || { echo 'FAIL: committed stage remained'; exit 1; }
# The stand-in rm signals again while the clean-up removes the stage: the
# clean-up must still finish and remove the download folder.
for left in "$work/tmp"/maprisma-install/download.*; do
  [ ! -d "$left" ] || { echo 'FAIL: a second signal cut the clean-up short'; exit 1; }
done
rm "$work/bin/rm"
mv "$work/bin/rm.real" "$work/bin/rm"
printf '%064d  %s\n' 0 "$asset" > "$work/release/checksum"
HOME="$work/failed-home" PATH="$work/bin" \
  /bin/sh "$here/maprisma-toggle" --install > "$work/failure" 2>&1 \
  && { echo 'FAIL: wrong checksum succeeded'; exit 1; }
[ ! -e "$work/failed-home/.local/bin/maprisma" ] || { echo 'FAIL: wrong checksum installed'; exit 1; }
cat > "$work/release/release.json" <<EOF
{"tag_name":"v1.0.0","assets":[
  {"name":"$asset","browser_download_url":"https://example.com/$asset"},
  {"name":"$asset.sha256","browser_download_url":"https://github.com/maprisma/maprisma/releases/download/v1.0.0/$asset.sha256"}
]}
EOF
HOME="$work/failed-home" PATH="$work/bin" \
  /bin/sh "$here/maprisma-toggle" --install > "$work/failure" 2>&1 \
  && { echo 'FAIL: outside release link accepted'; exit 1; }
# Dot segments between the release prefix and the asset (curl would normalise them into another
# repository): refused, even when both links agree.
evil=https://github.com/maprisma/maprisma/releases/download/v1.0.0/../../../../other/repo/releases/download/v1.0.0
cat > "$work/release/release.json" <<EOF
{"tag_name":"v1.0.0","assets":[
  {"name":"$asset","browser_download_url":"$evil/$asset"},
  {"name":"$asset.sha256","browser_download_url":"$evil/$asset.sha256"}
]}
EOF
HOME="$work/failed-home" PATH="$work/bin" /bin/sh "$here/install-appimage" > "$work/failure" 2>&1 \
  && { echo 'FAIL: dot-segment link accepted'; exit 1; }
grep -q 'outside the Maprisma release' "$work/failure" || { echo 'FAIL: dot-segment link not explained'; exit 1; }
[ ! -e "$work/failed-home/.local/bin/maprisma" ] || { echo 'FAIL: dot-segment link installed'; exit 1; }
[ ! -e "$work/failed-home/.local/bin/maprisma" ] || { echo 'FAIL: outside link installed'; exit 1; }
mkdir -p "$work/failed-home/.local/bin"
printf 'keep\n' > "$work/keep"
ln -s "$work/keep" "$work/failed-home/.local/bin/maprisma"
HOME="$work/failed-home" PATH="$work/bin" \
  /bin/sh "$here/install-appimage" > "$work/failure" 2>&1 \
  && { echo 'FAIL: existing target replaced'; exit 1; }
[ "$(cat "$work/keep")" = keep ] || { echo 'FAIL: existing file changed'; exit 1; }
echo 'toggle: OK'
