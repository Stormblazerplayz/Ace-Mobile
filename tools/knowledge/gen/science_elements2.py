#!/usr/bin/env python3
"""Writes data/science/gen_elements2.txt: more facts about chemical elements.

Data sources
  1. mendeleev (Python package, MIT license): Pauling electronegativity and natural
     isotope abundances.
  2. Bowserinator/Periodic-Table-JSON (from Wikipedia, CC BY-SA 3.0), cached in
     tools/knowledge/.cache/PeriodicTableJSON.json: Pauling electronegativity.
  Electronegativity is only written when both sources agree within 0.05.
  Isotope lists are the isotopes mendeleev gives a natural abundance for (elements up to
  uranium). Tantalum is left out because its second natural form is a nuclear isomer.
  3. Hand-checked tables in this file: what elements look like, the charges of common ions,
     which metals are magnetic, and which elements are poisonous.

Run from the repo root:  python3 tools/knowledge/gen/science_elements2.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import science_elements as se  # noqa: E402

OUT = os.path.join(se.KN, "data", "science", "gen_elements2.txt")

LOOKS = {
    "Hydrogen": "Hydrogen is a colorless gas with no smell or taste.",
    "Helium": "Helium is a colorless gas. In a glowing discharge tube it shines a pinkish orange.",
    "Lithium": "Lithium is a soft, silvery white metal, light enough to float on oil. It quickly tarnishes in air.",
    "Beryllium": "Beryllium is a hard, steel gray metal.",
    "Boron": "Pure boron is usually a black or dark brown solid. Crystals of it are shiny and very hard.",
    "Carbon": "It depends on its form. Graphite is soft, black and slightly shiny, while diamond is clear and sparkly. Both are pure carbon.",
    "Nitrogen": "Nitrogen is a colorless gas with no smell. As a liquid, at minus 196 °C, it's also colorless, like water.",
    "Oxygen": "Oxygen gas is colorless, but liquid and solid oxygen are pale blue.",
    "Fluorine": "Fluorine is a pale yellow gas.",
    "Neon": "Neon is a colorless gas, but it glows bright reddish orange when electricity passes through it, as in neon signs.",
    "Sodium": "Sodium is a soft, shiny, silvery metal you can cut with a knife. It tarnishes within seconds in air.",
    "Magnesium": "Magnesium is a shiny, silvery gray metal. It burns with a blinding white flame.",
    "Aluminum": "Aluminium is a light, silvery white metal.",
    "Silicon": "Silicon is a hard, shiny, blue gray solid that looks like a metal but is a metalloid.",
    "Phosphorus": "Phosphorus comes in several forms. White phosphorus is waxy and glows in the dark, and red phosphorus is a dark red powder used on match boxes.",
    "Sulfur": "Sulfur is a bright yellow solid. It burns with a blue flame.",
    "Chlorine": "Chlorine is a pale yellow green gas with a strong, choking smell.",
    "Argon": "Argon is a colorless gas. It glows lilac to violet in a discharge tube.",
    "Potassium": "Potassium is a soft, silvery metal that tarnishes almost instantly in air. It burns with a lilac flame.",
    "Calcium": "Calcium is a silvery white metal that quickly turns dull gray in air.",
    "Titanium": "Titanium is a shiny, silvery gray metal.",
    "Chromium": "Chromium is a hard, shiny, steel gray metal that can be polished to a mirror finish, which is why it's used for chrome plating.",
    "Iron": "Pure iron is a shiny, silvery gray metal, but in damp air it rusts to a reddish brown.",
    "Cobalt": "Cobalt is a hard, shiny, bluish gray metal. Its compounds make the deep blue color called cobalt blue.",
    "Nickel": "Nickel is a shiny, silvery metal with a slight golden tinge.",
    "Copper": "Copper is a shiny, reddish orange metal. Over years outdoors, it turns green, like the Statue of Liberty.",
    "Zinc": "Zinc is a bluish white, silvery metal.",
    "Gallium": "Gallium is a soft, silvery metal. It melts at about 30 °C, so it can melt in your hand.",
    "Bromine": "Bromine is a dark reddish brown liquid that gives off a reddish brown vapor.",
    "Krypton": "Krypton is a colorless gas. It glows whitish in a discharge tube.",
    "Silver": "Silver is a shiny, bright white metal. It slowly tarnishes black when it reacts with sulfur in the air.",
    "Tin": "Tin is a soft, silvery white metal.",
    "Iodine": "Iodine is a shiny, blackish gray solid. When warmed, it turns into a violet gas.",
    "Xenon": "Xenon is a colorless gas. It glows blue in a discharge tube and is used in some very bright lamps.",
    "Cesium": "Caesium is a soft, pale gold metal. It's one of only a few metals that aren't silvery or gray, along with copper and gold.",
    "Tungsten": "Tungsten is a hard, grayish white metal.",
    "Osmium": "Osmium is a hard, shiny, bluish white metal.",
    "Platinum": "Platinum is a shiny, silvery white metal that doesn't tarnish.",
    "Gold": "Gold is a shiny yellow metal that never rusts or tarnishes.",
    "Mercury": "Mercury is a shiny, silvery liquid metal.",
    "Lead": "Lead is a soft, dull bluish gray metal. Freshly cut, it's shiny.",
    "Bismuth": "Bismuth is a silvery white metal with a pinkish tinge. Lab-grown bismuth crystals have rainbow colors from a thin oxide layer.",
    "Uranium": "Uranium is a silvery gray metal that tarnishes darker in air.",
    "Radon": "Radon is a colorless gas with no smell, which is why homes are tested for it.",
}

ION = {
    "Hydrogen": ("1+", "H+", "losing its one electron"),
    "Lithium": ("1+", "Li+", "losing its one outer electron"),
    "Sodium": ("1+", "Na+", "losing its one outer electron"),
    "Potassium": ("1+", "K+", "losing its one outer electron"),
    "Magnesium": ("2+", "Mg2+", "losing its two outer electrons"),
    "Calcium": ("2+", "Ca2+", "losing its two outer electrons"),
    "Barium": ("2+", "Ba2+", "losing its two outer electrons"),
    "Aluminum": ("3+", "Al3+", "losing its three outer electrons"),
    "Zinc": ("2+", "Zn2+", "losing two electrons"),
    "Silver": ("1+", "Ag+", "losing one electron"),
    "Fluorine": ("1-", "F-", "gaining one electron, called fluoride"),
    "Chlorine": ("1-", "Cl-", "gaining one electron, called chloride"),
    "Bromine": ("1-", "Br-", "gaining one electron, called bromide"),
    "Iodine": ("1-", "I-", "gaining one electron, called iodide"),
    "Oxygen": ("2-", "O2-", "gaining two electrons, called oxide"),
    "Sulfur": ("2-", "S2-", "gaining two electrons, called sulfide"),
    "Nitrogen": ("3-", "N3-", "gaining three electrons, called nitride"),
}
ION_TEXT = {
    "Iron": "Iron commonly forms two ions: iron(II), Fe2+, and iron(III), Fe3+. Rust contains iron(III).",
    "Copper": "Copper commonly forms copper(II) ions, Cu2+, which make solutions blue, and also copper(I) ions, Cu+.",
}

ISO_EXTRA = {
    "Hydrogen": " They're called protium and deuterium. Tiny traces of radioactive tritium, hydrogen-3, also form naturally.",
    "Carbon": " Tiny traces of radioactive carbon-14 also form naturally, and it's used to date old remains.",
}

MAGNETIC = {
    "Iron": "Yes. Iron is strongly attracted to magnets and can be made into a magnet itself.",
    "Cobalt": "Yes. Cobalt is one of the few elements strongly attracted to magnets at room temperature, along with iron and nickel.",
    "Nickel": "Yes. Nickel is attracted to magnets, though less strongly than iron.",
    "Gadolinium": "Only when it's cool. Gadolinium is strongly magnetic below about 20 °C and loses it on a warm day.",
    "Copper": "No. Copper isn't attracted to a magnet. A strong magnet falling through a copper pipe does slow down, though, because it creates electric currents in the copper.",
    "Aluminum": "No. Aluminium isn't attracted to a fridge magnet. Its magnetism is far too weak to notice.",
    "Gold": "No. Gold isn't attracted to magnets. If a gold ring sticks to a magnet, it's mixed with another metal.",
    "Silver": "No. Silver isn't attracted to magnets, which is one quick test for fake silver.",
    "Zinc": "No. Zinc isn't attracted to magnets.",
    "Tin": "No. Tin isn't attracted to magnets. Tin cans stick to magnets because they're mostly steel with a thin tin coating.",
    "Lead": "No. Lead isn't attracted to magnets.",
    "Titanium": "No. Titanium isn't noticeably attracted to magnets, which is one reason it's used in medical implants.",
    "Platinum": "No. Platinum isn't noticeably attracted to magnets.",
}

POISON = {
    "Lead": "Yes. Lead is poisonous, especially to children's brains, and builds up in the body. That's why it was removed from paint, petrol and water pipes.",
    "Mercury": "Yes. Mercury and its vapor are poisonous and can damage the brain and kidneys. Old mercury thermometers were replaced for this reason.",
    "Arsenic": "Yes. Arsenic is very poisonous and was once a famous poison in history. Small amounts occur naturally in some groundwater.",
    "Cadmium": "Yes. Cadmium is toxic and can damage the kidneys and bones, so its use is restricted.",
    "Thallium": "Yes. Thallium is extremely poisonous, which is why it's rarely used.",
    "Polonium": "Yes. Polonium is extremely toxic because it's intensely radioactive.",
    "Beryllium": "Yes. Breathing beryllium dust can cause a serious lung disease, so it's handled with care.",
    "Chlorine": "Yes. Chlorine gas is poisonous to breathe and was used as a weapon in World War I. In tiny amounts, it keeps pool water clean.",
    "Fluorine": "Yes. Fluorine gas is extremely toxic and reactive. Fluoride compounds in toothpaste are safe in normal amounts.",
    "Gold": "No. Pure gold is not toxic, and thin gold leaf is even used to decorate food.",
    "Oxygen": "Not normally. We need it to live, but breathing pure oxygen at high pressure for a long time can harm the lungs.",
    "Sodium": "Pure sodium metal is dangerous because it reacts violently with water, but sodium in salt is something your body needs.",
}


SOURCE = {
    "Hydrogen": "Most hydrogen is made from natural gas by reacting methane with steam. It can also be made by splitting water with electricity.",
    "Helium": "Helium is collected from natural gas wells, where it builds up underground from the radioactive decay of uranium and thorium over millions of years.",
    "Lithium": "Lithium is mined from salty underground brines, mostly in South America, which are pumped into ponds to evaporate, and from hard rock ores like spodumene, mainly in Australia.",
    "Carbon": "Carbon is found as coal, graphite and diamond, and in limestone, oil, natural gas, carbon dioxide and every living thing.",
    "Nitrogen": "Nitrogen is taken from air, which is about 78% nitrogen, by cooling air until it turns liquid and then separating the gases.",
    "Oxygen": "Pure oxygen is made by cooling air until it's liquid and separating the gases by their boiling points. Plants and algae keep adding oxygen to the air.",
    "Fluorine": "Fluorine comes from the mineral fluorite (calcium fluoride). The pure gas is made by electrolysis, because nothing else will pull it out of its compounds.",
    "Neon": "Neon is separated from liquid air, where it makes up only about 18 parts per million.",
    "Sodium": "Sodium is made by passing electricity through melted salt (sodium chloride), which comes from rock salt mines and seawater.",
    "Magnesium": "Magnesium is extracted from seawater and brines, and from minerals like dolomite and magnesite.",
    "Aluminum": "Aluminium comes from bauxite ore. The ore is purified to aluminium oxide, then electricity is used to split it in huge smelters.",
    "Silicon": "Silicon is made by heating quartz sand (silicon dioxide) with carbon in an electric furnace. For computer chips, it's then purified to over 99.9999999%.",
    "Phosphorus": "Phosphorus comes from phosphate rock, mostly mined in places like Morocco, China and the US. Most of it is used to make fertilizer.",
    "Sulfur": "Most sulfur is now removed from natural gas and oil during refining. It's also found as yellow deposits near volcanoes.",
    "Chlorine": "Chlorine is made by passing electricity through salt water (brine), which also makes sodium hydroxide and hydrogen.",
    "Argon": "Argon is separated from liquid air, which is almost 1% argon.",
    "Potassium": "Potassium comes from potash minerals like sylvite, mined from the dried-up beds of ancient seas, especially in Canada.",
    "Calcium": "Calcium is found in limestone, chalk, marble and gypsum. The pure metal is made by electrolysis or by heating lime with aluminium.",
    "Titanium": "Titanium comes from the minerals rutile and ilmenite, often found in beach sands. Turning them into metal is difficult, which makes titanium expensive.",
    "Chromium": "Chromium comes from the mineral chromite, mined mostly in South Africa, Kazakhstan and Turkey.",
    "Manganese": "Manganese comes mainly from the mineral pyrolusite (manganese dioxide). Huge amounts also lie on the deep seafloor in lumps called nodules.",
    "Iron": "Iron comes from ores like hematite and magnetite, heated with coke and limestone in a blast furnace to make molten iron.",
    "Cobalt": "Cobalt is mostly produced as a by-product of copper and nickel mining, with the Democratic Republic of the Congo producing most of the world's supply.",
    "Nickel": "Nickel comes from ores like pentlandite and laterites, mined in places like Indonesia, the Philippines and Russia.",
    "Copper": "Copper comes mostly from the ore chalcopyrite, dug from huge open-pit mines, especially in Chile and Peru. Sometimes it's found as pure native copper.",
    "Zinc": "Zinc comes mainly from the ore sphalerite (zinc sulfide).",
    "Bromine": "Bromine is extracted from brines and seawater, such as the Dead Sea.",
    "Silver": "Silver is mostly produced as a by-product of mining lead, zinc, copper and gold. Mexico and Peru are the biggest producers.",
    "Tin": "Tin comes from the mineral cassiterite (tin oxide), often found in river gravels.",
    "Iodine": "Iodine is extracted from underground brines, especially in Japan, and from deposits in the Chilean desert. It was first found in seaweed ash.",
    "Tungsten": "Tungsten comes from the minerals wolframite and scheelite. China produces most of the world's tungsten.",
    "Platinum": "Platinum is mined mostly in South Africa, often in ores along with nickel and copper.",
    "Gold": "Gold is found as pure metal in rock veins and river gravels. It's mined in places like China, Australia, Russia and Canada.",
    "Mercury": "Mercury comes from the red mineral cinnabar (mercury sulfide), which is heated to release mercury vapor.",
    "Lead": "Lead comes mainly from the mineral galena (lead sulfide). Much lead today is recycled from old car batteries.",
    "Uranium": "Uranium is mined from ores like uraninite, with Kazakhstan, Canada and Australia among the biggest producers.",
    "Plutonium": "Almost all plutonium is made in nuclear reactors, when uranium-238 absorbs neutrons.",
    "Neodymium": "Neodymium comes from minerals like bastnäsite and monazite, mined mostly in China, and separated from other rare earth elements.",
}


def main():
    el, series, pt, iso, wiki = se.load()
    el = el.set_index("atomic_number")
    lines = ["# Generated by tools/knowledge/gen/science_elements2.py. Do not edit by hand.",
             "# Sources: mendeleev (MIT), Periodic-Table-JSON from Wikipedia (CC BY-SA 3.0), hand-checked tables.",
             "# tag: science.chem.element"]

    def add(qs, a):
        seen, out = set(), []
        for q in qs:
            q = q.lower().strip()
            if q and q not in seen:
                seen.add(q)
                out.append(q)
        assert len(out) >= 2, qs
        assert "—" not in a and "–" not in a
        lines.append(" | ".join(out[:6]) + " => " + a)

    nat = iso[iso.abundance > 0].groupby("atomic_number")["mass_number"].apply(sorted).to_dict()
    for z in range(1, 119):
        name = el.loc[z, "name"]
        disp = se.BANK_NAME.get(name, name)
        names = [name.lower()] + se.ALT.get(name, [])
        n = names[0]

        # Electronegativity
        a, b = el.loc[z, "en_pauling"], wiki[z].get("electronegativity_pauling")
        if a == a and b is not None and abs(float(a) - float(b)) <= 0.05:
            v = float(b)
            if v >= 3.0:
                note = "That's very high, so it pulls shared electrons strongly."
            elif v <= 1.0:
                note = "That's very low, so it gives up electrons easily."
            elif v < 1.7:
                note = "That's fairly low, typical of a metal."
            else:
                note = "That's in the middle of the range."
            qs = []
            for m in names:
                qs += [f"what is the electronegativity of {m}", f"{m} electronegativity", f"how electronegative is {m}"]
            add(qs, f"{disp} has an electronegativity of {v:.2f} on the Pauling scale. {note}")

        # Natural isotopes
        if z <= 92 and z in nat and z != 73:
            ms = nat[z]
            iso_names = [f"{disp.lower()}-{m}" for m in ms]
            if len(ms) == 1:
                ans = f"{disp} has just one naturally occurring isotope, {iso_names[0]}."
            else:
                listed = ", ".join(iso_names[:-1]) + " and " + iso_names[-1]
                ans = f"{disp} has {len(ms)} naturally occurring isotopes: {listed}."
            ans += ISO_EXTRA.get(name, " Scientists have made many more radioactive ones in labs.")
            qs = []
            for m in names:
                qs += [f"how many isotopes does {m} have", f"what are the isotopes of {m}", f"{m} isotopes"]
            add(qs, ans)

        if name in LOOKS:
            qs = []
            for m in names:
                qs += [f"what does {m} look like", f"what color is {m}", f"{m} appearance"]
            if name == "Mercury":
                qs = ["what does the element mercury look like", "what color is mercury metal", "mercury metal appearance"]
            add(qs, LOOKS[name])

        if name in ION:
            charge, sym, how = ION[name]
            sign = "positive" if "+" in charge else "negative"
            qs = []
            for m in names:
                qs += [f"what is the charge of a {m} ion", f"{m} ion charge", f"what ion does {m} form"]
            add(qs, f"{disp} forms a {sign} ion with a charge of {charge}, written {sym}, by {how}.")
        if name in ION_TEXT:
            add([f"what is the charge of a {n} ion", f"{n} ion charge", f"what ions does {n} form"], ION_TEXT[name])

        if name in SOURCE:
            qs = []
            for m in names:
                qs += [f"where does {m} come from", f"how do we get {m}", f"how is {m} obtained"]
            if name == "Mercury":
                qs = ["where does mercury metal come from", "how do we get mercury metal", "how is the element mercury obtained"]
            add(qs, SOURCE[name])

        if name in MAGNETIC:
            qs = []
            for m in names:
                qs += [f"is {m} magnetic", f"does {m} stick to a magnet", f"are magnets attracted to {m}"]
            add(qs, MAGNETIC[name])

        if name in POISON:
            qs = []
            for m in names:
                qs += [f"is {m} poisonous", f"is {m} toxic", f"is {m} dangerous to touch"]
            if name == "Mercury":
                qs = ["is mercury metal poisonous", "is the element mercury toxic", "is mercury liquid dangerous"]
            if name == "Oxygen":
                qs = ["is oxygen toxic", "can too much oxygen hurt you", "is pure oxygen dangerous"]
            add(qs, POISON[name])

    # Neighbors on the table, and family
    pos = {(int(wiki[z]["xpos"]), int(wiki[z]["ypos"])): z for z in wiki}

    def nm(z):
        n = el.loc[z, "name"]
        return se.BANK_NAME.get(n, n).lower()

    lan, act = range(57, 72), range(89, 104)
    for z in range(1, 119):
        name = el.loc[z, "name"]
        disp = se.BANK_NAME.get(name, name)
        names = [name.lower()] + se.ALT.get(name, [])
        parts = []
        if z == 1:
            parts.append("Hydrogen is element 1, so nothing comes before it. Helium (2) comes after it.")
        elif z == 118:
            parts.append("Before oganesson comes tennessine (117). As of 2025, no element after 118 has been made.")
        else:
            parts.append(f"Before {disp.lower()} comes {nm(z - 1)} ({z - 1}), and after it comes {nm(z + 1)} ({z + 1}).")
        x, y = int(wiki[z]["xpos"]), int(wiki[z]["ypos"])
        above, below = pos.get((x, y - 1)), pos.get((x, y + 1))
        if y == 9:
            above = None
        if y == 1 or (y == 10 and False):
            above = None
        if y == 7:
            below = None
        if above and below:
            parts.append(f"In its column, {nm(above)} is above it and {nm(below)} is below it.")
        elif above:
            parts.append(f"In its column, {nm(above)} is above it.")
        elif below:
            parts.append(f"In its column, {nm(below)} is below it.")
        qs = []
        for m in names:
            qs += [f"what element comes after {m}", f"what element comes before {m}", f"what is next to {m} on the periodic table"]
        add(qs, " ".join(parts))

        g = el.loc[z, "group_id"]
        if z in lan:
            fam = f"{disp} is a lanthanide, one of the 15 elements from lanthanum to lutetium in the first row below the main table. They're also called rare earth metals and behave a lot alike."
        elif z in act:
            fam = f"{disp} is an actinide, one of the 15 radioactive elements from actinium to lawrencium in the second row below the main table."
        elif z == 1:
            fam = "Hydrogen sits at the top of group 1, but it isn't an alkali metal. It's a nonmetal gas, so it's often treated as a family of its own."
        else:
            g = int(g)
            mates = [nm(k) for k in range(1, 119) if k != z and el.loc[k, "group_id"] == el.loc[k, "group_id"]
                     and int(el.loc[k, "group_id"]) == g and k not in lan and k not in act and k != 1]
            label = {1: "an alkali metal", 2: "an alkaline earth metal", 13: "in the boron group",
                     14: "in the carbon group", 15: "in the nitrogen group", 16: "in the oxygen group, also called the chalcogens",
                     17: "a halogen", 18: "a noble gas"}.get(g, "a transition metal")
            if z >= 104 and g in range(3, 13):
                label = "a transition metal, though too few atoms have been made to test most of its chemistry"
            if z in (113, 114, 115, 116, 117, 118):
                label = {113: "in the boron group", 114: "in the carbon group", 115: "in the nitrogen group",
                         116: "in the oxygen group", 117: "in the halogen group", 118: "in the noble gas group"}[z] + \
                        ", though too few atoms have been made to know how it really behaves"
            lst = ", ".join(mates[:-1]) + " and " + mates[-1] if len(mates) > 1 else mates[0]
            fam = f"{disp} is {label}. It's in group {g} with {lst}."
            if label.startswith("in "):
                fam = f"{disp} is {label}. It's in group {g} with {lst}."
            if z not in (113, 114, 115, 116, 117, 118) and z < 104:
                fam += " Elements in the same group have similar chemical properties."
        qs = []
        for m in names:
            qs += [f"what family is {m} in", f"what elements are in the same group as {m}", f"elements similar to {m}"]
        add(qs, fam.replace("is in the", "is in the"))

    # How common in Earth's crust (CRC Handbook values, via mendeleev)
    from decimal import Decimal, ROUND_HALF_UP

    def sig2(x):
        d = Decimal(repr(x))
        q = Decimal(1).scaleb(d.adjusted() - 1)
        r = d.quantize(q, rounding=ROUND_HALF_UP)
        return f"{r:,f}".rstrip("0").rstrip(".") if "." in f"{r:f}" else f"{int(r):,}"

    def ordinal(n):
        suf = "th" if 10 <= n % 100 <= 20 else {1: "st", 2: "nd", 3: "rd"}.get(n % 10, "th")
        return f"{n}{suf}"

    ab = el["abundance_crust"].dropna().sort_values(ascending=False)
    rank = {z: i + 1 for i, z in enumerate(ab.index)}
    for z, v in ab.items():
        if v < 0.0001 or z > 92:
            continue
        name = el.loc[z, "name"]
        disp = se.BANK_NAME.get(name, name)
        if v >= 1000:
            amt = f"about {sig2(v / 10000)}% of Earth's crust by mass"
        elif v >= 1:
            amt = f"about {sig2(v)} parts per million of Earth's crust by mass"
        elif v >= 0.001:
            amt = f"about {sig2(v * 1000)} parts per billion of Earth's crust by mass"
        else:
            amt = "less than one part per billion of Earth's crust by mass"
        r = rank[z]
        a = f"{disp} makes up {amt}, making it the {ordinal(r)} most common element there."
        if r == 1:
            a = f"{disp} makes up {amt}, making it the most common element there."
        if v < 1:
            a += " That makes it rare."
        qs = []
        for m in [name.lower()] + se.ALT.get(name, []):
            qs += [f"how common is {m}", f"how much {m} is in earths crust", f"is {m} rare"]
        add(qs, a)

    with open(OUT, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print(f"wrote {len(lines) - 3} entries to {OUT}")


if __name__ == "__main__":
    main()
