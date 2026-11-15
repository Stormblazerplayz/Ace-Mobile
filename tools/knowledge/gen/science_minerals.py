#!/usr/bin/env python3
"""Writes data/science/gen_rocks.txt: common minerals and rocks.

Data sources: hand-checked table below, using values from the Mohs hardness scale as given
by the Mineralogical Society of America and mindat.org, and standard school geology
(US Geological Survey and British Geological Survey teaching pages, public information).
Hardness ranges are given where minerals vary.

Run from the repo root:  python3 tools/knowledge/gen/science_minerals.py
"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, "..", "data", "science", "gen_rocks.txt"))

# name, other names, hardness text, description
MINERALS = [
    ("talc", [], "1", "Talc is the softest mineral, 1 on the Mohs scale. You can scratch it with a fingernail, and it's ground up to make talcum powder."),
    ("gypsum", ["selenite"], "2", "Gypsum is a soft mineral made of calcium sulfate and water. It's used to make plaster and drywall, and see-through crystals of it are called selenite."),
    ("calcite", [], "3", "Calcite is calcium carbonate, the main mineral in limestone and marble. It fizzes in weak acid, which is a handy test for it."),
    ("fluorite", [], "4", "Fluorite comes in purple, green, blue and other colors, and many pieces glow under UV light. The word fluorescence comes from it."),
    ("apatite", [], "5", "Apatite is a calcium phosphate mineral. A form of it makes up your teeth and bones, and it's mined to make fertilizer."),
    ("orthoclase", ["feldspar"], "6", "Orthoclase is a type of feldspar, the most common group of minerals in Earth's crust. It's often pink and found in granite."),
    ("quartz", [], "7", "Quartz is silicon dioxide, one of the most common minerals. Purple amethyst, smoky quartz and rose quartz are all types of it, and it's used in watches and glass."),
    ("topaz", [], "8", "Topaz is a hard gemstone that can be clear, yellow, orange, blue or pink."),
    ("corundum", [], "9", "Corundum is aluminium oxide. Red corundum is ruby and other colors are sapphire. It's also crushed for sandpaper."),
    ("diamond", [], "10", "Diamond is pure carbon and the hardest natural mineral, 10 on the Mohs scale. It forms deep in Earth's mantle under huge heat and pressure."),
    ("halite", ["rock salt"], "2 to 2.5", "Halite is rock salt, the mineral form of sodium chloride. It forms cube shaped crystals when salty water evaporates."),
    ("mica", ["muscovite"], "2 to 3", "Mica splits into thin, shiny, see-through sheets. It's used in electronics and makes glittery sparkles in some cosmetics and paints."),
    ("graphite", [], "1 to 2", "Graphite is soft, gray carbon that feels greasy. It's used in pencils, lubricants and batteries."),
    ("pyrite", ["fools gold"], "6 to 6.5", "Pyrite is iron sulfide, called fool's gold because it's shiny and gold colored. Unlike real gold, it's hard and brittle and makes a black streak."),
    ("magnetite", [], "5.5 to 6.5", "Magnetite is a black iron oxide and the most magnetic natural mineral. It's an important iron ore."),
    ("hematite", [], "5.5 to 6.5", "Hematite is iron oxide and the main ore of iron. It can look silver or black, but it always leaves a reddish brown streak."),
    ("galena", [], "2.5", "Galena is lead sulfide, the main ore of lead. It's very heavy and forms shiny silver gray cubes."),
    ("malachite", [], "3.5 to 4", "Malachite is a bright green copper mineral with swirly bands. It's been used as a pigment and for jewelry for thousands of years."),
    ("azurite", [], "3.5 to 4", "Azurite is a deep blue copper mineral, often found with green malachite. It was ground up as a blue paint pigment."),
    ("olivine", ["peridot"], "6.5 to 7", "Olivine is a green mineral common in Earth's mantle and in basalt. Gem quality olivine is called peridot."),
    ("garnet", [], "6.5 to 7.5", "Garnets are a group of minerals, usually dark red, used as gems and as sandpaper grit."),
    ("tourmaline", [], "7 to 7.5", "Tourmaline is a gem mineral that comes in more colors than almost any other, and some crystals are pink at one end and green at the other."),
    ("beryl", ["emerald", "aquamarine"], "7.5 to 8", "Beryl is a mineral containing beryllium. Green beryl is emerald and blue beryl is aquamarine."),
    ("opal", [], "5.5 to 6.5", "Opal is made of tiny silica spheres with water trapped between them. Precious opal flashes rainbow colors because the spheres bend light."),
    ("turquoise", [], "5 to 6", "Turquoise is a blue green mineral containing copper and aluminium. It has been used in jewelry for thousands of years."),
    ("amethyst", [], "7", "Amethyst is purple quartz. Its color comes from traces of iron and natural radiation."),
    ("sulfur mineral", ["native sulfur"], "1.5 to 2.5", "Native sulfur forms bright yellow crystals, often around volcanic vents and hot springs."),
    ("cinnabar", [], "2 to 2.5", "Cinnabar is bright red mercury sulfide, the main ore of mercury. It's toxic, but it was once used as a red pigment."),
    ("chalcopyrite", [], "3.5 to 4", "Chalcopyrite is a brassy yellow copper iron sulfide and the most important copper ore."),
    ("jade", ["jadeite", "nephrite"], "6 to 7", "Jade is the name for two different minerals, jadeite and nephrite. It's tough and has been carved into tools and art, especially in China and Central America."),
    ("zircon", [], "7.5", "Zircon is a tough mineral that lasts for billions of years. The oldest known bits of Earth are zircon crystals from Australia, about 4.4 billion years old."),
    ("hornblende", [], "5 to 6", "Hornblende is a dark green to black mineral found in many igneous and metamorphic rocks, like granite and diorite."),
    ("dolomite", [], "3.5 to 4", "Dolomite is a calcium magnesium carbonate. It's like calcite but only fizzes in acid when it's powdered."),
    ("kaolinite", ["kaolin", "china clay"], "2 to 2.5", "Kaolinite is a soft white clay mineral used to make porcelain, paper and some medicines."),
    ("labradorite", [], "6 to 6.5", "Labradorite is a feldspar that flashes blue and green colors when you turn it in the light."),
    ("native gold", ["gold mineral"], "2.5 to 3", "Gold is found as a native mineral, often as nuggets or flakes in quartz veins and river gravel. It's soft and very heavy."),
    ("native copper", ["copper mineral"], "2.5 to 3", "Native copper is copper found pure in nature, sometimes in big masses. Ancient people used it before they learned to smelt ore."),
]

# name, type, how it forms / what it is, uses or fact
ROCKS = [
    ("granite", "igneous", "Granite forms when magma cools slowly deep underground, so it has big crystals of quartz, feldspar and mica.", "It's very hard and is used for kitchen counters, buildings and monuments."),
    ("basalt", "igneous", "Basalt is a dark rock formed when lava cools quickly at the surface. Most of the ocean floor is basalt.", "It's crushed for roads and railway beds. The Giant's Causeway in Northern Ireland is made of basalt columns."),
    ("obsidian", "igneous", "Obsidian is natural volcanic glass, made when lava cools so fast that no crystals form.", "Its edges can be sharper than steel, so ancient people made blades and arrowheads from it."),
    ("pumice", "igneous", "Pumice forms when frothy, gas-filled lava cools quickly, trapping lots of bubbles.", "It's so full of holes it can float on water. It's used to scrub skin and in some concrete."),
    ("rhyolite", "igneous", "Rhyolite is a light colored volcanic rock with the same minerals as granite but tiny crystals, because it cooled fast.", "Very sticky rhyolite magma can cause explosive eruptions."),
    ("andesite", "igneous", "Andesite is a gray volcanic rock, between basalt and rhyolite. It's named after the Andes mountains.", "It's common in volcanoes above subduction zones, like around the Pacific Ring of Fire."),
    ("gabbro", "igneous", "Gabbro is a dark, coarse rock that forms when basalt magma cools slowly underground.", "It's found in the lower part of the ocean crust."),
    ("diorite", "igneous", "Diorite is a speckled black and white igneous rock that cooled slowly underground.", "Ancient Egyptians and others carved it into statues and vases."),
    ("tuff", "igneous", "Tuff is rock made from volcanic ash that settled and hardened.", "It's soft enough to carve, so people have built homes and statues from it, like the Moai of Easter Island."),
    ("scoria", "igneous", "Scoria is a dark, bubbly volcanic rock, heavier than pumice, so it usually sinks.", "It's used in landscaping and barbecue grills."),
    ("sandstone", "sedimentary", "Sandstone forms when layers of sand get buried and the grains are cemented together over time.", "It's used for buildings, and canyons like the Grand Canyon have thick sandstone layers."),
    ("limestone", "sedimentary", "Limestone is made mostly of calcium carbonate, often from shells and skeletons of sea creatures.", "It's used to make cement and lime. Caves form in limestone as acidic water dissolves it."),
    ("shale", "sedimentary", "Shale forms from layers of mud and clay squeezed together. It splits into thin layers.", "It often holds fossils, and some shales contain oil and natural gas."),
    ("conglomerate", "sedimentary", "Conglomerate is made of rounded pebbles cemented together, like natural concrete.", "The rounded pebbles show they were tumbled by rivers or waves."),
    ("breccia", "sedimentary", "Breccia is made of sharp, angular rock pieces cemented together.", "The sharp pieces show they didn't travel far before being buried."),
    ("chalk", "sedimentary", "Chalk is a soft white limestone made from the tiny shells of microscopic sea algae.", "The White Cliffs of Dover in England are made of chalk. School chalk today is usually gypsum."),
    ("coal", "sedimentary", "Coal forms from ancient swamp plants buried and squeezed for millions of years.", "It's burned for energy, but it releases lots of carbon dioxide."),
    ("rock salt", "sedimentary", "Rock salt forms when salty seas or lakes evaporate and leave thick salt layers.", "It's mined for table salt and for melting ice on roads."),
    ("flint", "sedimentary", "Flint is a very hard form of silica found as lumps in chalk.", "It breaks with sharp edges, so it was used for Stone Age tools, and it makes sparks when struck with steel."),
    ("marble", "metamorphic", "Marble forms when limestone is heated and squeezed, so its crystals grow and lock together.", "It's used for sculptures and buildings, like Michelangelo's David and the Taj Mahal."),
    ("slate", "metamorphic", "Slate forms when shale is squeezed, so it splits into flat, thin sheets.", "It's used for roof tiles, floors and old school chalkboards."),
    ("schist", "metamorphic", "Schist is a sparkly metamorphic rock with flat layers of mica, formed under more heat and pressure than slate.", "It can contain garnets."),
    ("gneiss", "metamorphic", "Gneiss is a metamorphic rock with light and dark bands, made under very high heat and pressure.", "Some of the oldest rocks on Earth, over 4 billion years old in Canada, are gneiss."),
    ("quartzite", "metamorphic", "Quartzite forms when sandstone is heated and squeezed so the quartz grains fuse together.", "It's extremely hard and is used for counters and tiles."),
    ("soapstone", "metamorphic", "Soapstone is a soft metamorphic rock made mostly of talc, so it feels soapy.", "It's easy to carve and holds heat well, so it's used for sculptures, sinks and stoves."),
]

TYPE_TEXT = {
    "igneous": "an igneous rock, made from cooled magma or lava",
    "sedimentary": "a sedimentary rock, made from layers of bits that were pressed and cemented together",
    "metamorphic": "a metamorphic rock, changed by heat and pressure",
}


def main():
    lines = ["# Generated by tools/knowledge/gen/science_minerals.py. Do not edit by hand.",
             "# tag: science.earth.minerals"]
    count = 0

    def add(qs, a):
        nonlocal count
        out = []
        for q in qs:
            q = q.lower().replace("'", "")
            if q not in out:
                out.append(q)
        assert 2 <= len(out) <= 6 and len(a) < 400
        lines.append(" | ".join(out) + " => " + a)
        count += 1

    for name, alts, hard, desc in MINERALS:
        alt = alts[0] if alts else name
        add([f"what is {name}", f"tell me about {alt}", f"{name} mineral facts"] +
            [f"what is {a}" for a in alts[:2]], desc)
        add([f"how hard is {name}", f"what is the mohs hardness of {name}", f"{alt} hardness"],
            f"{name[0].upper() + name[1:]} has a hardness of {hard} on the Mohs scale, which runs from 1 (talc) to 10 (diamond).")
    lines.append("# tag: science.earth.rocks")
    for name, kind, forms, use in ROCKS:
        add([f"what is {name}", f"how does {name} form", f"how is {name} made", f"{name} rock"], f"{forms} {use}")
        add([f"what type of rock is {name}", f"is {name} igneous sedimentary or metamorphic", f"{name} rock type"],
            f"{name[0].upper() + name[1:]} is {TYPE_TEXT[kind]}.")
    with open(OUT, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print(f"wrote {count} entries to {OUT}")


if __name__ == "__main__":
    main()
