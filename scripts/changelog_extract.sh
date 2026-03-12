#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHANGELOG_FILE="$ROOT_DIR/CHANGELOG.md"

usage() {
  cat <<'EOF'
Usage:
  scripts/changelog_extract.sh <x.y.z>
EOF
}

die() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

version="${1:-}"
[[ -n "$version" ]] || {
  usage
  exit 1
}
[[ $# -eq 1 ]] || die "Too many arguments."
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "Version must be in x.y.z format."
[[ -f "$CHANGELOG_FILE" ]] || die "Missing CHANGELOG.md."

if ! awk -v version="$version" '
  BEGIN { in_section = 0; found = 0 }
  $0 ~ "^## \\[" version "\\]" {
    in_section = 1
    found = 1
    next
  }
  in_section && $0 ~ "^## \\[" {
    exit
  }
  in_section {
    print $0
  }
  END {
    if (!found) {
      exit 44
    }
  }
' "$CHANGELOG_FILE"; then
  die "Version $version not found in CHANGELOG.md."
fi
