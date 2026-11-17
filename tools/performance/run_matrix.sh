#!/usr/bin/env bash
# Run the document/search benchmark matrix and summarize it.
#
# Usage: tools/performance/run_matrix.sh BUILD_DIR OUT_DIR [RUNS] [PROFILE]
#   BUILD_DIR  directory holding document_performance and search_performance
#   OUT_DIR    logs, profiles and summaries are written here
#   RUNS       fresh processes per (mode, scenario); default 5
#   PROFILE    1 = also record one SIGPROF profile per (mode, scenario); default 0
#
# Uses the deterministic fixture from gen_fixture.py; personal notes are never read.
# Frame totals are VSync-bound on most drivers: compare cpu_ms, not elapsed_ms.
set -euo pipefail
build=$(realpath "$1")
out=$(realpath -m "$2")
runs=${3:-5}
profile=${4:-0}
here=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$out"
python3 "$here/gen_fixture.py" "$out/fixture" >"$out/fixture.txt"
for mode in read edit; do
  for scenario in jump wheel page; do
    for run in $(seq 1 "$runs"); do
      log="$out/doc_${mode}_${scenario}_${run}.log"
      "$build/document_performance" "$out/fixture/vault" "$out/fixture/heavy.md" "$mode" "$scenario" >"$log" 2>>"$out/stderr.log"
    done
    if [ "$profile" = 1 ]; then
      ANTHRACITE_PERF_PROFILE="$out/prof_${mode}_${scenario}.txt" \
        "$build/document_performance" "$out/fixture/vault" "$out/fixture/heavy.md" "$mode" "$scenario" >/dev/null 2>>"$out/stderr.log"
    fi
    python3 "$here/summarize.py" --json "$out"/doc_${mode}_${scenario}_*.log >"$out/summary_${mode}_${scenario}.json"
  done
done
"$build/search_performance" "$out/fixture/vault" not 20 >"$out/search.log" 2>>"$out/stderr.log"
python3 "$here/summarize.py" --json "$out/search.log" >"$out/summary_search.json"
echo "done: $out"
