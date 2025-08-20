#!/bin/sh

git_repos=$(find . -type d -mindepth 2 -maxdepth 2 -name ".git" -exec dirname {} \;)

echo executing command "$@" in all git repos in directory
echo in 5 seconds
sleep 5

for repo in $git_repos; do 
  pushd $repo >/dev/null
  echo $repo: 
  git "$@"
  #echo $repo: git "$@"
  popd >/dev/null
done
