#!/usr/bin/env python3
"""Map ANTHRACITE_PERF_PROFILE C instruction addresses back to ATS2 sources.

Usage:
  python3 tools/performance/map_c_to_ats.py [--tag NAME] <binary> <profile_file> [build_dir]

--tag keeps only samples taken while the benchmark set that label
(load, first, idle, prewarm, scroll); untagged/other samples are dropped.
"""
import os
import re
import subprocess
import sys
from collections import Counter
from pathlib import Path

LOC_RE = re.compile(r"(?:/[^:\s*]+/src/)([^:\s*]+):\s*\d+\(line=(\d+),\s*offs=(\d+)\)")
ADDR2LINE_RE = re.compile(r"^([^\s]+)\s+at\s+([^:]+):(\d+|\?)")
MAP_RE = re.compile(r"^# map=0x([0-9a-fA-F]+)-0x([0-9a-fA-F]+)\s+(.+)$")


def is_pie_binary(binary: Path) -> bool:
    out = subprocess.check_output(["readelf", "-h", str(binary)], text=True, stderr=subprocess.DEVNULL)
    return "DYN" in out


class CFileMapper:
    def __init__(self, path: Path):
        self.lines = path.read_text(errors="replace").splitlines()
        self.sym_line_cache = {}

    def find_symbol_line(self, c_func: str) -> int:
        if c_func in self.sym_line_cache:
            return self.sym_line_cache[c_func]
        pat = f"{c_func}("
        found = 0
        for i, line in enumerate(self.lines):
            if line.startswith(pat):
                found = i + 1
                break
        if found == 0:
            for i, line in enumerate(self.lines):
                if pat in line and not line.strip().endswith(";"):
                    found = i + 1
                    break
        self.sym_line_cache[c_func] = found
        return found

    def lookup_ats(self, c_line_1based: int, c_func: str = ""):
        if c_line_1based <= 0 and c_func:
            c_line_1based = self.find_symbol_line(c_func)
        if c_line_1based <= 0:
            return None
        idx = min(max(0, c_line_1based - 1), len(self.lines) - 1)
        emit_loc = None
        func_loc = None
        for i in range(idx, max(-1, idx - 80), -1):
            line = self.lines[i]
            if emit_loc is None and "emit_instr: loc0 =" in line:
                m = LOC_RE.search(line)
                if m:
                    emit_loc = (f"src/{m.group(1)}", int(m.group(2)))
                    break
            if "end of [" in line and i < idx - 1:
                break
            if line.startswith("/*") or (i > 0 and self.lines[i - 1].startswith("/*")):
                m = LOC_RE.search(line)
                if m and func_loc is None:
                    func_loc = (f"src/{m.group(1)}", int(m.group(2)))
        if emit_loc is None:
            for i in range(idx, max(-1, idx - 500), -1):
                line = self.lines[i]
                if "end of [" in line and i < idx:
                    break
                m = LOC_RE.search(line)
                if m:
                    func_loc = (f"src/{m.group(1)}", int(m.group(2)))
                    break
        return emit_loc or func_loc


def ats_decl_snippet(repo_root: Path, rel_path: str, line_no: int) -> str:
    p = repo_root / rel_path
    if not p.is_file():
        return ""
    lines = p.read_text(errors="replace").splitlines()
    if line_no < 1 or line_no > len(lines):
        return ""
    for i in range(line_no - 1, max(-1, line_no - 25), -1):
        s = lines[i].strip()
        if s.startswith(("fun ", "implement ", "fn ", "and ")):
            return s.split("=", 1)[0][:72]
    return lines[line_no - 1].strip()[:72]


def find_module(pc: int, maps: list[tuple[int, int, str]]) -> str:
    for start, end, path in maps:
        if start <= pc < end:
            return os.path.basename(path)
    return "unknown"


def resolve_pcs(binary: Path, pcs: list[int], exe_base: int, pie: bool, maps: list[tuple[int, int, str]]):
    if not pcs:
        return {}
    bin_name = binary.name
    exe_pcs = []
    other_pcs = {}
    for pc in pcs:
        mod = find_module(pc, maps)
        if mod == bin_name or mod == "unknown":
            exe_pcs.append(pc)
        else:
            other_pcs[pc] = (f"[{mod}]", mod, 0)

    offsets = []
    for pc in exe_pcs:
        off = (pc - exe_base) if (pie and exe_base and pc >= exe_base) else pc
        offsets.append(f"0x{off:x}")
    mapping = dict(other_pcs)
    if exe_pcs:
        # -i lists the inline chain; attribute each PC to the outermost (real,
        # non-inlined) function. Without it, inlined prelude helpers such as
        # atspre_g0int_add_int appear as hot "functions" that do not exist.
        cmd = ["addr2line", "-e", str(binary), "-f", "-i", "-p", *offsets]
        res = subprocess.run(cmd, input="", text=True, capture_output=True, check=False)
        groups = []
        for out_line in res.stdout.splitlines():
            stripped = out_line.strip()
            if stripped.startswith("(inlined by)") and groups:
                groups[-1] = stripped[len("(inlined by)"):].strip()
            else:
                groups.append(stripped)
        for pc, out_line in zip(exe_pcs, groups):
            m = ADDR2LINE_RE.match(out_line)
            if m:
                func, fpath, lstr = m.group(1), m.group(2), m.group(3)
                c_line = int(lstr) if lstr.isdigit() else 0
                if func == "??":
                    mod = find_module(pc, maps)
                    mapping[pc] = (f"[{mod}]", mod, 0)
                else:
                    mapping[pc] = (func, fpath, c_line)
            else:
                mod = find_module(pc, maps)
                mapping[pc] = (f"[{mod}]", mod, 0)
    return mapping


# Must match TAG_* in tests/performance/document_performance.dats.
SAMPLE_TAGS = {"untagged": 0, "load": 1, "first": 2, "idle": 3, "prewarm": 4, "scroll": 5, "background": 6}


def parse_stack_line(line: str):
    """Parse 'S depth [T tag] pc...' (the T field is absent in older profiles)."""
    parts = line.split()
    tag = 0
    rest = parts[2:]
    if len(rest) >= 2 and rest[0] == "T":
        tag = int(rest[1])
        rest = rest[2:]
    return tag, [int(x, 16) for x in rest]


def main():
    args = sys.argv[1:]
    want_tag = None
    if len(args) >= 2 and args[0] == "--tag":
        if args[1] not in SAMPLE_TAGS:
            print(f"unknown tag {args[1]}; choose from {', '.join(SAMPLE_TAGS)}", file=sys.stderr)
            sys.exit(2)
        want_tag = SAMPLE_TAGS[args[1]]
        args = args[2:]
    if len(args) < 2:
        print("Usage: map_c_to_ats.py [--tag NAME] <binary> <profile_file> [build_dir]", file=sys.stderr)
        sys.exit(2)
    binary = Path(args[0]).resolve()
    prof = Path(args[1]).resolve()
    repo_root = Path(__file__).resolve().parents[2]
    build_dir = Path(args[2]).resolve() if len(args) > 2 else binary.parent

    exe_base = 0
    maps = []
    phases = []
    counters = []
    stacks = []
    for line in prof.read_text().splitlines():
        if line.startswith("# exe_base="):
            m = re.search(r"exe_base=0x([0-9a-fA-F]+)", line)
            if m:
                exe_base = int(m.group(1), 16)
        elif line.startswith("# map="):
            m = MAP_RE.match(line)
            if m:
                maps.append((int(m.group(1), 16), int(m.group(2), 16), m.group(3)))
        elif line.startswith("event=perf_phase "):
            phases.append(line)
        elif line.startswith("event=performance_counter "):
            counters.append(line)
        elif line.startswith("S "):
            tag, pcs = parse_stack_line(line)
            if pcs and (want_tag is None or tag == want_tag):
                stacks.append(pcs)

    unique_pcs = sorted({pc for st in stacks for pc in st})
    pie = is_pie_binary(binary)
    pc_map = resolve_pcs(binary, unique_pcs, exe_base, pie, maps)

    c_cache = {}
    def get_c_mapper(fpath: str):
        p = Path(fpath)
        if not p.is_file():
            cand = build_dir / p.name
            if cand.is_file():
                p = cand
            else:
                return None
        key = str(p)
        if key not in c_cache:
            c_cache[key] = CFileMapper(p)
        return c_cache[key]

    self_hits = Counter()
    incl_hits = Counter()
    func_c_loc = {}
    func_ats_loc = {}

    for st in stacks:
        leaf_func = pc_map.get(st[0], ("??", "??", 0))[0]
        self_hits[leaf_func] += 1
        seen_in_stack = set()
        for pc in st:
            fn, cf, cl = pc_map.get(pc, ("??", "??", 0))
            if fn not in seen_in_stack:
                incl_hits[fn] += 1
                seen_in_stack.add(fn)
            if (fn not in func_c_loc or func_c_loc[fn][1] == 0) and cf != "??":
                func_c_loc[fn] = (cf, cl)
                if cf.endswith("_dats.c"):
                    mapper = get_c_mapper(cf)
                    if mapper:
                        ats = mapper.lookup_ats(cl, fn)
                        if ats:
                            func_ats_loc[fn] = ats

    total = len(stacks)
    print(f"=== C <-> ATS2 Profile Summary ({binary.name}) ===")
    label = next((k for k, v in SAMPLE_TAGS.items() if v == want_tag), "all")
    print(f"Total SIGPROF samples: {total} (tag={label})")

    def fmt_ats(fn, cf, cl):
        cf_short = os.path.basename(cf)
        ats = func_ats_loc.get(fn)
        if ats:
            snip = ats_decl_snippet(repo_root, ats[0], ats[1])
            return f"{ats[0]}:{ats[1]}" + (f" ({snip})" if snip else "")
        if fn.startswith("[") and fn.endswith("]"):
            return f"[External Shared Lib: {cf_short}]"
        if cf_short.endswith((".c", ".cats", ".h")):
            return f"[Native C: {cf_short}:{cl}]"
        return f"[Unmapped C: {cf_short}:{cl}]"

    print("\n--- Top Self-Time C Functions -> ATS2 Source ---")
    print(f"{'Self%':>6} {'Incl%':>6} {'Self':>6}  {'C Symbol (C File:Line)':<52} -> ATS2 Location")
    for fn, cnt in self_hits.most_common(30):
        cf, cl = func_c_loc.get(fn, ("?", 0))
        sp = 100.0 * cnt / total if total else 0.0
        ip = 100.0 * incl_hits[fn] / total if total else 0.0
        c_col = f"{fn} ({os.path.basename(cf)}:{cl})"
        print(f"{sp:5.1f}% {ip:5.1f}% {cnt:6d}  {c_col:<52} -> {fmt_ats(fn, cf, cl)}")

    print("\n--- Top Inclusive C Functions -> ATS2 Source ---")
    print(f"{'Incl%':>6} {'Self%':>6} {'Incl':>6}  {'C Symbol (C File:Line)':<52} -> ATS2 Location")
    for fn, cnt in incl_hits.most_common(30):
        cf, cl = func_c_loc.get(fn, ("?", 0))
        ip = 100.0 * cnt / total if total else 0.0
        sp = 100.0 * self_hits[fn] / total if total else 0.0
        c_col = f"{fn} ({os.path.basename(cf)}:{cl})"
        print(f"{ip:5.1f}% {sp:5.1f}% {cnt:6d}  {c_col:<52} -> {fmt_ats(fn, cf, cl)}")

    if phases:
        print("\n--- Sub-Phase Timers ---")
        for p in phases:
            print(p)
    if counters:
        print("\n--- Counters ---")
        for c in counters:
            print(c)


if __name__ == "__main__":
    main()
