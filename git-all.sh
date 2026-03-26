#!/bin/sh

git_repos=$(find . -type d -mindepth 2 -maxdepth 2 -name ".git" -exec dirname {} \;)

echo Executing command "$@" in all git repos in this directory
echo in 5 seconds
sleep 5

for repo in $git_repos; do
  # shellcheck disable=SC3044
  pushd "$repo" >/dev/null

  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    # this is a valid git repo
    echo "$repo:"
    git "$@"
  fi

  # shellcheck disable=SC3044
  popd >/dev/null
done
