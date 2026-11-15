#!/usr/bin/env python3
"""Generates country Q&A for Ace: data/geo/gen_countries_*.txt

Sources
  - mledoze/countries, countries.json (https://github.com/mledoze/countries), licensed under the
    Open Database License (ODbL) v1.0. Used for official names, calling codes, internet domains,
    demonyms, land borders, areas, landlocked status, subregions, languages and currencies.
    Download it first:
      curl -sS -o tools/knowledge/.cache/countries.json \
        https://raw.githubusercontent.com/mledoze/countries/master/countries.json
  - geo_country_data.py: hand-written tables (leader titles, population as of 2024, biggest cities,
    highest points, independence, flags, food, what each country is known for) and fixes where the
    data set is out of date or unclear.
  - tools/qa_data_world.py: capitals and continents already in Ace's older bank (not repeated here).

Run from the repo root:  python3 tools/knowledge/gen/geo_countries.py
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.normpath(os.path.join(HERE, "..", "..")))

from geo_common import (CACHE, Writer, a_an, ascii_fold, cap, km2_mi2, m_ft, poss, rng_for)  # noqa: E402
import geo_country_data as D  # noqa: E402
import qa_data_world as OLD  # noqa: E402

FILES = {
    "basics": "gen_countries_basics.txt",
    "codes": "gen_countries_codes.txt",
    "size": "gen_countries_size.txt",
    "gov": "gen_countries_gov.txt",
    "culture": "gen_countries_culture.txt",
    "nature": "gen_countries_nature.txt",
}

OLD_NAME = {"CZE": "Czech Republic", "CIV": "Ivory Coast", "TLS": "East Timor", "COD": "Democratic Republic of the Congo",
            "COG": "Republic of the Congo", "TUR": "Turkey", "CPV": "Cape Verde", "SWZ": "Eswatini", "FSM": "Micronesia",
            "VAT": "Vatican City", "USA": "United States", "BHS": "Bahamas", "GMB": "Gambia", "STP": "São Tomé and Príncipe",
            "MMR": "Myanmar", "KOR": "South Korea", "PRK": "North Korea", "MKD": "North Macedonia"}

LANG_RENAME = {"Persian (Farsi)": "Persian (Farsi)", "Nauru": "Nauruan", "Gilbertese": "Gilbertese (Kiribati)",
               "Sotho": "Sesotho", "Montenegrin": "Montenegrin"}
LANG_EXTRA = {
    "COD": "French is the official language of the DR Congo, and Lingala, Swahili, Kikongo and Tshiluba are national languages.",
    "COG": "French is the official language of the Republic of the Congo, and Lingala and Kituba are national languages.",
    "GNQ": "Equatorial Guinea's official languages are Spanish, French and Portuguese. Spanish is the most used.",
}
ADJ_NOTE = {"DNK": "Danish", "FIN": "Finnish", "SWE": "Swedish", "POL": "Polish", "ESP": "Spanish", "TUR": "Turkish",
            "ISL": "Icelandic", "LUX": "Luxembourgish", "BWA": "Botswanan", "LSO": "Basotho"}
TLD_NOTE = {
    "TUV": " Lots of video and streaming websites pay Tuvalu to use .tv, which earns the country money.",
    "FSM": " Radio stations around the world like to use it because of FM radio.",
    "MNE": " People like it for personal websites because it spells \"me\".",
    "COL": " Many companies use it as a short version of .com.",
}
AREA_NOTE = {
    "DNK": " That's without Greenland and the Faroe Islands, which are part of the Kingdom of Denmark.",
    "FRA": " That's mainland France. With its overseas regions, it's about 640,000 square kilometers.",
    "NLD": " That's the European part of the country.",
    "NOR": " That's mainland Norway, without Svalbard.",
}
NOT_A_CAPITAL_QUIZ = {"Victoria", "Singapore", "Monaco", "Vatican City", "Luxembourg", "San Marino", "Djibouti",
                      "Kuwait City", "Panama City", "Guatemala City", "Mexico City", "Andorra la Vella", "Tarawa"}
BORDER_NAME = {"GUF": "France (through French Guiana)", "ESH": "Western Sahara", "GIB": "Gibraltar (a British territory)",
               "PSE": "the Palestinian territories", "UNK": "Kosovo"}
NO_COUNT = {"PSE", "UNK", "ESH", "GIB", "GUF"}
BORDER_OVERRIDE = {
    "FRA": "In Europe, France borders Belgium, Luxembourg, Germany, Switzerland, Italy, Monaco, Spain and Andorra. In South America, French Guiana, which is part of France, also borders Brazil and Suriname.",
    "MAR": "Morocco borders Algeria and Western Sahara, a disputed territory. It also borders Spain at the small Spanish cities of Ceuta and Melilla.",
    "ESP": "Spain borders Portugal, France, Andorra and Gibraltar (a British territory). Its cities of Ceuta and Melilla in North Africa border Morocco.",
    "AUS": "Australia has no land borders. It's a whole continent surrounded by ocean. Its closest neighbors are Papua New Guinea, Indonesia and New Zealand.",
    "SRB": "Serbia borders Hungary, Romania, Bulgaria, North Macedonia, Montenegro, Bosnia and Herzegovina, and Croatia, as well as Kosovo, which declared independence from Serbia in 2008.",
    "DOM": "The Dominican Republic shares the island of Hispaniola with Haiti, its only land neighbor.",
    "HTI": "Haiti shares the island of Hispaniola with the Dominican Republic, its only land neighbor.",
}


def load():
    path = os.path.join(CACHE, "countries.json")
    if not os.path.exists(path):
        sys.exit("Download countries.json into tools/knowledge/.cache first (see the header).")
    return {c["cca3"]: c for c in json.load(open(path, encoding="utf-8"))}


def old_lookup():
    caps = {n: (cap_, cont) for n, cap_, cont in OLD.COUNTRIES}
    return caps, set(OLD.CURRENCIES)


def join(items):
    items = list(items)
    if len(items) == 1:
        return items[0]
    return ", ".join(items[:-1]) + " and " + items[-1]


def pop_text(m):
    if m >= 1000:
        return f"{m / 1000:.2f}".rstrip("0").rstrip(".") + " billion"
    if m >= 10:
        return f"{round(m)} million"
    if m >= 1:
        return f"{m:.1f}".rstrip("0").rstrip(".") + " million"
    people = m * 1_000_000
    step = 10_000 if people >= 100_000 else 1_000
    return f"{int(round(people / step) * step):,}"


ORD = ["", "", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth", "tenth"]


def main():
    data = load()
    caps, old_cur = old_lookup()
    w = Writer(FILES.values())
    rows = {}
    for line in D.TABLE.strip().splitlines():
        p = [x.strip() for x in line.split("|")]
        rows[p[0]] = dict(zip(["code", "pop", "largest", "gov", "high", "drive", "indep", "flag", "known", "food"], p))

    for code, r in rows.items():
        c = data[code]
        common = c["name"]["common"]
        disp = D.DISPLAY.get(code, common)
        N = cap(disp)
        names = D.ALIASES.get(code) or [ascii_fold(common)]
        if code not in D.ALIASES and disp.startswith("the "):
            names = [ascii_fold(disp), ascii_fold(common)]
        n0 = names[0]
        n1 = names[1] if len(names) > 1 else names[0]
        n2 = names[2] if len(names) > 2 else n0
        oldname = OLD_NAME.get(code, common)
        capital, cont = caps.get(oldname, (None, None))
        if capital is None:
            print("no old capital for", code, oldname)
        rng = rng_for(code)

        def Q(templates, limit=5):
            out = []
            for i, t in enumerate(templates):
                nm = [n0, n1, n2][i % 3] if i else n0
                out.append(t.format(n=nm, cont=(cont or "").lower()).replace("the the ", "the "))
            first, rest = out[:1], out[1:]
            rng.shuffle(rest)
            return first + rest

        # ---------- basics ----------
        f = FILES["basics"]
        # currency
        if oldname not in old_cur and code in D.CURRENCY and D.CURRENCY[code] == "":
            pass
        elif oldname not in old_cur:
            ans = D.CURRENCY.get(code)
            if not ans:
                curs = c.get("currencies", {})
                if "XOF" in curs:
                    ans = f"{N} uses {D.XOF}."
                elif "XAF" in curs:
                    ans = f"{N} uses {D.XAF}."
                elif len(curs) == 1:
                    cname = list(curs.values())[0]["name"]
                    fix = {"lari": "Georgian lari", "dalasi": "Gambian dalasi", "denar": "Macedonian denar",
                           "Uzbekistani soʻm": "Uzbek som", "Turkmenistan manat": "Turkmen manat",
                           "Bosnia and Herzegovina convertible mark": "convertible mark",
                           "Venezuelan bolívar soberano": "Venezuelan bolívar"}
                    cname = fix.get(cname, cname)
                    ans = f"{N} uses the {cname}."
            if ans:
                w.add(f, "geo.currency", Q(["what currency does {n} use", "what money do they use in {n}",
                                             "whats the money in {n} called", "{n} money", "what do people pay with in {n}",
                                             "what kind of money does {n} have"]), ans)
        # language
        ans = D.LANGUAGES.get(code) or LANG_EXTRA.get(code)
        if not ans:
            langs = [LANG_RENAME.get(x, x) for x in c["languages"].values()]
            if len(langs) == 1:
                ans = f"The official language of {disp} is {langs[0]}."
            elif len(langs) <= 4:
                ans = f"{poss(N)} official languages are {join(langs)}."
        if ans:
            w.add(f, "geo.language", Q(["what language do they speak in {n}", "what language is spoken in {n}",
                                         "{n} official language", "what do people in {n} speak",
                                         "which languages are spoken in {n}", "main language of {n}"]), ans)
        # demonym
        if code != "VAT":
            adj = c["demonyms"]["eng"]["m"]
            phrase = D.DEMONYM.get(code) or a_an(adj)
            ans = f"Someone from {disp} is called {phrase}."
            if code in ADJ_NOTE:
                ans += f" The adjective is {ADJ_NOTE[code]}."
            w.add(f, "geo.demonym", Q(["what do you call someone from {n}", "what are people from {n} called",
                                        "whats a person from {n} called", "{n} demonym",
                                        "what is the word for people from {n}"]), ans)
        # official name
        off = c["name"]["official"]
        if code not in ("AFG", "KIR", "SYR", "IRL", "MNG") and off.lower() not in (common.lower(), disp.lower(), "the " + common.lower()):
            off = off.replace(" (Taiwan)", "")
            the = "" if off.startswith("Bosnia") else "the "
            extra = " Its short name is Czechia." if code == "CZE" else ""
            if code == "BRN":
                off, the = "Nation of Brunei, the Abode of Peace", "the "
            w.add(f, "geo.officialname", Q(["what is the full name of {n}", "{n} official name",
                                             "what is {n} officially called", "whats the long name for {n}"]),
                  f"{poss(N)} official name is {the}{off}.{extra}")
        # region
        sub = D.SUBREGION_OVERRIDE.get(code)
        if sub is None:
            sub = D.SUBREGION_NAMES.get(c["subregion"], "")
        if sub and (sub not in ("South America", "North America", "Oceania") or code in D.SUBREGION_OVERRIDE):
            tpl = ["what region is {n} in", "what part of the world is {n} in"]
            if cont:
                tpl.append("what part of {cont} is {n} in")
            w.add(f, "geo.region", Q(tpl), f"{N} is in {sub}.")
        # reverse capital
        if capital and capital not in D.TABLE and False:
            pass
        if capital and capital not in NOT_A_CAPITAL_QUIZ and ascii_fold(capital) != ascii_fold(common):
            cn = ascii_fold(capital).replace(",", "").replace(".", "")
            where = f", in {cont}" if cont else ""
            w.add(f, "geo.capital.reverse", [f"{cn} is the capital of what country", f"what country is {cn} the capital of",
                                             f"which country has {cn} as its capital", f"{cn} is in what country",
                                             f"where is {cn}"],
                  f"{capital} is the capital of {disp}{where}.", limit=4)

        # ---------- codes ----------
        f = FILES["codes"]
        idd = c["idd"]
        root, suf = idd.get("root", ""), idd.get("suffixes", [])
        code_ans = None
        if code in ("RUS", "KAZ"):
            code_ans = f"The phone country code for {disp} is +7. Russia and Kazakhstan share it."
        elif code == "VAT":
            code_ans = "Vatican City uses Italy's phone code, +39."
        elif code in ("USA", "CAN"):
            code_ans = f"The phone country code for {disp} is +1. The US, Canada and many Caribbean islands all share +1."
        elif root == "+1" and len(suf) == 1:
            code_ans = f"{N} uses +1, the same as the US and Canada, with the area code {suf[0]}."
        elif root == "+1":
            code_ans = f"{N} uses +1, the same as the US and Canada, with area codes {join(suf)}."
        elif root and len(suf) == 1:
            code_ans = f"The phone country code for {disp} is {root}{suf[0]}."
        if code_ans:
            w.add(f, "geo.callingcode", Q(["what is the country code for {n}", "{n} phone code",
                                            "what do i dial to call {n}", "{n} calling code",
                                            "whats the phone number code for {n}"]), code_ans)
        tld = [t for t in c.get("tld", []) if t.isascii()]
        if tld:
            ans = f"{poss(N)} internet country domain is {tld[0]}.{TLD_NOTE.get(code, '')}"
            w.add(f, "geo.domain", Q(["what is the internet domain for {n}", "{n} domain ending",
                                       "what do websites from {n} end in", "{n} web address ending",
                                       "whats the country domain of {n}"]), ans)
        side = {"L": "left", "R": "right"}[r["drive"]]
        extra = ""
        if code == "WSM":
            extra = " It switched from the right side to the left in 2009."
        w.add(f, "geo.driving", Q(["what side of the road do they drive on in {n}", "do they drive on the left in {n}",
                                    "which side does {n} drive on", "does {n} drive on the right",
                                    "do cars in {n} drive on the left or right"]),
              f"People in {disp} drive on the {side} side of the road.{extra}")

        # ---------- size ----------
        f = FILES["size"]
        area = D.AREA_OVERRIDE.get(code, c.get("area"))
        if area and code != "VAT":
            ans = f"{N} covers about {km2_mi2(area)}."
            if code in D.AREA_RANK:
                i = D.AREA_RANK.index(code) + 1
                ans += " That makes it the biggest country in the world." if i == 1 else f" That makes it the {ORD[i]} biggest country in the world."
            ans += AREA_NOTE.get(code, "")
            w.add(f, "geo.area", Q(["how big is {n}", "what is the area of {n}", "how many square miles is {n}",
                                     "how large is {n} in square kilometers", "size of {n}"]), ans)
        if r["pop"]:
            m = float(r["pop"])
            ans = f"As of 2024, about {pop_text(m)} people live in {disp}."
            if code in D.POP_RANK:
                i = D.POP_RANK.index(code) + 1
                ans += " That's the most of any country." if i == 1 else f" That's the {ORD[i]} most of any country."
            w.add(f, "geo.population", Q(["how many people live in {n}", "what is the population of {n}",
                                           "{n} population", "how many people are in {n}"]), ans)
        lg = r["largest"]
        if lg != "-" and capital:
            if lg.startswith("!"):
                ans = lg[1:]
            elif lg == "":
                ans = f"{capital} is both the capital and the biggest city of {disp}."
            else:
                ans = f"The biggest city in {disp} is {lg}. It's bigger than the capital, {capital}."
            w.add(f, "geo.largestcity", Q(["what is the biggest city in {n}", "largest city in {n}",
                                            "which city in {n} has the most people", "{n} biggest city"]), ans)
        if code in BORDER_OVERRIDE:
            ans = BORDER_OVERRIDE[code]
            w.add(f, "geo.borders", Q(["what countries border {n}", "which countries are next to {n}",
                                        "what countries are around {n}", "{n} neighboring countries",
                                        "which countries neighbor {n}"]), ans)
        else:
            b = [x for x in c.get("borders", []) if x not in ("HKG", "MAC")]
            bn = []
            for x in b:
                if x in BORDER_NAME:
                    bn.append(BORDER_NAME[x])
                elif x in data:
                    bn.append(D.DISPLAY.get(x, data[x]["name"]["common"]))
            if not b:
                ans = f"{N} is an island country, so it doesn't share a land border with any other country."
            elif len(b) == 1:
                ans = f"{N} borders only one country: {bn[0]}."
            else:
                ans = f"{N} borders {join(bn)}."
            w.add(f, "geo.borders", Q(["what countries border {n}", "which countries are next to {n}",
                                        "what countries are around {n}", "{n} neighboring countries",
                                        "which countries neighbor {n}"]), ans)
            if len(b) >= 2 and not (set(b) & NO_COUNT):
                w.add(f, "geo.borders.count", Q(["how many countries does {n} share a border with",
                                                  "number of countries bordering {n}", "how many neighbors does {n} have",
                                                  "how many countries touch {n}"]),
                      f"{N} shares land borders with {len(bn)} countries: {join(bn)}.")
        if c.get("landlocked"):
            ans = f"Yes, {disp} is landlocked, so it has no coast on the open ocean."
            note = {
                "AZE": " It does have a coast on the Caspian Sea, which is really a giant lake with no way out to the ocean.",
                "KAZ": " It has a coast on the Caspian Sea, which is really a giant lake. It's the biggest landlocked country in the world.",
                "TKM": " It has a coast on the Caspian Sea, which is really a giant lake with no way out to the ocean.",
                "LIE": " It's even doubly landlocked, which means all its neighbors are landlocked too.",
                "UZB": " It's even doubly landlocked, which means all its neighbors are landlocked too.",
                "BOL": " Bolivia lost its coast to Chile in the War of the Pacific, from 1879 to 1884.",
                "ETH": " Ethiopia lost its coast when Eritrea became independent in 1993.",
                "LSO": " It's completely surrounded by South Africa.",
                "SMR": " It's completely surrounded by Italy.",
                "VAT": " It's completely surrounded by the city of Rome, in Italy.",
            }.get(code, "")
            w.add(f, "geo.landlocked", Q(["is {n} landlocked", "does {n} have a coastline", "does {n} touch the ocean",
                                           "does {n} have a beach on the ocean", "can you get to the sea from {n}"]), ans + note)

        # ---------- gov ----------
        f = FILES["gov"]
        g = r["gov"]
        ans = None
        if g == "P":
            ans = f"{poss(N)} President is both the head of state and the head of government."
        elif g == "PP":
            ans = f"{poss(N)} head of state is the President, and the head of government is the Prime Minister."
        elif g == "PX":
            ans = (f"{poss(N)} head of state is the President, who holds most of the power, and there's also a "
                   f"Prime Minister who runs the government day to day.")
        elif g == "CR":
            ans = (f"{poss(N)} head of state is the British monarch, represented by a Governor-General, and the "
                   f"head of government is the Prime Minister.")
        elif g.startswith("K:"):
            title = g[2:]
            title = "monarch (the King or Queen)" if title == "monarch" else title
            ans = f"{poss(N)} head of state is the {title}, and the head of government is the Prime Minister."
        elif g.startswith("X:"):
            ans = g[2:]
        if ans:
            w.add(f, "geo.leader", Q(["what is the leader of {n} called", "does {n} have a president or a prime minister",
                                       "who is the head of state of {n}", "what title does the leader of {n} have",
                                       "who leads the government in {n}"]), ans)
        if r["indep"]:
            w.add(f, "geo.independence", Q(["when did {n} become independent", "when did {n} get independence",
                                             "when was {n} founded", "{n} independence day",
                                             "how did {n} become a country"]), r["indep"])

        # ---------- culture ----------
        f = FILES["culture"]
        if r["flag"] and r["flag"] != "-":
            w.add(f, "geo.flag", Q(["what does the {n} flag look like", "{n} flag", "what colors are on the flag of {n}",
                                     "describe the flag of {n}", "what is on the {n} flag"]), r["flag"])
        if r["known"]:
            w.add(f, "geo.knownfor", Q(["what is {n} known for", "what is {n} famous for", "whats special about {n}",
                                         "why is {n} famous", "cool things about {n}"]), r["known"])
        if r["food"]:
            w.add(f, "geo.food", Q(["what food is {n} known for", "what do people eat in {n}", "national dish of {n}",
                                     "traditional food in {n}", "famous food from {n}"]), r["food"])

        # ---------- nature ----------
        f = FILES["nature"]
        h = r["high"]
        if h:
            if h.startswith("!"):
                ans = h[1:]
            else:
                name, _, meters = h.partition(";")
                ans = f"The highest point in {disp} is {name}"
                ans += f", at about {m_ft(float(meters))}." if meters else "."
                if name == "Mount Everest":
                    ans += " That's the highest mountain on Earth, on Nepal's border with China."
                elif name == "Mount Kilimanjaro":
                    ans += " It's also the highest mountain in Africa."
                elif name == "Aconcagua":
                    ans += " It's also the highest mountain in South America."
                elif name == "Denali":
                    ans += " It's also the highest mountain in North America."
                elif name == "Mount Elbrus":
                    ans += " It's also the highest mountain in Europe."
                elif name == "K2":
                    ans += " It's the second highest mountain in the world."
            w.add(f, "geo.highestpoint", Q(["what is the highest mountain in {n}", "highest point in {n}",
                                             "tallest mountain in {n}", "whats the highest place in {n}"]), ans)

    total = w.save("""Generated by tools/knowledge/gen/geo_countries.py. Do not edit by hand.
Data: mledoze/countries (ODbL 1.0) plus hand-checked tables in geo_country_data.py.""")
    for d in [x for x in w.dropped if "capital" not in x[2]][:60]:
        print("  dropped:", d)
    return total


if __name__ == "__main__":
    main()
