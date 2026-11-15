"""Minecraft Java Edition mobs for Ace's knowledge pack: health, drops, where they spawn, behavior.

Mob list checked against PrismarineJS minecraft-data (MIT license), data/pc/1.21.8/entities.json.
minecraft-data has no health values and its entity loot amounts are rough, so health, drops and
spawning are hand-written from Java Edition 1.21 game facts.
Writes data/games/gen_minecraft_mobs.txt. Run from the repo root:
    python3 tools/knowledge/gen/games_mc_mobs.py
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from games_common import Writer, fetch  # noqa: E402

BASE = "https://raw.githubusercontent.com/PrismarineJS/minecraft-data/master/data/pc/1.21.8/"

H, N, P, B = "hostile", "neutral", "passive", "boss"
# id, name, health (number or text), behavior, where it spawns, drops, one useful fact
MOBS = [
    ("zombie", "zombie", 20, H, "in the Overworld in the dark, mostly at night or in caves",
     "0 to 2 rotten flesh, and rarely an iron ingot, a carrot or a potato",
     "Zombies burn in sunlight unless they wear a helmet or stand in water."),
    ("husk", "husk", 20, H, "in deserts, instead of most zombies",
     "0 to 2 rotten flesh, and rarely an iron ingot, a carrot or a potato",
     "Husks don't burn in sunlight, and their hit gives you Hunger."),
    ("drowned", "drowned", 20, H, "in oceans and rivers, and when a zombie drowns underwater",
     "0 to 2 rotten flesh and sometimes a copper ingot. One holding a trident or nautilus shell can drop it",
     "Drowned with tridents throw them at you, and they are the only way to get a trident."),
    ("zombie_villager", "zombie villager", 20, H, "in the dark like zombies, and when a zombie kills a villager on Normal or Hard",
     "0 to 2 rotten flesh, and rarely an iron ingot, a carrot or a potato",
     "You can cure one with a splash potion of Weakness and a golden apple."),
    ("skeleton", "skeleton", 20, H, "in the Overworld in the dark, and in Nether soul sand valleys",
     "0 to 2 bones and 0 to 2 arrows", "Skeletons burn in sunlight and shoot arrows from far away."),
    ("stray", "stray", 20, H, "in snowy and icy biomes, instead of most skeletons",
     "0 to 2 bones, 0 to 2 arrows and sometimes an arrow of Slowness",
     "Its arrows give you Slowness."),
    ("bogged", "bogged", 16, H, "in swamps and mangrove swamps, and from spawners in trial chambers",
     "0 to 2 bones, 0 to 2 arrows and sometimes an arrow of Poison", "The bogged is a mossy skeleton that shoots poison arrows."),
    ("wither_skeleton", "wither skeleton", 20, H, "in Nether fortresses",
     "0 to 1 coal, 0 to 2 bones and a rare wither skeleton skull (about 2.5 percent, more with Looting)",
     "You need 3 of their skulls to summon the Wither."),
    ("creeper", "creeper", 20, H, "in the Overworld in the dark",
     "0 to 2 gunpowder, and a music disc if a skeleton or stray shoots it",
     "A creeper hit by lightning becomes a charged creeper with a much bigger explosion."),
    ("spider", "spider", 16, H, "in the Overworld in the dark",
     "0 to 2 string and sometimes a spider eye", "Spiders can climb walls and are neutral in bright light."),
    ("cave_spider", "cave spider", 12, H, "only from spawners in abandoned mineshafts",
     "0 to 2 string and sometimes a spider eye", "Cave spiders poison you on Normal and Hard difficulty and fit through 1 block gaps."),
    ("enderman", "enderman", 40, N, "in all three dimensions, and in big groups in the End and warped forests",
     "0 to 1 ender pearl", "Endermen get angry if you look at their face, and water hurts them."),
    ("slime", "slime", "16 health (8 hearts) when big, 4 (2 hearts) when medium and 1 (half a heart) when small", H,
     "in slime chunks below Y 40 and in swamps at night",
     "slimeballs, but only from the smallest size", "Big slimes split into smaller ones when killed."),
    ("magma_cube", "magma cube", "16 health (8 hearts) when big, 4 (2 hearts) when medium and 1 (half a heart) when small", H,
     "in the Nether, especially in basalt deltas",
     "magma cream from the bigger sizes, and a froglight if a frog eats a small one",
     "Magma cubes don't take fall damage or burn."),
    ("blaze", "blaze", 20, H, "in Nether fortresses, often from spawners",
     "0 to 1 blaze rod, only when a player kills it", "Blaze rods make blaze powder for brewing and eyes of ender."),
    ("ghast", "ghast", 10, H, "in the Nether, in nether wastes, soul sand valleys and basalt deltas",
     "0 to 1 ghast tear and 0 to 2 gunpowder", "You can hit a ghast's fireball back at it to kill it."),
    ("witch", "witch", 26, H, "in the dark in the Overworld, in swamp huts, and when a villager is struck by lightning",
     "up to 6 random items like glass bottles, glowstone dust, gunpowder, redstone, spider eyes, sugar and sticks",
     "Witches throw harmful potions and drink healing ones."),
    ("guardian", "guardian", 30, H, "in and around ocean monuments",
     "0 to 2 prismarine shards and sometimes raw cod or prismarine crystals",
     "Guardians shoot a laser beam and their spikes hurt you when you hit them."),
    ("elder_guardian", "elder guardian", 80, H, "inside ocean monuments, 3 in each one",
     "a wet sponge, prismarine shards and sometimes a tide armor trim template",
     "Elder guardians give you Mining Fatigue so you can't break the monument easily."),
    ("shulker", "shulker", 30, H, "in End cities",
     "a shulker shell half the time (more with Looting)", "Their bullets give you Levitation, which floats you into the air."),
    ("phantom", "phantom", 20, H, "in the sky at night when a player hasn't slept for 3 or more days",
     "0 to 1 phantom membrane, only when a player kills it", "Sleep in a bed to stop phantoms from spawning."),
    ("pillager", "pillager", 24, H, "at pillager outposts, in patrols and in raids",
     "arrows and sometimes its crossbow. A raid captain also drops an ominous banner and, in Java 1.21 and newer, an ominous bottle",
     "Pillagers shoot crossbows and lead raids on villages."),
    ("vindicator", "vindicator", 24, H, "in woodland mansions and raids",
     "0 to 1 emerald and sometimes its iron axe", "Name one Johnny with a name tag and it attacks almost every mob."),
    ("evoker", "evoker", 24, H, "in woodland mansions and raids",
     "a totem of undying and 0 to 1 emerald", "Evokers summon vexes and snapping fangs from the ground."),
    ("ravager", "ravager", 100, H, "in raids", "a saddle", "Ravagers can break leaves and crops and knock you back hard."),
    ("vex", "vex", 14, H, "when an evoker summons them",
     "nothing special, though it can drop its iron sword", "Vexes fly through walls and die on their own after a while."),
    ("piglin", "piglin", 16, N, "in nether wastes, crimson forests and bastion remnants",
     "sometimes their golden sword, crossbow or gold armor",
     "Wear at least one piece of gold armor and piglins won't attack you. Throw them gold ingots to barter."),
    ("piglin_brute", "piglin brute", 50, H, "only in bastion remnants",
     "sometimes its golden axe", "Brutes attack you even if you wear gold armor."),
    ("hoglin", "hoglin", 40, H, "in crimson forests", "2 to 4 raw porkchops and 0 to 1 leather",
     "Hoglins are scared of warped fungus, nether portals and respawn anchors."),
    ("zoglin", "zoglin", 40, H, "when a hoglin goes into the Overworld or the End and zombifies",
     "1 to 3 rotten flesh", "Zoglins attack every mob except creepers and other zoglins."),
    ("zombified_piglin", "zombified piglin", 20, N, "in the Nether and near nether portals in the Overworld",
     "0 to 1 rotten flesh, 0 to 1 gold nugget and rarely a gold ingot",
     "Hit one and every zombified piglin nearby gangs up on you."),
    ("endermite", "endermite", 8, H, "sometimes when you throw an ender pearl", "nothing but XP",
     "Endermen hate endermites and attack them."),
    ("silverfish", "silverfish", 8, H, "from infested stone blocks in strongholds, mountains and ancient cities",
     "nothing but XP", "Silverfish hide in blocks and call their friends when you hit one."),
    ("warden", "warden", 500, H, "in the Deep Dark when sculk shriekers are set off 3 times",
     "a sculk catalyst and 5 XP", "The Warden is blind and finds you by sound and smell, so sneak to stay quiet."),
    ("breeze", "breeze", 30, H, "from trial spawners in trial chambers", "1 to 2 breeze rods",
     "Breezes shoot wind charges and deflect arrows and tridents."),
    ("wither", "Wither", "300 health (150 hearts) in Java Edition and 600 in Bedrock Edition", B, "only when a player builds it from soul sand and wither skeleton skulls",
     "a nether star", "Below half health it gets wither armor and arrows can't hurt it."),
    ("ender_dragon", "Ender Dragon", 200, B, "in the End, on the main island",
     "lots of XP (12,000 the first time) and the dragon egg on the first kill",
     "End crystals on the towers heal it, so break them first."),
    ("iron_golem", "iron golem", 100, N, "in villages, or when you build one from iron blocks and a carved pumpkin",
     "3 to 5 iron ingots and 0 to 2 poppies", "Iron golems protect villagers and attack hostile mobs."),
    ("snow_golem", "snow golem", 4, P, "only when you build one from 2 snow blocks and a carved pumpkin",
     "0 to 15 snowballs", "Snow golems leave a trail of snow and melt in hot biomes and rain."),
    ("villager", "villager", 20, P, "in villages", "nothing", "Villagers trade items for emeralds based on their job."),
    ("wandering_trader", "wandering trader", 20, P, "near players every now and then, with 2 trader llamas",
     "any potion or milk bucket it was holding", "Wandering traders disappear after about 40 to 60 minutes."),
    ("cow", "cow", 10, P, "in grassy biomes like plains and forests", "0 to 2 leather and 1 to 3 raw beef",
     "Use an empty bucket on a cow to get milk."),
    ("mooshroom", "mooshroom", 10, P, "in mushroom fields", "0 to 2 leather and 1 to 3 raw beef",
     "Use a bowl on a mooshroom for mushroom stew, or shears to turn it into a normal cow."),
    ("pig", "pig", 10, P, "in grassy biomes", "1 to 3 raw porkchops", "You can ride a saddled pig and steer it with a carrot on a stick."),
    ("sheep", "sheep", 8, P, "in grassy and snowy biomes", "1 wool and 1 to 2 raw mutton",
     "Shear a sheep to get 1 to 3 wool without hurting it."),
    ("chicken", "chicken", 4, P, "in grassy biomes", "0 to 2 feathers and 1 raw chicken",
     "Chickens lay an egg every 5 to 10 minutes and don't take fall damage."),
    ("rabbit", "rabbit", 3, P, "in deserts, flower forests, taigas, meadows and snowy biomes",
     "0 to 1 rabbit hide, 0 to 1 raw rabbit and rarely a rabbit's foot", "A rabbit's foot is used to brew potions of Leaping."),
    ("horse", "horse", "15 to 30 health (7.5 to 15 hearts), depending on the horse", P, "in plains and savannas", "0 to 2 leather",
     "Tame a horse by riding it until hearts appear, then put a saddle on it."),
    ("donkey", "donkey", "15 to 30 health (7.5 to 15 hearts), depending on the donkey", P, "in plains, savannas and meadows", "0 to 2 leather",
     "Put a chest on a tamed donkey to carry items."),
    ("mule", "mule", "15 to 30 health (7.5 to 15 hearts), depending on the mule", P, "only when you breed a horse with a donkey", "0 to 2 leather",
     "Mules can't be bred and can carry a chest."),
    ("llama", "llama", "15 to 30 health (7.5 to 15 hearts), depending on the llama", N, "in savannas and windswept hills", "0 to 2 leather",
     "Llamas spit at you if you attack them and can carry chests."),
    ("cat", "cat", 10, P, "in villages and swamp huts", "0 to 2 string",
     "Creepers and phantoms are scared of cats."),
    ("ocelot", "ocelot", 10, P, "in jungles", "nothing but XP", "Feed one raw cod or salmon so it trusts you. Creepers avoid ocelots too."),
    ("fox", "fox", 10, P, "in taigas, snowy taigas and groves", "whatever item it was holding in its mouth",
     "Foxes sleep in the day and hunt chickens and rabbits at night."),
    ("wolf", "wolf", "8 health (4 hearts) when wild and 40 health (20 hearts) once tamed, in Java 1.20.5 and newer", N,
     "in forests, taigas, groves, savannas and badlands", "nothing but XP",
     "Tame a wolf with bones. Wolf armor from armadillo scutes protects it."),
    ("polar_bear", "polar bear", 30, N, "in snowy plains, ice spikes and frozen oceans",
     "0 to 2 raw cod or raw salmon", "Polar bears attack if you get close to their cubs."),
    ("panda", "panda", 20, N, "in jungles and bamboo jungles", "0 to 2 bamboo",
     "Pandas have personalities like lazy, playful, worried and aggressive."),
    ("turtle", "turtle", 30, P, "on warm beaches", "0 to 2 seagrass",
     "Baby turtles drop a turtle scute when they grow up, which makes turtle shells."),
    ("dolphin", "dolphin", 10, N, "in oceans that aren't frozen", "0 to 1 raw cod",
     "Swim near a dolphin to get Dolphin's Grace, and feed it raw fish to lead you to treasure."),
    ("squid", "squid", 10, P, "in oceans and rivers", "1 to 3 ink sacs", "Ink sacs make black dye and book and quills."),
    ("glow_squid", "glow squid", 10, P, "in dark underwater areas, like underground lakes",
     "1 to 3 glow ink sacs", "Glow ink sacs make signs glow and turn item frames into glow item frames."),
    ("cod", "cod", 3, P, "in most oceans", "raw cod and sometimes bone meal", "You can catch one in a water bucket."),
    ("salmon", "salmon", 3, P, "in rivers and cold oceans", "raw salmon and sometimes bone meal",
     "Salmon come in small, medium and large sizes."),
    ("pufferfish", "pufferfish", 3, P, "in warm and lukewarm oceans", "a pufferfish and sometimes bone meal",
     "Eating a pufferfish gives you Poison, Hunger and Nausea."),
    ("tropical_fish", "tropical fish", 3, P, "in warm oceans, coral reefs and lush caves", "a tropical fish and sometimes bone meal",
     "There are thousands of color and pattern combinations."),
    ("axolotl", "axolotl", 14, P, "in water in lush caves", "nothing", "Axolotls help you fight underwater mobs and come in 5 colors."),
    ("frog", "frog", 10, P, "in swamps and mangrove swamps", "nothing",
     "Frogs eat small slimes and small magma cubes, and froglights come from magma cubes they eat."),
    ("bee", "bee", 10, N, "in bee nests in plains, meadows, flower forests and some other biomes", "nothing",
     "A bee loses its stinger and dies after it stings you."),
    ("parrot", "parrot", 6, P, "in jungles", "1 to 2 feathers", "Tame parrots with seeds and they can ride on your shoulder."),
    ("bat", "bat", 6, P, "in dark caves", "nothing", "Bats are harmless and just fly around in caves."),
    ("goat", "goat", 10, N, "in snowy slopes, jagged peaks and frozen peaks", "nothing",
     "Goats ram you off mountains, and a goat horn drops when one rams a hard block."),
    ("allay", "allay", 20, P, "in cages at pillager outposts and in woodland mansions", "nothing",
     "Give an allay an item and it collects matching items for you."),
    ("camel", "camel", 32, P, "in desert villages", "nothing", "Camels can carry 2 players and dash forward."),
    ("sniffer", "sniffer", 14, P, "only by hatching a sniffer egg from suspicious sand in warm ocean ruins", "nothing",
     "Sniffers dig up ancient seeds like the torchflower and pitcher pod."),
    ("armadillo", "armadillo", 12, P, "in savannas and badlands", "nothing, but brushing it gives an armadillo scute",
     "Armadillo scutes make wolf armor."),
    ("strider", "strider", 20, P, "on lava lakes in the Nether", "2 to 5 string",
     "Ride a saddled strider across lava and steer it with warped fungus on a stick."),
    ("skeleton_horse", "skeleton horse", 15, P, "from skeleton trap horses in thunderstorms", "0 to 2 bones",
     "Skeleton horses can swim underwater."),
    ("trader_llama", "trader llama", "15 to 30 health (7.5 to 15 hearts)", N, "next to wandering traders", "0 to 2 leather",
     "Trader llamas spit at mobs that attack their trader."),
    ("tadpole", "tadpole", 6, P, "when frog spawn hatches", "nothing",
     "A tadpole grows into a frog whose color depends on the biome it grows up in."),
    ("giant", "giant", 100, H, "only with commands", "nothing", "The giant is a huge zombie that doesn't move or attack."),
    ("illusioner", "illusioner", 32, H, "only with commands in Java Edition", "nothing special",
     "Illusioners make copies of themselves and cast Blindness."),
]

AN = ("a", "e", "i", "o", "u")
PLURALS = {"bogged": "bogged", "drowned": "drowned", "wolf": "wolves", "enderman": "endermen", "vex": "vexes", "wither": "withers", "ender_dragon": "ender dragons"}


def art(name):
    if name[0].isupper():
        return "the " + name
    return ("an " if name.startswith(AN) else "a ") + name


def main():
    ents = {e["name"] for e in json.load(open(fetch(BASE + "entities.json", "mcdata/entities.json")))}
    w = Writer(["gen_minecraft_mobs.txt"])
    f = "gen_minecraft_mobs.txt"
    for mid, name, hp, kind, where, drops, fact in MOBS:
        assert mid in ents, mid
        a = art(name)
        cap = a[0].upper() + a[1:]
        pl = name + ("es" if name.endswith("ch") else "" if name.endswith(("s", "sh", "fish", "salmon", "cod", "sheep")) else "s")
        pl = PLURALS.get(mid, pl)
        ln = name.lower()
        if isinstance(hp, int):
            hearts = hp / 2
            ht = f"{int(hearts)}" if hearts == int(hearts) else f"{hearts}"
            hq = f"{cap} has {hp} health, which is {ht} heart{'s' if hearts != 1 else ''}."
        else:
            hq = f"{cap} has {hp}."
        w.add(f, "minecraft.mobs", [f"how much health does {a.lower()} have", f"how many hearts does {a.lower()} have",
                                    f"{ln} health", f"{ln} hp minecraft"], hq)
        if drops != "nothing" and not drops.startswith("nothing but"):
            w.add(f, "minecraft.mobs", [f"what does {a.lower()} drop", f"what do {pl.lower()} drop" if kind != B else
                                        f"what loot does {a.lower()} give", f"{ln} drops", f"what do you get from killing {a.lower()}"],
                  f"{cap} drops {drops}.")
        elif kind != B:
            w.add(f, "minecraft.mobs", [f"what does {a.lower()} drop", f"what do {pl.lower()} drop", f"{ln} drops"],
                  f"{cap} drops {drops}" + ("." if not drops.endswith(".") else ""))
        w.add(f, "minecraft.mobs", [f"where do {pl.lower()} spawn" if kind != B else f"where does {a.lower()} spawn",
                                    f"where can i find {a.lower()}",
                                    f"where to find {pl.lower() if kind != B else a.lower()} in minecraft", f"{ln} spawn location"],
              f"{cap} spawns {where}." if kind != B else f"{cap} appears {where}.")
        if kind != B:
            kt = {H: f"Yes, {pl.lower()} are hostile and attack you on sight.",
                  N: f"No, {pl.lower()} are neutral. They only attack if you provoke them.",
                  P: f"No, {pl.lower()} are passive and never attack you."}[kind]
            if mid == "spider":
                kt = "Yes, spiders attack you in the dark, but in bright light they are neutral unless you hit them."
            if mid == "enderman":
                kt = "No, endermen are neutral. They only attack if you look at their face or hit them."
            if mid == "llama":
                kt = "No, llamas are neutral. They spit at you if you hit them, and at wolves."
            if mid == "bee":
                kt = "No, bees are neutral. They sting you if you hit one or take honey from their nest without a campfire under it."
            if mid == "zombified_piglin":
                kt = "No, zombified piglins are neutral until you hit one. Then the whole group attacks you."
            if mid == "piglin":
                kt = "Piglins attack you unless you wear at least one piece of gold armor."
            if mid in ("polar_bear", "panda", "goat", "dolphin", "wolf", "iron_golem", "trader_llama"):
                kt = f"No, {pl.lower()} are neutral. They only fight back if you or something provokes them."
            w.add(f, "minecraft.mobs", [f"are {pl.lower()} hostile", f"do {pl.lower()} attack you",
                                        f"is {a.lower()} friendly", f"will {a.lower()} hurt me"], kt)
        w.add(f, "minecraft.mobs", [f"tell me about the {ln} in minecraft", f"what is {a.lower()} in minecraft",
                                    f"fun fact about {pl.lower() if kind != B else a.lower()}",
                                    f"what should i know about {pl.lower() if kind != B else a.lower()}"],
              fact)
    w.write(["Minecraft Java Edition mobs, generated by tools/knowledge/gen/games_mc_mobs.py",
             "Mob list checked against PrismarineJS minecraft-data (MIT) 1.21.8 entities.json; stats hand-written."])


if __name__ == "__main__":
    main()
