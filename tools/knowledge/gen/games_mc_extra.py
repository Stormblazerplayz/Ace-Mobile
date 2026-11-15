"""Extra Minecraft Java Edition entries for Ace's knowledge pack.

Writes three files in data/games:
  gen_minecraft_uses.txt      "what can you make with X", from minecraft-data 1.21.8 recipes.json
  gen_minecraft_sizes.txt     mob hitbox sizes and the gap a mob needs, from minecraft-data 1.21.8 entities.json
  gen_minecraft_enchant_items.txt  which enchantments go on which item (hand-written for Java Edition 1.21,
                              max levels from minecraft-data 1.21.8 enchantments.json)
PrismarineJS minecraft-data is MIT licensed. Run from the repo root:
    python3 tools/knowledge/gen/games_mc_extra.py
"""
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from games_common import Writer, fetch, plural  # noqa: E402
from games_mc_mobs import MOBS, PLURALS, art  # noqa: E402

VER = "1.21.8"
BASE = "https://raw.githubusercontent.com/PrismarineJS/minecraft-data/master/data/pc/" + VER + "/"

COLORS = "white orange magenta light_blue yellow lime pink gray light_gray cyan purple blue brown green red black".split()
COLORS.sort(key=len, reverse=True)
WOODS = "oak spruce birch jungle acacia dark_oak mangrove cherry bamboo crimson warped pale_oak".split()
WOODS.sort(key=len, reverse=True)
COPPER = ("exposed_", "weathered_", "oxidized_", "waxed_")
TOOLS = ("pickaxe", "axe", "shovel", "hoe", "sword")
ARMOR = ("helmet", "chestplate", "leggings", "boots")
MAT = {"wooden": "wooden", "stone": "stone", "iron": "iron", "golden": "golden", "diamond": "diamond", "netherite": "netherite"}

# Ingredients that are not worth a "what can you make with" entry (tools used up, or too odd to ask about).
SKIP_ING = {"air", "water_bucket", "lava_bucket", "milk_bucket", "honey_bottle", "potion", "bowl", "glass_bottle",
            "shears", "flint_and_steel", "debug_stick"}
NICE = {"redstone": "redstone dust", "slime_ball": "slimeballs", "ender_eye": "eyes of ender", "tnt": "TNT",
        "lapis_lazuli": "lapis lazuli", "glowstone_dust": "glowstone dust"}


# Result names that read badly when made plural automatically.
RES_NAMES = {"bookshelf": "bookshelves", "writable_book": "books and quills", "bricks": "brick blocks",
             "nether_bricks": "nether brick blocks", "chest_minecart": "minecarts with chests",
             "hopper_minecart": "minecarts with hoppers", "furnace_minecart": "minecarts with furnaces",
             "tnt_minecart": "minecarts with TNT", "beetroot_soup": "beetroot soup", "mushroom_stew": "mushroom stew",
             "rabbit_stew": "rabbit stew", "suspicious_stew": "suspicious stew", "bamboo_chest_raft": "bamboo rafts with chests",
             "jack_o_lantern": "jack o'lanterns", "tnt": "TNT", "glass_pane": "glass panes", "iron_bars": "iron bars",
             "pumpkin_pie": "pumpkin pie", "honey_block": "honey blocks", "slime_block": "slime blocks",
             "ender_eye": "eyes of ender", "fire_charge": "fire charges", "glistering_melon_slice": "glistering melon slices",
             "golden_carrot": "golden carrots", "golden_apple": "golden apples", "flower_pot": "flower pots",
             "leather_horse_armor": "leather horse armor", "wolf_armor": "wolf armor", "dried_kelp_block": "dried kelp blocks",
             "hay_block": "hay bales", "chiseled_bookshelf": "chiseled bookshelves", "spyglass": "spyglasses",
             "compass": "compasses", "recovery_compass": "recovery compasses", "flint_and_steel": "flint and steel",
             "bread": "bread", "crimson_hyphae": "crimson hyphae", "warped_hyphae": "warped hyphae",
             "netherite_upgrade_smithing_template": "copies of the netherite upgrade template", "snow": "snow layers", "snow_block": "snow blocks", "clay": "clay blocks"}


ING_PLURAL = {"compass": "compasses", "glass": "glass", "bamboo": "bamboo"}


def roman(n):
    return ["", "I", "II", "III", "IV", "V"][n]


def num(x):
    return f"{round(x, 2):g}"


def uses(w, items, recipes):
    f = "gen_minecraft_uses.txt"
    by_id = {i["id"]: i for i in items}

    item_names = {i["name"] for i in items}

    def color_of(name):
        """The dye color prefix of a name, only when the item comes in all 16 colors."""
        for c in COLORS:
            if name.startswith(c + "_"):
                rest = name[len(c) + 1:]
                if all(f"{k}_{rest}" in item_names for k in ("white", "black", "lime")):
                    return c
        return None

    def wood_of(name):
        for wd in WOODS:
            if name.startswith(wd + "_"):
                rest = name[len(wd) + 1:]
                if sum(f"{k}_{rest}" in item_names for k in WOODS) >= 3 or wd == "bamboo":
                    return wd
        return None

    def ing_key(name):
        if name.endswith("_planks"):
            return "planks"
        if name.startswith("stripped_") and name.endswith(("_log", "_stem")):
            return "stripped logs"
        if name.endswith(("_log", "_wood", "_stem", "_hyphae")) and not name.startswith("stripped_") and name != "mushroom_stem":
            return "logs"
        if name.endswith("_wool"):
            return "wool"
        if wood_of(name):
            return "wooden slabs" if name.endswith("_slab") else None
        if (color_of(name) and not name.endswith("_dye")) or name.startswith(COPPER) or name in SKIP_ING:
            return None
        if name.startswith("stripped_"):
            return None
        return name

    def res_label(name, keep_color=False):
        """Returns (group, label) for a recipe result."""
        disp = by_name[name]["displayName"].lower()
        if name in RES_NAMES:
            return "item", RES_NAMES[name]
        if name == "air":
            return None, None
        if name.endswith("_banner_pattern"):
            return "item", "banner patterns"
        if name.endswith("_armor_trim_smithing_template"):
            return "item", "copies of the " + name.split("_armor_trim")[0].replace("_", " ") + " armor trim template"
        for t in TOOLS:
            if name.endswith("_" + t) and name.split("_")[0] in MAT:
                return "tools", name.split("_")[0]
        for a in ARMOR:
            if name.endswith("_" + a) and name.split("_")[0] in ("leather", "iron", "golden", "diamond", "chainmail"):
                return "armor", name.split("_")[0]
        if name.startswith(COPPER):
            return None, None
        if name.startswith("stripped_"):
            return "item", "stripped wood blocks"
        c = color_of(name)
        if c and keep_color:
            return "item", disp + ("es" if disp.endswith("harness") else "")
        if c and not name.endswith("_dye"):
            base = disp[len(c.replace("_", " ")) + 1:]
            if base == "harness":
                return "item", "harnesses"
            if base == "wool":
                return "item", "dyed wool"
            return "item", "dyed " + base if base in ("terracotta", "glass", "glass pane", "candle", "shulker box") else base
        wd = wood_of(name)
        if wd:
            base = disp[len(wd.replace("_", " ")) + 1:]
            if base in ("planks",):
                return "item", "wooden planks"
            if base in ("wood", "hyphae"):
                return "item", "wood blocks"
            rest = name[len(wd) + 1:]
            if "raft" in rest or "mosaic" in rest or rest == "block":
                return "item", disp
            if base == "boat with chest":
                return "item", "wooden boats with chests"
            return "item", "wooden " + base
        return "item", disp

    by_name = {i["name"]: i for i in items}
    found = {}
    for rid, variants in recipes.items():
        rname = by_id[int(rid)]["name"]
        for v in variants:
            cells = []
            if "inShape" in v:
                for row in v["inShape"]:
                    cells += row
            else:
                cells = list(v.get("ingredients", []))
            for c in cells:
                if c is None:
                    continue
                cid = c["id"] if isinstance(c, dict) else c
                if cid not in by_id:
                    continue
                key = ing_key(by_id[cid]["name"])
                if key is None or key == rname:
                    continue
                found.setdefault(key, []).append(rname)

    for key, results in sorted(found.items()):
        seen, order = set(), []
        tools, armor = [], []
        for r in results:
            if r in seen:
                continue
            seen.add(r)
            g, label = res_label(r, keep_color=key.endswith("_dye"))
            if g is None:
                continue
            if g == "tools":
                tools.append(label)
            elif g == "armor":
                armor.append(label)
            elif label not in order:
                order.append(label)
        groups = []
        tools, armor = sorted(set(tools)), sorted(set(armor))
        if len(tools) == 1:
            groups.append(f"{tools[0]} tools and swords")
        elif tools:
            groups.append("tools and swords")
        if len(armor) == 1:
            groups.append(f"{armor[0]} armor")
        elif armor:
            groups.append("armor")
        names = groups + [n if (n.endswith("s") or n in RES_NAMES.values() or n.startswith("copies of")) else plural(n)
                          for n in order]
        names = [n.replace(" with chest", "s with chests").replace("boats with", "boats with") if " with chest" in n and not n.endswith("chests") else n
                 for n in names]
        names = [n for n in names if n]
        if len(names) < 2:
            continue
        verb = "are"
        if key == "planks":
            ing, sing = "wooden planks", "planks"
        elif key == "logs":
            ing, sing = "logs", "wood logs"
        elif key == "stripped logs":
            ing, sing = "stripped logs", "stripped wood logs"
        elif key == "wooden slabs":
            ing, sing = "wooden slabs", "wooden slab"
        elif key == "wool":
            ing, sing, verb = "wool", "wool", "is"
        else:
            disp = by_name[key]["displayName"].lower()
            ing = NICE.get(key, ING_PLURAL.get(key, plural(disp)))
            sing = disp
            if key.endswith("_dye"):
                ing = disp
            if ing == disp and plural(disp) == disp or key.endswith("_dye") or ing in ("TNT", "redstone dust", "glowstone dust", "lapis lazuli"):
                verb = "is"
        shown = names[:12]
        more = len(names) - len(shown)
        listing = ", ".join(shown[:-1]) + (", " if more else " and ") + shown[-1] if len(shown) > 1 else shown[0]
        if more:
            listing += f" and {more} more"
        ans = f"In Java Edition {VER}, {ing} {verb} used to craft {listing}."
        qs = [f"what can you make with {ing}", f"what can you craft with {ing}", f"what can i make with {sing}",
              f"what uses {ing} in crafting", f"{sing} crafting uses", f"recipes that use {ing}"]
        w.add(f, "minecraft.crafting", qs, ans)


def sizes(w, ents):
    f = "gen_minecraft_sizes.txt"
    skip = {"slime", "magma_cube", "ender_dragon"}
    for mid, name, _hp, kind, *_ in MOBS:
        if mid in skip or mid not in ents:
            continue
        e = ents[mid]
        wd, ht = e["width"], e["height"]
        a = art(name).lower()
        cap = a[0].upper() + a[1:]
        ln = name.lower()
        pl = PLURALS.get(mid, ln + ("" if ln.endswith(("s", "fish", "salmon", "cod", "sheep")) else "s"))
        cmp = "taller than" if ht > 1.8 else "shorter than" if ht < 1.8 else "the same height as"
        w.add(f, "minecraft.mobs", [f"how tall is {a}", f"how big is {a}", f"{ln} size minecraft", f"how wide is {a}",
                                    f"{ln} hitbox size"],
              f"{cap}'s hitbox is {num(ht)} blocks tall and {num(wd)} blocks wide, so it is {cmp} a player, who is 1.8 blocks tall.")
        if kind != "boss":
            gh, gw = math.ceil(ht), math.ceil(wd)
            w.add(f, "minecraft.mobs", [f"what size gap can {a} fit through", f"how big of a hole does {a} need",
                                        f"what size hole can {pl} go through",
                                        f"{ln} gap size"],
                  f"{cap} needs a gap at least {gh} block{'s' if gh > 1 else ''} tall and {gw} block{'s' if gw > 1 else ''} wide to fit through, because its hitbox is {num(ht)} by {num(wd)} blocks.")
    # The ender dragon's hitbox in minecraft-data is one big box, which is worth a single entry.
    e = ents["ender_dragon"]
    w.add(f, "minecraft.mobs", ["how big is the ender dragon", "how tall is the ender dragon", "ender dragon size",
                                "how long is the ender dragon"],
          f"The ender dragon's main hitbox is {num(e['width'])} blocks wide and {num(e['height'])} blocks tall, which makes it one of the biggest mobs in Java Edition.")


# Java Edition 1.21 enchantments each item can hold (from an enchanting table, anvil or book).
ITEMS = [
    ("sword", "a sword", ["sharpness", "smite", "bane_of_arthropods", "knockback", "fire_aspect", "looting", "sweeping_edge"],
     "Sharpness V, Looting III, Sweeping Edge III, Fire Aspect II, Unbreaking III and Mending"),
    ("axe", "an axe", ["efficiency", "fortune", "silk_touch", "sharpness", "smite", "bane_of_arthropods"],
     "Efficiency V, Sharpness V, Unbreaking III and Mending"),
    ("pickaxe", "a pickaxe", ["efficiency", "fortune", "silk_touch"],
     "Efficiency V, Fortune III or Silk Touch, Unbreaking III and Mending"),
    ("shovel", "a shovel", ["efficiency", "fortune", "silk_touch"],
     "Efficiency V, Silk Touch, Unbreaking III and Mending"),
    ("hoe", "a hoe", ["efficiency", "fortune", "silk_touch"],
     "Efficiency V, Fortune III, Unbreaking III and Mending"),
    ("bow", "a bow", ["power", "punch", "flame", "infinity"],
     "Power V, Infinity or Mending, Unbreaking III, Flame and Punch II"),
    ("crossbow", "a crossbow", ["quick_charge", "multishot", "piercing"],
     "Quick Charge III, Multishot or Piercing IV, Unbreaking III and Mending"),
    ("trident", "a trident", ["loyalty", "riptide", "channeling", "impaling"],
     "Loyalty III or Riptide III, Impaling V, Channeling, Unbreaking III and Mending"),
    ("mace", "a mace", ["density", "breach", "wind_burst", "smite", "bane_of_arthropods", "fire_aspect"],
     "Density V or Breach IV, Wind Burst III, Unbreaking III and Mending"),
    ("helmet", "a helmet", ["protection", "fire_protection", "blast_protection", "projectile_protection", "thorns",
                            "respiration", "aqua_affinity", "binding_curse"],
     "Protection IV, Respiration III, Aqua Affinity, Unbreaking III and Mending"),
    ("chestplate", "a chestplate", ["protection", "fire_protection", "blast_protection", "projectile_protection", "thorns",
                                    "binding_curse"],
     "Protection IV, Unbreaking III and Mending"),
    ("leggings", "leggings", ["protection", "fire_protection", "blast_protection", "projectile_protection", "thorns",
                              "swift_sneak", "binding_curse"],
     "Protection IV, Swift Sneak III, Unbreaking III and Mending"),
    ("boots", "boots", ["protection", "fire_protection", "blast_protection", "projectile_protection", "thorns",
                        "feather_falling", "depth_strider", "frost_walker", "soul_speed", "binding_curse"],
     "Protection IV, Feather Falling IV, Depth Strider III, Soul Speed III, Unbreaking III and Mending"),
    ("fishing rod", "a fishing rod", ["luck_of_the_sea", "lure"],
     "Luck of the Sea III, Lure III, Unbreaking III and Mending"),
    ("shield", "a shield", [], "Unbreaking III and Mending"),
    ("elytra", "an elytra", ["binding_curse"], "Unbreaking III and Mending"),
    ("shears", "shears", ["efficiency"], "Efficiency V, Unbreaking III and Mending"),
    ("flint and steel", "flint and steel", [], "Unbreaking III and Mending"),
    ("brush", "a brush", [], "Unbreaking III and Mending"),
]
COMMON = ["unbreaking", "mending", "vanishing_curse"]
ANVIL_ONLY = {("axe", "sharpness"), ("axe", "smite"), ("axe", "bane_of_arthropods")}
# Combinations people often ask about that do not work in Java Edition 1.21.
NOPE = [
    ("axe", "looting", "Axes can't get Looting in Java Edition. Only swords can."),
    ("axe", "fire_aspect", "Axes can't get Fire Aspect in Java Edition. It goes on swords and maces."),
    ("axe", "knockback", "Knockback only goes on swords."),
    ("axe", "sweeping_edge", "Sweeping Edge only goes on swords."),
    ("bow", "fire_aspect", "Bows use Flame instead, which sets arrows on fire."),
    ("bow", "sharpness", "Bows use Power instead, which adds arrow damage."),
    ("bow", "multishot", "Multishot is only for crossbows."),
    ("crossbow", "power", "Crossbows can't get Power. They use Quick Charge, Multishot and Piercing."),
    ("crossbow", "infinity", "Infinity only goes on bows, so crossbows always use up arrows."),
    ("crossbow", "flame", "Flame only goes on bows. Crossbows can shoot firework rockets instead."),
    ("sword", "flame", "Swords use Fire Aspect instead."),
    ("sword", "fortune", "Swords use Looting instead, which works like Fortune for mob drops."),
    ("sword", "efficiency", "Efficiency goes on tools like pickaxes, axes and shears, not swords."),
    ("sword", "channeling", "Channeling only goes on tridents."),
    ("sword", "density", "Density only goes on maces."),
    ("trident", "sharpness", "Tridents use Impaling instead."),
    ("trident", "looting", "Tridents can't get Looting in Java Edition."),
    ("mace", "sharpness", "Maces use Density or Breach instead, though Smite and Bane of Arthropods work."),
    ("mace", "looting", "Maces can't get Looting."),
    ("elytra", "protection", "Elytra can only get Unbreaking, Mending and the two curses."),
    ("shield", "protection", "Shields can only get Unbreaking, Mending and Curse of Vanishing."),
    ("shield", "thorns", "Shields can only get Unbreaking, Mending and Curse of Vanishing."),
    ("shears", "silk_touch", "Shears can get Efficiency, Unbreaking and Mending, and already pick up things like leaves and cobwebs."),
    ("pickaxe", "looting", "Pickaxes use Fortune instead to get more drops from ores."),
    ("helmet", "feather_falling", "Feather Falling only goes on boots."),
    ("chestplate", "feather_falling", "Feather Falling only goes on boots."),
    ("leggings", "feather_falling", "Feather Falling only goes on boots."),
    ("boots", "swift_sneak", "Swift Sneak only goes on leggings."),
    ("boots", "respiration", "Respiration only goes on helmets."),
    ("leggings", "depth_strider", "Depth Strider only goes on boots."),
    ("chestplate", "respiration", "Respiration only goes on helmets."),
    ("fishing rod", "looting", "Fishing rods use Luck of the Sea instead for better catches."),
    ("hoe", "sharpness", "Hoes can only get Efficiency, Fortune, Silk Touch, Unbreaking, Mending and Curse of Vanishing."),
    ("shovel", "sharpness", "Shovels can only get Efficiency, Fortune, Silk Touch, Unbreaking, Mending and Curse of Vanishing."),
    ("bow", "piercing", "Piercing only goes on crossbows."),
]


def enchant_items(w, ench):
    f = "gen_minecraft_enchant_items.txt"
    for key, a, specific, best in ITEMS:
        allowed = specific + COMMON
        names = [ench[e]["displayName"] for e in allowed]
        pl = key if key.endswith("s") or key in ("flint and steel", "elytra") else plural(key)
        w.add(f, "minecraft.enchantments", [f"what enchantments can go on {a}", f"what enchantments can you put on {a}",
                                            f"best {key} enchantments", f"{key} enchantments", f"what to enchant {pl} with"],
              f"In Java Edition, {a} can get {', '.join(names[:-1])} and {names[-1]}. A strong setup is {best}.")
        for e in allowed:
            if e.endswith("_curse"):
                continue
            d = ench[e]
            lvl = d["maxLevel"]
            ex = [ench[x]["displayName"] for x in d.get("exclude", []) if x in allowed]
            ans = f"Yes, {d['displayName']} can go on {a}" + (f", up to level {roman(lvl)}" if lvl > 1 else "")
            if (key, e) in ANVIL_ONLY:
                ans += ", using an anvil and an enchanted book"
            ans += "."
            if ex:
                ans += f" It can't be combined with {' or '.join(ex)}."
            dn = d["displayName"].lower()
            w.add(f, "minecraft.enchantments", [f"can you put {dn} on {a}", f"can {a} have {dn}", f"{dn} on {a}",
                                                f"does {dn} work on {pl}"], ans)
    by_key = {k: a for k, a, *_ in ITEMS}
    for key, e, why in NOPE:
        a = by_key[key]
        dn = ench[e]["displayName"].lower()
        pl = key if key.endswith("s") or key == "elytra" else plural(key)
        w.add(f, "minecraft.enchantments", [f"can you put {dn} on {a}", f"can {a} have {dn}", f"{dn} on {a}",
                                            f"does {dn} work on {pl}"], f"No. {why}")


def main():
    items = json.load(open(fetch(BASE + "items.json", "mcdata/items.json")))
    recipes = json.load(open(fetch(BASE + "recipes.json", "mcdata/recipes.json")))
    ents = {e["name"]: e for e in json.load(open(fetch(BASE + "entities.json", "mcdata/entities.json")))}
    ench = {e["name"]: e for e in json.load(open(fetch(BASE + "enchantments.json", "mcdata/enchantments.json")))}
    w = Writer(["gen_minecraft_uses.txt", "gen_minecraft_sizes.txt", "gen_minecraft_enchant_items.txt"])
    enchant_items(w, ench)
    sizes(w, ents)
    uses(w, items, recipes)
    w.write(["Minecraft Java Edition extras, generated by tools/knowledge/gen/games_mc_extra.py",
             "Source: PrismarineJS minecraft-data (MIT) 1.21.8: recipes.json, entities.json, enchantments.json."])


if __name__ == "__main__":
    main()
