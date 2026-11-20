---
name: workspace-status
description: Finn brancher, lokale endringer og nylige commits i AAP-workspace. Bruk når brukeren vil ha Git-status eller finne hvilke repoer som er endret.
---

# Finn status og endrede repoer

Kjør fra workspace-roten:

```sh
git status --short --branch
./git-all.sh --now status --short --branch
```

Den første kommandoen viser workspace-repoet. Den andre viser repoer rett
under roten med en `.git`-mappe. Root-status viser ikke endringene inne i
disse repoene.

For et bestemt repo eller en worktree med en `.git`-fil, kjør status direkte:

```sh
git -C aap-oppgave status --short --branch
```

Bruk stien til det aktuelle repoet eller worktree-en.

Bruk eksisterende script når spørsmålet krever det:

- `./modified-repos.sh` viser repoer med endringer i sporede filer.
  Det utelater repoer som bare har nye, usporede filer, og worktrees med
  en `.git`-fil. Ikke bruk dette som en fullstendig statusoversikt.
- `sh ./latest-changed-repos.sh` sorterer repoene etter siste commit.
  Det viser ikke lokale endringer og beviser ikke hvem som gjorde arbeidet.

Undersøk bare relevante repoer videre, for eksempel med
`git -C aap-oppgave --no-pager diff --stat` og
`git -C aap-oppgave --no-pager diff --cached --stat`.
Oppsummer branch, lokale endringer og eventuelle feil per repo.
Ikke endre brancher, filer eller staging-området.
