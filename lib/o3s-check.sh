#!/usr/bin/env bash
# Check every feature's o3s metadata against the shape CONTRIBUTING.md describes: lists of
# entries that each carry a name and a description, plus the fields their kind needs.
set -euo pipefail

root="${1:-$(cd "$(dirname "$0")/.." && pwd)}"

python3 -I - "$root" <<'PY'
import json, pathlib, sys

root = pathlib.Path(sys.argv[1])
# The fields each kind of entry needs beside its name and description.
needs = {"hosts": ["ports"], "env": ["value"], "files": ["target"]}
problems, checked = [], 0
for path in sorted(root.glob("src/*/devcontainer-feature.json")):
    checked += 1
    feature = f"src/{path.parent.name}"
    o3s = json.loads(path.read_text()).get("customizations", {}).get("o3s")
    if o3s is None:
        continue
    for kind in o3s:
        if kind not in needs:
            problems.append(f"{feature}: {kind} sits beside the sections hosts, env and files")
    for kind, fields in needs.items():
        entries = o3s.get(kind, [])
        if not isinstance(entries, list):
            problems.append(f"{feature}: {kind} must be a list")
            continue
        for i, entry in enumerate(entries):
            for field in ["name", "description", *fields]:
                if not entry.get(field):
                    problems.append(f"{feature}: {kind}[{i}] needs a {field}")
for problem in problems:
    print(problem, file=sys.stderr)
print(f"{checked} features checked")
sys.exit(1 if problems else 0)
PY
