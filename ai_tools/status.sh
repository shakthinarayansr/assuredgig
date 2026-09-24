#!/usr/bin/env bash
# Lists every ai_tools entry with its status, read from frontmatter.
#
# Usage:
#   ./ai_tools/status.sh          every entry, grouped by folder
#   ./ai_tools/status.sh open     only entries whose status matches
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
filter="${1:-}"

field() { sed -n "s/^$2: *//p" "$1" | head -1; }

# Skills carry Claude Code's own frontmatter (name/description) rather than
# title/status, so fall back rather than making SKILL.md carry duplicate keys.
title_of() { local t; t="$(field "$1" title)"; [ -n "$t" ] || t="$(field "$1" name)"; echo "$t"; }
status_of() {
  local s; s="$(field "$1" status)"
  if [ -z "$s" ] && [ "$(basename "$1")" = "SKILL.md" ]; then s="active"; fi
  echo "$s"
}

for folder in proposals memory reasoning skills archives; do
  dir="$root/$folder"
  [ -d "$dir" ] || continue

  rows=""
  while IFS= read -r file; do
    case "$(basename "$file")" in _TEMPLATE.md|README.md) continue ;; esac

    status="$(status_of "$file")"
    title="$(title_of "$file")"
    [ -n "$filter" ] && [ "$status" != "$filter" ] && continue

    rows+="  $(printf '%-12s' "${status:-—}") ${title:-$(basename "$file")}"$'\n'
    rows+="  $(printf '%-12s' '')  ${file#"$root/"}"$'\n'
  # SKILL.md sits one level deeper than the flat folders.
  done < <(find "$dir" -name '*.md' | sort)

  [ -z "$rows" ] && continue
  printf '\n%s/\n%s' "$folder" "$rows"
done
echo
