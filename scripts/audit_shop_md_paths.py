#!/usr/bin/env python3
"""Verify every `.dart` basename listed in docs/shop/shop.md exists under lib/shop/."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MD = ROOT / "docs/shop/shop.md"
SHOP = ROOT / "lib/shop"


def main() -> None:
    text = MD.read_text(encoding="utf-8")
    basenames: set[str] = set()
    for line in text.splitlines():
        line = line.strip()
        if not line.endswith(".dart"):
            continue
        # Tree lines end with `├── foo.dart` or `└── foo.dart`
        m = re.search(r"([\w./]+\.dart)\s*$", line)
        if m:
            basenames.add(Path(m.group(1)).name)

    missing: list[str] = []
    for base in sorted(basenames):
        if not list(SHOP.rglob(base)):
            missing.append(base)

    n_dart = len(list(SHOP.rglob("*.dart")))
    print(f"lib/shop: {n_dart} Dart files")
    print(f"shop.md: {len(basenames)} unique .dart basenames in tree")
    if missing:
        print("MISSING files for basenames:", ", ".join(missing))
        sys.exit(1)
    print("audit_shop_md_paths: OK")


if __name__ == "__main__":
    main()
