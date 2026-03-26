#!/bin/bash

# Oppdaterer hoved-branchen til alle repositories i underkataloger.

set -e

repos=$(find . -type d -mindepth 2 -maxdepth 2 -name ".git")

echo "$repos" | while read gitdir; do
    repo_dir=$(dirname "$gitdir")

    echo "Oppdaterer $repo_dir ..."

    cd "$repo_dir"

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        # ikke et gyldig repo
        cd - >/dev/null
        continue
    fi

    current_branch=$(git rev-parse --abbrev-ref HEAD)

    main_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')

    if [ -z "$main_branch" ]; then
        echo "Kunne ikke avgjøre hva som er main-branch for $repo_dir"
        cd - >/dev/null
        continue
    fi

    # Check if there are local changes that need stashing
    stash_needed=false
    if ! git diff --quiet || ! git diff --cached --quiet; then
        stash_needed=true
        echo "Lagrer lokale endringer midlertidig (stash)"
        git stash push -u -m "auto-stash-before-update"
    fi

    # Fetch updates (no prune)
    git fetch --all

    # Switch to main branch if needed
    if [ "$current_branch" != "$main_branch" ]; then
        git checkout "$main_branch"
    fi

    # Pull latest changes
    git pull --ff-only

    # Return to previous branch if needed
    if [ "$current_branch" != "$main_branch" ]; then
        git checkout "$current_branch"
    fi

    # Restore stashed changes if any
    if [ "$stash_needed" = true ]; then
        echo "Gjenoppretter lokale endringer (stash pop)"
        git stash pop || echo "Advarsel: stash pop feilet, sjekk repoet manuelt"
    fi

    cd - >/dev/null
done

echo "Alle repositories oppdatert."
