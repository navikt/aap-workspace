---
name: workspace-setup
description: Sett opp AAP-workspace, klon manglende repoer og oppdater inkluderte Gradle-bygg. Bruk ved førstegangsoppsett eller når et repo mangler i workspace.
---

# Sett opp workspace

Les `init.sh`, `clone-all-aap-repos.sh`, `aap-repos.txt` og
`gen-settings-gradle-kts.sh` før du kjører oppsettet.
Kjør kommandoene fra workspace-roten.

## Førstegangsoppsett

Kontroller at GitHub CLI er tilgjengelig og innlogget:

```sh
gh auth status
```

Hvis autentisering mangler, rapporter det. Ikke hent eller skriv ut tokens.
Når autentisering fungerer:

```sh
./init.sh
```

Scriptet kloner manglende repoer fra `aap-repos.txt` og genererer
`settings.gradle.kts`. Eksisterende mapper blir hoppet over; det henter
ikke nye commits i eksisterende repoer.

## Manglende repoer eller inkluderte bygg

Hvis bare kloner mangler, kjør `./clone-all-aap-repos.sh`.
Hvis Gradle-oppsettet må oppdateres, kjør:

```sh
./gen-settings-gradle-kts.sh > settings.gradle.kts
```

`settings.gradle.kts` er generert og ignorert av Git. Les eventuelle lokale
tilpasninger før du overskriver filen. Endre generatoren hvis oppgaven krever
en varig endring i genereringen.

Kontroller at de aktuelle repoene finnes, og at de forventede
`includeBuild`-oppføringene står i den genererte filen. Ikke stol på
exit-koden alene: klonescriptet stopper ikke nødvendigvis ved første feil.
Ikke klon hele workspace eller kjør et fullt bygg hvis oppgaven bare gjelder
ett repo. Bruk `workspace-pull` for å hente endringer i eksisterende repoer.
