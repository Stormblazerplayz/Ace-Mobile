#!/usr/bin/env python3
"""Generates world facts Q&A for Ace: data/geo/gen_world_*.txt

  - hemispheres for every country (mledoze countries.json centre points, ODbL 1.0, plus a hand list of
    countries that cross the equator, the prime meridian or the 180th meridian)
  - where country names come from, country nicknames, old names of countries and cities, old capitals
  - capital mix-ups, countries with more than one capital, groups of countries and organizations
  - continents, the countries of the United Kingdom, flags to recognize, national animals and birds

Source: hand-written tables below from general knowledge, checked against standard references.
Run from the repo root:  python3 tools/knowledge/gen/geo_world.py
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from geo_common import CACHE, Writer, add_block, ascii_fold, cap, rng_for  # noqa: E402
import geo_country_data as D  # noqa: E402
from geo_world_text import NAMES_TEXT, FACTS_TEXT, SYMBOLS_TEXT  # noqa: E402

F_HEMI = "gen_world_hemispheres.txt"
F_NAMES = "gen_world_names.txt"
F_FACTS = "gen_world_facts.txt"
F_SYM = "gen_world_symbols.txt"

EQUATOR = {"ECU", "COL", "BRA", "GAB", "COG", "COD", "UGA", "KEN", "SOM", "IDN", "MDV", "STP"}
PRIME = {"GBR", "FRA", "ESP", "DZA", "MLI", "BFA", "TGO", "GHA"}
SPECIAL = {
    "KIR": "Kiribati is in all four hemispheres. Its islands sit on both sides of the equator and both sides of the 180th meridian, which makes it the only country in all four.",
    "FJI": "Fiji is in the Southern Hemisphere. The 180th meridian runs right through it, so it's in both the Eastern and Western Hemispheres.",
    "RUS": "Russia is in the Northern Hemisphere. Most of it is in the Eastern Hemisphere, but its far eastern tip crosses the 180th meridian into the Western Hemisphere.",
    "USA": "The United States is in the Northern and Western Hemispheres, except for a few far-off Alaskan islands across the 180th meridian and some Pacific territories.",
    "GNQ": "Most of Equatorial Guinea is in the Northern and Eastern Hemispheres, but its small island of Annobón is just south of the equator.",
}
MOSTLY = {"NLD", "DNK", "NOR", "NZL"}

# code | where the name comes from
ETYMOLOGY = r"""
ARG | Argentina comes from argentum, the Latin word for silver. Early Spanish explorers hoped to find silver there.
ECU | Ecuador is Spanish for equator, because the equator runs right through the country.
VEN | Venezuela means little Venice. Explorers saw houses built on stilts over the water and were reminded of Venice, Italy.
CRI | Costa Rica is Spanish for rich coast.
HND | Honduras means depths in Spanish, probably after the deep waters off its coast.
SLV | El Salvador is Spanish for the Savior, meaning Jesus.
PHL | The Philippines were named after King Philip II of Spain.
COL | Colombia is named after Christopher Columbus.
BOL | Bolivia is named after Simón Bolívar, who led the fight for independence from Spain in South America.
AUS | Australia comes from the Latin terra australis, meaning southern land.
NLD | Netherlands means low lands, because much of the country is flat and a lot of it is below sea level.
SLE | Sierra Leone comes from the Portuguese for lion mountains, the name early Portuguese sailors gave its hills.
CIV | Ivory Coast (Côte d'Ivoire) was named by European traders for the elephant ivory traded there.
CMR | Cameroon comes from Rio dos Camarões, River of Prawns, the name Portuguese sailors gave a river there that was full of shrimp.
NGA | Nigeria is named after the Niger River. The name was suggested in 1897 by a British journalist, Flora Shaw.
PAK | Pakistan means land of the pure in Urdu and Persian. The name was made up in 1933 by Choudhry Rahmat Ali.
IND | India comes from the Indus River, called Sindhu in Sanskrit.
SGP | Singapore comes from Singapura, which means lion city in Sanskrit.
JPN | Japan's own name, Nihon or Nippon, means origin of the sun, which is why it's called the Land of the Rising Sun.
CHN | The English name China probably comes from the Qin dynasty, whose first emperor united China in 221 BC. In Chinese, the country is called Zhongguo, meaning Middle Kingdom.
KOR | Korea comes from Goryeo, a kingdom that ruled the Korean Peninsula from 918 to 1392.
THA | Thailand means land of the Thai people, and Thai is often explained as meaning free.
MEX | Mexico comes from the Mexica, the people we often call the Aztecs, who built the city of Tenochtitlan where Mexico City is today.
CAN | Canada comes from kanata, a Saint Lawrence Iroquoian word meaning village or settlement.
BRA | Brazil is named after brazilwood, a tree with red wood that Portuguese traders sold to make red dye.
MNE | Montenegro means black mountain, after the dark forests on Mount Lovćen.
BLR | Belarus means White Rus.
RUS | Russia comes from the Rus, a medieval people who started the first big East Slavic state, Kievan Rus.
FRA | France is named after the Franks, a Germanic people who ruled the area after the fall of the Roman Empire.
PRT | Portugal comes from Portus Cale, the Roman name for a port town near where the city of Porto is now.
CHE | Switzerland is named after Schwyz, one of the three original cantons that formed the Swiss Confederation in 1291.
AUT | Austria comes from the German Österreich, meaning eastern realm.
ROU | Romania means land of the Romans, because the Romanian language comes from Latin, the language of ancient Rome.
JOR | Jordan is named after the Jordan River.
LBN | Lebanon comes from an old word meaning white, because of the snow on Mount Lebanon.
SAU | Saudi Arabia is named after the House of Saud, the royal family that founded the country in 1932.
IRN | Iran means land of the Aryans, an old name the Iranian peoples used for themselves. Until 1935, most of the world called it Persia.
KEN | Kenya is named after Mount Kenya, the country's highest mountain.
TZA | Tanzania joins the names Tanganyika and Zanzibar, which united in 1964.
ZWE | Zimbabwe means houses of stone in the Shona language, after the stone ruins of Great Zimbabwe.
ZMB | Zambia is named after the Zambezi River.
BWA | Botswana means land of the Tswana, the country's biggest group of people.
NAM | Namibia is named after the Namib Desert.
MUS | Mauritius was named by Dutch sailors in 1598 after Prince Maurice of Nassau.
SYC | Seychelles is named after Jean Moreau de Séchelles, a French finance minister in the 1750s.
LKA | Sri Lanka means resplendent island or holy island in Sanskrit.
IDN | Indonesia comes from Greek words meaning Indian islands.
NZL | New Zealand is named after Zeeland, a province of the Netherlands, by Dutch mapmakers. In Māori it's called Aotearoa, often translated as land of the long white cloud.
SLB | The Solomon Islands were named by Spanish explorer Álvaro de Mendaña in 1568, who hoped they held King Solomon's riches.
MHL | The Marshall Islands are named after British sea captain John Marshall, who sailed there in 1788.
TUV | Tuvalu means eight standing together, for the eight islands people lived on. It actually has nine islands.
LUX | Luxembourg means little castle.
SMR | San Marino is named after Saint Marinus, a stonemason who legend says founded it in 301 AD.
VAT | Vatican City is named after Vatican Hill in Rome, where it stands.
DOM | The Dominican Republic is named after its capital, Santo Domingo, which honors Saint Dominic.
HTI | Haiti comes from the Taíno word Ayiti, meaning land of high mountains.
JAM | Jamaica comes from the Taíno name Xaymaca, often translated as land of wood and water.
BRB | Barbados comes from Portuguese for the bearded ones, probably after the bearded fig trees growing there.
TTO | Trinidad means Trinity in Spanish. Christopher Columbus named it in 1498, and Tobago may be named after tobacco.
LCA | Saint Lucia is named after Saint Lucy.
NIC | Nicaragua is named after Nicarao, a chief of the people living there when the Spanish arrived.
GUY | Guyana comes from a native word meaning land of many waters.
ISL | Iceland was named by a Viking, Flóki Vilgerðarson, after he saw a fjord full of sea ice.
ETH | Ethiopia comes from an ancient Greek word that meant burnt faces.
SDN | Sudan comes from the Arabic bilad al-sudan, meaning land of the Black people.
LBR | Liberia comes from the Latin word liber, meaning free. It was founded in the 1800s as a home for freed Black Americans.
GHA | Ghana is named after the ancient Ghana Empire, which was northwest of modern Ghana.
MLI | Mali is named after the Mali Empire, a rich West African empire famous for its gold.
BFA | Burkina Faso means land of upright (honest) people. It was called Upper Volta until 1984.
AFG | Afghanistan means land of the Afghans. The ending -stan means land of in Persian.
KAZ | Kazakhstan means land of the Kazakhs. The ending -stan means land of in Persian.
UZB | Uzbekistan means land of the Uzbeks. The ending -stan means land of in Persian.
MNG | Mongolia means land of the Mongols.
ESP | Spain comes from Hispania, the Roman name for the Iberian Peninsula.
EGY | Egypt comes from the Greek name Aigyptos. Egyptians call their country Misr.
URY | Uruguay is named after the Uruguay River.
PRY | Paraguay is named after the Paraguay River.
MYS | Malaysia means land of the Malays.
MAR | Morocco comes from the city of Marrakesh, an old capital. In Arabic, Morocco is called al-Maghrib, meaning the west.
TUR | Turkey, now officially Türkiye, means land of the Turks.
GRC | Greece comes from the Latin Graecia. Greeks call their country Hellas or Elláda.
IRL | Ireland comes from Ériu, a goddess in Irish myths. In Irish, the country is called Éire.
"""

NICKNAMES = r"""
JPN | land of the rising sun | Japan is called the Land of the Rising Sun, because its name in Japanese means origin of the sun and it's in the far east of Asia, where the sun rises.
NOR | land of the midnight sun | Norway is called the Land of the Midnight Sun, because in its far north the sun doesn't set for weeks in summer.
IRL | emerald isle | Ireland is called the Emerald Isle because of its very green fields, kept green by lots of rain.
ISL | land of fire and ice | Iceland is called the Land of Fire and Ice, because it has both active volcanoes and big glaciers.
UGA | pearl of africa | Uganda is called the Pearl of Africa, a name Winston Churchill made popular, because of its lakes, mountains and wildlife.
ZAF | rainbow nation | South Africa is called the Rainbow Nation, a name Archbishop Desmond Tutu used for its many peoples living together after apartheid ended.
RWA | land of a thousand hills | Rwanda is called the Land of a Thousand Hills because it's so hilly.
THA | land of smiles | Thailand is called the Land of Smiles because of its friendly people.
BTN | land of the thunder dragon | Bhutan is called the Land of the Thunder Dragon. Its name in its own language, Druk Yul, means just that, and a dragon is on its flag.
NZL | land of the long white cloud | New Zealand is called the Land of the Long White Cloud, a common translation of its Māori name, Aotearoa.
AUS | land down under | Australia is called the Land Down Under because it's in the Southern Hemisphere, below most other countries on a typical map.
KOR | land of the morning calm | Korea is called the Land of the Morning Calm, from an old name for the country, Joseon.
FIN | land of a thousand lakes | Finland is called the Land of a Thousand Lakes, though it really has about 188,000 lakes.
AZE | land of fire | Azerbaijan is called the Land of Fire because of natural gas fires that burn out of the ground there, like at Yanar Dag.
PRK | hermit kingdom | North Korea is often called the Hermit Kingdom because it's so closed off from the rest of the world. The name was first used for old Korea.
GRD | spice isle | Grenada is called the Spice Isle because it grows lots of nutmeg, cinnamon and cloves. Nutmeg is even on its flag.
LKA | pearl of the indian ocean | Sri Lanka is called the Pearl of the Indian Ocean because of its shape and beauty.
ALB | land of the eagles | Albania is called the Land of the Eagles. Its own name, Shqipëria, is often linked to the word for eagle, and an eagle is on its flag.
CHN | middle kingdom | China is called the Middle Kingdom, from its Chinese name Zhongguo.
"""

FORMER = r"""
THA | siam | Thailand was called Siam until 1939, and again from 1945 to 1949.
IRN | persia | Iran was known to most of the world as Persia until 1935, when it asked other countries to call it Iran, the name Iranians had always used.
LKA | ceylon | Sri Lanka was called Ceylon until 1972.
MMR | burma | Myanmar was called Burma until 1989, and some people and countries still use the old name.
COD | zaire | The Democratic Republic of the Congo was called Zaire from 1971 to 1997.
ZWE | rhodesia | Rhodesia is now Zimbabwe, which became independent under its new name in 1980.
ZMB | northern rhodesia | Northern Rhodesia became Zambia when it became independent in 1964.
MWI | nyasaland | Nyasaland became Malawi when it became independent in 1964.
GHA | gold coast | The Gold Coast became Ghana when it became independent in 1957.
BEN | dahomey | Benin was called Dahomey until 1975.
BFA | upper volta | Burkina Faso was called Upper Volta until 1984.
ETH | abyssinia | Ethiopia used to be called Abyssinia, mostly by Europeans.
SWZ | swaziland | Eswatini was called Swaziland until 2018, when the king changed the name.
BGD | east pakistan | Bangladesh was East Pakistan until it became independent in 1971.
TWN | formosa | Taiwan used to be called Formosa, from a Portuguese word meaning beautiful island.
BWA | bechuanaland | Bechuanaland became Botswana when it became independent in 1966.
LSO | basutoland | Basutoland became Lesotho when it became independent in 1966.
BLZ | british honduras | British Honduras was renamed Belize in 1973, and it became independent in 1981.
GUY | british guiana | British Guiana became Guyana when it became independent in 1966.
SUR | dutch guiana | Dutch Guiana is now Suriname, which became independent from the Netherlands in 1975.
TUV | ellice islands | The Ellice Islands became Tuvalu in 1978.
KIR | gilbert islands | The Gilbert Islands became Kiribati in 1979.
VUT | new hebrides | The New Hebrides became Vanuatu when it became independent in 1980.
MKD | macedonia | North Macedonia was called the Republic of Macedonia until 2019, when it added North to settle an argument with Greece.
MYS | malaya | Malaya joined with Sabah, Sarawak and Singapore in 1963 to form Malaysia. Singapore left in 1965.
KHM | kampuchea | Cambodia was officially called Kampuchea for part of the 1970s and 1980s.
"""

CITY_FORMER = r"""
## geo.city-name
what was mumbai called before | is bombay the same as mumbai | old name of mumbai => Mumbai was called Bombay until 1995.
what was chennai called before | is madras the same as chennai | old name of chennai => Chennai was called Madras until 1996.
what was kolkata called before | is calcutta the same as kolkata | old name of kolkata => Kolkata was spelled Calcutta in English until 2001.
what was beijing called before | is peking the same as beijing | old name of beijing => Beijing used to be written Peking in English. The spelling Beijing became standard in the 1970s and 1980s.
what was istanbul called before | is constantinople the same as istanbul | old name of istanbul => Istanbul was called Byzantium in ancient times and Constantinople for about 1,600 years. Istanbul became its only official name in 1930.
what was tokyo called before | old name of tokyo | was tokyo called edo => Tokyo was called Edo until 1868, when it became the capital and was renamed Tokyo, meaning eastern capital.
what was ho chi minh city called before | is saigon the same as ho chi minh city | old name of saigon => Ho Chi Minh City was called Saigon until 1976. Many people still call the city center Saigon.
what was new york called before | old name of new york city | why was new york called new amsterdam => New York City was called New Amsterdam when it was a Dutch colony. The English took it in 1664 and renamed it after the Duke of York.
what was st petersburg called before | is leningrad the same as st petersburg | old name of st petersburg => St. Petersburg was called Petrograd from 1914 to 1924 and Leningrad from 1924 to 1991, then got its old name back.
what was volgograd called before | where is stalingrad now | is stalingrad the same as volgograd => Volgograd was called Stalingrad from 1925 to 1961. The huge World War II Battle of Stalingrad was fought there.
what was yangon called before | is rangoon the same as yangon | old name of yangon => Yangon, Myanmar's biggest city, was called Rangoon in English until 1989.
what was oslo called before | old name of oslo | was oslo called christiania => Oslo was called Christiania (later spelled Kristiania) from 1624 until 1925.
what was jakarta called before | old name of jakarta | is batavia the same as jakarta => Jakarta was called Batavia when Indonesia was a Dutch colony.
what was harare called before | old name of harare | is salisbury the same as harare => Harare, the capital of Zimbabwe, was called Salisbury until 1982.
what was kinshasa called before | old name of kinshasa | is leopoldville the same as kinshasa => Kinshasa was called Léopoldville until 1966.
what was gdansk called before | is danzig the same as gdansk | old name of gdansk => Gdańsk, in Poland, was called Danzig in German.
what was kaliningrad called before | is konigsberg the same as kaliningrad | old name of kaliningrad => Kaliningrad, in Russia, was the German city of Königsberg until 1946.
why is it kyiv not kiev | is kiev the same as kyiv | how do you spell kyiv => Kyiv is the Ukrainian spelling of Ukraine's capital, and most of the world switched to it from the Russian-based Kiev, especially after 2019 and 2022.
what was astana called before | old names of astana | was astana called nur-sultan => Astana, the capital of Kazakhstan, was called Nur-Sultan from 2019 to 2022, then went back to Astana. It also had other names before, like Akmola.
what was nuuk called before | old name of nuuk | is godthab the same as nuuk => Nuuk, the capital of Greenland, used to be called Godthåb in Danish.
"""

OLD_CAPITALS = r"""
## geo.old-capital
what was the capital of brazil before brasilia | did rio used to be the capital of brazil | when did brasilia become the capital => Rio de Janeiro was Brazil's capital until 1960, when the new planned city of Brasília became the capital.
what was the capital of nigeria before abuja | did lagos used to be the capital of nigeria | when did abuja become the capital of nigeria => Lagos was Nigeria's capital until 1991, when the government moved to Abuja, a planned city in the middle of the country.
what was the capital of pakistan before islamabad | did karachi used to be the capital of pakistan | when did islamabad become the capital => Karachi was Pakistan's first capital. Islamabad was built in the 1960s to become the new capital.
what was the capital of turkey before ankara | did istanbul used to be the capital of turkey | when did ankara become the capital => Istanbul was the capital of the Ottoman Empire. Ankara became the capital of the new Republic of Turkey in 1923.
what was the capital of japan before tokyo | did kyoto used to be the capital of japan | when did tokyo become the capital of japan => Kyoto was Japan's imperial capital for more than 1,000 years. The emperor moved to Tokyo in 1868 and 1869.
what was the capital of russia before moscow | did st petersburg used to be the capital of russia | when did moscow become the capital of russia => St. Petersburg was Russia's capital from 1712 to 1918, when the government moved back to Moscow.
what was the capital of kazakhstan before astana | did almaty used to be the capital of kazakhstan | when did astana become the capital => Almaty was Kazakhstan's capital until 1997, when the capital moved north to Astana.
what was the capital of myanmar before naypyidaw | did yangon used to be the capital of myanmar | when did naypyidaw become the capital => Yangon was Myanmar's capital until 2005 and 2006, when the government moved to the new city of Naypyidaw.
what was the capital of germany before berlin | did bonn used to be the capital of germany | when did berlin become the capital of germany again => Bonn was the capital of West Germany. After Germany reunited in 1990, Berlin became the capital, and the government moved there by 1999.
what was the capital of australia before canberra | did melbourne used to be the capital of australia | when did canberra become the capital => Melbourne was the temporary home of Australia's government from 1901 to 1927, while Canberra was being built.
what was the capital of the united states before washington dc | did new york used to be the capital of the united states | was philadelphia the capital of the us => New York City was the first capital under the Constitution, in 1789 and 1790. Philadelphia was the capital from 1790 to 1800, and then Washington, DC.
what was the capital of belize before belmopan | was belize city the capital | when did belmopan become the capital => Belize City was the capital until 1970, when the government moved inland to Belmopan after a hurricane flooded Belize City in 1961.
what was the capital of malawi before lilongwe | did zomba used to be the capital of malawi => Zomba was Malawi's capital until 1975, when the capital moved to Lilongwe.
what was the capital of ivory coast before yamoussoukro | did abidjan used to be the capital of ivory coast => Abidjan was Ivory Coast's capital until 1983, when Yamoussoukro became the official capital. Most government offices are still in Abidjan.
what was the capital of tanzania before dodoma | did dar es salaam used to be the capital of tanzania => Dar es Salaam was Tanzania's capital. Dodoma was chosen as the new capital in 1973, and the government finished moving there in the 2010s and 2020s.
"""


def load():
    return {c["cca3"]: c for c in json.load(open(os.path.join(CACHE, "countries.json"), encoding="utf-8"))}


def names_for(code, data):
    common = data[code]["name"]["common"]
    disp = D.DISPLAY.get(code, common)
    names = D.ALIASES.get(code) or [ascii_fold(common)]
    if code not in D.ALIASES and disp.startswith("the "):
        names = [ascii_fold(disp), ascii_fold(common)]
    return cap(disp), names


def hemispheres(w, data, codes):
    for code in codes:
        N, names = names_for(code, data)
        lat, lng = data[code]["latlng"]
        ns = "Northern" if lat >= 0 else "Southern"
        ew = "Eastern" if lng >= 0 else "Western"
        if code in SPECIAL:
            ans = SPECIAL[code]
        elif code in EQUATOR and code in PRIME:
            ans = f"{N} crosses both the equator and the prime meridian."
        elif code in EQUATOR:
            ans = f"{N} is in the {ew} Hemisphere, and the equator runs through it, so it's in both the Northern and Southern Hemispheres."
        elif code in PRIME:
            ans = f"{N} is in the {ns} Hemisphere, and the prime meridian runs through it, so it's in both the Eastern and Western Hemispheres."
        elif code in MOSTLY:
            ans = f"Most of {N} is in the {ns} and {ew} Hemispheres, though some of its far-off islands or territories are not."
        else:
            ans = f"{N} is in the {ns} and {ew} Hemispheres."
        n0 = names[0]
        n1 = names[1] if len(names) > 1 else n0
        rng = rng_for("hemi", code)
        rest = [f"is {n1} in the northern or southern hemisphere", f"which side of the equator is {n0} on",
                f"{n1} hemisphere", f"is {n0} north or south of the equator", f"is {n1} in the eastern or western hemisphere"]
        rng.shuffle(rest)
        w.add(F_HEMI, "geo.hemisphere", [f"what hemisphere is {n0} in"] + rest, ans, limit=4)


def per_country(w, data, text, fname, tag, templates):
    for line in text.strip().splitlines():
        code, *rest = [x.strip() for x in line.split("|")]
        N, names = names_for(code, data)
        n0 = names[0]
        n1 = names[1] if len(names) > 1 else n0
        bare = n0[4:] if n0.startswith("the ") else n0
        rng = rng_for(tag, code)
        if len(rest) == 1:
            ans = rest[0]
            qs = [t.format(n=n0, n1=n1, b=bare) for t in templates]
        else:
            key, ans = rest
            qs = [t.format(n=n0, n1=n1, b=bare, k=key) for t in templates]
        first, more = qs[:1], qs[1:]
        rng.shuffle(more)
        w.add(fname, tag, first + more, ans, limit=4)


def main():
    data = load()
    codes = [line.split("|")[0].strip() for line in D.TABLE.strip().splitlines()]
    w = Writer([F_HEMI, F_NAMES, F_FACTS, F_SYM])
    hemispheres(w, data, codes)
    per_country(w, data, ETYMOLOGY, F_NAMES, "geo.name-origin",
                ["what does the name {b} mean", "why is {n} called {b}", "where does the name {b} come from",
                 "how did {n1} get its name", "meaning of the name {b}", "{b} name origin"])
    per_country(w, data, NICKNAMES, F_NAMES, "geo.country-nickname",
                ["which country is called the {k}", "what country is the {k}", "{k}", "why is {n} called the {k}",
                 "what is the nickname of {n1}"])
    per_country(w, data, FORMER, F_NAMES, "geo.former-name",
                ["what was {n} called before", "what is {k} called now", "what country was {k}",
                 "old name of {n1}", "is {k} the same as {b}"])
    add_block(w, F_NAMES, CITY_FORMER)
    add_block(w, F_NAMES, OLD_CAPITALS)
    add_block(w, F_NAMES, NAMES_TEXT)
    add_block(w, F_FACTS, FACTS_TEXT)
    add_block(w, F_SYM, SYMBOLS_TEXT)
    w.save("""Generated by tools/knowledge/gen/geo_world.py. Do not edit by hand.
Data: hand-written tables of world facts; hemispheres use mledoze/countries centre points (ODbL 1.0).""")
    for d in w.dropped:
        print("  dropped:", d)


if __name__ == "__main__":
    main()
