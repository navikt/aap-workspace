#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Samle README-filer fra første mappenivå i en overordnet HTML-fil.

Bruk: bash scripts/samle-readme.sh [--root MAPPE] [--output FIL]

  --root MAPPE   Kildemappe (standard: arbeidsområdet over scripts/).
  --output FIL   Utfil, relativt til --root eller absolutt.
                 Standard: README-samlet.html
  --help         Vis denne hjelpeteksten.

README-innholdet vises som tekst med bevart formatering, ikke rendret Markdown.
Krever Bash, sed og GNU find, sort og realpath.
EOF
}

fail() {
    printf 'Kunne ikke samle README-filene: %s\n' "$*" >&2
    exit 1
}

escape_html() {
    sed -e 's/\&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' \
        -e 's/"/\&quot;/g' -e "s/'/\&#39;/g"
}

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
output="README-samlet.html"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --root|--output)
            [[ $# -ge 2 && -n "$2" ]] || fail "Mangler verdi for $1"
            if [[ "$1" == "--root" ]]; then
                root=$2
            else
                output=$2
            fi
            shift 2
            ;;
        --help|-h) usage; exit 0 ;;
        *) usage >&2; fail "Ukjent argument: $1" ;;
    esac
done

root=$(realpath -e -- "$root")
[[ -d "$root" ]] || fail "Kildemappen finnes ikke: $root"
if [[ "$output" != /* ]]; then
    output="$root/$output"
fi
output=$(realpath -m -- "$output")
mkdir -p -- "$(dirname -- "$output")"
temporary=$(mktemp -d -- "$(dirname -- "$output")/.samle-readme.XXXXXX")
trap 'rm -f -- "$temporary/files" "$temporary/samlet.html"; rmdir -- "$temporary"' EXIT

# Skriv fillisten separat slik at feil fra find/sort stopper genereringen.
find "$root" -mindepth 1 -maxdepth 2 \
    -type d \( \
        -name .git -o -name .gradle -o -name .next -o -name .opencode \
        -o -name .pnpm-store -o -name .venv -o -name .yarn \
        -o -name __pycache__ -o -name build -o -name coverage \
        -o -name dist -o -name node_modules -o -name venv \
    \) -prune -o \
    -type f -path "$root/*/*" \( -iname readme -o -iname 'readme.*' \) \
    ! -path "$output" -print0 |
    LC_ALL=C sort -z > "$temporary/files"
mapfile -d '' -t readmes < "$temporary/files"
[[ ${#readmes[@]} -gt 0 ]] || fail "Ingen README-filer funnet i $root"

{
    cat <<'HTML'
<!doctype html>
<html lang="nb">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Samlede README-filer</title>
<style>
body { margin: 0; font-family: system-ui, sans-serif; line-height: 1.6; color: #202020; background: #fff; }
main { max-width: 1000px; margin-left: 18rem; padding: 2rem; }
nav { position: fixed; top: 0; bottom: 0; left: 0; width: 18rem; box-sizing: border-box; overflow-y: auto; padding: 1.5rem; border-right: 1px solid #ccc; background: #f5f5f5; }
nav h2 { margin-top: 0; }
nav ul { padding-left: 1.25rem; }
nav a { overflow-wrap: anywhere; }
a { color: #005b9a; }
section { border-top: 1px solid #ccc; margin-top: 2rem; padding-top: 1rem; }
h2 { overflow-wrap: anywhere; }
pre { white-space: pre-wrap; overflow-wrap: anywhere; padding: 1rem; background: #f5f5f5; }
@media (max-width: 48rem) {
    main { margin-left: 0; padding: 1rem; }
    nav { position: static; width: auto; max-height: 40vh; border-right: 0; border-bottom: 1px solid #ccc; margin-bottom: 2rem; }
}
</style>
</head>
<body>
<main>
<h1>Samlede README-filer</h1>
HTML
    printf '<p>Samlet fra %s README-filer med <code>scripts/samle-readme.sh</code>.</p>\n' "${#readmes[@]}"
    printf '<p>Innholdet vises som tekst med bevart formatering. Bruk kildelenken for å åpne originalfilen.</p>\n'
    printf '<nav aria-label="Innholdsfortegnelse">\n<h2>Innholdsfortegnelse</h2>\n<ul>\n'
    for index in "${!readmes[@]}"; do
        label=$(realpath --relative-to="$root" -- "${readmes[index]}")
        label=${label%%/*}
        label=$(printf '%s' "$label" | escape_html)
        printf '<li><a href="#readme-%s">%s</a></li>\n' "$((index + 1))" "$label"
    done
    printf '</ul>\n</nav>\n'
    for index in "${!readmes[@]}"; do
        source=${readmes[index]}
        label=$(realpath --relative-to="$root" -- "$source")
        label=$(printf '%s' "$label" | escape_html)
        link=$(realpath --relative-to="$(dirname -- "$output")" -- "$source")
        link=${link//%/%25}
        link=${link// /%20}
        link=${link//#/%23}
        link=${link//\?/%3F}
        link=${link//</%3C}
        link=${link//>/%3E}
        link=$(printf '%s' "$link" | escape_html)
        printf '<section id="readme-%s">\n' "$((index + 1))"
        printf '<h2>%s</h2>\n<p><a href="%s">Åpne originalfilen</a></p>\n<pre>' "$label" "$link"
        escape_html < "$source"
        printf '</pre>\n</section>\n'
    done
    printf '</main>\n</body>\n</html>\n'
} > "$temporary/samlet.html"

# Erstatt utfilen først når alle kildefilene er lest uten feil.
mv -- "$temporary/samlet.html" "$output"
printf 'Samlet %s README-filer i %s\n' "${#readmes[@]}" "$output"
