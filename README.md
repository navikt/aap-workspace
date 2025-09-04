## AAP-workspace
Setter opp et workspace for aap-utviklere. 
Slik får du alle aap-repoene i samme mappe, og kan bygge dem sammen.

Forutsetter at gh-cli er installert, og at den er logget inn.

Kjør ./init.sh for å initialisere. 
Det vil laste ned alle AAP-repoene, og lage en gradle-config.

Deretter kan du åpne mappen til dette repoet i IntelliJ IDEA, 
eller en annen IDE, for å ha alle repoene tilgjengelig i samme editor samtidig.

Du kan bygge alle aap-repoene samtidig ved å bruke ./gradlew build osv. fra denne mappen.

### git-all.sh
Scriptet ./git-all.sh utfører en git kommando i alle repoene.

Eksempel: 
```shell
./git-all.sh checkout main
./git-all.sh pull
```
Vær forsiktig.  

### latest-changed-repos.sh
Viser sammendrag av hvilke endringer som er gjort nylig i repoene. 
Bruk den feks. for å se hva du har gjort i løpet av dagen.