"""Makes project-llama.yml: the same Xcode project, plus the llama.cpp engine for LFM3 Omni.

The iOS build downloads llama.xcframework into Vendor/ first. If that worked, it runs
this script and builds from project-llama.yml. If not, it builds from project.yml, and
Ace still works without the on-device model.
"""
import pathlib
import sys

root = pathlib.Path(__file__).resolve().parent.parent
base = (root / "project.yml").read_text()
anchor = "    dependencies:\n      - target: AceWidgets\n        embed: true\n"
if anchor not in base:
    sys.exit("project.yml changed: couldn't find the Ace target's dependencies")
extra = "      - framework: Vendor/llama.xcframework\n        embed: true\n"
(root / "project-llama.yml").write_text(base.replace(anchor, anchor + extra, 1))
print("Wrote project-llama.yml")
