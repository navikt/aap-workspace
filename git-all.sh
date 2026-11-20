#!/bin/sh

now=false
if [ "${1:-}" = "--now" ]; then
  now=true
  shift
fi

git_repos=$(find . -type d -mindepth 2 -maxdepth 2 -name ".git" -exec dirname {} \;)

echo Executing command "$@" in all git repos in this directory
if [ "$now" = false ]; then
  echo in 5 seconds
  sleep 5
fi

tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/git-all.XXXXXX") || exit 1
trap 'rm -rf "$tmpdir"' 0
trap 'exit 1' HUP INT TERM

pids=""
repo_count=0
for repo in $git_repos; do
  repo_count=$((repo_count + 1))
  (
    cd "$repo" || exit 1

    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      git "$@"
    fi
  ) > "$tmpdir/$repo_count.log" 2>&1 &
  pids="$pids $!"
done

status=0
for pid in $pids; do
  wait "$pid" || status=1
done

separator="----------------------------------------------------------------"
color=false
if [ -t 1 ] && [ "${TERM:-dumb}" != dumb ] && [ "${NO_COLOR+x}" != x ]; then
  color=true
fi

repo_count=0
for repo in $git_repos; do
  repo_count=$((repo_count + 1))
  printf '\n'
  if [ "$color" = true ]; then
    printf '\033[1;36m'
  fi
  printf '%s\n| %s\n%s\n' "$separator" "${repo#./}" "$separator"
  if [ "$color" = true ]; then
    printf '\033[0m'
  fi
  cat "$tmpdir/$repo_count.log"
  printf '\n%s\n' "$separator"
done

exit "$status"
