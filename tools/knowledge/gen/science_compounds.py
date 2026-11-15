#!/usr/bin/env python3
"""Writes data/science/gen_compounds.txt: common chemical compounds, their formulas,
what atoms are in them, their molar mass and what they are.

Data sources
  - Formulas and descriptions: hand-written table below (well known school chemistry).
  - Atomic weights for molar masses: mendeleev Python package (MIT license,
    https://github.com/lmmentel/mendeleev), which uses IUPAC standard atomic weights.

Run from the repo root:  python3 tools/knowledge/gen/science_compounds.py
"""
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, "..", "data", "science", "gen_compounds.txt"))

# (name, other names, formula, description). The description starts with the name or "It".
COMPOUNDS = [
    ("water", ["dihydrogen monoxide"], "H2O", "Water is the most important compound for life. It covers about 71% of Earth's surface and makes up roughly 60% of your body."),
    ("hydrogen peroxide", [], "H2O2", "Hydrogen peroxide is a mild antiseptic and bleach. It breaks down into water and oxygen, which is why it fizzes on a cut."),
    ("sodium chloride", ["table salt", "salt"], "NaCl", "Sodium chloride is table salt. It's made of sodium ions and chloride ions packed into cube shaped crystals."),
    ("carbon dioxide", [], "CO2", "Carbon dioxide is the gas you breathe out and plants take in for photosynthesis. It's also a greenhouse gas and makes soda fizzy."),
    ("carbon monoxide", [], "CO", "Carbon monoxide is a poisonous gas with no color or smell, made when fuel burns without enough oxygen. That's why homes have CO detectors."),
    ("oxygen gas", [], "O2", "Oxygen gas is two oxygen atoms bonded together. It's about 21% of the air, and you need it to live."),
    ("ozone", [], "O3", "Ozone is a form of oxygen with three atoms. High in the sky it blocks harmful UV light, but near the ground it's a pollutant."),
    ("nitrogen gas", [], "N2", "Nitrogen gas is two nitrogen atoms joined by a strong triple bond. It makes up about 78% of the air."),
    ("hydrogen gas", [], "H2", "Hydrogen gas is two hydrogen atoms bonded together. It's the lightest gas and burns to make water."),
    ("chlorine gas", [], "Cl2", "Chlorine gas is a toxic yellow green gas made of two chlorine atoms. It's used to make bleach and to clean water."),
    ("ammonia", [], "NH3", "Ammonia is a strong smelling gas used mainly to make fertilizer. Weak ammonia solutions are used in some household cleaners."),
    ("methane", ["natural gas"], "CH4", "Methane is the main part of natural gas, used for cooking and heating. Cows and swamps give it off, and it's a strong greenhouse gas."),
    ("ethane", [], "C2H6", "Ethane is a gas found in natural gas. It's mainly used to make ethylene for plastics."),
    ("propane", [], "C3H8", "Propane is the gas in barbecue tanks and camping stoves. It's stored as a liquid under pressure."),
    ("butane", [], "C4H10", "Butane is the fuel in lighters and some camping stoves."),
    ("octane", [], "C8H18", "Octane is one of the main compounds in petrol (gasoline). The octane rating on fuel pumps is named after it."),
    ("ethanol", ["alcohol", "ethyl alcohol"], "C2H5OH", "Ethanol is the alcohol in drinks, made when yeast ferments sugar. It's also used as a fuel and in hand sanitizer."),
    ("methanol", ["methyl alcohol", "wood alcohol"], "CH3OH", "Methanol is a simple alcohol used as a fuel and to make plastics. It's very poisonous to drink."),
    ("glucose", ["blood sugar"], "C6H12O6", "Glucose is the sugar your cells burn for energy. Plants make it in photosynthesis."),
    ("sucrose", ["table sugar", "sugar"], "C12H22O11", "Sucrose is regular table sugar, made from sugar cane or sugar beets. It's one glucose joined to one fructose."),
    ("fructose", ["fruit sugar"], "C6H12O6", "Fructose is the sugar in fruit and honey. It has the same formula as glucose but its atoms are arranged differently."),
    ("sodium bicarbonate", ["baking soda", "sodium hydrogen carbonate"], "NaHCO3", "Sodium bicarbonate is baking soda. It makes cakes rise by giving off carbon dioxide, and fizzes with vinegar."),
    ("sodium carbonate", ["washing soda", "soda ash"], "Na2CO3", "Sodium carbonate is washing soda. It's used to make glass and to soften water for laundry."),
    ("calcium carbonate", ["chalk", "limestone"], "CaCO3", "Calcium carbonate is what chalk, limestone, marble, eggshells and seashells are made of. It's also in antacid tablets."),
    ("calcium oxide", ["quicklime", "lime"], "CaO", "Calcium oxide, or quicklime, is made by heating limestone. It's used to make cement and steel."),
    ("calcium hydroxide", ["slaked lime", "limewater"], "Ca(OH)2", "Calcium hydroxide is slaked lime. Dissolved in water it's limewater, which turns cloudy when carbon dioxide bubbles through."),
    ("hydrochloric acid", [], "HCl", "Hydrochloric acid is a strong acid. Your stomach makes it to help digest food and kill germs."),
    ("sulfuric acid", ["sulphuric acid", "battery acid"], "H2SO4", "Sulfuric acid is a strong, dangerous acid used in car batteries and to make fertilizer. More of it is made than any other industrial chemical."),
    ("nitric acid", [], "HNO3", "Nitric acid is a strong acid used to make fertilizers and explosives."),
    ("phosphoric acid", [], "H3PO4", "Phosphoric acid is used in fertilizers, rust removers and cola drinks, where it adds a tangy taste."),
    ("acetic acid", ["ethanoic acid"], "CH3COOH", "Acetic acid is the acid in vinegar, which is usually about 5% acetic acid in water."),
    ("citric acid", [], "C6H8O7", "Citric acid is the acid that makes lemons and limes sour. It's used in sweets, drinks and cleaning products."),
    ("carbonic acid", [], "H2CO3", "Carbonic acid forms when carbon dioxide dissolves in water. It gives soda its slightly sour bite."),
    ("ascorbic acid", ["vitamin c"], "C6H8O6", "Ascorbic acid is vitamin C, found in oranges, peppers and strawberries. Your body needs it for healthy skin and gums."),
    ("lactic acid", [], "C3H6O3", "Lactic acid is in sour milk and yogurt. Your muscles also make it when they work hard with little oxygen."),
    ("sodium hydroxide", ["lye", "caustic soda"], "NaOH", "Sodium hydroxide, or lye, is a strong base used to make soap and to unclog drains. It can badly burn skin."),
    ("potassium hydroxide", ["caustic potash"], "KOH", "Potassium hydroxide is a strong base used in alkaline batteries and to make soft soaps."),
    ("magnesium hydroxide", ["milk of magnesia"], "Mg(OH)2", "Magnesium hydroxide is the base in milk of magnesia, used to calm an upset stomach."),
    ("aluminium oxide", ["aluminum oxide", "alumina"], "Al2O3", "Aluminium oxide is a very hard compound. Rubies and sapphires are crystals of it, and it's used in sandpaper."),
    ("iron oxide", ["rust", "iron iii oxide"], "Fe2O3", "Iron(III) oxide is the main part of rust. It forms when iron reacts with oxygen and water."),
    ("magnetite", ["iron ii iii oxide", "lodestone"], "Fe3O4", "Magnetite is a naturally magnetic iron oxide. Pieces called lodestones were used in the first compasses."),
    ("copper sulfate", ["copper ii sulfate", "blue vitriol"], "CuSO4", "Copper(II) sulfate forms bright blue crystals when it has water in it. It's used to kill algae and fungus and in school crystal growing."),
    ("silicon dioxide", ["silica", "quartz"], "SiO2", "Silicon dioxide, or silica, is what quartz and most sand are made of. It's the main ingredient in glass."),
    ("titanium dioxide", [], "TiO2", "Titanium dioxide is a bright white powder used in paint, toothpaste and sunscreen."),
    ("zinc oxide", [], "ZnO", "Zinc oxide is the white cream in many sunscreens and diaper rash creams. It blocks UV light."),
    ("sodium hypochlorite", ["bleach"], "NaOCl", "Sodium hypochlorite is household bleach. Never mix it with ammonia or acids, because that makes toxic gases."),
    ("potassium chloride", [], "KCl", "Potassium chloride is used in salt substitutes and fertilizers."),
    ("potassium nitrate", ["saltpeter", "saltpetre"], "KNO3", "Potassium nitrate, or saltpeter, is used in fertilizer and was a key part of old gunpowder."),
    ("ammonium nitrate", [], "NH4NO3", "Ammonium nitrate is a common fertilizer. It can also explode, so it's stored carefully."),
    ("calcium chloride", [], "CaCl2", "Calcium chloride is spread on roads to melt ice, and it soaks up moisture in damp rooms."),
    ("magnesium sulfate", ["epsom salt", "epsom salts"], "MgSO4", "Magnesium sulfate is Epsom salt, which people put in baths to soak sore muscles. Epsom salt crystals also contain water."),
    ("sodium fluoride", [], "NaF", "Sodium fluoride is added to toothpaste and some drinking water to help protect teeth from decay."),
    ("nitrous oxide", ["laughing gas"], "N2O", "Nitrous oxide is laughing gas, used by dentists to help people relax. It's also used in whipped cream cans."),
    ("nitrogen dioxide", [], "NO2", "Nitrogen dioxide is a brown, toxic gas from car exhausts. It adds to smog and acid rain."),
    ("sulfur dioxide", [], "SO2", "Sulfur dioxide is a choking gas from volcanoes and burning coal. It causes acid rain, and small amounts preserve dried fruit."),
    ("hydrogen sulfide", [], "H2S", "Hydrogen sulfide is the toxic gas that smells like rotten eggs."),
    ("calcium sulfate", ["gypsum"], "CaSO4", "Calcium sulfate is the main part of gypsum (which also holds water), used to make plaster and drywall."),
    ("silver nitrate", [], "AgNO3", "Silver nitrate was used in old photography. It stains skin black where light hits it."),
    ("potassium permanganate", [], "KMnO4", "Potassium permanganate forms deep purple crystals. It's used to disinfect water and kill germs."),
    ("acetone", ["propanone"], "C3H6O", "Acetone is the solvent in most nail polish remover. It evaporates quickly and is very flammable."),
    ("benzene", [], "C6H6", "Benzene is a ring of six carbon atoms, each with a hydrogen. It's used to make plastics but is toxic and can cause cancer."),
    ("ethylene", ["ethene"], "C2H4", "Ethylene is a gas used to make polyethylene, the most common plastic. Fruits also give it off as they ripen."),
    ("acetylene", ["ethyne"], "C2H2", "Acetylene is a gas that burns extremely hot with oxygen, so it's used in welding torches."),
    ("chloroform", [], "CHCl3", "Chloroform was used to put patients to sleep for surgery in the 1800s. Today it's used as a lab solvent."),
    ("formaldehyde", ["methanal"], "CH2O", "Formaldehyde is a strong smelling gas. Dissolved in water, it's used to preserve specimens."),
    ("urea", ["carbamide"], "CO(NH2)2", "Urea is the main waste in urine and a common fertilizer. In 1828 it was the first natural compound made in a lab from non-living stuff."),
    ("caffeine", [], "C8H10N4O2", "Caffeine is the stimulant in coffee, tea, energy drinks and chocolate. It helps you feel awake."),
    ("aspirin", ["acetylsalicylic acid"], "C9H8O4", "Aspirin is a medicine for pain, fever and swelling. It was first made from a compound found in willow bark."),
    ("glycerol", ["glycerin", "glycerine"], "C3H8O3", "Glycerol is a sweet, thick liquid used in soap, lotions and some foods to keep them moist."),
    ("ethylene glycol", [], "C2H6O2", "Ethylene glycol is the main part of car antifreeze. It's sweet tasting but very poisonous."),
    ("sulfur hexafluoride", [], "SF6", "Sulfur hexafluoride is a very heavy gas. Breathing it makes your voice deep, the opposite of helium."),
    ("silver chloride", [], "AgCl", "Silver chloride is a white solid that darkens in light. It was used in early photography."),
    ("copper oxide", ["copper ii oxide"], "CuO", "Copper(II) oxide is a black powder. It forms on copper when it's heated in air."),
    ("magnesium oxide", [], "MgO", "Magnesium oxide is the white powder made when magnesium burns. It's used in heat resistant bricks and as an antacid."),
    ("sodium nitrate", [], "NaNO3", "Sodium nitrate is used as fertilizer and to preserve meats."),
    ("ammonium chloride", [], "NH4Cl", "Ammonium chloride is used in batteries, as a flux for soldering, and in salty licorice."),
    ("boric acid", [], "H3BO3", "Boric acid is a weak acid used as an insecticide against cockroaches and as a mild antiseptic."),
    ("silicon carbide", ["carborundum"], "SiC", "Silicon carbide is extremely hard. It's used in sandpaper, cutting tools and car brakes."),
    ("tungsten carbide", [], "WC", "Tungsten carbide is much harder and stiffer than steel. It's used for drill bits and cutting tools."),
    ("hydrogen fluoride", ["hydrofluoric acid"], "HF", "Hydrogen fluoride dissolves in water to make hydrofluoric acid, which can eat through glass and is very dangerous."),
    ("hydrogen cyanide", [], "HCN", "Hydrogen cyanide is an extremely poisonous gas that smells a bit like bitter almonds."),
    ("sodium azide", [], "NaN3", "Sodium azide was used in car airbags. It breaks down into nitrogen gas in a split second and fills the bag."),
    ("nitroglycerin", ["nitroglycerine"], "C3H5N3O9", "Nitroglycerin is a powerful explosive. Alfred Nobel made it safer by turning it into dynamite. It's also a heart medicine."),
    ("trinitrotoluene", ["tnt"], "C7H5N3O6", "TNT is an explosive used in mining and the military. Big explosions are often measured in tons of TNT."),
    ("potassium iodide", [], "KI", "Potassium iodide is added to iodized salt. It's also taken to protect the thyroid after a nuclear accident."),
    ("sodium thiosulfate", [], "Na2S2O3", "Sodium thiosulfate is used in photography to fix photos and to remove chlorine from aquarium water."),
    ("heavy water", ["deuterium oxide"], "D2O", "Heavy water is water made with deuterium, a heavier form of hydrogen. It's used in some nuclear reactors."),
    ("lead sulfide", ["galena"], "PbS", "Lead(II) sulfide is the mineral galena, the main ore of lead. It forms shiny gray cubes."),
    ("iron sulfide", ["pyrite", "fools gold"], "FeS2", "Iron disulfide is pyrite, also called fool's gold because its shiny gold color tricked miners."),
    ("calcium phosphate", [], "Ca3(PO4)2", "Calcium phosphate is used in fertilizers and as a food additive. A form of it called hydroxyapatite makes up most of your bones and teeth."),
    ("lithium cobalt oxide", [], "LiCoO2", "Lithium cobalt oxide is used in the positive side of many lithium ion batteries, like in phones and laptops."),
    ("carbon tetrachloride", [], "CCl4", "Carbon tetrachloride was once used in fire extinguishers and dry cleaning, but it's toxic and harms the ozone layer."),
    ("sodium sulfate", [], "Na2SO4", "Sodium sulfate is used to make laundry detergent, glass and paper."),
    ("ammonium sulfate", [], "(NH4)2SO4", "Ammonium sulfate is a fertilizer that adds both nitrogen and sulfur to soil."),
    ("lithium hydroxide", [], "LiOH", "Lithium hydroxide is used in spacecraft and submarines to remove carbon dioxide from the air, and in making batteries."),
    ("sodium silicate", ["water glass"], "Na2SiO3", "Sodium silicate, or water glass, is used in cements, in detergents, and was once used to preserve eggs."),
    ("ethyl acetate", [], "C4H8O2", "Ethyl acetate is a sweet smelling solvent used in some nail polish removers and glues."),
    ("tin oxide", ["tin iv oxide", "cassiterite"], "SnO2", "Tin(IV) oxide is the main tin ore, cassiterite. It's also used in glazes and touchscreens."),
    ("chromium oxide", ["chromium iii oxide"], "Cr2O3", "Chromium(III) oxide is a green pigment used in paints and inks."),
    ("manganese dioxide", [], "MnO2", "Manganese dioxide is used in regular alkaline batteries. In labs it speeds up the breakdown of hydrogen peroxide."),
]

EXTRA_FACTS = []


def load_weights():
    from mendeleev.fetch import fetch_table
    el = fetch_table("elements")
    w = {r.symbol: float(r.atomic_weight) for _, r in el.iterrows()}
    names = {r.symbol: r["name"].lower() for _, r in el.iterrows()}
    w["D"] = 2.014
    names["D"] = "deuterium"
    names["Al"] = "aluminium"
    return w, names


def parse(formula):
    """Counts atoms in a formula like Ca(OH)2 or CH3COOH. Returns (order, counts)."""
    tokens = re.findall(r"([A-Z][a-z]?|\(|\)|\d+)", formula)
    stack = [dict()]
    order = []
    i = 0
    while i < len(tokens):
        t = tokens[i]
        if t == "(":
            stack.append(dict())
        elif t == ")":
            group = stack.pop()
            mult = 1
            if i + 1 < len(tokens) and tokens[i + 1].isdigit():
                mult = int(tokens[i + 1])
                i += 1
            for k, v in group.items():
                stack[-1][k] = stack[-1].get(k, 0) + v * mult
        elif t.isdigit():
            pass
        else:
            n = 1
            if i + 1 < len(tokens) and tokens[i + 1].isdigit():
                n = int(tokens[i + 1])
                i += 1
            stack[-1][t] = stack[-1].get(t, 0) + n
            if t not in order:
                order.append(t)
        i += 1
    return order, stack[0]


def atoms_text(order, counts, names):
    parts = []
    for s in order:
        c = counts[s]
        parts.append(f"{c} {names[s]} atom{'s' if c != 1 else ''}")
    if len(parts) == 1:
        return parts[0]
    return ", ".join(parts[:-1]) + " and " + parts[-1]



BOND_METALS = {"Li", "Na", "K", "Mg", "Ca", "Ba", "Al", "Fe", "Cu", "Zn", "Ag", "Ti", "Sn", "Cr", "Mn"}
BOND_SKIP = {"oxygen gas", "ozone", "nitrogen gas", "hydrogen gas", "chlorine gas", "tungsten carbide", "lead sulfide",
             "iron sulfide", "magnetite", "lithium cobalt oxide", "heavy water"}
POLYATOMIC = {"carbonate", "bicarbonate", "hydroxide", "sulfate", "nitrate", "phosphate", "hypochlorite",
              "permanganate", "azide", "thiosulfate", "silicate"}
NETWORK = {"silicon dioxide", "silicon carbide"}


def bond_text(name, f, counts, names):
    """Ionic or covalent, from whether the compound has a metal or ammonium ion. Returns None to skip."""
    if name in BOND_SKIP:
        return None
    disp = name[0].upper() + name[1:]
    metals = [s for s in counts if s in BOND_METALS]
    if "ammonium" in name or metals:
        if "ammonium" in name:
            cation = "ammonium"
        else:
            cation = names[metals[0]].lower()
            cation = {"aluminum": "aluminium"}.get(cation, cation)
        anion = name.split()[-1].replace("dioxide", "oxide")
        a = f"{disp} ({f}) is ionic. It's made of {cation} ions and {anion} ions, held together by the pull between opposite charges."
        poly = [x for x in (cation, anion) if x in POLYATOMIC or x == "ammonium"]
        if len(poly) == 2:
            a += f" The atoms inside the {poly[0]} and {poly[1]} ions are held together by covalent bonds."
        elif poly:
            a += f" The atoms inside the {poly[0]} ion are held together by covalent bonds."
        return a
    if "acid" in name:
        return f"{disp} ({f}) is a covalent compound, but in water it breaks apart into ions, which is what makes it an acid."
    if name in NETWORK:
        return (f"{disp} ({f}) is covalent. It forms a giant network of atoms all joined by covalent bonds, "
                f"which makes it very hard with a very high melting point.")
    return f"{disp} ({f}) is covalent. Its atoms share electrons to form molecules."


def main():
    w, names = load_weights()
    lines = ["# Generated by tools/knowledge/gen/science_compounds.py. Do not edit by hand.",
             "# tag: science.chem.compound"]
    count = 0
    formula_users = {}
    for name, alts, f, desc in COMPOUNDS:
        formula_users.setdefault(f, []).append(name)
    done_formula = set()

    def add(qs, a):
        nonlocal count
        out = []
        for q in qs:
            q = q.lower().strip()
            if q not in out:
                out.append(q)
        assert len(out) >= 2, qs
        lines.append(" | ".join(out[:6]) + " => " + a)
        count += 1

    for name, alts, f, desc in COMPOUNDS:
        if desc is None:
            continue
        order, counts = parse(f)
        total = sum(counts.values())
        mass = sum(w[s] * c for s, c in counts.items())
        alt = alts[0] if alts else name
        disp = name[0].upper() + name[1:]
        # formula
        a = (f"The chemical formula for {name} is {f}. Each molecule or unit has {atoms_text(order, counts, names)}"
             f" ({total} atoms in all).")
        if name in ("sodium chloride", "potassium chloride", "calcium chloride", "sodium fluoride", "potassium iodide",
                    "silver chloride", "magnesium oxide", "calcium oxide", "zinc oxide", "copper oxide"):
            a = (f"The chemical formula for {name} is {f}. It's an ionic compound, with "
                 f"{atoms_text(order, counts, names).replace(' atoms', '').replace(' atom', '')} in each formula unit.")
        qs = [f"what is the chemical formula for {name}", f"{name} formula", f"formula of {alt}",
              f"whats the formula for {alt}", f"how do you write {name} in chemistry"]
        add(qs, a)
        # reverse
        fl = f.lower()
        if f not in done_formula:
            done_formula.add(f)
            users = formula_users[f]
            if len(users) > 1 and f == "C6H12O6":
                a = ("C6H12O6 is the formula for glucose, the sugar your cells use for energy. Fructose and galactose "
                     "have the same formula with the atoms arranged differently.")
            else:
                a = f"{f} is the formula for {name}" + (f", also called {alts[0]}." if alts and alts[0] != name else ".")
            add([f"what is {fl}", f"what compound is {fl}", f"what does {fl} stand for", f"{fl} chemical name"], a)
        # molar mass
        ms = f"{mass:.2f}"
        add([f"what is the molar mass of {name}", f"molar mass of {alt}", f"{name} molecular weight",
             f"how many grams in a mole of {name}"],
            f"The molar mass of {name} ({f}) is about {ms} g/mol. So one mole of it weighs about {ms} grams.")
        # what is it
        qs = [f"what is {name}", f"what is {name} used for", f"tell me about {alt}", f"what is {alt}"]
        if alt != name:
            qs.append(f"what is {alt} made of")
        add(qs, desc)
        # bond type
        bond = bond_text(name, f, counts, names)
        if bond:
            add([f"is {name} ionic or covalent", f"is {alt} ionic or covalent", f"what type of bonding is in {name}",
                 f"is {fl} ionic or covalent"], bond)
    with open(OUT, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines) + "\n")
    print(f"wrote {count} entries to {OUT}")


if __name__ == "__main__":
    main()
