# Sourced by install-appimage and maprisma-toggle (POSIX sh).
uid=$(id -u)
# A folder only this user can change: a real directory (no symlink), owned by us, and neither group nor
# others may write to it. Inside such a folder nobody else can plant or swap a name between a check
# and its use.
private_dir() {
  [ -d "$1" ] && [ ! -L "$1" ] && [ -O "$1" ] || return 1
  mode=$(stat -c '%a' -- "$1") || return 1
  other=${mode#"${mode%?}"}
  group=${mode%?}
  group=${group#"${group%?}"}
  case "$group$other" in *[2367]*) return 1 ;; esac
}
# An ancestor of such a folder: nobody else may rename entries in it. A real directory (never a
# symlink, whoever owns it), ours or root's and not writable by group or others, or root's with the
# sticky bit (like /tmp).
stable_dir() {
  [ -d "$1" ] && [ ! -L "$1" ] || return 1
  owner=$(stat -c '%u' -- "$1") || return 1
  [ "$owner" = "$uid" ] || [ "$owner" = 0 ] || return 1
  mode=$(stat -c '%a' -- "$1") || return 1
  other=${mode#"${mode%?}"}
  group=${mode%?}
  group=${group#"${group%?}"}
  case "$group$other" in *[2367]*) ;; *) return 0 ;; esac
  [ "$owner" = 0 ] && [ ${#mode} -eq 4 ] && case "$mode" in [1357]*) true ;; *) false ;; esac
}
# An absolute, normalised path: no trailing slash, no //, no . or .. part. Then every symlink test
# and the walk below see each real component.
plain_path() {
  case "$1" in /?*) ;; *) return 1 ;; esac
  case "$1" in */ | *//* | */./* | */../* | */. | */..) return 1 ;; esac
}
# The folder itself private, and every folder above it stable, up to /.
private_tree() {
  plain_path "$1" && private_dir "$1" || return 1
  here=$1
  while :; do
    up=${here%/*}
    [ -n "$up" ] || up=/
    [ "$up" != "$here" ] || return 1
    stable_dir "$up" || return 1
    [ "$up" = / ] && return 0
    here=$up
  done
}
