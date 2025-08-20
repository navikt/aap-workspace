#!/bin/sh
for repo in $(cat aap-repos.txt|egrep -v '^#'); do 
  if [ ! -d "$repo" ]; then
    gh repo clone navikt/$repo
  else 
    echo Skipping already present $repo
  fi
done
