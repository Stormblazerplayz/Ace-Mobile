#!/usr/bin/env python3
"""Writes data/science/gen_materials.txt: sink-or-float, sound speed and melting/boiling of
common substances.

Data sources: CRC Handbook of Chemistry and Physics typical values and the NIST Chemistry
WebBook (melting and boiling points at 1 atmosphere), checked against Engineering ToolBox
tables for densities and speed of sound. Materials whose density varies a lot (most woods,
rubber, glass) are given as ranges or left out.

Run from the repo root:  python3 tools/knowledge/gen/science_materials.py
"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, "..", "data", "science", "gen_materials.txt"))

# key, wording name (with article), answer
FLOAT = [
    ("ice", "ice", "Yes, ice floats. It's about 0.92 g/cm³, a bit less dense than water, because water molecules spread out into an open pattern when they freeze. That's why about 90% of an iceberg is underwater."),
    ("cork", "cork", "Yes, cork floats very well. It's only about 0.24 g/cm³ because it's full of tiny air-filled cells."),
    ("balsa", "balsa wood", "Yes, balsa wood floats easily. It's one of the lightest woods, often around 0.1 to 0.2 g/cm³."),
    ("wood", "wood", "Most wood floats because it's less dense than water, usually about 0.4 to 0.9 g/cm³. A few very dense woods, like ebony and lignum vitae, sink."),
    ("ebony", "ebony", "Ebony usually sinks. It's around 1.1 to 1.2 g/cm³, denser than water, which is unusual for wood."),
    ("aluminium", "aluminium", "A solid lump of aluminium sinks, since it's 2.7 g/cm³. A foil boat or a can can float, because its shape pushes aside enough water to hold it up."),
    ("steel", "steel", "Solid steel sinks, since it's about 7.8 g/cm³. Steel ships float because their hollow shape pushes aside a weight of water equal to the ship's weight."),
    ("gold", "gold", "Gold sinks fast. At about 19.3 g/cm³, it's over 19 times denser than water, which is why gold panners can wash lighter sand away and keep the gold."),
    ("lead", "lead", "Lead sinks. It's about 11.3 g/cm³, which is why it's used for fishing weights and diving belts."),
    ("glass", "glass", "Solid glass sinks, since it's about 2.5 g/cm³. An empty, sealed glass bottle can float because of the air inside it."),
    ("pumice", "pumice", "Yes, pumice can float. This volcanic rock is full of gas bubbles, so it's less dense than water until water slowly soaks into the holes."),
    ("granite", "granite", "Granite sinks. It's about 2.7 g/cm³, nearly three times as dense as water."),
    ("diamond", "a diamond", "A diamond sinks. It's about 3.5 g/cm³."),
    ("oil", "oil", "Yes, cooking oil floats on water. It's about 0.92 g/cm³ and doesn't mix with water, so it forms a layer on top."),
    ("honey", "honey", "Honey sinks in water. It's about 1.4 g/cm³, so it settles to the bottom of a glass before slowly dissolving."),
    ("gasoline", "gasoline", "Gasoline floats on water, since it's about 0.7 to 0.77 g/cm³ and doesn't mix with water. That's one reason water is a bad way to put out a fuel fire."),
    ("candle", "a candle", "Yes, a wax candle floats. Paraffin wax is about 0.9 g/cm³, a little less dense than water."),
    ("apple", "an apple", "Yes, apples float. About a quarter of an apple is air, so it's less dense than water. That's why bobbing for apples works."),
    ("orange", "an orange", "An orange with its peel floats, because the peel is full of tiny air pockets like a life jacket. Peel it and the orange usually sinks."),
    ("egg", "an egg", "A fresh egg sinks in water. As an egg ages, its air cell gets bigger, so an old egg stands up or floats. In very salty water, even a fresh egg floats."),
    ("grape", "a grape", "Grapes usually sink in plain water because they're a bit denser than water. Raisins also sink at first."),
    ("potato", "a potato", "A potato usually sinks in plain water. It floats in very salty water, which is a fun density experiment."),
    ("coconut", "a coconut", "Yes, coconuts float, thanks to their light, fibrous husk full of air. They can drift across oceans and grow on new beaches."),
    ("banana", "a banana", "A banana usually floats, because it's slightly less dense than water."),
    ("plastic", "plastic", "It depends on the plastic. Polyethylene and polypropylene, used in milk jugs and bottle caps, are less dense than water and float. PET drink bottles and PVC are denser and sink unless air is trapped inside."),
    ("styrofoam", "styrofoam", "Yes, foam polystyrene floats very well because it's mostly air. Solid polystyrene, like in a plastic cup, is only just denser than water."),
    ("brick", "a brick", "A brick sinks. Most are around 1.8 to 2 g/cm³."),
    ("human", "a person", "Most people can float, especially with lungs full of air. The body's density is very close to water's. Body fat floats, while bone and muscle sink, and salty sea water makes floating easier."),
    ("mercury", "mercury", "Liquid mercury sinks under water, since it's about 13.5 g/cm³. It's so dense that a steel bolt floats on top of mercury."),
    ("milk", "milk", "Milk is slightly denser than water, about 1.03 g/cm³, so it doesn't float on water. It mixes in instead."),
]

# (name, speed m/s, note)
SOUND = [
    ("air", "about 343 m/s at 20 °C", "It's a little faster in warm air and slower in cold air."),
    ("water", "about 1,480 m/s", "That's over four times faster than in air."),
    ("sea water", "about 1,500 m/s", "It changes a bit with temperature, saltiness and depth."),
    ("steel", "about 5,000 to 6,000 m/s", "That's up to about 17 times faster than in air, which is why you can hear a train coming through the rails before you hear it in the air."),
    ("helium", "about 1,000 m/s", "That's why breathing helium makes your voice sound squeaky: the sound resonates at higher frequencies in your throat."),
    ("ice", "about 3,800 m/s", "That's more than 10 times faster than in air."),
    ("space", None, "Sound can't travel through space at all, because there's almost no matter there to carry the vibrations."),
]

# name, melts, boils, extra
PHASE = [
    ("ethanol", "about minus 114 °C", "about 78 °C", "That's why alcohol evaporates faster than water and is used in thermometers for very cold places."),
    ("table salt", "about 801 °C", "about 1,465 °C", None),
    ("ammonia", "about minus 78 °C", "about minus 33 °C", "So it's a gas at room temperature, though it's sold dissolved in water as a cleaner."),
    ("methane", "about minus 182 °C", "about minus 162 °C", "Natural gas, which is mostly methane, is shipped cooled to a liquid."),
    ("propane", "about minus 188 °C", "about minus 42 °C", "It's stored as a liquid under pressure in barbecue tanks."),
    ("butane", "about minus 138 °C", "just below 0 °C", "That's why lighters and camping stoves can struggle on freezing days."),
    ("acetone", "about minus 95 °C", "about 56 °C", "Acetone is the main liquid in many nail polish removers."),
    ("liquid nitrogen", "about minus 210 °C", "about minus 196 °C", "That's why liquid nitrogen boils wildly at room temperature."),
    ("liquid oxygen", "about minus 218 °C", "about minus 183 °C", "Liquid oxygen is pale blue and is used in rockets to help the fuel burn."),
    ("glycerol", "about 18 °C", "about 290 °C", "It's a thick, sweet liquid used in soap and bubble mixtures."),
]


def main():
    lines = ["# Generated by tools/knowledge/gen/science_materials.py. Do not edit by hand.",
             "# Sources: CRC Handbook typical values and NIST Chemistry WebBook, cross-checked with Engineering ToolBox tables.",
             "# tag: science.physics.density"]
    for key, name, ans in FLOAT:
        n = name
        bare = n.split(" ", 1)[1] if n.startswith(("a ", "an ")) else n
        qs = [f"does {n} float", f"will {n} float or sink", f"does {n} sink in water"]
        if n.startswith(("a ", "an ")):
            pl = {"person": "people", "potato": "potatoes"}.get(bare, bare + "s")
            qs.append(f"do {pl} float")
        else:
            qs.append(f"is {bare} denser than water")
        lines.append(" | ".join(qs) + " => " + ans)
    lines.append("# tag: science.physics.sound")
    for name, speed, note in SOUND:
        qs = [f"how fast does sound travel in {name}", f"speed of sound in {name}", f"how fast is sound in {name}"]
        if speed is None:
            ans = note + " Astronauts talk by radio, which uses light-speed radio waves."
        else:
            ans = f"Sound travels through {name} at {speed}. {note}"
        lines.append(" | ".join(qs) + " => " + ans)
    lines.append("# tag: science.chem.matter")
    for name, mp, bp, extra in PHASE:
        qs = [f"what is the boiling point of {name}", f"what is the melting point of {name}",
              f"at what temperature does {name} boil", f"at what temperature does {name} melt"]
        ans = f"At normal air pressure, {name} melts at {mp} and boils at {bp}."
        if extra:
            ans += " " + extra
        lines.append(" | ".join(qs) + " => " + ans[0].upper() + ans[1:])
    with open(OUT, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print(f"wrote {sum(1 for l in lines if '=>' in l)} entries to {OUT}")


if __name__ == "__main__":
    main()
