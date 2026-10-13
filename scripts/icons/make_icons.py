#!/usr/bin/env python3
# Runs inside the juxt-vlc-icons image (see make-icons.sh).
#
# Converts the Figma stroke icons listed in mapping.json into filled 24x24
# outlines, points VLC's VLCIcons.json at them and regenerates VLCIcons.ttf
# with VLC's own makeIconFont.py.
import json
import os
import re
import subprocess
import sys
import xml.etree.ElementTree as ET

SVG_NS = "http://www.w3.org/2000/svg"
ET.register_namespace("", SVG_NS)

ASSETS = "/design/figma-assets"
MAPPING = "/scripts/icons/mapping.json"
PIXMAPS = "/vlc/modules/gui/qt/pixmaps"
OUT_REL = "icons/juxt"


def tag(el):
    return el.tag.split("}")[-1]


def clean(src, mirror):
    """Return a black-only 24x24 SVG string for one Figma icon."""
    root = ET.parse(src).getroot()
    w = float(root.get("width"))
    h = float(root.get("height"))

    # Component exports carry a background fill and the dashed component-set
    # outline as plain <rect>s; neither is part of the glyph.
    for parent in list(root.iter()):
        for child in list(parent):
            if tag(child) == "rect" and (child.get("stroke-dasharray")
                                         or (child.get("width") == root.get("width")
                                             and child.get("height") == root.get("height")
                                             and not child.get("rx"))):
                parent.remove(child)

    for el in root.iter():
        for attr in ("fill", "stroke"):
            v = el.get(attr)
            if v and v != "none" and not v.startswith("url("):
                el.set(attr, "#000000")
        el.attrib.pop("style", None)

    body = "".join(ET.tostring(c, encoding="unicode") for c in root
                   if tag(c) != "defs")
    # Center smaller frames (e.g. the 18px "more" dots) on the 24px grid.
    transform = f"translate({(24 - w) / 2} {(24 - h) / 2})"
    if mirror:
        transform = f"matrix(-1 0 0 1 24 0) {transform}"
    return (f'<svg xmlns="{SVG_NS}" width="24" height="24" viewBox="0 0 24 24">'
            f'<g transform="{transform}" fill="{root.get("fill", "black")}">{body}</g></svg>')


def outline(path):
    # Strokes become fills, then everything is merged into one path so the
    # glyph has no overlapping contours (a makeIconFont.py requirement).
    subprocess.run([
        "inkscape", path,
        "--actions=select-all:all;object-to-path;object-stroke-to-path;"
        "select-all:all;path-union;export-plain-svg;"
        f"export-filename:{path};export-do",
    ], check=True, stderr=subprocess.DEVNULL)


def main():
    mapping = {k: v for k, v in json.load(open(MAPPING)).items()
               if not k.startswith("_")}
    out_dir = os.path.join(PIXMAPS, OUT_REL)
    os.makedirs(out_dir, exist_ok=True)

    for key, spec in mapping.items():
        dst = os.path.join(out_dir, f"{key}.svg")
        with open(dst, "w") as f:
            f.write(clean(os.path.join(ASSETS, spec["src"]), spec.get("mirror", False)))
        outline(dst)
        print("glyph", key, "<-", spec["src"])

    cfg_path = os.path.join(PIXMAPS, "VLCIcons.json")
    cfg = json.load(open(cfg_path))
    keys = {g["key"] for g in cfg["glyphs"]}
    # Glyphs the redesign needs that VLC has no key for are appended, so the
    # code points of the existing glyphs do not move.
    for key, spec in mapping.items():
        if spec.get("new") and key not in keys:
            cfg["glyphs"].append({"key": key, "path": ""})
            keys.add(key)
    missing = set(mapping) - keys
    if missing:
        sys.exit(f"unknown VLC icon keys: {sorted(missing)}")
    for g in cfg["glyphs"]:
        if g["key"] in mapping:
            g["path"] = f"./{OUT_REL}/{g['key']}.svg"

    # Keep VLCIcons.json's one-glyph-per-line layout so diffs stay readable.
    text = json.dumps(cfg, indent=4)
    text = re.sub(r'\{\s+"key": ("[^"]*"),\s+"path": ("[^"]*")\s+\}',
                  r'{"key":\1, "path": \2}', text)
    open(cfg_path, "w").write(text + "\n")

    os.chdir(PIXMAPS)
    subprocess.run(["python3", "makeIconFont.py", "VLCIcons.json"], check=True)


if __name__ == "__main__":
    main()
