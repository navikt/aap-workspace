#!/usr/bin/env bash
find . -type d -name ".git" -mindepth 2 -maxdepth 2| while read repo; do
    pushd "$(dirname "$repo")" > /dev/null 2>&1
    if [ -n "$(git status --porcelain | grep -v "^??")" ]; then
        echo $PWD
        echo $(git status --porcelain | grep -v "^??") fi
    fi
    popd > /dev/null 2>&1
done

