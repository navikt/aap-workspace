#!/bin/sh

for repo in $(find . -type d -name ".git" -maxdepth 2 -mindepth 2); do name=$(dirname $repo); pushd $name ; git fetch origin &&
git merge --ff-only origin/main main ; popd; done
