#!/bin/bash
# Static checks for the course material. Needs no cluster, no PBS, no containers.
#   en/tests/lint.sh           checks en/
#   en/tests/lint.sh pt        checks a translation instead (pt/, fr/, es/)
# Exit status is the number of problems found.

if [ -n "${1:-}" ]; then cd "$(dirname "$0")/../../$1" || exit 1; else cd "$(dirname "$0")/.." || exit 1; fi
problems=0
bad() { echo "PROBLEM: $*"; problems=$((problems + 1)); }

echo "1. shell syntax (bash -n) of every .sh / .pbs"
while IFS= read -r f; do
    bash -n "$f" 2>/dev/null || bad "syntax error in $f"
done < <(find . \( -name '*.sh' -o -name '*.pbs' \) | sort)
if command -v shellcheck >/dev/null 2>&1; then
    echo "   (shellcheck found: running it too)"
    while IFS= read -r f; do shellcheck -S warning -x "$f" >/dev/null 2>&1 || bad "shellcheck warnings in $f"; done < <(find . -name '*.sh' | sort)
fi

echo "2. no cluster-specific values outside examples/"
while IFS= read -r l; do bad "cluster-specific value: $l"; done < <(grep -rnE 'pne[0-9]|workq|/data2' . | grep -v '^./examples/' | grep -v '^./tests/lint.sh')

echo "3. #PBS lines: no trailing comments, a name, a valid walltime"
while IFS= read -r f; do
    while IFS= read -r l; do bad "trailing comment on a #PBS line in $f: $l"; done < <(grep -nE '^#PBS [^#]*[[:space:]]#' "$f")
    grep -q '^#PBS' "$f" || continue
    grep -q '^#PBS -N ' "$f" || bad "$f has #PBS lines but no -N job name"
    grep -q '^#PBS -l walltime=' "$f" || bad "$f has no walltime"
    w="$(sed -n 's/^#PBS -l walltime=\([^ ]*\)$/\1/p' "$f" | head -1)"
    case "$w" in *___*|"") ;; *) echo "$w" | grep -qE '^[0-9]{2}:[0-5][0-9]:[0-5][0-9]$' || bad "bad walltime '$w' in $f" ;; esac
done < <(find . -name '*.pbs' | sort)

echo "4. blanks (___) only in exercises and their checkers"
while IFS= read -r f; do
    case "$(basename "$f")" in exercise_*|check_*|lint.sh) ;; *) bad "'___' outside an exercise: $f" ;; esac
done < <(grep -rl '___' . --include='*.pbs' --include='*.sh' --include='*.nf')

echo "5. every exercise has a checker and a solution; checkers are executable"
has_solution() { # has_solution <dir> <id like 02a>
    ls "$1"/solutions/exercise_"$2"* >/dev/null 2>&1 || ls "$1"/solutions/exercise_"${2:0:2}".* >/dev/null 2>&1
}
while IFS= read -r f; do
    d="$(dirname "$f")"; b="$(basename "$f")"; id="${b#exercise_}"; id="${id:0:3}"
    [ -f "$d/check_$id.sh" ] || bad "$f has no $d/check_$id.sh"
    has_solution "$d" "$id" || bad "$f has no solution in $d/solutions/"
done < <(find . -name 'exercise_[0-9][0-9][a-z]_*' -not -path '*/solutions/*' | sort)
while IFS= read -r c; do
    [ -x "$c" ] || bad "$c is not executable"
    d="$(dirname "$c")"; id="$(basename "$c" .sh)"; id="${id#check_}"
    if [ "${#id}" -eq 3 ]; then has_solution "$d" "$id" || bad "$c has no solution"; else [ -f "$d/solutions/README.md" ] || bad "$c has no solutions/README.md"; fi
done < <(find . -name 'check_[0-9]*.sh' | sort)

echo "6. markdown links resolve"
while IFS= read -r md; do
    dir="$(dirname "$md")"
    while IFS= read -r link; do
        case "$link" in http*|mailto:*|"") continue ;; esac
        [ -e "$dir/$link" ] || bad "broken link in $md: $link"
    done < <(grep -oE '\]\([^)#]+(#[^)]*)?\)' "$md" | sed -E 's/^\]\(//; s/\)$//; s/#.*$//')
done < <(find . -name '*.md' | sort)

echo "7. container images pinned"
while IFS= read -r l; do bad "unpinned image: $l"; done < <(grep -E '^IMG_' containers.conf | grep -vE ':[0-9][A-Za-z0-9._-]*"$')
while IFS= read -r l; do bad "':latest' used: $l"; done < <(grep -rn ':latest' . | grep -v 'tests/lint.sh' | grep -vE '^[^:]+:[0-9]+:[[:space:]]*(#|//|>)' | grep -v '\.md:')
for t in $(sed -n 's/^TOOLS=(\(.*\))/\1/p' containers.conf); do grep -q "^IMG_$t=" containers.conf || bad "tool $t in TOOLS has no IMG_$t"; done

echo
if [ "$problems" -eq 0 ]; then echo "lint: OK"; else echo "lint: $problems problem(s)"; fi
exit "$problems"
