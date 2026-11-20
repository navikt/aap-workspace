## AAP-workspace
Setter opp et workspace for aap-utviklere. 
Slik får du alle aap-repoene i samme mappe, og kan bygge dem sammen.

Forutsetter at gh-cli er installert, og at den er logget inn.

### Komme i gang
Kjør ./init.sh for å initialisere. 
Det vil laste ned alle AAP-repoene, og lage en gradle-config.

Deretter kan du åpne mappen til dette repoet i IntelliJ IDEA, 
eller en annen IDE, for å ha alle repoene tilgjengelig i samme editor samtidig. 
Du kan også velge å åpne ett og ett repo. 

Du kan bygge alle aap-repoene samtidig ved å bruke ./gradlew build osv. fra denne mappen.

### git-all.sh
Scriptet ./git-all.sh utfører en git kommando i alle repoene.

Eksempel: 
```shell
./git-all.sh checkout main
./git-all.sh pull
```
Vær forsiktig.  

### git-workspace.py
Interaktiv Git-oversikt for repoene rett under denne mappen, inkludert Git-worktrees.
Krever [uv](https://docs.astral.sh/uv/); Python og TUI-avhengigheter hentes automatisk.

```shell
./git-workspace.py
```

Bruk pil opp/ned for å navigere og mellomrom for å velge/velge bort repoer.
Status for markert repo vises i sidepanelet; valgte repoer markeres tydelig.
Bruk `a` for alle/ingen, `s` for status,
`r` for å oppdatere og `b` for å bytte branch i valgte repoer.
Branchbytte bekreftes i en dialog. `q` avslutter.
Status gjelder alle repoer dersom ingen er valgt.

Kan også brukes uten TUI:

```shell
./git-workspace.py status
./git-workspace.py status --repo aap-oppgave --repo aap-behandlingsflyt
./git-workspace.py switch main --all
./git-workspace.py switch main --repo aap-oppgave
./git-workspace.py --directory /sti/til/workspace status
```

CLI-branchbytte krever eksplisitt `--all` eller `--repo` og kjøres uten dialog.
Scriptet bruker vanlig `git switch`, uten force, stash eller reset.
Remote-brancher kan opprette en lokal tracking-branch, som med vanlig Git.
Repoer som feiler vises tydelig; resten forsøkes fortsatt. CLI returnerer en
feilkode hvis et repo feiler. Et batchbytte er ikke atomisk: vellykkede bytter
blir ikke rullet tilbake dersom et annet repo feiler.

### latest-changed-repos.sh
Viser sammendrag av hvilke endringer som er gjort nylig i repoene. 
Bruk den feks. for å se hva du har gjort i løpet av dagen.
