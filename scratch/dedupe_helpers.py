import glob
import re

root = "/home/emrehan/kod/kod/anthracite/src/"
common = open(root + "common.hats").read().splitlines()
shared = {l for l in common if l.startswith("fun ")}
include = '#include "common.hats"'
anchor = '#include "share/atspre_staload.hats"'

for path in glob.glob(root + "**/*.dats", recursive=True):
    lines = open(path).read().split("\n")
    has_local = any(l in shared for l in lines)
    has_include = include in lines
    if not has_local and not has_include:
        continue
    kept = [l for l in lines if l not in shared]
    if include not in kept:
        idx = kept.index(anchor) + 1
        kept.insert(idx, include)
    text = "\n".join(kept)
    text = re.sub(r"\n{3,}", "\n\n", text)
    open(path, "w").write(text)
    print("updated", path, len(lines) - len(kept))
