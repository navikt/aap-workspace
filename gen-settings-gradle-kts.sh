#!/bin/sh

projects=$(find . -mindepth 2 -maxdepth 3 -name "build.gradle.kts" -o -name "settings.gradle.kts" -o -name "buildSrc"|cut -d"/" -f 1-2|sort|uniq|cut -c 3-)

echo 'rootProject.name = "aap-workspace"'

for p in $projects; do 
  if [ "$p" = "aap-kelvin-komponenter" ]; then
    printf '%s\n' \
      "includeBuild(\"$p\") {" \
      '    dependencySubstitution {' \
      "        file(\"$p\").listFiles().orEmpty()" \
      '            .filter {' \
      '                it.isDirectory && it.name !in setOf("build-logic", "version-catalog") &&' \
      '                    it.resolve("build.gradle.kts").isFile' \
      '            }' \
      '            .sortedBy { it.name }' \
      '            .forEach {' \
      '                substitute(module("no.nav.aap.kelvin:${it.name}")).using(project(":${it.name}"))' \
      '            }' \
      '    }' \
      '}'
  else
    echo "includeBuild(\"$p\")"
  fi
done
