#!/usr/bin/env bash
# profile-apply.sh — switch a profile on or off by sparse checkout. A profile hides the
# scaffolding of the engines a project does not use; the files stay in git, so a
# `git merge` of upstream still works and nothing conflicts on a release.
#
# Usage: bash .claude/scripts/profile-apply.sh <profile> | --restore | --status [--root DIR]
#   <profile>   apply .claude/profiles/<profile>.sparse: git sparse-checkout, no-cone mode
#   --restore   turn the sparse checkout off: every hidden path is back on disk
#   --status    one row per hidden path of the profile in project.yaml (`profile:`), or of
#               the one applied, with how many tracked files under it are hidden
#   --root DIR  the project; defaults to the repo this script is in
#   -h, --help  this text
#
# Observations only, never verdicts. Output: TSV.
#   applied   <profile> <rows>                  the profile now applied
#   restored  <hidden files that came back>
#   group     <name> <reason>                   a group header from the .sparse file
#   path      <pattern> hidden|visible|untracked <hidden files> <tracked files>
#   total     <profile> <hidden files> <tracked files>
#   profile   none                              no profile applied
#   note      <text>
# A group's rows follow its `group` row. Exit 0 whatever was found; 2 for a usage error.
# Git Bash safe: grep -E, awk, no jq, no python.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=""; MODE=""; PROFILE=""
usage() { sed -n '2,/^# Git Bash safe/p' "$0" | sed 's/^# \{0,1\}//' | head -24; }
while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT=$2; shift 2 ;;
    --restore) MODE=restore; shift ;;
    --status) MODE=status; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "usage: unknown option $1" >&2; exit 2 ;;
    *) MODE=apply; PROFILE=$1; shift ;;
  esac
done
[ -n "$MODE" ] || { echo "usage: profile-apply.sh <profile> | --restore | --status" >&2; exit 2; }
[ -n "$ROOT" ] || ROOT=$(cd "$HERE/../.." && pwd)
cd "$ROOT" 2>/dev/null || { echo "usage: no such root $ROOT" >&2; exit 2; }
git rev-parse --git-dir >/dev/null 2>&1 || { printf 'note\tnot a git checkout: a profile needs one\n'; exit 0; }

# rules FILE — the non-comment, non-blank lines
rules() { grep -vE '^[[:space:]]*(#|$)' "$1" | tr -d '\r'; }
# hidden_count PATHSPEC — tracked files under it that are skipped in the working tree
count_hidden() { git ls-files -t -- "$1" 2>/dev/null | grep -cE '^S '; }
count_tracked() { git ls-files -- "$1" 2>/dev/null | grep -c .; }

applied_profile() {
  # project.yaml's `profile:` key, else none
  [ -f project.local.yaml ] && p=$(awk -F: '$1=="profile"{gsub(/[ "\r]/,"",$2);print $2;exit}' project.local.yaml)
  [ -n "$p" ] || p=$(awk -F: '$1=="profile"{gsub(/[ "\r]/,"",$2);print $2;exit}' project.yaml 2>/dev/null)
  printf '%s' "$p"
}

case "$MODE" in
  apply)
    F=".claude/profiles/$PROFILE.sparse"
    [ -f "$F" ] || { echo "usage: no profile file $F" >&2; exit 2; }
    git sparse-checkout set --no-cone --stdin < <(rules "$F") >/dev/null 2>&1 \
      || { printf 'note\tgit sparse-checkout failed; nothing applied\n'; exit 0; }
    n=$(rules "$F" | grep -cE '^!')
    printf 'applied\t%s\t%s\n' "$PROFILE" "$n"
    ;;
  restore)
    before=$(git ls-files -t 2>/dev/null | grep -cE '^S ')
    git sparse-checkout disable >/dev/null 2>&1
    printf 'restored\t%s\n' "$before"
    ;;
  status)
    PROFILE=$(applied_profile)
    F=".claude/profiles/$PROFILE.sparse"
    if [ -z "$PROFILE" ] || [ ! -f "$F" ]; then printf 'profile\tnone\n'; exit 0; fi
    th=0; tt=0
    while IFS= read -r line; do
      case "$line" in
        '# group:'*) g=${line#\# group: }; printf 'group\t%s\t%s\n' "${g%% - *}" "${g#* - }" ;;
        '!'*)
          pat=${line#!/}; spec=$pat
          case "$pat" in *'*'*) spec=":(glob)$pat" ;; esac
          t=$(count_tracked "$spec"); h=$(count_hidden "$spec")
          if [ "$t" = 0 ]; then st=untracked; elif [ "$h" = "$t" ]; then st=hidden; else st=visible; fi
          printf 'path\t%s\t%s\t%s\t%s\n' "$line" "$st" "$h" "$t"
          th=$((th + h)); tt=$((tt + t)) ;;
      esac
    done < <(tr -d '\r' < "$F" | grep -E '^(# group:|!)')
    printf 'total\t%s\t%s\t%s\n' "$PROFILE" "$th" "$tt"
    if [ "$th" -gt 0 ] && [ -f .claude/scripts/one-shot-new.sh ]; then
      printf 'note\t%s\n' "the prototype browser sketch (one-shot-*.sh, vendor-three.sh) needs hidden web templates; --restore to use it"
    fi
    ;;
esac
exit 0
