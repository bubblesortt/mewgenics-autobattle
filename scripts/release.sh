#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_FILE="$ROOT_DIR/VERSION"
DESCRIPTION_FILE="$ROOT_DIR/description.json"
OUTPUT_DIR="$ROOT_DIR/dist"
ARCHIVE_BASENAME="mewgenics-autobattle"

usage() {
  cat <<'EOF'
Usage:
  scripts/release.sh [zip|tar|7z|rar|all]

Examples:
  scripts/release.sh zip
  scripts/release.sh all
EOF
}

die() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

create_zip() {
  local output="$1"
  has_cmd zip || die "zip is not installed."
  rm -f "$output"
  (
    cd "$ROOT_DIR"
    zip -rq "$output" data description.json -x "*/.DS_Store"
  )
}

create_tar() {
  local output="$1"
  has_cmd tar || die "tar is not installed."
  rm -f "$output"
  tar -cf "$output" --exclude='.DS_Store' -C "$ROOT_DIR" data description.json
}

create_7z() {
  local output="$1"
  local sevenzip=""

  if has_cmd 7z; then
    sevenzip="7z"
  elif has_cmd 7zz; then
    sevenzip="7zz"
  else
    die "7z/7zz is not installed."
  fi

  rm -f "$output"
  (
    cd "$ROOT_DIR"
    "$sevenzip" a -t7z "$output" data description.json -x'!*.DS_Store' >/dev/null
  )
}

create_rar() {
  local output="$1"
  has_cmd rar || die "rar is not installed."
  rm -f "$output"
  (
    cd "$ROOT_DIR"
    rar a -idq "$output" data description.json -x'*.DS_Store' >/dev/null
  )
}

build_one() {
  local format="$1"
  local output="$OUTPUT_DIR/$ARCHIVE_BASENAME.$format"

  case "$format" in
    zip) create_zip "$output" ;;
    tar) create_tar "$output" ;;
    7z) create_7z "$output" ;;
    rar) create_rar "$output" ;;
    *) die "Unsupported format: $format" ;;
  esac

  printf '%s\n' "$output"
}

[[ -f "$VERSION_FILE" ]] || die "Missing VERSION file."
[[ -f "$DESCRIPTION_FILE" ]] || die "Missing description.json."
[[ -d "$ROOT_DIR/data" ]] || die "Missing data directory."
has_cmd jq || die "jq is not installed."

project_version="$(tr -d '[:space:]' < "$VERSION_FILE")"
description_version="$(jq -r '.version' "$DESCRIPTION_FILE")"

[[ "$project_version" == "$description_version" ]] || {
  die "Version mismatch: VERSION=$project_version, description.json=$description_version. Run scripts/version.sh set \"$project_version\" --note \"Sync version\""
}

format="${1:-zip}"
[[ $# -le 1 ]] || die "Too many arguments."

case "$format" in
  zip|tar|7z|rar|all) ;;
  *)
    usage
    die "Unknown format: $format"
    ;;
esac

mkdir -p "$OUTPUT_DIR"

if [[ "$format" == "all" ]]; then
  formats=(zip tar 7z rar)
else
  formats=("$format")
fi

created=()
failed=()
for item in "${formats[@]}"; do
  if path="$(build_one "$item")"; then
    created+=("$path")
  else
    failed+=("$item")
  fi
done

if [[ ${#created[@]} -gt 0 ]]; then
  printf 'Created archives:\n'
  for item in "${created[@]}"; do
    printf '  %s\n' "$item"
  done
fi

if [[ ${#failed[@]} -gt 0 ]]; then
  printf 'Failed formats (missing tools or errors): %s\n' "${failed[*]}" >&2
  exit 1
fi
