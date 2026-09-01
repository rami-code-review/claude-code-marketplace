#!/usr/bin/env python3

import argparse
import difflib
import os
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
SOURCE_ROOT = ROOT / "workflows"
TARGET_ROOT = ROOT / "plugins" / "rami" / "skills"
CODEX_UNSUPPORTED_FRONTMATTER = {"context", "model"}
REQUIRED_FRONTMATTER = {"name", "description"}


def codex_skill(source: Path) -> str:
    lines = source.read_text().splitlines(keepends=True)
    if not lines or lines[0].strip() != "---":
        raise ValueError(f"missing frontmatter in {source}")

    end = next(
        (index for index, line in enumerate(lines[1:], start=1) if line.strip() == "---"),
        None,
    )
    if end is None:
        raise ValueError(f"unterminated frontmatter in {source}")

    frontmatter = [
        line
        for line in lines[1:end]
        if line.split(":", 1)[0].strip() not in CODEX_UNSUPPORTED_FRONTMATTER
    ]
    keys = {
        line.split(":", 1)[0].strip()
        for line in frontmatter
        if ":" in line and not line[0].isspace()
    }
    missing = REQUIRED_FRONTMATTER - keys
    if missing:
        raise ValueError(f"missing frontmatter keys {sorted(missing)} in {source}")
    return "".join([lines[0], *frontmatter, lines[end], *lines[end + 1 :]])


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    changed = False

    for source in sorted(SOURCE_ROOT.glob("*/SKILL.md")):
        target = TARGET_ROOT / source.parent.name / "SKILL.md"
        expected = codex_skill(source)
        actual = target.read_text() if target.exists() else ""
        if actual == expected:
            continue

        changed = True
        if args.check:
            print(
                "".join(
                    difflib.unified_diff(
                        actual.splitlines(keepends=True),
                        expected.splitlines(keepends=True),
                        fromfile=str(target),
                        tofile=str(source),
                    )
                ),
                end="",
            )
        else:
            target.parent.mkdir(parents=True, exist_ok=True)
            staging = target.with_name(target.name + ".tmp")
            staging.write_text(expected)
            os.replace(staging, target)

    return int(changed and args.check)


if __name__ == "__main__":
    raise SystemExit(main())
