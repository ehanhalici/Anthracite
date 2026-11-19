#!/usr/bin/env python3
"""Generate deterministic performance fixtures (no personal notes involved).

Usage:
  python3 tools/performance/gen_fixture.py OUT_DIR [--notes N] [--sections S]

Writes OUT_DIR/heavy.md (one large mixed-syntax note, ~87 KB, ~1300 lines with the default
--sections) and OUT_DIR/vault/note_XXX.md (N small notes for search).
Output is byte-for-byte stable for a given set of arguments.
"""
import argparse
import random
from pathlib import Path

WORDS = ("not belge satır başlık kalın eğik bağlantı görev arama yazı tipi glif "
         "şekillendirme önbellek kaydırma çizim düzen paragraf ağaç ölçüm performans "
         "çğıöşü ÇĞİÖŞÜ editor vault render layout shaping cache scroll").split()
ARABIC = "النص العربي يتطلب تشكيلاً سياقياً للحروف المتصلة"


def sentence(rng: random.Random, n: int) -> str:
    out = []
    for _ in range(n):
        w = rng.choice(WORDS)
        r = rng.random()
        if r < 0.06:
            w = f"**{w}**"
        elif r < 0.11:
            w = f"*{w}*"
        elif r < 0.13:
            w = f"~~{w}~~"
        elif r < 0.15:
            w = f"`{w}`"
        elif r < 0.18:
            w = f"[[note_{rng.randrange(50):03d}|{w}]]"
        out.append(w)
    return " ".join(out).capitalize() + "."


def section(rng: random.Random, i: int) -> str:
    parts = [f"{'#' * (1 + i % 3)} Bölüm {i} {rng.choice(WORDS)}", ""]
    for _ in range(3):
        parts.append(sentence(rng, rng.randrange(18, 40)))
        parts.append("")
    parts += [f"- [ ] {sentence(rng, 6)}", f"- [x] {sentence(rng, 5)}",
              f"  - {sentence(rng, 7)}", ""]
    kind = i % 5
    if kind == 0:
        parts += ["> [!note] Callout", f"> {sentence(rng, 20)}", ""]
    elif kind == 1:
        parts += ["| A | B | C |", "|---|---|---|"]
        parts += [f"| {rng.choice(WORDS)} | {rng.randrange(1000)} | {rng.choice(WORDS)} |"
                  for _ in range(4)]
        parts.append("")
    elif kind == 2:
        parts += ["$$", r"\sum_{k=1}^{n} \frac{x_k^2}{\sqrt{k}} = \int_0^1 f(t)\,dt", "$$",
                  f"Satır içi $a^2+b^2=c^2$ {sentence(rng, 6)}", ""]
    elif kind == 3:
        parts += ["```c", "for (int i = 0; i < n; ++i) {", "  sum += values[i] * i;", "}",
                  "```", ""]
    else:
        parts += [ARABIC + " " + sentence(rng, 8), ""]
    return "\n".join(parts)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("out")
    ap.add_argument("--notes", type=int, default=50)
    ap.add_argument("--sections", type=int, default=78)
    ap.add_argument("--seed", type=int, default=20261117)
    args = ap.parse_args()
    rng = random.Random(args.seed)
    out = Path(args.out)
    vault = out / "vault"
    vault.mkdir(parents=True, exist_ok=True)
    heavy = "\n".join(section(rng, i) for i in range(args.sections)) + "\n"
    (out / "heavy.md").write_text(heavy, encoding="utf-8")
    for n in range(args.notes):
        body = "\n\n".join(sentence(rng, rng.randrange(20, 60)) for _ in range(4))
        (vault / f"note_{n:03d}.md").write_text(f"# Not {n}\n\n{body}\n", encoding="utf-8")
    print(f"heavy_bytes={len(heavy.encode())} heavy_lines={heavy.count(chr(10))} notes={args.notes}")


if __name__ == "__main__":
    main()
