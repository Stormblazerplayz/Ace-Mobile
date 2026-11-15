"""Minecraft Java Edition blocks, items, food, enchantments, effects and biomes for Ace's knowledge pack.

Data: PrismarineJS minecraft-data (MIT license), https://github.com/PrismarineJS/minecraft-data
Files: data/pc/1.21.8/{blocks,items,foods,enchantments,effects,biomes}.json and data/pc/1.20/blockLoot.json.
Numbers (hardness, harvest tools, light, stack size, durability, hunger, saturation, max enchantment level,
temperature, rain) come from the data. The short descriptions of what enchantments, effects and biomes do
are hand-written.
Writes data/games/gen_minecraft_blocks.txt, gen_minecraft_items.txt, gen_minecraft_food.txt,
gen_minecraft_enchantments.txt, gen_minecraft_effects.txt and gen_minecraft_biomes.txt.
Run from the repo root:  python3 tools/knowledge/gen/games_mc_data.py
"""
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from games_common import Writer, fetch, plural  # noqa: E402

VER = "1.21.8"
BASE = "https://raw.githubusercontent.com/PrismarineJS/minecraft-data/master/data/pc/"

COLORS = "white orange magenta light_blue yellow lime pink gray light_gray cyan purple blue brown green red black".split()
WOODS = "oak spruce birch jungle acacia dark_oak mangrove cherry bamboo crimson warped pale_oak".split()
TIERS = ["wooden", "golden", "stone", "iron", "diamond", "netherite"]
SPEED = {"wooden": 2, "stone": 4, "iron": 6, "diamond": 8, "netherite": 9, "golden": 12}

# Which blocks get a mining entry: skip variants and technical blocks.
SKIP_BLOCK_WORDS = ("_stairs", "_slab", "_wall", "_fence", "_fence_gate", "_button", "_pressure_plate", "potted_",
                    "wall_", "_wall_", "infested_", "candle_cake", "_door", "_trapdoor", "_sign", "_carpet", "_banner",
                    "_bed", "_glazed_terracotta", "_concrete_powder", "_shulker_box", "_stem", "attached_",
                    "_coral_fan", "_head", "_skull", "_bud", "_cauldron", "_portal", "_air", "_gateway", "_cake")
SKIP_BLOCKS = {"air", "water", "lava", "fire", "soul_fire", "moving_piston", "piston_head", "light", "structure_void",
               "jigsaw", "structure_block", "command_block", "chain_command_block", "repeating_command_block",
               "bubble_column", "tripwire", "redstone_wire", "frosted_ice", "end_portal", "nether_portal", "barrier",
               "test_block", "test_instance_block", "beetroots", "carrots", "potatoes", "wheat", "cocoa", "kelp_plant",
               "cave_vines_plant", "twisting_vines_plant", "weeping_vines_plant", "big_dripleaf_stem", "tall_seagrass",
               "pitcher_crop", "torchflower_crop", "sweet_berry_bush", "powder_snow", "petrified_oak_slab", "void_air",
               "cave_air", "melon_stem", "pumpkin_stem", "trial_spawner_x", "dead_bush", "short_grass", "fern",
               "large_fern", "tall_grass", "seagrass", "kelp", "vine", "glow_lichen", "lily_pad", "small_dripleaf"}
COUNTABLE_FOOD = {"apple", "golden_apple", "enchanted_golden_apple", "cookie", "carrot", "potato", "baked_potato",
                  "poisonous_potato", "golden_carrot", "pumpkin_pie", "melon_slice", "honey_bottle", "beetroot",
                  "chorus_fruit", "pufferfish", "tropical_fish", "spider_eye"}
TIME_BLOCKS = {"obsidian", "crying_obsidian", "ancient_debris", "netherite_block", "diamond_ore", "deepslate_diamond_ore",
               "iron_ore", "deepslate", "stone", "cobblestone", "end_stone", "ender_chest", "respawn_anchor",
               "diamond_block", "iron_block", "emerald_ore", "gold_ore", "netherrack", "anvil", "enchanting_table"}
KEEP_WOOD = {"oak_log", "oak_planks", "oak_leaves", "crimson_stem", "warped_stem", "bamboo_block"}


def wanted(name):
    if name in SKIP_BLOCKS:
        return False
    if name in KEEP_WOOD:
        return True
    if any(name.startswith(c + "_") for c in COLORS) and name not in ("white_wool",):
        return False
    if any(name.startswith(w + "_") for w in WOODS) or name.startswith("stripped_"):
        return False
    if name.startswith(("waxed_", "exposed_", "weathered_", "oxidized_")):
        return False
    if "copper" in name and name not in ("copper_ore", "deepslate_copper_ore", "copper_block", "raw_copper_block"):
        return False
    if any(s in name for s in SKIP_BLOCK_WORDS):
        return False
    return True


def tier_of(tool):
    for t in TIERS:
        if tool.startswith(t):
            return t
    return None


def break_time(hardness, speed, can_harvest):
    if hardness <= 0:
        return 0
    dmg = speed / hardness / (30 if can_harvest else 100)
    if dmg >= 1:
        return 0
    return math.ceil(1 / dmg) / 20


def secs(t):
    if t == 0:
        return "instantly"
    s = f"{t:.2f}".rstrip("0").rstrip(".")
    return f"{s} second" + ("" if s == "1" else "s")


ENCH = {
    "aqua_affinity": ("lets you mine at normal speed underwater instead of 5 times slower", "helmets"),
    "bane_of_arthropods": ("does extra damage to spiders, cave spiders, bees, silverfish and endermites, and slows them down", "swords, axes and maces"),
    "binding_curse": ("is a curse that stops you from taking the armor off until it breaks or you die", "armor and other wearable items"),
    "blast_protection": ("lowers damage and knockback from explosions", "armor"),
    "breach": ("makes the mace ignore part of the target's armor", "maces"),
    "channeling": ("calls down lightning on a mob you hit with a thrown trident during a thunderstorm", "tridents"),
    "density": ("makes the mace's smash attack do more damage for every block you fall", "maces"),
    "depth_strider": ("makes you move faster underwater", "boots"),
    "efficiency": ("makes you mine faster", "pickaxes, shovels, axes, hoes and shears"),
    "feather_falling": ("lowers fall damage and ender pearl damage", "boots"),
    "fire_aspect": ("sets the mob you hit on fire", "swords and maces"),
    "fire_protection": ("lowers fire and lava damage and makes you burn for less time", "armor"),
    "flame": ("makes your arrows set targets on fire", "bows"),
    "fortune": ("gives more drops from ores and some other blocks, like more diamonds from diamond ore", "pickaxes, shovels, axes and hoes"),
    "frost_walker": ("freezes water under you into ice as you walk and stops damage from magma blocks", "boots"),
    "impaling": ("does extra damage to water mobs like guardians, squid and drowned (in Java Edition)", "tridents"),
    "infinity": ("lets your bow shoot forever while you have at least 1 arrow", "bows"),
    "knockback": ("knocks mobs farther back when you hit them", "swords"),
    "looting": ("makes mobs drop more loot and rare drops more often", "swords"),
    "loyalty": ("makes a thrown trident fly back to you", "tridents"),
    "luck_of_the_sea": ("gives you a better chance of catching treasure when fishing", "fishing rods"),
    "lure": ("makes fish bite faster", "fishing rods"),
    "mending": ("repairs the item with experience orbs you pick up", "anything with durability"),
    "multishot": ("shoots 3 arrows at once for the cost of 1", "crossbows"),
    "piercing": ("lets arrows go through several mobs and shields", "crossbows"),
    "power": ("makes arrows do more damage", "bows"),
    "projectile_protection": ("lowers damage from arrows, tridents and other projectiles", "armor"),
    "protection": ("lowers most kinds of damage", "armor"),
    "punch": ("knocks mobs farther back with arrows", "bows"),
    "quick_charge": ("makes the crossbow load faster", "crossbows"),
    "respiration": ("lets you breathe longer underwater", "helmets"),
    "riptide": ("launches you forward when you throw the trident in water or rain", "tridents"),
    "sharpness": ("adds extra damage to every mob you hit", "swords and axes"),
    "silk_touch": ("makes blocks drop themselves, like glass, ore blocks and grass blocks", "pickaxes, shovels, axes, hoes and shears"),
    "smite": ("does extra damage to undead mobs like zombies, skeletons and the Wither", "swords, axes and maces"),
    "soul_speed": ("makes you walk faster on soul sand and soul soil", "boots"),
    "sweeping_edge": ("makes the sweep attack hit nearby mobs harder (Java Edition only)", "swords"),
    "swift_sneak": ("lets you walk faster while sneaking", "leggings"),
    "thorns": ("hurts mobs that attack you, but uses up the armor faster", "armor"),
    "unbreaking": ("makes the item lose durability less often so it lasts longer", "anything with durability"),
    "vanishing_curse": ("is a curse that makes the item disappear when you die", "almost any item that can be enchanted"),
    "wind_burst": ("launches you back up into the air after a smash attack", "maces"),
}
TREASURE_HOW = {
    "mending": "Get it from librarian villagers, fishing, raids or loot chests, not the enchanting table.",
    "frost_walker": "It can't come from the enchanting table. Find it in loot chests, fishing or librarian trades.",
    "soul_speed": "You only get it by bartering with piglins or from bastion remnant chests.",
    "swift_sneak": "You only find it in ancient city chests in the Deep Dark.",
    "wind_burst": "You only find it in ominous vaults in trial chambers.",
    "binding_curse": "It shows up on loot from chests, fishing and trades, never the enchanting table.",
    "vanishing_curse": "It shows up on loot from chests, fishing and trades, never the enchanting table.",
}

EFFECTS = {
    "Speed": "makes you walk 20 percent faster per level",
    "Slowness": "makes you walk slower, 15 percent per level",
    "Haste": "makes you mine and attack faster",
    "MiningFatigue": "makes you mine much slower. Elder guardians give it to you in ocean monuments",
    "Strength": "adds 3 attack damage per level",
    "InstantHealth": "heals 4 health (2 hearts) per level right away, but hurts undead mobs",
    "InstantDamage": "does 6 damage (3 hearts) per level right away, but heals undead mobs",
    "JumpBoost": "makes you jump higher and take less fall damage",
    "Nausea": "makes your screen wobble and warp",
    "Regeneration": "heals you over time",
    "Resistance": "lowers the damage you take by 20 percent per level",
    "FireResistance": "makes you immune to fire and lava damage",
    "WaterBreathing": "lets you breathe underwater",
    "Invisibility": "makes you invisible, but mobs can still see any armor you wear",
    "Blindness": "makes everything dark and stops you from sprinting",
    "NightVision": "lets you see in the dark and underwater like it's daytime",
    "Hunger": "makes your hunger bar drain faster. Rotten flesh can give it",
    "Weakness": "makes your melee attacks do 4 less damage per level",
    "Poison": "hurts you over time but can't kill you, it stops at half a heart",
    "Wither": "hurts you over time, turns your hearts black and can kill you",
    "HealthBoost": "gives you 2 extra hearts of max health per level",
    "Absorption": "gives you extra yellow hearts that soak up damage. Golden apples give it",
    "Saturation": "fills your hunger and saturation bars",
    "Glowing": "puts an outline around you that others can see through walls. Spectral arrows cause it",
    "Levitation": "makes you float upward. Shulker bullets cause it",
    "Luck": "makes better loot more likely, like when fishing",
    "BadLuck": "makes good loot less likely",
    "SlowFalling": "makes you fall slowly with no fall damage",
    "ConduitPower": "lets you breathe, see and mine faster underwater near an active conduit",
    "DolphinsGrace": "makes you swim much faster. You get it by swimming near dolphins",
    "BadOmen": "turns into Raid Omen in a village (starting a raid) or Trial Omen in a trial chamber. In Java 1.21 you get it from an ominous bottle",
    "HeroOfTheVillage": "gives you discounts from villagers after you win a raid",
    "Darkness": "makes your screen pulse dark. The Warden and sculk shriekers give it",
    "TrialOmen": "turns trial spawners and vaults ominous, with harder mobs and better loot",
    "RaidOmen": "starts a raid when it runs out",
    "WindCharged": "makes you let out a burst of wind when you die. It comes from a potion of Wind Charging",
    "Weaving": "spreads cobwebs around you when you die. It comes from a potion of Weaving",
    "Oozing": "makes 2 slimes pop out when you die. It comes from a potion of Oozing",
    "Infested": "gives a chance of silverfish coming out when you get hurt. It comes from a potion of Infestation",
}

BIOMES = {
    "badlands": "red sand, layers of colored terracotta and extra gold ore, plus mineshafts above ground",
    "bamboo_jungle": "lots of bamboo, pandas, parrots and ocelots",
    "basalt_deltas": "basalt and blackstone pillars, lava and lots of magma cubes",
    "beach": "sand next to the ocean, with turtles in warm areas and buried treasure",
    "birch_forest": "lots of birch trees and sometimes bee nests",
    "cherry_grove": "pink cherry trees and pink petals on the ground, with bees, pigs and rabbits",
    "crimson_forest": "red huge fungi, crimson nylium, hoglins and piglins",
    "dark_forest": "thick dark oak trees, big mushrooms and woodland mansions",
    "deep_dark": "sculk blocks, sculk shriekers, the Warden and ancient cities, deep underground",
    "desert": "sand, cactus, dead bushes, husks, rabbits, desert temples, desert wells and villages",
    "dripstone_caves": "pointed dripstone stalactites and stalagmites and lots of copper ore",
    "end_highlands": "the big outer End islands with chorus plants and End cities",
    "flower_forest": "tons of different flowers, bees and rabbits",
    "forest": "oak and birch trees, wolves and flowers",
    "frozen_peaks": "icy mountaintops with packed ice, snow and goats",
    "grove": "snowy spruce forests on mountain sides, with foxes, wolves and rabbits",
    "ice_spikes": "giant spikes of packed ice on snow, with polar bears and strays",
    "jagged_peaks": "very tall, sharp snowy mountain peaks with goats and emerald ore",
    "jungle": "huge jungle trees, vines, melons, cocoa, parrots, ocelots and jungle temples",
    "lush_caves": "moss, azaleas, glow berries, dripleaf, clay pools and axolotls",
    "mangrove_swamp": "mangrove trees with roots in the water, mud, frogs and slimes",
    "meadow": "grassy flower fields next to mountains, with bees, donkeys and rabbits",
    "mushroom_fields": "mycelium, giant mushrooms and mooshrooms, and no hostile mobs spawn there",
    "nether_wastes": "netherrack, lava, nether fortresses, piglins, ghasts and zombified piglins",
    "old_growth_pine_taiga": "giant spruce trees, podzol, mossy cobblestone boulders and foxes",
    "pale_garden": "pale oak trees, pale moss and creaking hearts that spawn creakings at night",
    "plains": "flat grass, flowers, horses, villages and lots of space to build",
    "savanna": "acacia trees, horses, llamas, armadillos and villages",
    "snowy_plains": "flat snow, igloos, strays, polar bears and rabbits",
    "snowy_slopes": "snowy mountainsides with powder snow and goats",
    "soul_sand_valley": "soul sand, soul soil, blue soul fire, skeletons, ghasts and fossils",
    "stony_peaks": "rocky stone and calcite mountain peaks",
    "swamp": "murky water, lily pads, slimes at night, witch huts and frogs",
    "taiga": "spruce trees, ferns, sweet berry bushes, wolves, foxes and villages",
    "the_end": "the main End island with obsidian towers and the Ender Dragon",
    "warm_ocean": "coral reefs, sea pickles, tropical fish and pufferfish",
    "warped_forest": "blue warped fungi and lots of endermen, and it's one of the safest Nether biomes",
    "windswept_hills": "steep grassy hills with emerald ore, llamas and goats",
    "deep_ocean": "deep water, ocean monuments, guardians and shipwrecks",
    "frozen_ocean": "icebergs, sea ice and polar bears",
    "river": "flowing water, salmon, squid and drowned between other biomes",
}
BIOME_Q = {"nether_wastes": ["what is in the nether wastes"], "the_end": ["what is in the end biome"]}


def main():
    blocks = json.load(open(fetch(BASE + VER + "/blocks.json", "mcdata/blocks.json")))
    items = json.load(open(fetch(BASE + VER + "/items.json", "mcdata/items.json")))
    foods = json.load(open(fetch(BASE + VER + "/foods.json", "mcdata/foods.json")))
    enchants = json.load(open(fetch(BASE + VER + "/enchantments.json", "mcdata/enchantments.json")))
    effects = json.load(open(fetch(BASE + VER + "/effects.json", "mcdata/effects.json")))
    biomes = json.load(open(fetch(BASE + VER + "/biomes.json", "mcdata/biomes.json")))
    loot = {b["block"]: b for b in json.load(open(fetch(BASE + "1.20/blockLoot.json", "mcdata/blockLoot.json")))}
    item_by_id = {i["id"]: i for i in items}
    item_by_name = {i["name"]: i for i in items}

    names = ["gen_minecraft_blocks.txt", "gen_minecraft_items.txt", "gen_minecraft_food.txt",
             "gen_minecraft_enchantments.txt", "gen_minecraft_effects.txt", "gen_minecraft_biomes.txt"]
    w = Writer(names)

    # ---------------- Blocks ----------------
    F = "gen_minecraft_blocks.txt"
    for b in blocks:
        n = b["name"]
        if not wanted(n):
            continue
        disp = b["displayName"].lower()
        if n in KEEP_WOOD:
            disp = {"oak_log": "logs", "oak_planks": "planks", "oak_leaves": "leaves"}.get(n, disp)
        hard = b["hardness"]
        tools = [item_by_id[int(t)]["name"] for t in b.get("harvestTools", {})]
        mat = b["material"]
        drops = loot.get(n, {}).get("drops", [])
        silk_only = drops and all(d.get("silkTouch") for d in drops)
        if hard is None or hard < 0:
            ans = f"You can't break {disp} in Survival mode. Only players in Creative mode can break it."
            tool_type = None
        elif hard == 0:
            ans = f"{disp[0].upper() + disp[1:]} breaks instantly with anything, even your bare hand."
            tool_type = None
        elif tools:
            kinds = {t.split("_")[-1] for t in tools}
            if kinds == {"pickaxe"} or kinds == {"shovel"} or kinds == {"axe"} or kinds == {"hoe"}:
                tool_type = kinds.pop()
                low = min((tier_of(t) for t in tools), key=lambda t: {"wooden": 0, "golden": 0, "stone": 1, "iron": 2,
                                                                     "diamond": 3, "netherite": 4}[t])
                if low in ("wooden", "golden"):
                    ans = (f"You need a {tool_type} to mine {disp}. Any {tool_type} works, even a wooden one, "
                           f"but by hand it drops nothing.")
                else:
                    ans = (f"You need a {low} {tool_type} or better to mine {disp}. With a weaker {tool_type} or your "
                           f"hand it drops nothing.")
            elif "shears" in kinds and "sword" in kinds:
                tool_type = "sword"
                ans = f"Use a sword or shears on {disp}. A sword cuts it fast and drops string, and shears get the block itself."
                if n != "cobweb":
                    continue
            else:
                continue
        else:
            tool_type = None
            for m, t in (("mineable/pickaxe", "pickaxe"), ("mineable/axe", "axe"), ("mineable/shovel", "shovel"),
                         ("mineable/hoe", "hoe")):
                if m in mat:
                    tool_type = t
            if tool_type:
                ans = f"{'An' if tool_type == 'axe' else 'A'} {tool_type} breaks {disp} fastest, but you can break it with your hand too."
            else:
                ans = f"No tool breaks {disp} faster, so your hand works just as well."
            if "leaves" in mat:
                ans = "Shears or a hoe break leaves fastest. Shears or Silk Touch get you the leaf block itself."
        if silk_only and hard and hard > 0:
            ans += f" It only drops itself if your tool has Silk Touch, otherwise you get nothing."
        qs = [f"what tool do you need to mine {disp}", f"what pickaxe can mine {disp}" if tool_type == "pickaxe" else
              f"what tool breaks {disp} fastest", f"can you mine {disp} by hand", f"how do you break {disp}",
              f"how to mine {disp} in minecraft"]
        w.add(F, "minecraft.blocks", qs, ans)

        # How long it takes to mine some well-known blocks.
        if n in TIME_BLOCKS and tools:
            parts = []
            for t in ("wooden", "stone", "iron", "diamond", "netherite"):
                can = f"{t}_pickaxe" in tools
                parts.append(f"{t} pickaxe {secs(break_time(hard, SPEED[t], can))}" + ("" if can else " (no drop)"))
            hand = secs(break_time(hard, 1, False))
            ans = (f"With no enchantments, mining {disp} takes: by hand {hand} (no drop), " + ", ".join(parts) + ".")
            w.add(F, "minecraft.blocks", [f"how long does it take to mine {disp}", f"how fast can you mine {disp}",
                                          f"{disp} mining time", f"how long to break {disp}"], ans)

        # Blast resistance for very strong blocks.
        res = b["resistance"]
        if res >= 600 and hard is not None and hard >= 0:
            w.add(F, "minecraft.blocks", [f"can tnt blow up {disp}", f"is {disp} blast proof",
                                          f"can a creeper destroy {disp}", f"{disp} blast resistance"],
                  f"No. {disp[0].upper() + disp[1:]} has a blast resistance of {int(res):,}, so TNT and creepers can't break it.")
        elif hard is not None and hard < 0 and n not in ("end_portal_frame",):
            pass

        # Light level.
        light = b["emitLight"]
        if light > 0 and n not in ("lava", "fire", "soul_fire", "nether_portal", "end_portal", "end_gateway"):
            note = " That's the brightest light level there is." if light == 15 else " The brightest light level is 15."
            if n in ("redstone_ore", "deepslate_redstone_ore", "redstone_lamp", "furnace", "smoker", "blast_furnace",
                     "respawn_anchor", "campfire", "soul_campfire", "sea_pickle", "candle", "light", "copper_bulb",
                     "redstone_torch", "sculk_catalyst", "sculk_sensor", "calibrated_sculk_sensor", "cave_vines",
                     "glow_lichen", "creaking_heart", "big_dripleaf", "vault", "trial_spawner", "beehive",
                     "brewing_stand", "dragon_egg", "magma_block", "end_portal_frame", "amethyst_cluster", "crafter"):
                continue
            w.add(F, "minecraft.blocks", [f"how much light does {plural(disp) if False else disp} give off",
                                          f"{disp} light level", f"how bright is {disp}", f"does {disp} give light"],
                  f"{disp[0].upper() + disp[1:]} gives off light level {light}.{note}")

    # ---------------- Items: stack sizes and durability ----------------
    F = "gen_minecraft_items.txt"
    stack_items = ["ender_pearl", "snowball", "egg", "bucket", "water_bucket", "lava_bucket", "milk_bucket",
                   "honey_bottle", "armor_stand", "written_book", "writable_book", "enchanted_book", "potion",
                   "splash_potion", "totem_of_undying", "shulker_box", "saddle", "minecart", "elytra", "trident",
                   "shield", "cake", "bundle", "mushroom_stew", "rabbit_stew", "suspicious_stew", "beetroot_soup",
                   "ender_eye", "arrow", "firework_rocket", "diamond", "emerald", "iron_ingot", "netherite_ingot",
                   "torch", "wind_charge", "golden_apple", "enchanted_golden_apple", "experience_bottle", "goat_horn",
                   "spyglass", "nautilus_shell", "heart_of_the_sea", "nether_star", "dragon_breath", "name_tag",
                   "iron_horse_armor", "diamond_horse_armor", "axolotl_bucket", "spectral_arrow", "tipped_arrow",
                   "oak_sign", "white_banner", "white_bed", "oak_boat", "bone_meal", "end_crystal", "fire_charge",
                   "cobblestone", "tnt", "obsidian", "crying_obsidian", "dragon_egg", "slime_ball", "lead",
                   "music_disc_cat", "mace", "breeze_rod", "trial_key", "ominous_trial_key", "ominous_bottle",
                   "heavy_core", "echo_shard", "recovery_compass", "compass", "clock", "filled_map", "map",
                   "turtle_egg", "sniffer_egg", "dried_ghast"]
    nice = {"oak_sign": "signs", "white_banner": "banners", "white_bed": "beds", "oak_boat": "boats",
            "music_disc_cat": "music discs", "potion": "potions", "filled_map": "maps", "map": "empty maps",
            "ender_eye": "eyes of ender", "slime_ball": "slimeballs", "tnt": "TNT", "golden_apple": "golden apples",
            "enchanted_golden_apple": "enchanted golden apples", "experience_bottle": "bottles o' enchanting",
            "dragon_breath": "dragon's breath bottles", "lead": "leads", "cake": "cakes"}
    for n in stack_items:
        it = item_by_name.get(n)
        if not it:
            continue
        p = nice.get(n) or plural(it["displayName"].lower())
        if n == "cobblestone":
            p = "cobblestone"
        size = it["stackSize"]
        if size == 1:
            ans = f"{p[0].upper() + p[1:]} don't stack. Each one takes up its own inventory slot."
            if p in ("TNT", "cobblestone", "obsidian"):
                ans = f"{p[0].upper() + p[1:]} doesn't stack."
        else:
            verb = "stacks" if p in ("TNT", "cobblestone", "obsidian", "crying obsidian", "bone meal") else "stack"
            ans = f"{p[0].upper() + p[1:]} {verb} up to {size} in one slot."
        if n == "shulker_box":
            ans += " But you can put a whole shulker box full of items inside your inventory, and it keeps its items."
        if n in ("water_bucket", "lava_bucket", "milk_bucket"):
            ans += " Empty buckets stack to 16."
        w.add(F, "minecraft.items", [f"how many {p.lower()} can you stack", f"do {p.lower()} stack",
                                     f"{p.lower()} stack size", f"what is the max stack of {p.lower()}",
                                     f"how many {p.lower()} fit in one slot"], ans)
    groups = {"swords": "diamond_sword", "pickaxes": "iron_pickaxe", "armor": "iron_chestplate", "tools": "iron_axe"}
    for g, n in groups.items():
        assert item_by_name[n]["stackSize"] == 1
        w.add(F, "minecraft.items", [f"can you stack {g}", f"do {g} stack in minecraft", f"{g} stack size"],
              f"No, {g} don't stack in Minecraft. Each one takes a full inventory slot.")

    for it in items:
        if "maxDurability" not in it:
            continue
        n = it["name"]
        d = it["maxDurability"]
        disp = it["displayName"].lower()
        uses = {"bow": "shots", "crossbow": "shots", "fishing_rod": "casts or catches",
                "flint_and_steel": "uses", "shears": "uses", "elytra": "seconds of flying",
                "brush": "uses", "carrot_on_a_stick": "uses", "warped_fungus_on_a_stick": "uses"}.get(n, "uses")
        has = "have" if disp.endswith(("leggings", "boots", "shears")) else "has"
        ans = f"{art(disp)} {has} {d} durability" + (", so it lasts about 7 minutes and 12 seconds of flying." if n == "elytra" else ".")
        if n.endswith(("_helmet", "_chestplate", "_leggings", "_boots")):
            ans = f"{art(disp)} {has} {d} durability. {'They lose' if has == 'have' else 'It loses'} some each time you take damage."
        elif uses == "uses" and n.split("_")[-1] in ("pickaxe", "axe", "shovel", "hoe", "sword"):
            ans = f"{art(disp)} has {d} durability, so it can break about {d} blocks before it breaks."
            if n.endswith("sword"):
                ans = f"{art(disp)} has {d} durability. Each hit on a mob uses 1 and breaking a block uses 2."
            if n.endswith("hoe"):
                ans = f"{art(disp)} has {d} durability. Tilling a block or breaking a block uses 1."
        ans += " Unbreaking makes it last longer." if n != "elytra" else " Mending or phantom membranes fix it."
        ans = ans[0].upper() + ans[1:]
        w.add(F, "minecraft.items", [f"how much durability {'do' if has == 'have' else 'does'} {art(disp)} have", f"{disp} durability",
                                     f"how long {'do' if has == 'have' else 'does'} {art(disp)} last",
                                     f"how many uses {'do' if has == 'have' else 'does'} {art(disp)} have"], ans)

    # ---------------- Food ----------------
    F = "gen_minecraft_food.txt"
    food_notes = {
        "golden_apple": " It also gives Regeneration II for 5 seconds and Absorption (2 extra hearts) for 2 minutes.",
        "enchanted_golden_apple": " It also gives Regeneration II, Absorption IV, Resistance and Fire Resistance.",
        "rotten_flesh": " It has an 80 percent chance to give you Hunger for 30 seconds.",
        "spider_eye": " It also poisons you for 4 seconds.",
        "pufferfish": " It also gives you Poison, Hunger and Nausea, so don't eat it.",
        "poisonous_potato": " It has a 60 percent chance to poison you.",
        "chicken": " It has a 30 percent chance to give you Hunger, so cook it first.",
        "chorus_fruit": " It also teleports you to a random spot nearby.",
        "honey_bottle": " It also cures Poison.",
        "suspicious_stew": " It also gives a status effect that depends on the flower used to make it.",
        "golden_carrot": " It has some of the best saturation of any food.",
        "cooked_porkchop": " Tied with steak for the most hunger from a single item you can stack.",
        "cooked_beef": " Tied with cooked porkchop for the most hunger from a single item you can stack.",
        "dried_kelp": " It's quick to eat.",
        "rabbit_stew": " That's the most hunger of any food item.",
        "milk_bucket": "",
    }
    for f in foods:
        n = f["name"]
        disp = {"cooked_beef": "steak", "beef": "raw beef", "porkchop": "raw porkchop", "chicken": "raw chicken",
                "mutton": "raw mutton", "rabbit": "raw rabbit", "cod": "raw cod", "salmon": "raw salmon"}.get(
            n, f["displayName"].lower())
        hunger = int(f["foodPoints"])
        sat = f["saturation"] / (2 * f["foodPoints"])
        sat_t = f"{sat:.1f}".rstrip("0").rstrip(".")
        dr = hunger / 2
        dr_t = (f"{int(dr)}" if dr == int(dr) else f"{dr}") + (" drumstick" if dr == 1 else " drumsticks")
        pl = disp.endswith("s")
        ad = ("an " if disp[0] in "aeiou" else "a ") + disp if n in COUNTABLE_FOOD else disp
        ans = f"{ad[0].upper() + ad[1:]} restore{'' if pl else 's'} {hunger} hunger ({dr_t}) and {sat_t} saturation." + food_notes.get(n, "")
        do = "do" if pl else "does"
        qs = [f"how much hunger {do} {ad} restore", f"how many drumsticks {do} {ad} give",
              f"{disp} hunger", f"{'are' if pl else 'is'} {disp} good food in minecraft", f"how filling is {ad}"]
        if n == "cooked_beef":
            qs.insert(0, "how much hunger does cooked beef restore")
        w.add(F, "minecraft.food", qs, ans)

    # ---------------- Enchantments ----------------
    F = "gen_minecraft_enchantments.txt"
    roman = ["", "I", "II", "III", "IV", "V"]
    for e in enchants:
        n = e["name"]
        disp = e["displayName"]
        low = disp.lower()
        does, on = ENCH[n]
        mx = e["maxLevel"]
        w.add(F, "minecraft.enchantments", [f"what does {low} do", f"what is {low} in minecraft",
                                            f"{low} enchantment", f"is {low} good"],
              f"{disp} {does}. It goes on {on}.")
        if mx > 1:
            w.add(F, "minecraft.enchantments", [f"what is the max level of {low}", f"how high can {low} go",
                                                f"max {low} level", f"how many levels does {low} have"],
                  f"The highest {disp} level you can get in Survival is {disp} {roman[mx]}.")
        else:
            w.add(F, "minecraft.enchantments", [f"what is the max level of {low}", f"is there {low} 2",
                                                f"can you get {low} ii"],
                  f"{disp} only has one level, so {disp} I is the max.")
        how = TREASURE_HOW.get(n)
        if how or e["treasureOnly"]:
            w.add(F, "minecraft.enchantments", [f"how do you get {low}", f"where do you find {low}",
                                                f"can you get {low} from an enchanting table"],
                  how or f"{disp} is a treasure enchantment, so it never comes from the enchanting table.")
        for other in e["exclude"]:
            if other < n or other not in ENCH:
                continue
            if not set(ENCH[other][1].replace(",", "").split()) & set(on.replace(",", "").split()) - {"and", "anything", "with", "durability"}:
                continue
            od = [x for x in enchants if x["name"] == other][0]["displayName"]
            w.add(F, "minecraft.enchantments", [f"can you have {low} and {od.lower()} together",
                                                f"can you put {od.lower()} and {low} on the same item",
                                                f"{low} and {od.lower()}"],
                  f"No, {disp} and {od} can't go on the same item in Java Edition. You have to pick one.")

    # ---------------- Effects ----------------
    F = "gen_minecraft_effects.txt"
    for e in effects:
        n = e["name"]
        disp = {"InstantHealth": "Instant Health", "InstantDamage": "Instant Damage", "BadLuck": "Bad Luck",
                "MiningFatigue": "Mining Fatigue", "JumpBoost": "Jump Boost", "FireResistance": "Fire Resistance",
                "WaterBreathing": "Water Breathing", "NightVision": "Night Vision", "HealthBoost": "Health Boost",
                "SlowFalling": "Slow Falling", "ConduitPower": "Conduit Power", "DolphinsGrace": "Dolphin's Grace",
                "BadOmen": "Bad Omen", "HeroOfTheVillage": "Hero of the Village", "TrialOmen": "Trial Omen",
                "RaidOmen": "Raid Omen", "WindCharged": "Wind Charged"}.get(n, n)
        low = disp.lower()
        kind = "a good" if e["type"] == "good" else "a bad"
        w.add(F, "minecraft.effects", [f"what does the {low} effect do", f"what is {low} in minecraft",
                                       f"what does {low} do to you", f"{low} effect minecraft"],
              f"{disp} {EFFECTS[n]}. It counts as {kind} effect.")

    # ---------------- Biomes ----------------
    F = "gen_minecraft_biomes.txt"
    for bi in biomes:
        n = bi["name"]
        if n in ("the_void",):
            continue
        disp = bi["displayName"].lower()
        t = bi["temperature"]
        dim = {"overworld": "the Overworld", "nether": "the Nether", "end": "the End"}[bi["dimension"]]
        if bi["dimension"] != "overworld":
            ans = f"No. It never rains or snows in {disp} because it's in {dim}."
        elif not bi["has_precipitation"]:
            ans = f"No, it never rains or snows in the {disp} biome. Storms there are dry."
        elif t < 0.15:
            ans = f"It snows instead of rains in the {disp} biome, because it's a cold biome."
        else:
            ans = f"Yes, it rains in the {disp} biome."
            if t >= 0.8:
                ans = f"Yes, it rains in the {disp} biome, but it's too warm for snow."
        if bi["dimension"] == "overworld" and bi["category"] != "underground":
            w.add(F, "minecraft.biomes", [f"does it rain in the {disp}", f"does it snow in {disp}",
                                          f"{disp} weather minecraft", f"can it rain in a {disp} biome"], ans)
        desc = BIOMES.get(n)
        if desc:
            w.add(F, "minecraft.biomes", BIOME_Q.get(n, []) + [f"what is in a {disp} biome",
                                                               f"what can you find in the {disp}",
                                                               f"what spawns in the {disp} biome",
                                                               f"tell me about the {disp} biome"],
                  f"The {disp} biome has {desc}." if n != "the_end" else f"The End biome is {desc}.")
        if bi["dimension"] != "overworld":
            w.add(F, "minecraft.biomes", [f"what dimension is the {disp} in", f"is the {disp} in the nether",
                                          f"where is the {disp} biome"], f"The {disp} biome is in {dim}.")

    w.write(["Minecraft Java Edition data, generated by tools/knowledge/gen/games_mc_data.py",
             f"Source: PrismarineJS minecraft-data (MIT), Java Edition {VER} (block loot from 1.20).",
             "Descriptions of enchantments, effects and biomes are hand-written."])


def art(name):
    if name.endswith("s") and not name.endswith(("shears", "boots", "leggings")):
        return name
    if name in ("shears",):
        return "shears"
    if name.endswith(("boots", "leggings")):
        return name
    return ("an " if name[0] in "aeiou" else "a ") + name


if __name__ == "__main__":
    main()
