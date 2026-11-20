---
name: workspace-pull
description: Hent siste endringer i AAP-workspace med git-all.sh. Bruk når brukeren ber om å oppdatere alle repoene eller kjøre git pull på tvers av workspace.
---

# Hent endringer i repoene

Kjør fra workspace-roten. Hvert repo er et eget Git-repo.

1. Les status før du henter endringer:

   ```sh
   git status --short --branch
   ./git-all.sh --now status --short --branch
   ```

2. Oppdater gjeldende branch fra dens upstream:

   ```sh
   ./git-all.sh --now pull --ff-only --no-rebase --no-autostash
   ```

3. Les hele resultatet. Rapporter hvilke repoer som feilet og hvorfor.
   Scriptet fortsetter i andre repoer og returnerer en feilkode hvis noe feiler.
   Vellykkede oppdateringer blir ikke rullet tilbake.

`--now` må stå først. Uten dette argumentet venter scriptet fem sekunder.
Kommandoene kjører parallelt i repoer rett under roten med en `.git`-mappe.
Workspace-repoet, dypere repoer og worktrees med en `.git`-fil er ikke med.
Hvis forespørselen gjelder alle repoene inkludert workspace-roten, kjør også:

```sh
git pull --ff-only --no-rebase --no-autostash
```

For worktrees utenfor scriptets utvalg må du kjøre samme pull-kommando
fra hvert aktuelt repo.

Ikke bytt til `main`, stash, reset, stage eller unstage for å få en pull til
å lykkes. Bevar lokale endringer og rapporter manglende upstream, avvikende
historikk eller konflikter. Ikke bruk `update-all-repos.sh` som alternativ:
det scriptet stasher og bytter branch automatisk.
