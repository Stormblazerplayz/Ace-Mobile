# @title Code Line Counter
# @category Files and data
# @kind Console program
# @where Save as line_count.py and run: python3 line_count.py, then type a project folder.
# @keywords python count lines of code, python project stats, python lines per file, python code comments count
# @about Counts the lines of code, comments and blank lines in every code file of a project.

from collections import defaultdict
from pathlib import Path

COMMENT = {".py": "#", ".lua": "--", ".swift": "//", ".cpp": "//", ".js": "//", ".c": "//", ".h": "//"}

folder = Path(input("Project folder (Enter for this one): ").strip() or ".").expanduser()
totals = defaultdict(lambda: [0, 0, 0, 0])  # files, code, comments, blank

for path in folder.rglob("*"):
    marker = COMMENT.get(path.suffix.lower())
    if not marker or not path.is_file() or any(part.startswith(".") for part in path.parts):
        continue
    stats = totals[path.suffix.lower()]
    stats[0] += 1
    for line in path.read_text(encoding="utf-8", errors="ignore").splitlines():
        stripped = line.strip()
        if not stripped:
            stats[3] += 1
        elif stripped.startswith(marker):
            stats[2] += 1
        else:
            stats[1] += 1

print(f"\n{'Type':<8}{'Files':>7}{'Code':>8}{'Comments':>10}{'Blank':>8}")
for ext, (files, code, comments, blank) in sorted(totals.items(), key=lambda kv: -kv[1][1]):
    print(f"{ext:<8}{files:>7}{code:>8}{comments:>10}{blank:>8}")
all_code = sum(v[1] for v in totals.values())
print(f"\nTotal lines of code: {all_code:,}")
