#!/bin/sh
set -e

./clone-all-aap-repos.sh

./gen-settings-gradle-kts.sh > settings.gradle.kts
