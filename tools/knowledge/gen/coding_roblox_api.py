#!/usr/bin/env python3
"""Builds data/coding/gen_roblox_api.txt: "what does X do" entries for the Roblox engine API.

Source: Roblox Creator Documentation, https://github.com/Roblox/creator-docs
        (content/en-us/reference/engine/**.yaml), licensed CC BY 4.0.
        Text is adapted: links and markup are removed, and usage lines are added from the
        documented parameters.

Run from the repo root:
    python3 tools/knowledge/gen/coding_roblox_api.py
The YAML files are downloaded into tools/knowledge/.cache/robloxdocs/ (not committed).
"""
import os
import re
import sys
import urllib.request

import yaml

HERE = os.path.dirname(os.path.abspath(__file__))
KNOW = os.path.dirname(HERE)
CACHE = os.path.join(KNOW, ".cache", "robloxdocs")
OUT = os.path.join(KNOW, "data", "coding", "gen_roblox_api.txt")
BASE = "https://raw.githubusercontent.com/Roblox/creator-docs/main/content/en-us/reference/engine"

# Classes a game dev actually touches. Members are listed on the class that defines them.
CLASSES = """Instance Players Player Workspace WorldRoot BasePart Part MeshPart Model PVInstance Humanoid
ReplicatedStorage ServerStorage StarterGui StarterPlayer DataStoreService GlobalDataStore
DataStore OrderedDataStore DataStoreKeyInfo MemoryStoreService TweenService TweenBase Tween RunService
UserInputService ContextActionService Debris MarketplaceService BadgeService TeleportService HttpService
PathfindingService Path CollectionService SoundService Sound Lighting Camera PlayerGui ScreenGui
LayerCollector GuiBase2d GuiObject Frame ScrollingFrame TextLabel TextButton TextBox ImageLabel ImageButton
GuiButton UIListLayout UIGridLayout UICorner UIStroke UIGradient UIPadding UIAspectRatioConstraint UIScale
ProximityPrompt ProximityPromptService ClickDetector RemoteEvent RemoteFunction UnreliableRemoteEvent
BindableEvent BindableFunction Script Tool BackpackItem Animator Animation AnimationTrack Attachment Weld
WeldConstraint Motor6D HingeConstraint RopeConstraint SpringConstraint RodConstraint PrismaticConstraint
BallSocketConstraint AlignPosition AlignOrientation LinearVelocity AngularVelocity VectorForce Constraint Beam
Trail ParticleEmitter PointLight SpotLight SurfaceLight Light Fire Smoke Sparkles Explosion SpawnLocation Team
Teams TextChatService BillboardGui SurfaceGui Highlight Terrain Seat VehicleSeat IntValue StringValue
NumberValue BoolValue ObjectValue Folder Backpack Decal Texture Accessory Atmosphere Sky
Clouds BloomEffect BlurEffect ColorCorrectionEffect PolicyService GroupService ReplicatedFirst
SoundGroup PhysicsService TextService MessagingService UITextSizeConstraint UISizeConstraint
ViewportFrame AnimationController""".split()
DATATYPES = """CFrame Vector3 Vector2 Color3 UDim2 UDim TweenInfo RaycastParams RaycastResult BrickColor
NumberSequence ColorSequence NumberRange OverlapParams Random Instance RBXScriptSignal RBXScriptConnection""".split()
LIBRARIES = "task math string table os coroutine".split()
GLOBALS = "LuaGlobals RobloxGlobals".split()

# Niche members (gamepad selection, VR, localization, voice, internal tuning) are left out.
SKIP_NAME = re.compile(r"Accelerometer|Gyroscope|Device|Selection|Localiz|Voice|VR|Gamepad|Haptic|AutoLocalize|RootLocalizationTable|"
                       r"Interpolation|Streaming|LevelOfDetail|ModelStreaming|Sleep|FluidForces|Pivot Offset|"
                       r"^Archivable$|UniqueId|ExperienceSettings|RichTextContent|OpenTypeFeatures|ContentText$")
SKIP_TAGS = {"Deprecated", "Hidden", "NotScriptable", "NotBrowsable"}
DATED = re.compile(r"\b(currently|right now|these days|nowadays|the current|at the moment|today's)\b", re.I)
# Very generic member names never get a bare "what is X in roblox" wording.
GENERIC = {"name", "parent", "size", "position", "color", "value", "enabled", "visible", "text", "image",
           "transparency", "rotation", "orientation", "length", "volume", "playing", "x", "y", "z", "magnitude",
           "unit", "new", "type", "id", "time", "speed", "range", "brightness", "shadows", "face", "texture"}


def fetch(kind, name, fname):
    path = os.path.join(CACHE, fname)
    if not os.path.exists(path):
        os.makedirs(CACHE, exist_ok=True)
        url = f"{BASE}/{kind}/{name}.yaml"
        try:
            with urllib.request.urlopen(url, timeout=30) as r:
                data = r.read()
        except Exception as ex:  # noqa: BLE001
            print("could not fetch", url, ex, file=sys.stderr)
            return None
        open(path, "wb").write(data)
    return yaml.safe_load(open(path, encoding="utf-8"))


def ref(m):
    inner = m.group(1)
    if "|" in inner:
        return inner.split("|", 1)[1]
    for pre in ("Class.", "Datatype.", "Library.", "Global.LuaGlobals.", "Global.RobloxGlobals.", "Enum."):
        if inner.startswith(pre):
            return ("Enum." if pre == "Enum." else "") + inner[len(pre):]
    return inner


def clean(text):
    if not text:
        return ""
    def sub(m):
        nxt = m.string[m.end():m.end() + 1]
        return ref(m) + (" " if nxt.isalpha() else "")
    t = re.sub(r"`([^`\n]*)`", sub, text)
    t = re.sub(r"\[([^\]]+)\]\([^)]*\)", r"\1", t)
    t = t.replace("**", "").replace("__", "")
    t = re.sub(r"(?<![\w])_([^_]+)_(?![\w])", r"\1", t)
    t = t.replace("—", ", ").replace("–", ", ").replace("‑", "-")
    t = re.sub(r"\s+", " ", t).strip()
    # drop sentences with time words the checker rejects
    sents = re.split(r"(?<=[.!?])\s+", t)
    sents = [s for s in sents if not DATED.search(s)]
    t = " ".join(sents).strip()
    if t and t[-1] not in ".!?":
        t += "."
    if t:
        t = t[0].upper() + t[1:]
    return t


def short(text, limit=330):
    sents = re.split(r"(?<=[.!?])\s+", text)
    out = ""
    for s in sents:
        if len(out) + len(s) + 1 > limit:
            break
        out = (out + " " + s).strip()
    return out or text[:limit].rsplit(" ", 1)[0] + "."


def ok_member(m, sec_ok=True):
    tags = set(m.get("tags") or [])
    if SKIP_NAME.search(member_short(m["name"])):
        return False
    if tags & SKIP_TAGS:
        return False
    if (m.get("deprecation_message") or "").strip():
        return False
    s = m.get("security")
    if isinstance(s, dict):
        if s.get("read") != "None":
            return False
    elif s not in (None, "None"):
        return False
    return True


def params_sig(m):
    ps = m.get("parameters") or []
    return ", ".join(p["name"] for p in ps)


def art(word):
    if word.startswith(("RBX", "Enum")) or (word[:1].lower() in "aeio") or (word[:1] == "u" and not word.startswith("u")):
        return "an"
    if word[:1] in "Uu" and not word.lower().startswith(("udim", "userdata", "unit", "uni")):
        return "an"
    return "a"


def ret_word(t):
    t = t.strip()
    if t in ("Variant", "...", "any", ""):
        return None
    if t.startswith(("List<", "Array", "Instances", "{")) or t.endswith("[]"):
        return "an array (a list table)"
    if t.startswith("Tuple"):
        return "one or more values"
    if t in ("Dictionary", "table"):
        return "a table"
    if t in ("int", "int64", "float", "double", "number"):
        return "a number"
    if t in ("bool", "boolean"):
        return "true or false"
    if t in ENUMS:
        return f"an Enum.{t} value"
    if not re.match(r"^[A-Za-z0-9]+$", t):
        return None
    if t == "Enum":
        return "an enum value"
    return art(t) + " " + t


def returns_text(m):
    rs = [r.get("type") for r in (m.get("returns") or []) if r.get("type") and r.get("type") not in ("()", "void")]
    if len(rs) != 1:
        return " It returns several values." if len(rs) > 1 else ""
    w = ret_word(rs[0])
    return f" It returns {w}." if w else ""


TYPE_WORDS = {"bool": "true/false", "boolean": "true/false", "float": "number", "double": "number", "int": "whole number",
              "int64": "whole number", "string": "string (text)", "number": "number"}


ENUMS = set()
_dump = os.path.join(KNOW, ".cache", "api_dump.json")
DUMP_URL = "https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/API-Dump.json"


def load_enums():
    if not os.path.exists(_dump):
        try:
            with urllib.request.urlopen(DUMP_URL, timeout=60) as r:
                open(_dump, "wb").write(r.read())
        except Exception as ex:  # noqa: BLE001
            print("no API dump, enum types will not be marked", ex, file=sys.stderr)
            return
    import json
    dump = json.load(open(_dump, encoding="utf-8"))
    for e in dump["Enums"]:
        ENUMS.add(e["Name"])
    for c in dump["Classes"]:
        if "Service" in (c.get("Tags") or []):
            SERVICES.add(c["Name"])


def type_phrase(typ):
    typ = typ.replace("Datatype.", "").replace("Class.", "").replace("Enum.", "")
    tw = TYPE_WORDS.get(typ, typ)
    if typ in ENUMS:
        return f"an Enum.{typ}"
    return art(tw) + " " + tw


SERVICES = set()
VAR = {"CFrame": "cf", "Vector3": "vec", "Vector2": "vec2", "Color3": "color", "UDim2": "udim2", "UDim": "udim",
       "RBXScriptSignal": "event", "RBXScriptConnection": "connection", "BrickColor": "brickColor",
       "RaycastParams": "params", "OverlapParams": "params", "RaycastResult": "result", "TweenInfo": "tweenInfo",
       "Random": "rng", "Instance": "instance", "NumberRange": "range", "NumberSequence": "sequence",
       "ColorSequence": "sequence", "GlobalDataStore": "dataStore", "DataStore": "dataStore",
       "OrderedDataStore": "orderedStore", "DataStoreKeyInfo": "keyInfo"}


def var_of(name):
    if name in VAR:
        return VAR[name]
    return name[0].lower() + name[1:]


def is_service(name):
    return name in SERVICES or name.endswith("Service")


def lw(s):
    return s.lower()


sys.path.insert(0, KNOW)
from check_data import keyset, norm  # noqa: E402  same duplicate rules as the checker
from coding_common import existing  # noqa: E402

entries = []
seen_q = set()
seen_keys = set()
bare_count = {}


def add(tag, qs, answer):
    qs2 = []
    for q in qs:
        q = re.sub(r"\s+", " ", q.lower()).strip()
        k = keyset(q)
        if q and norm(q) not in seen_q and q not in qs2 and 1 <= len(q.split()) <= 16 and k not in seen_keys:
            qs2.append(q)
    if len(qs2) < 2 or len(answer) < 15:
        return
    if len(answer) > 560:
        answer = short(answer, 520)
    for q in qs2:
        seen_q.add(norm(q))
        if len(keyset(q)) >= 2:
            seen_keys.add(keyset(q))
    entries.append((tag, qs2, answer))


def member_short(full):
    return re.split(r"[.:]", full)[-1]


def collect_names(docs):
    for kind, d in docs:
        for sec in ("properties", "methods", "events", "functions"):
            for m in d.get(sec) or []:
                if ok_member(m):
                    n = member_short(m["name"]).lower()
                    bare_count[n] = bare_count.get(n, 0) + 1


def do_class(d, cls_kind):
    cname = d["name"]
    lc = cname.lower()
    summ = short(clean(d.get("summary")), 300)
    if summ and cls_kind == "class":
        art = "an" if lc[0] in "aeiou" else "a"
        add("coding.roblox.api", [f"what is {art} {lc} in roblox", f"what does {lc} do in roblox", f"roblox {lc} class"],
            f"{cname} is a Roblox class. {summ}")
    elif summ and cls_kind == "datatype":
        add("coding.roblox.api", [f"what is {'an' if lc[0] in 'aeiou' else 'a'} {lc} in roblox", f"what is the {lc} data type", f"roblox {lc} datatype"],
            f"{cname} is a Roblox data type. {summ}")
    elif summ and cls_kind == "library":
        add("coding.roblox.api", [f"what is the {lc} library in roblox", f"what is {lc} in luau", f"luau {lc} library"],
            f"The {cname} library: {summ}")
    for p in d.get("properties") or []:
        if not ok_member(p):
            continue
        name = member_short(p["name"])
        s = clean(p.get("summary"))
        if not s:
            continue
        typ = p.get("type") or ""
        tw = TYPE_WORDS.get(typ, typ)
        ro = " It is read-only." if "ReadOnly" in (p.get("tags") or []) else ""
        if cls_kind == "class":
            a = f"{cname}.{name} is {type_phrase(typ)} property. {short(s)}{ro}" if tw else f"{short(s)}{ro}"
            qs = [f"what does {lc}.{name.lower()} do", f"{lc} {name.lower()} property",
                  f"what is the {name.lower()} property of a {lc}"]
        else:
            a = f"{p['name']}: {short(s)}{ro}"
            qs = [f"what is {p['name'].lower()}", f"{lc} {name.lower()} in roblox", f"what does {p['name'].lower()} mean"]
        n = name.lower()
        if bare_count.get(n, 0) == 1 and n not in GENERIC and len(n) > 4:
            qs.append(f"what is {n} in roblox")
        add("coding.roblox.api", qs, a)
    for m in d.get("methods") or []:
        if not ok_member(m):
            continue
        name = member_short(m["name"])
        s = clean(m.get("summary"))
        if not s:
            continue
        sep = ":" if ":" in m["name"] else "."
        if cls_kind == "class" and is_service(cname):
            usage = f"game:GetService(\"{cname}\"):{name}({params_sig(m)})"
            if cname == "Workspace":
                usage = f"workspace:{name}({params_sig(m)})"
        elif sep == ".":
            usage = f"{cname}.{name}({params_sig(m)})"
        else:
            usage = f"{var_of(cname)}:{name}({params_sig(m)})"
        y = " It yields, so the script waits until it finishes." if "Yields" in (m.get("tags") or []) else ""
        a = f"{short(s, 260)} Use it like `{usage}`.{returns_text(m)}{y}"
        n = name.lower()
        qs = [f"what does {lc}:{n} do", f"how do i use {n} in roblox", f"{lc} {n} function"]
        if cls_kind != "class":
            qs = [f"what does {lc}:{n} do", f"{lc} {n} method roblox", f"how does {n} work on a {lc}"]
        add("coding.roblox.api", qs, a)
    for e in d.get("events") or []:
        if not ok_member(e):
            continue
        name = member_short(e["name"])
        s = clean(e.get("summary"))
        if not s:
            continue
        ps = params_sig(e)
        if is_service(cname):
            var = "workspace" if cname == "Workspace" else f"game:GetService(\"{cname}\")"
        else:
            var = var_of(cname)
        a = f"{short(s, 260)} Connect it with `{var}.{name}:Connect(function({ps}) end)`."
        n = name.lower()
        qs = [f"what is the {lc}.{n} event", f"when does {lc} {n} fire", f"{lc} {n} event roblox"]
        add("coding.roblox.api", qs, a)
    for f in d.get("functions") or []:
        if not ok_member(f):
            continue
        full = f["name"]
        s = clean(f.get("summary"))
        if not s:
            continue
        n = full.lower()
        a = f"{short(s, 260)} Use it like `{full}({params_sig(f)})`.{returns_text(f)}"
        if cls_kind == "global":
            qs = [f"what does {n} do in roblox", f"what is {n} in luau", f"how does {n} work in lua"]
        else:
            qs = [f"what does {n} do in roblox", f"how do i use {n}", f"{n.replace('.', ' ')} in luau"]
        add("coding.roblox.api", qs, a)
    for c in d.get("constructors") or []:
        if not ok_member(c):
            continue
        s = clean(c.get("summary"))
        if not s:
            continue
        full = c["name"]
        sig = params_sig(c)
        n = full.lower()
        if sig:
            qs = [f"{n} with {sig.lower().replace(',', '')}", f"how do i make a {lc} from {sig.lower().replace(',', '')}"]
        else:
            qs = [f"what does {n}() with no arguments do", f"empty {n} in roblox"]
        a = f"`{full}({sig})`: {short(s, 280)}"
        add("coding.roblox.api", qs, a)


def main():
    docs = []
    for c in CLASSES:
        d = fetch("classes", c, f"{c}.yaml")
        if d:
            docs.append(("class", d))
    for c in DATATYPES:
        d = fetch("datatypes", c, f"dt_{c}.yaml")
        if d:
            docs.append(("datatype", d))
    for c in LIBRARIES:
        d = fetch("libraries", c, f"lib_{c}.yaml")
        if d:
            docs.append(("library", d))
    for c in GLOBALS:
        d = fetch("globals", c, f"g_{c}.yaml")
        if d:
            docs.append(("global", d))
    load_enums()
    w, k = existing(OUT)
    seen_q.update(w)
    seen_keys.update(k)
    collect_names(docs)
    for kind, d in docs:
        do_class(d, kind)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as fh:
        fh.write("# Generated by tools/knowledge/gen/coding_roblox_api.py from the Roblox Creator Documentation\n")
        fh.write("# (github.com/Roblox/creator-docs, CC BY 4.0). Do not edit by hand.\n")
        tag = None
        for t, qs, a in entries:
            if t != tag:
                fh.write(f"# tag: {t}\n")
                tag = t
            fh.write(" | ".join(qs) + " => " + a + "\n")
    print(f"wrote {len(entries)} entries to {OUT}")


if __name__ == "__main__":
    main()
