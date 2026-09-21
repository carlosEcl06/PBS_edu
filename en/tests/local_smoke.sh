#!/bin/bash
# Local smoke test: runs the course's own scripts against FAKE qsub/qstat/pbsnodes/apptainer,
# in an isolated copy of the repository, so it needs no cluster and never touches your
# real site.conf. It verifies the plumbing (setup, downloads, image pulls, env check, the helper
# library, node table, section 01 exercises and checkers), NOT the real PBS or the bio tools.
#
#   en/tests/local_smoke.sh          (needs curl and internet for the 60 KB dataset)

set -u
SRC="$(cd "$(dirname "$0")/.." && pwd)"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
cp -r "$SRC" "$T/en"
rm -f "$T/en/site.conf"
mkdir -p "$T/bin" "$T/store"
fails=0
ok()  { echo "  ok    $1"; }
nok() { echo "  FAIL  $1"; fails=$((fails + 1)); }
expect() { if eval "$2"; then ok "$1"; else nok "$1"; fi; }

# ---- fake PBS + container runtime --------------------------------------------
cat > "$T/bin/qstat" <<'X'
#!/bin/bash
case "$1" in
  -Q)  printf 'Queue  Max  Tot\n----  ---  ---\nbatchq  0  0\nsmall  0  0\n' ;;
  -Bf) printf 'Server: fake\n    default_queue = batchq\n' ;;
  *)   exit 1 ;;
esac
X
cat > "$T/bin/qsub" <<'X'
#!/bin/bash
# run the script immediately and synchronously, as PBS would later on a node
script="${@: -1}"
name="$(sed -n 's/^#PBS -N //p' "$script" | head -1)"; id=$((RANDOM + 1000))
( cd "$PWD" && PBS_O_WORKDIR="$PWD" PBS_JOBID="$id.fake" NCPUS=1 bash "$script" > "$name.o$id" 2>&1 )
echo "$id.fake"
X
cat > "$T/bin/qdel" <<'X'
#!/bin/bash
exit 0
X
cat > "$T/bin/pbsnodes" <<'X'
#!/bin/bash
cat <<'N'
node01
     state = free
     resources_available.ncpus = 32
     resources_available.mem = 131072000kb
     resources_assigned.ncpus = 4
     resources_assigned.mem = 8388608kb

node02
     state = down,offline
     resources_available.ncpus = 16
     resources_available.mem = 64gb
     resources_assigned.ncpus = 0
     resources_assigned.mem = 0kb
N
X
cat > "$T/bin/apptainer" <<'X'
#!/bin/bash
case "$1" in
  --version) echo "apptainer version fake" ;;
  pull)      echo "fake image" > "$2" ;;
  exec)      echo "fake-exec: $*" ;;
esac
X
chmod +x "$T/bin/"*
export PATH="$T/bin:$PATH"

cd "$T/en/00_getting_started" || exit 1

echo "setup.sh"
./setup.sh --yes > setup.out 2>&1
expect "writes site.conf"                     '[ -f ../site.conf ]'
expect "detects the default queue (none required)" 'grep -q "^EDU_QUEUE=\"\"" ../site.conf'
expect "detects apptainer"                    'grep -q "^CONTAINER_RUNTIME=\"apptainer\"" ../site.conf'
# redirect data/work/sif out of the copied tree, into $T/store
sed -i "s#^DATA_DIR=.*#DATA_DIR=\"$T/store/data\"#; s#^WORKDIR=.*#WORKDIR=\"$T/store/work\"#; s#^SIF_CACHE=.*#SIF_CACHE=\"$T/store/sif\"#; s#^READS_PER_SAMPLE=.*#READS_PER_SAMPLE=100#; s#^N_SAMPLES=.*#N_SAMPLES=2#" ../site.conf

echo "pull_containers.sh (fake runtime)"
./pull_containers.sh > pull.out 2>&1
expect "creates one .sif per tool"            '[ "$(ls "$T/store/sif"/*.sif | wc -l)" -eq 6 ]'
expect "is idempotent"                        './pull_containers.sh 2>&1 | grep -q "^have  seqkit"'

echo "fetch_data.sh (needs internet)"
if ./fetch_data.sh > fetch.out 2>&1; then
    expect "downloads and verifies checksums"  'grep -q "Data ready" fetch.out'
    # stand-in for make_samples.pbs (needs the real wgsim): reuse the real reads as two "samples"
    mkdir -p "$T/store/data/samples"
    : > "$T/store/data/samples/samples.tsv"
    for i in 1 2; do
        id="sample_0$i"
        cp "$T/store/data/real/test_1.fastq.gz" "$T/store/data/samples/${id}_R1.fastq.gz"
        cp "$T/store/data/real/test_2.fastq.gz" "$T/store/data/samples/${id}_R2.fastq.gz"
        printf '%s\t%s\t%s\n' "$id" "$T/store/data/samples/${id}_R1.fastq.gz" "$T/store/data/samples/${id}_R2.fastq.gz" >> "$T/store/data/samples/samples.tsv"
    done
    echo "check_env.sh"
    ./check_env.sh > env.out 2>&1
    expect "all checks pass incl. the (fake) smoke job" 'grep -q "All checks passed" env.out'
    expect "smoke job log is cleaned up"       '! ls smoke_test.o* >/dev/null 2>&1'

    echo "section 01: checkers fail first, then pass after the solutions run"
    cd ../01_pbs_basics || exit 1
    export PBS_O_WORKDIR="$PWD" PBS_JOBID="4242.fake" NCPUS=1
    expect "check_01a fails before the job ran"  '! ./check_01a.sh >/dev/null 2>&1'
    for s in solutions/exercise_01a.pbs solutions/exercise_01b.pbs solutions/exercise_01c.pbs example_count_reads.pbs; do bash "$s" >/dev/null 2>&1 || nok "solution runs: $s"; done
    for c in check_01a.sh check_01b.sh check_01c.sh; do expect "$c passes after the solution" "./$c >/dev/null 2>&1"; done
    expect "results/ shortcut points to the section output folder" '[ -L results ] && [ -s results/fastq_counts.tsv ] && [ "$(readlink results)" = "$T/store/work/01_pbs_basics" ]'
    unset PBS_O_WORKDIR PBS_JOBID NCPUS
    cd ../00_getting_started || exit 1
else
    echo "  (skipped: no internet; fetch_data.sh failed)"
fi

echo "lib/edu.sh"
cd ../01_pbs_basics || exit 1
out="$(bash -c 'source ../lib/edu.sh; edu_exec seqkit version' 2>&1)"
expect "edu_exec builds: runtime exec --bind ... seqkit.sif seqkit version" 'echo "$out" | grep -q "fake-exec: exec --bind .* .*seqkit.sif seqkit version"'
expect "edu_exec fails clearly without an image" '! bash -c "source ../lib/edu.sh; edu_exec nosuchtool x" 2>&1 | grep -qv "is missing"'
expect "edu_threads defaults to 1"            '[ "$(bash -c "unset NCPUS; source ../lib/edu.sh; edu_threads")" = 1 ]'
expect "edu_qsub adds no -q when none is configured" 'bash -c "source ../lib/edu.sh; qsub() { echo \"\$@\"; }; [ \"\$(edu_qsub x.pbs)\" = x.pbs ]"'
expect "edu_qsub adds -q when configured"     'bash -c "source ../lib/edu.sh; EDU_QUEUE=big; qsub() { echo \"\$@\"; }; [ \"\$(edu_qsub x.pbs)\" = \"-q big x.pbs\" ]"'
mv ../site.conf ../site.conf.x
msg="$(bash -c 'source ../lib/edu.sh' 2>&1)"
mv ../site.conf.x ../site.conf
expect "a missing site.conf gives a clear error" 'echo "$msg" | grep -q "Run 00_getting_started/setup.sh"'

echo "06 check_free_nodes.sh (fake pbsnodes)"
cd ../06_interactive_and_nodes || exit 1
expect "lists both nodes"                      '[ "$(./check_free_nodes.sh | grep -c node0)" -eq 2 ]'
expect "marks only the healthy node usable"    '[ "$(./check_free_nodes.sh 8 16 | grep -c usable)" -eq 1 ]'
expect "decimal point, not comma"              './check_free_nodes.sh | grep -q "117.0/125.0"'

echo
if [ "$fails" -eq 0 ]; then echo "local smoke test: OK"; else echo "local smoke test: $fails failure(s)"; fi
exit "$fails"
