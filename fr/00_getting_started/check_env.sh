#!/bin/bash
# Vérifie que tout ce dont le cours a besoin est en place. Lancez-le sur le nœud de connexion :
#
#   ./check_env.sh             vérification complète, y compris un vrai job de test de 10 secondes
#   ./check_env.sh --no-job    saute le job de test (vérifie seulement fichiers et commandes)
#
# Il ne modifie rien, à part soumettre smoke_test.pbs.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$HERE" || exit 1
source ../lib/edu.sh || exit 1

RUN_JOB=1
[ "${1:-}" = "--no-job" ] && RUN_JOB=0

echo "== 1. Commandes PBS"
for c in qsub qstat qdel pbsnodes; do
    if command -v "$c" >/dev/null 2>&1; then edu_pass "$c"; else edu_fail "$c introuvable" "êtes-vous sur le nœud de connexion ? essayez 'module avail pbs'"; fi
done

echo "== 2. Runtime de conteneurs"
if command -v "$CONTAINER_RUNTIME" >/dev/null 2>&1; then
    edu_pass "$CONTAINER_RUNTIME sur ce nœud"
else
    edu_warn "$CONTAINER_RUNTIME n'est pas dans le PATH sur ce nœud (pas grave si seuls les nœuds de calcul l'ont ; le job de test le vérifie)"
fi

echo "== 3. Données (fetch_data.sh)"
if (cd "$DATA_DIR" 2>/dev/null && sha256sum -c --quiet "$HERE/data.sha256" >/dev/null 2>&1); then
    edu_pass "référence + vraies lectures présentes et intactes"
else
    edu_fail "données absentes ou corrompues dans $DATA_DIR" "lancez ./fetch_data.sh"
fi

echo "== 4. Images de conteneur (pull_containers.sh)"
for tool in "${TOOLS[@]}"; do
    if [ -s "$(edu_sif "$tool")" ]; then edu_pass "$tool.sif"; else edu_fail "$tool.sif absent" "lancez ./pull_containers.sh"; fi
done

echo "== 5. Échantillons simulés (make_samples.pbs)"
sheet="$DATA_DIR/samples/samples.tsv"
if [ -s "$sheet" ]; then
    n="$(wc -l < "$sheet")"
    missing="$(awk -F'\t' '{print $2; print $3}' "$sheet" | while read -r f; do [ -s "$f" ] || echo "$f"; done | wc -l)"
    edu_expect_eq "échantillons dans samples.tsv" "$N_SAMPLES" "$n" "relancez : qsub make_samples.pbs"
    edu_expect_eq "fichiers d'échantillon manquants" "0" "$missing" "relancez : qsub make_samples.pbs"
else
    edu_fail "pas de samples.tsv" "soumettez : qsub make_samples.pbs   (puis attendez qu'il finisse)"
fi

if [ "$RUN_JOB" -eq 1 ] && command -v qsub >/dev/null 2>&1 && [ "$EDU_FAILS" -eq 0 ]; then
    echo "== 6. Job de test sur un nœud de calcul"
    jid="$(edu_qsub smoke_test.pbs)" || { edu_fail "qsub a échoué" "s'il dit qu'une file est obligatoire, définissez EDU_QUEUE dans site.conf"; jid=""; }
    if [ -n "$jid" ]; then
        num="${jid%%.*}"
        log="smoke_test.o$num"
        echo "  $jid soumis, attente de $log (jusqu'à 3 minutes)..."
        for _ in $(seq 1 90); do [ -f "$log" ] && break; sleep 2; done
        if [ ! -f "$log" ]; then
            edu_fail "le job n'a pas fini en 3 minutes" "regardez 'qstat -u \$USER' ; un cluster chargé peut juste demander plus de temps"
        elif grep -q 'SMOKE OK' "$log"; then
            edu_pass "le job de test a tourné sur $(awk '/^== host/ {print $3}' "$log") et a pu utiliser les conteneurs + vos données"
            rm -f "$log"
        else
            edu_fail "le job de test a échoué ; son log ($log) dit :" ""
            sed 's/^/        /' "$log"
        fi
    fi
elif [ "$RUN_JOB" -eq 1 ]; then
    echo "== 6. Job de test sauté (corrigez d'abord les échecs ci-dessus)"
fi

edu_summary
