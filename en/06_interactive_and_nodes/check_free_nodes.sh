#!/bin/bash
# List every compute node with its state and how many CPUs / GB of memory are free.
# Nothing to edit: node names come from PBS itself.
#
#   ./check_free_nodes.sh              all nodes
#   ./check_free_nodes.sh 4 8          only usable nodes with >= 4 free CPUs and >= 8 GB free
#
# "Free" = resources_available - resources_assigned, as PBS reports them.
# Run it on the login node. It only reads information.

# print decimals with "." whatever the language of your account
export LC_ALL=C

MIN_CPUS="${1:-0}"
MIN_GB="${2:-0}"

if ! command -v pbsnodes >/dev/null 2>&1; then
    echo "pbsnodes not found: run this on the cluster's login node" >&2
    exit 1
fi

pbsnodes -a 2>/dev/null | awk -v min_cpus="$MIN_CPUS" -v min_gb="$MIN_GB" '
    # convert "131072000kb", "64gb", "512mb" ... to GB
    function to_gb(v,   n, u) {
        n = v + 0; u = tolower(v); sub(/^[0-9.]+/, "", u)
        if (u == "kb") return n / 1048576
        if (u == "mb") return n / 1024
        if (u == "gb") return n
        if (u == "tb") return n * 1024
        if (u == "b" || u == "") return n / 1073741824
        return n
    }
    function flush(   fc, fm, usable) {
        if (name == "") return
        fc = ac - sc; fm = am - sm
        usable = (state !~ /down|offline|unknown|unresolvable|busy|exclusive|maintenance/ && fc >= min_cpus && fm >= min_gb)
        if (min_cpus + min_gb > 0 && !usable) return
        printf "%-22s %-24s %5d/%-5d %8.1f/%-8.1f %s\n", name, state, fc, ac, fm, am, (usable ? "<- usable" : "")
        shown++
    }
    /^[^ \t]/ { flush(); name = $1; state = "?"; ac = sc = am = sm = 0; next }
    $1 == "state"                       { state = $3 }
    $1 == "resources_available.ncpus"   { ac = $3 }
    $1 == "resources_assigned.ncpus"    { sc = $3 }
    $1 == "resources_available.mem"     { am = to_gb($3) }
    $1 == "resources_assigned.mem"      { sm = to_gb($3) }
    BEGIN { printf "%-22s %-24s %-11s %-17s\n", "NODE", "STATE", "CPUS free/all", "MEM(GB) free/all" }
    END { flush(); if (!shown) print "(no node matches)" }
'
