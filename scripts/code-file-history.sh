#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 <manifest-path> <since-date>" >&2
    exit 2
}

[[ $# -eq 2 ]] || usage

manifest_arg=$1
since=$2

# The report always ends on the day it is generated.
until=$(date +%F)

# Resolve the manifest before asking Git about it, so relative paths work
# regardless of the caller's current directory.
manifest_dir=$(cd -- "$(dirname -- "$manifest_arg")" && pwd)
manifest_file="$manifest_dir/$(basename -- "$manifest_arg")"

[[ -f "$manifest_file" ]] || {
    echo "Manifest file not found: $manifest_arg" >&2
    exit 1
}

repo_root=$(git -C "$manifest_dir" rev-parse --show-toplevel)
manifest=$(realpath --relative-to="$repo_root" "$manifest_file")

git -C "$repo_root" ls-files --error-unmatch -- "$manifest" >/dev/null

# Normalize supported origin URL forms to HTTPS so commit links work in the
# generated report.
remote_url=$(git -C "$repo_root" remote get-url origin)

if [[ "$remote_url" =~ ^https?:// ]]; then
    repo_url=$remote_url
elif [[ "$remote_url" =~ ^ssh://([^/@]+@)?([^/:]+)(:[0-9]+)?/(.+)$ ]]; then
    repo_url="https://${BASH_REMATCH[2]}/${BASH_REMATCH[4]}"
elif [[ "$remote_url" =~ ^([^/@:]+@)?([^/:]+):(.+)$ ]]; then
    repo_url="https://${BASH_REMATCH[2]}/${BASH_REMATCH[3]}"
else
    echo "Cannot create commit links from origin URL: $remote_url" >&2
    exit 1
fi

repo_url=${repo_url%/}
repo_url=${repo_url%.git}
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_name=$(basename -- "$repo_root")
output="$script_dir/$repo_name-$(basename -- "$manifest")-$until-history.md"
mkdir -p "$(dirname -- "$output")"

# Write beside the final report, then rename into place so a failed run
# doesn't leave a partially written Markdown file.
temp=$(mktemp "${output}.XXXXXX")
trap 'rm -f "$temp"' EXIT

# Include the last pre-range change as a baseline, then list in-range commits
# oldest first to show how the manifest evolved.
baseline=$(git -C "$repo_root" log -1 --before="$since 00:00:00"  --date=short  --format='%h%x09%ad%x09%s'  -- "$manifest")

history=$(git -C "$repo_root" log   --reverse  --since="$since 00:00:00"   --until="$until 23:59:59"  --date=short  --format='%h%x09%ad%x09%s'  -- "$manifest")
{
    printf '# `%s` history\n\n' "$manifest"
    printf 'Changes from %s through %s:\n\n' "$since" "$until"
    printf '| Date | Commit | Change |\n|---|---|---|\n'

    if [[ -n "$baseline" ]]; then
        IFS=$'\t' read -r hash date subject <<< "$baseline"
        # Escape table delimiters in commit subjects to preserve Markdown rows.
        subject=${subject//|/\\|}
        printf '| As of %s (last changed %s) | [%s](%s/commit/%s) | State at start of range; last change: %s |\n' \
            "$since" "$date" "$hash" "$repo_url" "$hash" "$subject"
    else
        printf '| As of %s | — | No earlier committed version found. |\n' "$since"
    fi

    if [[ -n "$history" ]]; then
        while IFS=$'\t' read -r hash date subject; do
            subject=${subject//|/\\|}
            printf '| %s | [%s](%s/commit/%s) | %s |\n' \
                "$date" "$hash" "$repo_url" "$hash" "$subject"
        done <<< "$history"
    fi
} > "$temp"

mv -- "$temp" "$output"
trap - EXIT
# Convert the completed Markdown report to PDF using the project's uv-managed
# Python environment.
uv run "$script_dir/md-to-pdf.py" "$output"
