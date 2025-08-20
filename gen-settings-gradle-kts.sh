#!/bin/sh

projects=$(find . -mindepth 2 -maxdepth 3 -name "build.gradle.kts" -o -name "settings.gradle.kts" -o -name "buildSrc"|cut -d"/" -f 1-2|sort|uniq|cut -c 3-)

echo 'rootProject.name = "aap-workspace"'

for p in $projects; do 
  echo "includeBuild(\"$p\")"
done
