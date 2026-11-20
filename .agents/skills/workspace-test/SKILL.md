---
name: workspace-test
description: Bygg og test målrettet i AAP-workspace. Bruk når en endring skal verifiseres i ett eller flere underrepoer uten å bygge hele workspace.
---

# Bygg og test det berørte repoet

1. Finn repoet som eier endringen. Les dets `AGENTS.md`, eventuelle
   `.github/copilot-instructions.md` og relevante byggfiler.
   Hvert underrepo har egne konvensjoner og avhengigheter.
2. Velg minste test- eller byggkommando som dekker endringen.
3. Kjør kommandoen, les resultatet og rett feil som skyldes endringen.
   Skill slike feil fra manglende miljøoppsett og eksisterende feil.

## Gradle

Workspace bruker composite build. Les `settings.gradle.kts` for å finne
inkluderte bygg, og repoets byggfiler for modul- og testnavn.
Bruk workspace-wrapperen med en konkret oppgavesti:

```text
./gradlew :<inkludert-bygg>:<modul>:test
./gradlew :<inkludert-bygg>:<modul>:test --tests '<testklasse>'
```

Erstatt plassholderne med navn fra byggkonfigurasjonen. Har repoet ingen
undermodul, bruk `:<inkludert-bygg>:test`. Du kan også kjøre repoets egen
wrapper fra repoets mappe.

Behold configuration cache aktivert. Ikke bruk `--no-configuration-cache`.
Root-oppgavene `build`, `assemble`, `check` og `clean` kjører på tvers av
inkluderte bygg. Ikke velg dem når en målrettet oppgave er nok.

## Frontend og workspace-script

For frontend, les repoets `package.json` og lockfil. Bruk dets
pakkehåndterer og eksisterende test-, lint- og typecheck-script.
Ikke anta at workspace-rotens npm-oppsett gjelder underrepoene.

For shell-endringer, kontroller syntaks med riktig shell og test den
endrede oppførselen. Syntakssjekk alene bekrefter ikke oppførselen.
Test Git-script mot isolerte testrepoer, ikke ved å bytte branch eller
kjøre pull i utviklerens repoer.

Installer avhengigheter bare hvis manifestet er endret eller en valgt
kommando feiler fordi en avhengighet mangler. Rene dokumentasjonsendringer
krever ikke applikasjonsbygg.
