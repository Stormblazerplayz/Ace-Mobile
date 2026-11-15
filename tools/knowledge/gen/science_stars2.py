#!/usr/bin/env python3
"""Writes data/science/gen_stars2.txt (bright named stars) and gen_skyguide.txt (when and
where each constellation can be seen).

Data sources, downloaded once to tools/knowledge/.cache/dl/:
  1. HYG Database v3.8 by David Nash (astronexus), CC BY-SA 4.0,
     https://github.com/astronexus/HYG-Database : star names, constellations, Bayer letters,
     distances (from Hipparcos parallaxes) and spectral types.
  2. d3-celestial by Olaf Frohn, BSD-3-Clause, https://github.com/ofrohn/d3-celestial :
     constellation names, Latin genitives and center coordinates.
  Checks: distances are only written for stars closer than 100 parsecs (about 326 light
  years), where Hipparcos parallaxes are good. Spectral types were checked by hand, and the
  few that HYG gets wrong for multiple stars are fixed in FIX_SPECT. The 20 stars already in
  gen_stars.txt and the Sun are skipped.
  The best viewing month is worked out from each constellation's right ascension: a point in
  the sky is highest at about 9 pm when the Sun's right ascension is 9 hours less than it.

Run from the repo root:  python3 tools/knowledge/gen/science_stars2.py
"""
import csv
import gzip
import json
import os
import re
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
KN = os.path.normpath(os.path.join(HERE, ".."))
DL = os.path.join(KN, ".cache", "dl")
OUT_STARS = os.path.join(KN, "data", "science", "gen_stars2.txt")
OUT_SKY = os.path.join(KN, "data", "science", "gen_skyguide.txt")
HYG_URL = "https://raw.githubusercontent.com/astronexus/HYG-Database/main/hyg/v3/hyg_v38.csv.gz"
CON_URL = "https://raw.githubusercontent.com/ofrohn/d3-celestial/master/data/constellations.json"

SKIP = {"Sol", "Sirius", "Canopus", "Arcturus", "Rigil Kentaurus", "Toliman", "Vega", "Capella", "Rigel",
        "Procyon", "Betelgeuse", "Altair", "Aldebaran", "Spica", "Antares", "Pollux", "Fomalhaut",
        "Deneb", "Regulus", "Castor", "Cih", "Tiaki", "Larawag", "Alsephina", "Aljanah"}
EXTRA_NAMES = {"Mizar", "Alcor", "Algol", "Mira", "Thuban", "Albireo", "Merak", "Phecda", "Megrez",
               "Polaris", "Mintaka", "Vindemiatrix", "Alcyone", "Atlas", "Electra", "Maia", "Merope",
               "Taygeta", "Pleione", "Zubenelgenubi", "Rasalgethi"}
# Names that are also ordinary words, so wordings say "the star ...".
AMBIG = {"Atlas", "Electra", "Maia", "Merope", "Peacock", "Mira", "Polaris", "Naos", "Markab", "Avior",
         "Diphda", "Caph", "Izar", "Enif"}
FIX_SPECT = {"Dubhe": "K0III", "Izar": "K0II-III", "Almach": "K3II", "Mira": "M7III"}

EXTRA = {
    "Polaris": "It's the North Star: it sits almost exactly above Earth's North Pole, so it barely moves while other stars circle around it.",
    "Algol": "It's called the Demon Star because it dims noticeably every 2.87 days, when its dimmer partner star passes in front of it.",
    "Mira": "It's a famous variable star that brightens and fades over about 11 months, sometimes easy to see and sometimes invisible without a telescope.",
    "Mizar": "With its fainter neighbor Alcor, it makes a famous naked-eye pair in the handle of the Big Dipper, and it was one of the first double stars seen through a telescope.",
    "Alcor": "It sits next to Mizar in the handle of the Big Dipper, and spotting the pair was once used as an eyesight test.",
    "Thuban": "About 4,700 years ago, when the Egyptian pyramids were built, Thuban was the North Star, because Earth's axis slowly wobbles.",
    "Albireo": "Through a small telescope, it splits into a beautiful pair of gold and blue stars.",
    "Alcyone": "It's the brightest star in the Pleiades star cluster.",
    "Dubhe": "With Merak, it forms the Pointers of the Big Dipper, which point to Polaris.",
    "Merak": "With Dubhe, it forms the Pointers of the Big Dipper, which point to Polaris.",
    "Alnitak": "It's the left-hand star of Orion's Belt as seen from the Northern Hemisphere.",
    "Alnilam": "It's the middle star of Orion's Belt.",
    "Mintaka": "It's the right-hand star of Orion's Belt as seen from the Northern Hemisphere.",
    "Achernar": "It spins so fast that it's flattened, much wider at its equator than from pole to pole.",
    "Acrux": "It's the brightest star in the Southern Cross, which appears on the flags of Australia, New Zealand and Brazil.",
    "Hadar": "With Rigil Kentaurus, it forms the Pointers that lead to the Southern Cross.",
    "Shaula": "It marks the stinger at the end of the Scorpion's tail.",
    "Denebola": "Its name means the lion's tail, and it marks the tail of Leo.",
    "Alphard": "Its name means the solitary one, because it sits alone in a dim area of sky.",
    "Gacrux": "It's the star at the top of the Southern Cross.",
    "Naos": "It's one of the hottest and most massive stars you can see without a telescope.",
    "Alpheratz": "It's shared by Andromeda and the Great Square of Pegasus.",
    "Kochab": "With Pherkad, it's one of the two Guardians of the Pole at the end of the Little Dipper's bowl.",
    "Eltanin": "It marks the head of Draco the dragon.",
    "Schedar": "It's one of the five bright stars that make Cassiopeia's W shape.",
    "Caph": "It's one of the five bright stars that make Cassiopeia's W shape.",
    "Alkaid": "It's the star at the end of the Big Dipper's handle.",
    "Alioth": "It's the brightest star in the Big Dipper.",
}

GREEK = {"Alp": "Alpha", "Bet": "Beta", "Gam": "Gamma", "Del": "Delta", "Eps": "Epsilon", "Zet": "Zeta",
         "Eta": "Eta", "The": "Theta", "Iot": "Iota", "Kap": "Kappa", "Lam": "Lambda", "Mu": "Mu", "Nu": "Nu",
         "Xi": "Xi", "Omi": "Omicron", "Pi": "Pi", "Rho": "Rho", "Sig": "Sigma", "Tau": "Tau",
         "Ups": "Upsilon", "Phi": "Phi", "Chi": "Chi", "Psi": "Psi", "Ome": "Omega"}
COLOR = {"O": "blue", "B": "blue-white", "A": "white", "F": "yellowish white", "G": "yellow", "K": "orange", "M": "red"}
LUM = [("III", "giant"), ("IV-V", "main sequence"), ("Iab", "supergiant"), ("Ia", "supergiant"),
       ("Ib", "supergiant"), ("IA", "supergiant"), ("II", "bright giant"), ("IV", "subgiant"), ("V", "main sequence"),
       ("I", "supergiant")]
MONTHS = ["January", "February", "March", "April", "May", "June", "July", "August", "September",
          "October", "November", "December"]
MONTH_START = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]


def fetch():
    os.makedirs(DL, exist_ok=True)
    for url, name in ((HYG_URL, "hyg.csv.gz"), (CON_URL, "constellations.json")):
        p = os.path.join(DL, name)
        if not os.path.exists(p):
            urllib.request.urlretrieve(url, p)


def star_type(spect):
    m = re.match(r"^([OBAFGKM])[\d.]*:?\s*(.*)$", spect)
    if not m:
        return None
    color = COLOR[m.group(1)]
    rest = m.group(2)
    kind = None
    for code, label in LUM:
        if rest.startswith(code):
            kind = label
            break
    return color, kind


def art(word):
    return "an" if word[0] in "aeiou" else "a"


def ly_text(pc):
    ly = pc * 3.26156
    if ly < 20:
        return f"{ly:.1f}"
    if ly < 100:
        return f"{round(ly)}"
    return f"{round(ly / 10) * 10}"


def add(lines, qs, a):
    seen, out = set(), []
    for q in qs:
        q = q.lower().replace("'", "").strip()
        if q not in seen:
            seen.add(q)
            out.append(q)
    assert len(out) >= 2 and "—" not in a and "–" not in a
    lines.append(" | ".join(out[:6]) + " => " + a)


def main():
    fetch()
    cons = {f["id"]: f["properties"] for f in json.load(open(os.path.join(DL, "constellations.json"), encoding="utf-8"))["features"]}

    # Stars
    lines = ["# Generated by tools/knowledge/gen/science_stars2.py. Do not edit by hand.",
             "# Sources: HYG Database v3.8 (CC BY-SA 4.0), d3-celestial (BSD-3-Clause), hand-checked.",
             "# tag: science.space.star"]
    rows = [r for r in csv.DictReader(gzip.open(os.path.join(DL, "hyg.csv.gz"), "rt", encoding="utf-8")) if r["proper"]]
    rows = [r for r in rows if r["proper"] not in SKIP and (float(r["mag"]) <= 2.6 or r["proper"] in EXTRA_NAMES)]
    rows.sort(key=lambda r: float(r["mag"]))
    for r in rows:
        name = r["proper"]
        n = name.lower()
        ref = f"the star {n}" if name in AMBIG else n
        con = cons[r["con"]]
        bayer = ""
        if r["bayer"]:
            g = GREEK[r["bayer"].split("-")[0]]
            bayer = f" Its scientific name is {g} {con['gen']}."
        add(lines, [f"what constellation is {ref} in", f"which constellation is {ref} in", f"where is {ref} in the sky"],
            f"{name} is in the constellation {con['name']}.{bayer}")

        t = star_type(FIX_SPECT.get(name, r["spect"]))
        if t:
            color, kind = t
            if kind == "main sequence":
                desc = f"{name} is a {color} main sequence star, which means it's burning hydrogen in its core like the Sun."
            elif kind:
                desc = f"{name} is {art(color)} {color} {kind} star."
            else:
                desc = f"{name} is {art(color)} {color} star."
            if name in EXTRA:
                desc += " " + EXTRA[name]
            add(lines, [f"what type of star is {ref}", f"what color is the star {n}", f"what kind of star is {ref}"], desc)

        pc = float(r["dist"])
        if 0 < pc < 100:
            ly = ly_text(pc)
            add(lines, [f"how far away is the star {n}" if name in AMBIG else f"how far away is {n}",
                        f"how far is {ref} from earth", f"distance to {ref}"],
                f"{name} is about {ly} light years away, so the light you see left it about {ly} years ago.")

    with open(OUT_STARS, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print(f"wrote {len(lines) - 3} entries to {OUT_STARS}")

    # Constellations: when and from where
    lines = ["# Generated by tools/knowledge/gen/science_stars2.py. Do not edit by hand.",
             "# Source: d3-celestial constellation centers (BSD-3-Clause), viewing month worked out from right ascension.",
             "# tag: science.space.constellation"]
    for cid, p in sorted(cons.items(), key=lambda kv: kv[1]["name"]):
        name = p["name"]
        n = name.lower()
        ra_deg, dec = p["display"][0], p["display"][1]
        ra_h = (ra_deg % 360) / 15.0
        day = (79 + ((ra_h - 9) % 24) * 15.22) % 365
        month = MONTHS[max(i for i, s in enumerate(MONTH_START) if s <= day)]
        if dec >= 50:
            where = (f"{name} is far in the northern sky. From northern places like Canada and most of Europe it never sets, so it can be seen all year, "
                     f"highest in the evening around {month}. It's hard or impossible to see from far southern places like Australia.")
        elif dec <= -50:
            where = (f"{name} is far in the southern sky, so it's best seen from the Southern Hemisphere, highest in the evening around {month}. "
                     f"It can't be seen from most of the US, Canada and Europe.")
        elif dec >= 25:
            where = (f"{name} is best seen in the evening around {month}. It's in the northern part of the sky, so it's easiest to see "
                     f"from the Northern Hemisphere and sits low in the north from the far south.")
        elif dec <= -25:
            where = (f"{name} is best seen in the evening around {month}. It's in the southern part of the sky, so it's easiest to see "
                     f"from the Southern Hemisphere and sits low in the south from places like the US and Europe.")
        else:
            where = f"{name} is best seen in the evening around {month}, and it can be seen from both the Northern and Southern Hemispheres."
        add(lines, [f"when can you see {n}", f"best time to see {n}", f"what month can you see {n}",
                    f"which hemisphere can see {n}"], where)
    with open(OUT_SKY, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print(f"wrote {len(lines) - 3} entries to {OUT_SKY}")


if __name__ == "__main__":
    main()
