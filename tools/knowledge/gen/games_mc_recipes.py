"""Minecraft Java Edition crafting recipes for Ace's knowledge pack.

Data: PrismarineJS minecraft-data (MIT license), https://github.com/PrismarineJS/minecraft-data
Files: data/pc/1.21.8/recipes.json and items.json (Java Edition 1.21.8).
Writes data/games/gen_minecraft_recipes.txt. Run from the repo root:
    python3 tools/knowledge/gen/games_mc_recipes.py
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from games_common import Writer, count_of, fetch, plural  # noqa: E402

VER = "1.21.8"
BASE = "https://raw.githubusercontent.com/PrismarineJS/minecraft-data/master/data/pc/" + VER + "/"

COLORS = "white orange magenta light_blue yellow lime pink gray light_gray cyan purple blue brown green red black".split()
WOODS = "oak spruce birch jungle acacia dark_oak mangrove cherry bamboo crimson warped pale_oak".split()

# Recipes the older bank already answers (qa_bank.json), so they are skipped here.
IN_BANK = {"crafting_table", "torch", "furnace", "pickaxe", "sword", "bucket", "ender_eye", "cake", "piston", "tnt",
           "enchanting_table", "map", "shield", "bow", "arrow", "fishing_rod", "chest", "bread", "compass", "clock",
           "beacon", "brewing_stand", "lead", "cookie", "anvil", "boat", "bed", "glass"}

# Hand-picked friendlier names for some items.
NICE = {"ender_eye": "eye of ender", "redstone": "redstone dust", "slime_ball": "slimeball", "stick": "stick",
        "lapis_lazuli": "lapis lazuli", "glowstone_dust": "glowstone dust", "tnt": "TNT", "tnt_minecart": "minecart with TNT",
        "jack_o_lantern": "jack o'lantern", "music_disc_5": "music disc 5", "honeycomb": "honeycomb",
        "cobblestone": "cobblestone", "glistering_melon_slice": "glistering melon slice", "wheat": "wheat"}

EXTRA_Q = {
    "stick": ["how do you get sticks", "how to make sticks in minecraft"],
    "ladder": ["how to make a ladder in minecraft"],
    "rail": ["how do you make minecart tracks", "how to make rails"],
    "powered_rail": ["how do you make booster rails", "how to make rails that speed up minecarts"],
    "ender_chest": ["how to get an ender chest"],
    "netherite_ingot": ["how do you make netherite ingots", "how many netherite scraps for an ingot"],
    "golden_apple": ["how to make a gapple"],
    "firework_rocket": ["how do you make fireworks", "how to make rockets for elytra"],
    "hopper": ["how to make a hopper"],
    "observer": ["how to make an observer block"],
    "shulker_box": ["how to make a shulker box", "how do you get a shulker box"],
    "respawn_anchor": ["how to make a respawn anchor"],
    "conduit": ["how do you make a conduit"],
    "crafter": ["how to make the crafter"],
    "mace": ["how do you get a mace", "how to make the mace"],
    "wind_charge": ["how to make wind charges"],
    "spyglass": ["how to make a telescope in minecraft"],
    "lodestone": ["how to make a lodestone"],
    "end_crystal": ["how to make end crystals", "how to respawn the ender dragon crystals"],
    "saddle": ["can you craft a saddle"],
    "bundle": ["how to make a bundle"],
    "wolf_armor": ["how to make armor for a dog", "how do you get wolf armor"],
    "scaffolding": ["how to make scaffolding"],
    "target": ["how to make a target block"],
    "smithing_table": ["how to make a smithing table"],
    "jukebox": ["how to make a jukebox"],
    "note_block": ["how to make a note block"],
    "redstone_torch": ["how to make a redstone torch"],
    "repeater": ["how to make a redstone repeater"],
    "comparator": ["how to make a redstone comparator"],
    "daylight_detector": ["how to make a daylight sensor"],
    "dispenser": ["how to make a dispenser"],
    "dropper": ["how to make a dropper"],
    "sticky_piston": ["how to make a sticky piston"],
    "lectern": ["how to make a lectern"],
    "item_frame": ["how to make an item frame"],
    "painting": ["how to make a painting"],
    "armor_stand": ["how to make an armor stand"],
    "bookshelf": ["how to make bookshelves"],
    "book": ["how to make a book"],
    "paper": ["how to make paper"],
    "writable_book": ["how do you make a book and quill", "how to make a book you can write in"],
}

GROUP_NAMES = [
    (lambda ns: all(n.endswith("_planks") for n in ns), "wooden planks"),
    (lambda ns: all(n.endswith(("_log", "_wood", "_stem", "_hyphae")) for n in ns), "logs"),
    (lambda ns: all(n.endswith("_wool") for n in ns), "wool"),
    (lambda ns: all(n.endswith("_slab") and any(n.startswith(w) for w in WOODS) for n in ns), "wooden slabs"),
    (lambda ns: set(ns) <= {"cobblestone", "blackstone", "cobbled_deepslate"}, "cobblestone (or blackstone or cobbled deepslate)"),
    (lambda ns: set(ns) <= {"coal", "charcoal"}, "coal or charcoal"),
    (lambda ns: set(ns) <= {"stone_slab", "smooth_stone_slab"} or all(n.endswith("_slab") for n in ns), "slabs"),
    (lambda ns: all(n.endswith("_carpet") for n in ns), "carpet"),
    (lambda ns: all(n.endswith("_terracotta") for n in ns), "terracotta"),
    (lambda ns: all(n.endswith("_sand") or n == "sand" for n in ns), "sand"),
]


def main():
    items = {i["id"]: i for i in json.load(open(fetch(BASE + "items.json", "mcdata/items.json")))}
    recipes = json.load(open(fetch(BASE + "recipes.json", "mcdata/recipes.json")))
    by_name = {i["name"]: i for i in items.values()}

    def iname(i):
        n = items[i]["name"]
        return NICE.get(n, items[i]["displayName"].lower())

    def group(ids):
        ids = [i for i in ids]
        uniq = sorted(set(ids), key=ids.index)
        if len(uniq) == 1:
            return iname(uniq[0])
        names = [items[i]["name"] for i in uniq]
        for test, label in GROUP_NAMES:
            if test(names):
                return label
        return " or ".join(iname(i) for i in uniq[:3])

    def merge(variants):
        """Merges tag variants (like every plank type) into one recipe with group names."""
        shaped = [v for v in variants if "inShape" in v]
        if shaped:
            first = shaped[0]["inShape"]
            same = [v["inShape"] for v in shaped if len(v["inShape"]) == len(first)
                    and all(len(r) == len(f) for r, f in zip(v["inShape"], first))]
            grid = []
            for y, row in enumerate(first):
                out = []
                for x, cell in enumerate(row):
                    cells = [s[y][x] for s in same]
                    if any(c is None for c in cells):
                        out.append(None if all(c is None for c in cells) else group([c for c in cells if c is not None]))
                    else:
                        out.append(group(cells))
                grid.append(out)
            return "shaped", grid, shaped[0]["result"]["count"]
        first = variants[0]["ingredients"]
        same = [v["ingredients"] for v in variants if len(v["ingredients"]) == len(first)]
        ing = [group([s[k] for s in same]) for k in range(len(first))]
        return "shapeless", ing, variants[0]["result"]["count"]

    def describe(kind, data):
        if kind == "shapeless":
            counts = {}
            for n in data:
                counts[n] = counts.get(n, 0) + 1
            parts = [count_of(c, n) for n, c in counts.items()]
            if len(parts) == 1 and len(data) == 9:
                return f"Fill all 9 slots of a crafting table with {plural(data[0])}."
            if len(parts) == 1:
                return f"Put {parts[0]} anywhere in the crafting grid."
            return "Put " + ", ".join(parts[:-1]) + " and " + parts[-1] + " anywhere in the crafting grid."
        grid = data
        h, w = len(grid), len(grid[0])
        cells = [c for r in grid for c in r if c]
        kinds = sorted(set(cells), key=cells.index)
        if len(kinds) == 1 and len(cells) == h * w:
            k = kinds[0]
            if h == w == 3:
                return f"Fill all 9 slots of a crafting table with {plural(k)}."
            if h == w == 2:
                return f"Put 4 {plural(k)} in a 2 by 2 square."
            if h == 1:
                return f"Put {w} {plural(k)} side by side in a row."
            if w == 1:
                return f"Put {h} {plural(k)} stacked in one column."
        if h == 3 and w == 3 and grid[1][1] and all(grid[y][x] == grid[0][0] for y in range(3) for x in range(3)
                                                   if (y, x) != (1, 1)) and grid[0][0]:
            return f"Put {count_of(1, grid[1][1])} in the middle and surround it with 8 {plural(grid[0][0])}."
        if h == 3 and w == 3 and not grid[1][1] and all(grid[y][x] == grid[0][0] for y in range(3) for x in range(3)
                                                       if (y, x) != (1, 1)) and grid[0][0]:
            return f"Fill every slot of a crafting table with {plural(grid[0][0])} except the middle one (8 in all)."
        if h == 3 and w == 3 and grid[1][1] and not any(grid[y][x] for y, x in ((0, 0), (0, 2), (2, 0), (2, 2))) \
                and len({grid[0][1], grid[1][0], grid[1][2], grid[2][1]}) == 1 and grid[0][1]:
            return (f"Put {count_of(1, grid[1][1])} in the middle and 4 {plural(grid[0][1])} above, below, left "
                    f"and right of it, in a plus shape.")
        if w == 1:
            col = [r[0] for r in grid]
            if len(col) == 2:
                return f"Put {count_of(1, col[0])} on top of {count_of(1, col[1])}."
            return "Stack them in one column, top to bottom: " + ", ".join(c or "empty" for c in col) + "."
        labels = {3: ["Top", "Middle", "Bottom"], 2: ["Top", "Bottom"], 1: ["One"]}[h]
        parts = []
        for label, row in zip(labels, grid):
            if all(c is None for c in row):
                parts.append(f"{label} row: empty.")
            elif all(c == row[0] for c in row) and w > 1:
                parts.append(f"{label} row: {w} {plural(row[0])}.")
            else:
                parts.append(f"{label} row: " + ", ".join(c or "empty" for c in row) + ".")
        text = " ".join(parts)
        if h < 3 and w == 3:
            text += " Any two rows next to each other work."
        elif h < 3 and w < 3:
            text += " It fits in your 2 by 2 inventory grid."
        return text

    def result_text(name, count):
        disp = iname(by_name[name]["id"])
        return f" It makes {count_of(count, disp)}." if count > 1 else ""

    def skip(n):
        if n in ("air",) or n in IN_BANK:
            return True
        if any(n.startswith(c + "_") for c in COLORS):
            return True
        if "copper" in n and n not in ("lightning_rod",):
            return True
        if n.startswith(("waxed_", "exposed_", "weathered_", "oxidized_")):
            return True
        if n.endswith(("_stairs", "_slab", "_wall", "_button", "_pressure_plate")) and n not in (
                "stone_pressure_plate", "light_weighted_pressure_plate", "heavy_weighted_pressure_plate", "stone_button"):
            return True
        if any(n.startswith(w + "_") for w in WOODS) or n.startswith("stripped_"):
            return True
        if n.endswith(("_pickaxe", "_sword")) or n in ("pickaxe", "sword"):
            return True
        return False

    w = Writer(["gen_minecraft_recipes.txt"])
    tag = "minecraft.crafting"
    ordered = sorted(recipes.items(), key=lambda kv: items[int(kv[0])]["name"])

    def qs_for(disp, name):
        a = ("an " if disp[0] in "aeiou" else "a ")
        single = disp if disp.endswith("s") or plural(disp) == disp else a + disp
        out = [f"how do you craft {single} in minecraft", f"how to make {disp} in minecraft",
               f"{disp} recipe", f"how do i make {single}"]
        return EXTRA_Q.get(name, []) + out

    # Armor sets and tool sets get one entry per piece.
    for rid, variants in ordered:
        name = items[int(rid)]["name"]
        if skip(name):
            continue
        if name.endswith(("_dye", "_smithing_template")):
            continue
        kind, data, count = merge(variants)
        disp = iname(int(rid))
        ans = describe(kind, data) + result_text(name, count)
        grp = "cobblestone (or blackstone or cobbled deepslate)"
        if grp in ans:
            ans = ans.replace(grp, "cobblestone") + " Blackstone or cobbled deepslate work instead of cobblestone too."
        if name == "stick":
            ans = "Put 2 wooden planks on top of each other in the crafting grid. It makes 4 sticks. You can also stack 2 bamboo to make 1 stick."
        if name == "saddle":
            ans = "Yes, in Java Edition 1.21.6 and newer. " + ans
        mat = data[0][0] if kind == "shaped" and data[0][0] else None
        if mat and name.endswith("_helmet") and name != "turtle_helmet":
            ans = f"Put 5 {plural(mat)} in an upside-down U: 3 across the top row, then 1 on each side of the middle row."
        elif mat and name.endswith("_chestplate"):
            ans = f"Put 8 {plural(mat)} in a vest shape: fill the crafting grid except the top middle slot."
        elif mat and name.endswith("_leggings"):
            ans = f"Put 7 {plural(mat)} in an upside-down U: 3 across the top row, then 1 on each side of the middle and bottom rows."
        elif mat and name.endswith("_boots"):
            ans = f"Put 4 {plural(mat)} in two columns of 2, one on the left side and one on the right side, with the middle empty."
        w.add("gen_minecraft_recipes.txt", tag, qs_for(disp, name), f"In Java Edition: {ans}" if False else ans)

    # Dyes: list every source the data has.
    for rid, variants in ordered:
        name = items[int(rid)]["name"]
        if not name.endswith("_dye"):
            continue
        disp = iname(int(rid))
        srcs = []
        for v in variants:
            if "ingredients" in v:
                ing = [iname(i) for i in v["ingredients"]]
                if len(ing) == 1:
                    srcs.append(ing[0])
                else:
                    srcs.append(" plus ".join(sorted(set(ing), key=ing.index)))
            else:
                cells = [iname(c) for r in v["inShape"] for c in r if c]
                srcs.append(" plus ".join(sorted(set(cells), key=cells.index)))
        srcs = list(dict.fromkeys(srcs))
        if len(srcs) == 1:
            body = f"Put {srcs[0]} in the crafting grid."
        else:
            body = "Craft it from any of these: " + ", ".join(srcs[:-1]) + " or " + srcs[-1] + "."
        if name == "green_dye":
            body = "Smelt a cactus in a furnace to get green dye."
        elif name == "lime_dye":
            body += " You can also smelt a sea pickle in a furnace."
        w.add("gen_minecraft_recipes.txt", tag, [f"how do you make {disp} in minecraft", f"how to get {disp}",
                                                 f"{disp} recipe minecraft", f"where do you get {disp}"], body)

    # Armor trim templates: duplicating them.
    for rid, variants in ordered:
        name = items[int(rid)]["name"]
        if name == "netherite_upgrade_smithing_template":
            w.add("gen_minecraft_recipes.txt", tag, ["how do you duplicate the netherite upgrade template",
                  "how to copy netherite upgrade smithing template", "netherite template duplication recipe",
                  "how to get more netherite upgrade templates"],
                  "Put the netherite upgrade template in the top middle slot, netherrack in the center, and fill the "
                  "other 7 slots with diamonds. That gives you 2 templates.")
            continue
        if not name.endswith("armor_trim_smithing_template"):
            continue
        kind, data, count = merge(variants)
        raw = [v for v in variants if "inShape" in v][0]["inShape"]
        base = [iname(c) for r in raw for c in r if c and items[c]["name"] not in ("diamond", name)]
        trim = name.replace("_armor_trim_smithing_template", "").replace("_", " ")
        ans = (f"Put the {trim} armor trim template in the top middle slot, {base[0]} in the center, and fill the "
               f"other 7 slots with diamonds. That gives you 2 templates.")
        w.add("gen_minecraft_recipes.txt", tag, [f"how do you duplicate the {trim} armor trim",
                                                 f"how to copy {trim} trim template", f"{trim} trim duplication recipe"], ans)

    # One general entry for each wood item, using the oak recipe.
    wood_items = {"door": "door", "trapdoor": "trapdoor", "fence": "fence", "fence_gate": "fence gate",
                  "sign": "sign", "hanging_sign": "hanging sign", "stairs": "wooden stairs", "slab": "wooden slab",
                  "button": "wooden button", "pressure_plate": "wooden pressure plate", "planks": "wooden planks",
                  "chest_boat": "boat with a chest", "wood": "wood block with bark on all sides"}
    for suffix, disp in wood_items.items():
        key = f"oak_{suffix}"
        rid = by_name[key]["id"]
        if str(rid) not in recipes:
            continue
        kind, data, count = merge(recipes[str(rid)])
        ans = describe(kind, data).replace("oak planks", "planks").replace("oak logs", "logs").replace(
            "oak log", "log").replace("oak slab", "wooden slab").replace("oak ", "")
        ans += result_text(key, count).replace("oak ", "").replace("3 woods", "3 wood blocks")
        ans += " Any one wood type works, like oak, spruce, birch or cherry."
        qs = [f"how do you make a {disp}" if suffix not in ("planks", "stairs") else f"how do you make {disp}",
              f"how to craft {disp} in minecraft", f"oak {suffix.replace('_', ' ')} recipe",
              f"{disp} crafting recipe", f"spruce {suffix.replace('_', ' ')} recipe"]
        w.add("gen_minecraft_recipes.txt", tag, qs, ans)

    # Colored blocks: one general entry each.
    colored = {"carpet": ("carpet", "white_carpet"), "stained_glass": ("stained glass", "white_stained_glass"),
               "stained_glass_pane": ("stained glass panes", "white_stained_glass_pane"),
               "concrete_powder": ("concrete powder", "white_concrete_powder"),
               "banner": ("a banner", "white_banner"), "candle": ("a colored candle", "white_candle"),
               "terracotta": ("colored terracotta", "white_terracotta")}
    for suffix, (disp, key) in colored.items():
        rid = by_name[key]["id"]
        if str(rid) not in recipes:
            continue
        kind, data, count = merge(recipes[str(rid)])
        ans = describe(kind, data).replace("white ", "") + result_text(key, count).replace("white ", "")
        ans += " Swap the white dye or wool for any color you want."
        bare = disp.replace("a ", "", 1) if disp.startswith("a ") else disp
        w.add("gen_minecraft_recipes.txt", tag, [f"how do you make {disp} in minecraft", f"{bare} recipe",
                                                 f"how to craft {bare}", f"how to make white {bare.replace('colored ', '')}"], ans)

    w.write(["Minecraft Java Edition crafting recipes, generated by tools/knowledge/gen/games_mc_recipes.py",
             f"Source: PrismarineJS minecraft-data (MIT), Java Edition {VER} recipes.json and items.json."])


if __name__ == "__main__":
    main()
