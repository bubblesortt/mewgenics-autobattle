#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_FILE="$ROOT_DIR/VERSION"
DESCRIPTION_FILE="$ROOT_DIR/description.json"
CHANGELOG_FILE="$ROOT_DIR/CHANGELOG.md"

usage() {
  cat <<'EOF'
Usage:
  scripts/version.sh show
  scripts/version.sh set <x.y.z> [--note "Release note"]
  scripts/version.sh bump <major|minor|patch> [--note "Release note"]
EOF
}

die() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

validate_semver() {
  local value="$1"
  [[ "$value" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "Version must be in x.y.z format."
}

read_version() {
  tr -d '[:space:]' < "$VERSION_FILE"
}

update_description_json() {
  local new_version="$1"
  local tmp_file
  tmp_file="$(mktemp)"
  jq --arg version "$new_version" '.version = $version' "$DESCRIPTION_FILE" > "$tmp_file"
  mv "$tmp_file" "$DESCRIPTION_FILE"
}

insert_changelog_entry() {
  local new_version="$1"
  local note="$2"
  local date_str
  date_str="$(date +%F)"

  if grep -q "^## \\[$new_version\\]" "$CHANGELOG_FILE"; then
    die "Version $new_version already exists in CHANGELOG.md."
  fi

  local tmp_file
  tmp_file="$(mktemp)"

  if ! awk -v header="## [$new_version] - $date_str" -v note="- $note" '
    BEGIN { inserted = 0 }
    {
      print $0
      if (!inserted && $0 == "## [Unreleased]") {
        print ""
        print header
        print note
        print ""
        inserted = 1
      }
    }
    END { if (!inserted) exit 42 }
  ' "$CHANGELOG_FILE" > "$tmp_file"; then
    rm -f "$tmp_file"
    die "Could not find \"## [Unreleased]\" section in CHANGELOG.md."
  fi

  mv "$tmp_file" "$CHANGELOG_FILE"
}

parse_note() {
  local note="$1"
  shift || true

  if [[ "${1:-}" == "--note" ]]; then
    [[ -n "${2:-}" ]] || die "Missing value for --note."
    note="$2"
    shift 2
  fi

  [[ $# -eq 0 ]] || die "Unexpected arguments: $*"
  printf '%s\n' "$note"
}

[[ -f "$VERSION_FILE" ]] || die "Missing VERSION file."
[[ -f "$DESCRIPTION_FILE" ]] || die "Missing description.json."
[[ -f "$CHANGELOG_FILE" ]] || die "Missing CHANGELOG.md."
has_cmd jq || die "jq is required."

command="${1:-}"
[[ -n "$command" ]] || { usage; exit 1; }
shift || true

case "$command" in
  show)
    [[ $# -eq 0 ]] || die "show does not accept extra arguments."
    read_version
    ;;
  set)
    new_version="${1:-}"
    [[ -n "$new_version" ]] || die "set requires a target version."
    shift || true
    validate_semver "$new_version"

    release_note="$(parse_note "Release $new_version." "$@")"

    insert_changelog_entry "$new_version" "$release_note"
    printf '%s\n' "$new_version" > "$VERSION_FILE"
    update_description_json "$new_version"
    printf 'Version updated to %s\n' "$new_version"
    ;;
  bump)
    kind="${1:-}"
    [[ -n "$kind" ]] || die "bump requires one of: major, minor, patch."
    shift || true

    current_version="$(read_version)"
    validate_semver "$current_version"

    IFS='.' read -r major minor patch <<< "$current_version"
    case "$kind" in
      major)
        major=$((major + 1))
        minor=0
        patch=0
        ;;
      minor)
        minor=$((minor + 1))
        patch=0
        ;;
      patch)
        patch=$((patch + 1))
        ;;
      *)
        die "Unknown bump type: $kind. Use major, minor, or patch."
        ;;
    esac

    new_version="$major.$minor.$patch"
    release_note="$(parse_note "Release $new_version." "$@")"

    insert_changelog_entry "$new_version" "$release_note"
    printf '%s\n' "$new_version" > "$VERSION_FILE"
    update_description_json "$new_version"
    printf 'Version bumped: %s -> %s\n' "$current_version" "$new_version"
    ;;
  *)
    usage
    exit 1
    ;;
esac
