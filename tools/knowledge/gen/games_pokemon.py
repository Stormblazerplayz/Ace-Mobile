"""Pokémon facts for Ace's knowledge pack: types, Pokédex numbers, generations, evolutions and type matchups.

Data: PokeAPI (BSD 3-Clause license), https://github.com/PokeAPI/pokeapi, data/v2/csv:
pokemon_species.csv, pokemon.csv, pokemon_types.csv, types.csv, type_names.csv, type_efficacy.csv,
pokemon_species_names.csv, pokemon_evolution.csv, item_names.csv, move_names.csv.
Types are the current ones (Generation 6 and later type chart, with Fairy).
Writes data/games/gen_pokemon.txt, gen_pokemon_evolution.txt and gen_pokemon_types.txt.
Run from the repo root:  python3 tools/knowledge/gen/games_pokemon.py
"""
import csv
import os
import sys
import unicodedata

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from games_common import Writer, fetch  # noqa: E402

BASE = "https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv/"
EN = "9"


def rows(name):
    return list(csv.DictReader(open(fetch(BASE + name + ".csv", "pokeapi/" + name + ".csv"), encoding="utf-8")))


def plain(name):
    """How a kid would type the name."""
    s = name.replace("♀", " female").replace("♂", " male").replace("’", "").replace("'", "")
    s = s.replace(":", "").replace(".", "").replace("-", " ")
    s = unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode()
    return " ".join(s.lower().split())


def join(xs, word="and"):
    xs = list(xs)
    if len(xs) == 1:
        return xs[0]
    return ", ".join(xs[:-1]) + f" {word} " + xs[-1]


SPECIAL = {  # evolutions that the CSV only marks as a special trigger
    "shedinja": "appears in an empty party slot when Nincada evolves into Ninjask, if you have a free slot and a spare Poké Ball",
    "gholdengo": "after you collect 999 Gimmighoul Coins",
    "alcremie": "when you spin around while it holds a Sweet",
    "sirfetchd": "after it lands 3 critical hits in one battle (Galarian Farfetch'd only)",
    "runerigus": "after it takes at least 49 damage and then walks under a certain stone arch (Galarian Yamask only)",
    "kingambit": "after it defeats 3 Bisharp that hold a Leader's Crest",
    "melmetal": "when you feed Meltan 400 Meltan Candy in Pokémon GO",
    "urshifu": "after training in one of the two towers on the Isle of Armor",
    "basculegion": "after it takes at least 294 recoil damage without fainting (white-striped Basculin only)",
    "overqwil": "after it uses Barb Barrage in Strong Style 20 times (Hisuian Qwilfish only)",
    "wyrdeer": "after it uses Psyshield Bash in Agile Style 20 times",
    "sneasler": "when it levels up during the day holding a Razor Claw (Hisuian Sneasel only)",
    "annihilape": "after it uses Rage Fist 20 times",
    "brambleghast": "after you walk 1,000 steps with it in Let's Go mode",
    "rabsca": "after you walk 1,000 steps with it in Let's Go mode",
    "palafin": "at level 38 while you are in a Union Circle with another player",
    "maushold": "at level 25 (its family size is random)",
    "dudunsparce": "at level 32 when it knows Hyper Drill",
    "toxtricity": "at level 30, and its form depends on its nature",
    "farigiraf": "when it levels up knowing Twin Beam",
    "inteleon": "at level 35",
    "hydrapple": "when it levels up knowing Dragon Cheer",
    "archaludon": "when you use a Metal Alloy on it",
    "sinistcha": "when you use a Masterpiece Teacup on it (or an Unremarkable Teacup for the regular form)",
    "kleavor": "when you use a Black Augurite on it",
    "silcoon": "at level 7 (whether Wurmple becomes Silcoon or Cascoon is random)",
    "cascoon": "at level 7 (whether Wurmple becomes Silcoon or Cascoon is random)",
    "hitmonlee": "at level 20 if its Attack is higher than its Defense",
    "hitmonchan": "at level 20 if its Defense is higher than its Attack",
    "hitmontop": "at level 20 if its Attack and Defense are equal",
    "goodra": "at level 50 while it's raining or foggy",
    "malamar": "at level 30 while you hold your game system upside down",
    "mantine": "when it levels up with a Remoraid in your party",
    "pangoro": "at level 32 with a Dark-type Pokémon in your party",
    "pawmot": "when it levels up after you walk 1,000 steps with it in Let's Go mode",
    "ursaluna": "when you use a Peat Block on it during a full moon",
}


def main():
    species = rows("pokemon_species")
    names = {r["pokemon_species_id"]: r["name"] for r in rows("pokemon_species_names") if r["local_language_id"] == EN}
    genus = {r["pokemon_species_id"]: r["genus"] for r in rows("pokemon_species_names") if r["local_language_id"] == EN}
    tnames = {r["type_id"]: r["name"] for r in rows("type_names") if r["local_language_id"] == EN}
    types_all = [t for t in rows("types") if int(t["id"]) <= 18]
    default_pokemon = {r["species_id"]: r["id"] for r in rows("pokemon") if r["is_default"] == "1"}
    ptypes = {}
    for r in rows("pokemon_types"):
        ptypes.setdefault(r["pokemon_id"], []).append((int(r["slot"]), r["type_id"]))
    eff = {}
    for r in rows("type_efficacy"):
        eff[(r["damage_type_id"], r["target_type_id"])] = int(r["damage_factor"]) / 100
    items = {r["item_id"]: r["name"] for r in rows("item_names") if r["local_language_id"] == EN}
    moves = {r["move_id"]: r["name"] for r in rows("move_names") if r["local_language_id"] == EN}
    evo = {}
    for r in rows("pokemon_evolution"):
        if r["is_default"] != "1" or r["region_id"]:
            continue
        evo.setdefault(r["evolved_species_id"], r)

    sp = {s["id"]: s for s in species}
    children = {}
    for s in species:
        if s["evolves_from_species_id"]:
            children.setdefault(s["evolves_from_species_id"], []).append(s["id"])

    def types_of(sid):
        return [tnames[t] for _, t in sorted(ptypes[default_pokemon[sid]])]

    def method(sid):
        key = plain(names[sid]).replace(" ", "")
        if key in SPECIAL:
            return SPECIAL[key]
        r = evo.get(sid)
        if not r:
            return None
        trig = r["evolution_trigger_id"]
        known = {"id", "evolved_species_id", "evolution_trigger_id", "version_group_id", "is_default",
                 "required_pokemon_form_id", "evolved_pokemon_form_id"}
        extra = []
        handled = set()
        if trig == "1":
            if r["minimum_level"]:
                extra.append(f"at level {r['minimum_level']}")
                handled.add("minimum_level")
            if r["minimum_happiness"]:
                extra.append("when it levels up with high friendship")
                handled.add("minimum_happiness")
            if r["held_item_id"]:
                extra.append(f"while holding {'an' if items[r['held_item_id']][0] in 'AEIOU' else 'a'} {items[r['held_item_id']]}")
                handled.add("held_item_id")
            if r["known_move_id"]:
                extra.append(f"when it levels up knowing {moves[r['known_move_id']]}")
                handled.add("known_move_id")
            if r["known_move_type_id"]:
                extra.append(f"while it knows a {tnames[r['known_move_type_id']]}-type move")
                handled.add("known_move_type_id")
            if r["time_of_day"] in ("day", "night"):
                extra.append("during the day" if r["time_of_day"] == "day" else "at night")
                handled.add("time_of_day")
            if r["gender_id"]:
                extra.append("if it's female" if r["gender_id"] == "1" else "if it's male")
                handled.add("gender_id")
            if not extra:
                extra.append("when it levels up")
        elif trig == "2":
            extra.append("when you trade it")
            if r["held_item_id"]:
                extra.append(f"while it holds {'an' if items[r['held_item_id']][0] in 'AEIOU' else 'a'} {items[r['held_item_id']]}")
                handled.add("held_item_id")
            if r["trade_species_id"]:
                extra.append(f"for a {names[r['trade_species_id']]}")
                handled.add("trade_species_id")
        elif trig == "3":
            extra.append(f"when you use {'an' if items[r['trigger_item_id']][0] in 'AEIOU' else 'a'} {items[r['trigger_item_id']]} on it")
            handled.add("trigger_item_id")
            if r["gender_id"]:
                extra.append("if it's female" if r["gender_id"] == "1" else "if it's male")
                handled.add("gender_id")
        else:
            return "in a special way"
        left = [k for k, v in r.items() if v and v != "0" and k not in known and k not in handled]
        if left:
            return " ".join(extra) + ", plus a special condition"
        if r["held_item_id"] and trig == "1" and not r["minimum_level"]:
            pass
        return " ".join(extra)

    files = ["gen_pokemon.txt", "gen_pokemon_evolution.txt", "gen_pokemon_types.txt"]
    w = Writer(files)

    # Types, number, generation.
    for s in species:
        sid = s["id"]
        nm = names[sid]
        p = plain(nm)
        ts = types_of(sid)
        tt = (f"{ts[0]} type" if len(ts) == 1 else f"{ts[0]} and {ts[1]} type")
        kind = ""
        if s["is_legendary"] == "1":
            kind = " Legendary"
        elif s["is_mythical"] == "1":
            kind = " Mythical"
        ans = (f"{nm} is a{'n' if tt[0] in 'AEIOU' and not kind else ''}{kind} {tt} Pokémon, the {genus[sid]}. "
               f"It's number {int(sid)} in the National Pokédex and comes from Generation {s['generation_id']}.")
        w.add("gen_pokemon.txt", "pokemon.species", [f"what type is {p}", f"{p} type", f"what kind of pokemon is {p}",
                                                     f"what generation is {p} from", f"what number is {p} in the pokedex",
                                                     f"is {p} a {ts[0].lower()} type"], ans)

    # Pokédex number lookup for the first 251.
    for s in species:
        sid = int(s["id"])
        if sid > 251:
            continue
        nm = names[s["id"]]
        w.add("gen_pokemon.txt", "pokemon.number", [f"what pokemon is number {sid}", f"pokemon number {sid}",
                                                    f"pokedex number {sid}", f"who is #{sid} in the pokedex"],
              f"Number {sid} in the National Pokédex is {nm}.")

    # Evolutions.
    for s in species:
        sid = s["id"]
        nm = names[sid]
        p = plain(nm)
        kids = children.get(sid, [])
        parent = s["evolves_from_species_id"]
        if kids:
            parts = []
            for k in kids:
                m = method(k)
                parts.append(f"{names[k]} {m}" if m else names[k])
            if len(kids) == 1:
                ans = f"{nm} evolves into {parts[0]}."
            else:
                ans = f"{nm} can evolve into {len(kids)} different Pokémon: " + "; ".join(parts) + "."
            if nm == "Eevee":
                ans = ("Eevee can evolve into 8 Pokémon: Vaporeon (Water Stone), Jolteon (Thunder Stone), Flareon "
                       "(Fire Stone), Leafeon (Leaf Stone), Glaceon (Ice Stone), Espeon (high friendship during the "
                       "day), Umbreon (high friendship at night) and Sylveon (high friendship while knowing a Fairy move).")
            if len(ans) > 560:
                ans = f"{nm} can evolve into {len(kids)} different Pokémon: " + join(names[k] for k in kids) + "."
            w.add("gen_pokemon_evolution.txt", "pokemon.evolution",
                  [f"what does {p} evolve into", f"when does {p} evolve", f"what level does {p} evolve",
                   f"how do you evolve {p}", f"{p} evolution"], ans)
        if parent:
            m = method(sid)
            ans = f"{nm} evolves from {names[parent]}" + ((f" {m}." if m.startswith("at ") else f", {m}.") if m else ".")
            if not kids:
                root = parent
                while sp[root]["evolves_from_species_id"]:
                    root = sp[root]["evolves_from_species_id"]
                ans += f" It's the final form of {names[root]}'s family." if root != parent or True else ""
            w.add("gen_pokemon_evolution.txt", "pokemon.evolution",
                  [f"what does {p} evolve from", f"what pokemon evolves into {p}", f"{p} pre evolution",
                   f"how do you get {p}"], ans)
        if not kids and not parent:
            w.add("gen_pokemon_evolution.txt", "pokemon.evolution",
                  [f"does {p} evolve", f"what does {p} evolve into", f"{p} evolution"],
                  f"No, {nm} doesn't evolve into or from any other Pokémon.")

    # Type matchups.
    tids = [t["id"] for t in types_all]

    def mult(att, defs):
        m = 1.0
        for d in defs:
            m *= eff[(att, d)]
        return m

    for t in types_all:
        tid = t["id"]
        nm = tnames[tid]
        low = nm.lower()
        weak = [tnames[a] for a in tids if eff[(a, tid)] == 2]
        resist = [tnames[a] for a in tids if eff[(a, tid)] == 0.5]
        immune = [tnames[a] for a in tids if eff[(a, tid)] == 0]
        strong = [tnames[d] for d in tids if eff[(tid, d)] == 2]
        notvery = [tnames[d] for d in tids if eff[(tid, d)] == 0.5]
        noeff = [tnames[d] for d in tids if eff[(tid, d)] == 0]
        F = "gen_pokemon_types.txt"
        w.add(F, "pokemon.types", [f"what is super effective against {low}", f"what is {low} weak to",
                                   f"what beats {low} type", f"{low} type weakness", f"what is good against {low} pokemon"],
              f"{join(weak)} moves are super effective against {nm}-type Pokémon.")
        w.add(F, "pokemon.types", [f"what is {low} strong against", f"what is {low} super effective against",
                                   f"what does {low} beat", f"{low} type strengths"],
              (f"{nm} moves are super effective against {join(strong)} types." if strong else
               f"{nm} moves aren't super effective against any type."))
        w.add(F, "pokemon.types", [f"what does {low} resist", f"what is not very effective against {low}",
                                   f"{low} type resistances", f"what types do half damage to {low}"],
              (f"{nm}-type Pokémon take half damage from {join(resist)} moves." if resist else
               f"{nm}-type Pokémon don't resist any type.") +
              (f" {join(immune, 'or')} moves can't hurt them at all." if immune else ""))
        w.add(F, "pokemon.types", [f"what is {low} not very effective against", f"what resists {low} moves",
                                   f"what is {low} bad against", f"{low} moves are weak against what"],
              (f"{nm} moves are not very effective against {join(notvery)} types." if notvery else
               f"No type resists {nm} moves.") +
              (f" They don't affect {join(noeff, 'or')} types at all." if noeff else ""))
        if immune:
            w.add(F, "pokemon.types", [f"what is {low} immune to", f"what can't hit {low} types",
                                       f"what moves don't affect {low} pokemon"],
                  f"{nm}-type Pokémon are immune to {join(immune)} moves.")

    # Weaknesses of individual Pokémon: Generation 1, starters and Legendary or Mythical Pokémon.
    starters = {"1", "4", "7", "152", "155", "158", "252", "255", "258", "387", "390", "393", "495", "498", "501",
                "650", "653", "656", "722", "725", "728", "810", "813", "816", "906", "909", "912", "25"}
    for s in species:
        sid = s["id"]
        line = set()
        r = sid
        while r:
            line.add(r)
            r = sp[r]["evolves_from_species_id"]
        if not (int(sid) <= 151 or line & starters or s["is_legendary"] == "1" or s["is_mythical"] == "1"):
            continue
        nm = names[sid]
        p = plain(nm)
        defs = [t for _, t in sorted(ptypes[default_pokemon[sid]])]
        x4 = [tnames[a] for a in tids if mult(a, defs) == 4]
        x2 = [tnames[a] for a in tids if mult(a, defs) == 2]
        x0 = [tnames[a] for a in tids if mult(a, defs) == 0]
        tt = "/".join(tnames[d] for d in defs)
        parts = []
        if x4:
            parts.append(f"{join(x4)} (4 times damage)")
        if x2:
            parts.append(f"{join(x2)} (2 times damage)")
        ans = f"{nm} ({tt}) is weak to " + " and ".join(parts) + "."
        if x0:
            ans += f" {join(x0, 'and')} moves can't hurt it."
        w.add("gen_pokemon_types.txt", "pokemon.weakness", [f"what is {p} weak to", f"{p} weakness",
                                                            f"what beats {p}", f"what is super effective against {p}",
                                                            f"how do i beat {p}"], ans)

    w.write(["Pokémon data, generated by tools/knowledge/gen/games_pokemon.py",
             "Source: PokeAPI CSV data (BSD 3-Clause), github.com/PokeAPI/pokeapi data/v2/csv."])


if __name__ == "__main__":
    main()
