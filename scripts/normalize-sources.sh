#!/usr/bin/env bash
set -euo pipefail

# Normalize newlines and indentation in Swift source files.
#
# What it does:
#   1. Converts CRLF / CR line endings to LF
#   2. Removes trailing whitespace on every line
#   3. Converts leading tabs to spaces (1 tab = 4 spaces, matching Xcode default)
#   4. Ensures the file ends with exactly one newline
#   5. Removes trailing blank lines before EOF

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR=""

SPACES_PER_TAB=4
DRY_RUN=false
VERBOSE=false

usage() {
    echo "Usage: $(basename "$0") [OPTIONS] [SOURCE_DIR]"
    echo ""
    echo "Normalize newlines and indentation in Swift source files."
    echo ""
    echo "Options:"
    echo "  -n, --dry-run    Show which files would be changed without modifying them"
    echo "  -v, --verbose    Print every file that is processed"
    echo "  -s, --spaces N   Spaces per tab for conversion (default: $SPACES_PER_TAB)"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "SOURCE_DIR defaults to ../src relative to the script location."
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--dry-run)  DRY_RUN=true; shift ;;
        -v|--verbose)  VERBOSE=true; shift ;;
        -s|--spaces)   SPACES_PER_TAB="$2"; shift 2 ;;
        -h|--help)     usage; exit 0 ;;
        -*)            echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
        *)             SRC_DIR="$1"; shift ;;
    esac
done

SRC_DIR="${SRC_DIR:-$SCRIPT_DIR/../src}"

if [[ ! -d "$SRC_DIR" ]]; then
    echo "Error: directory not found: $SRC_DIR" >&2
    exit 1
fi

CHANGED=0
SCANNED=0

normalize_file() {
    local file="$1"
    local original
    original="$(cat "$file")"

    local content="$original"

    # 1. CRLF / CR -> LF
    content="$(printf '%s\n' "$content" | sed $'s/\r$//' | tr '\r' '\n')"

    # 2. Remove trailing whitespace on each line
    content="$(printf '%s\n' "$content" | sed 's/[[:blank:]]*$//')"

    # 3. Convert leading tabs to spaces
    #    Repeatedly replace one leading tab with N spaces until none remain.
    local spaces
    spaces="$(printf '%*s' "$SPACES_PER_TAB" '')"
    local prev=""
    while [[ "$content" != "$prev" ]]; do
        prev="$content"
        content="$(printf '%s\n' "$content" | sed "s/^\(${spaces}*\)\t/\1${spaces}/")"
    done

    # 4. Remove trailing blank lines and ensure single final newline
    #    Using awk for macOS compatibility
    content="$(printf '%s\n' "$content" | awk '
        /^[[:space:]]*$/ { blank = blank ORS; next }
        { if (NR > 1 && blank != "") printf "%s", blank; blank = ""; print }
    ')"

    if [[ "$content" != "$original" ]]; then
        CHANGED=$((CHANGED + 1))
        if [[ "$DRY_RUN" == true ]]; then
            echo "  would fix: $file"
        else
            printf '%s\n' "$content" > "$file"
            if [[ "$VERBOSE" == true ]]; then
                echo "  fixed: $file"
            fi
        fi
    else
        if [[ "$VERBOSE" == true ]]; then
            echo "  ok:    $file"
        fi
    fi
}

echo "Scanning Swift files in $SRC_DIR ..."

while IFS= read -r -d '' file; do
    SCANNED=$((SCANNED + 1))
    normalize_file "$file"
done < <(find "$SRC_DIR" \
    -name '*.swift' \
    -type f \
    -not -path '*/Pods/*' \
    -not -path '*/DerivedData/*' \
    -not -path '*/DerivedData-*/*' \
    -not -path '*/.build/*' \
    -not -path '*/build/*' \
    -not -path '*/Carthage/*' \
    -not -path '*/SourcePackages/*' \
    -print0 | sort -z)

if [[ "$DRY_RUN" == true ]]; then
    echo "Dry run complete: $CHANGED of $SCANNED files would be changed."
else
    echo "Done: $CHANGED of $SCANNED files normalized."
fi
