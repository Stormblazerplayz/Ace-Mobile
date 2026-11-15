#!/usr/bin/env python3
"""Generates more world facts Q&A for Ace: data/geo/gen_city_rivers.txt, gen_country_time.txt

  - which river runs through a city
  - which time zone a country uses (as of 2025)

Source: hand-written tables below from general knowledge, checked against standard references
(time zones as of 2025, from the IANA time zone database as commonly published).
Run from the repo root:  python3 tools/knowledge/gen/geo_more.py
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from geo_common import Writer, rng_for  # noqa: E402

# city as typed | answer
RIVERS = r"""
london | London is on the River Thames.
paris | Paris is on the Seine River.
rome | Rome is on the Tiber River.
vienna | Vienna is on the Danube River.
budapest | Budapest is on the Danube River. Buda is on the west bank and Pest on the east bank, and they joined into one city in 1873.
belgrade | Belgrade is where the Sava River flows into the Danube.
bratislava | Bratislava is on the Danube River, right by the borders of Austria and Hungary.
cairo | Cairo is on the Nile River, near where it spreads out into its delta.
baghdad | Baghdad is on the Tigris River.
prague | Prague is on the Vltava River, crossed by the famous Charles Bridge.
warsaw | Warsaw is on the Vistula River.
krakow | Kraków is on the Vistula River, below Wawel Castle.
moscow | Moscow is on the Moskva River, which the city is named after.
st petersburg | St. Petersburg is on the Neva River, where it flows into the Baltic Sea.
berlin | Berlin is on the Spree and Havel rivers.
hamburg | Hamburg is on the Elbe River, and it's one of Europe's biggest ports even though it's about 100 kilometers (60 miles) from the sea.
dresden | Dresden is on the Elbe River.
cologne | Cologne is on the Rhine River.
basel | Basel is on the Rhine River, where Switzerland, France and Germany meet.
lisbon | Lisbon is where the Tagus River meets the Atlantic Ocean.
seville | Seville is on the Guadalquivir River.
florence | Florence is on the Arno River, crossed by the old Ponte Vecchio bridge.
dublin | Dublin is on the River Liffey.
glasgow | Glasgow is on the River Clyde.
kyiv | Kyiv is on the Dnieper River.
montreal | Montreal is on an island in the St. Lawrence River.
quebec city | Quebec City is on the St. Lawrence River.
new orleans | New Orleans is on the Mississippi River, near where it reaches the Gulf of Mexico.
st louis | St. Louis is on the Mississippi River, just south of where the Missouri River joins it.
memphis | Memphis is on the Mississippi River.
minneapolis | Minneapolis is on the Mississippi River, next to its twin city, St. Paul.
pittsburgh | Pittsburgh is where the Allegheny and Monongahela rivers meet to form the Ohio River. It has more than 400 bridges.
cincinnati | Cincinnati is on the Ohio River, across from Kentucky.
louisville | Louisville is on the Ohio River.
washington dc | Washington, DC, is on the Potomac River, across from Virginia.
new york city | New York City is where the Hudson River reaches the Atlantic Ocean. The East River separates Manhattan from Brooklyn and Queens.
portland oregon | Portland, Oregon, is on the Willamette River, near where it joins the Columbia River.
austin | Austin is on the Colorado River of Texas, which is a different river from the big Colorado River out west.
sacramento | Sacramento is where the American River flows into the Sacramento River.
shanghai | Shanghai is on the Huangpu River, near where the Yangtze River reaches the sea.
wuhan | Wuhan is on the Yangtze River, where the Han River joins it.
bangkok | Bangkok is on the Chao Phraya River.
phnom penh | Phnom Penh is where the Mekong and Tonlé Sap rivers meet.
vientiane | Vientiane, the capital of Laos, is on the Mekong River, across from Thailand.
kolkata | Kolkata is on the Hooghly River, a branch of the Ganges.
varanasi | Varanasi is on the Ganges River, and it's one of the holiest cities in Hinduism.
delhi | Delhi is on the Yamuna River.
agra | Agra is on the Yamuna River, and the Taj Mahal stands on its bank.
buenos aires | Buenos Aires is on the Río de la Plata, a wide estuary where the Paraná and Uruguay rivers meet the sea.
manaus | Manaus is near where the Rio Negro meets the Amazon River. The dark and light waters flow side by side for miles without mixing.
khartoum | Khartoum is where the White Nile and the Blue Nile meet to form the Nile.
bamako | Bamako, the capital of Mali, is on the Niger River.
kinshasa | Kinshasa is on the Congo River, right across from Brazzaville, the capital of the Republic of the Congo.
seoul | Seoul is on the Han River.
ottawa | Ottawa is on the Ottawa River, across from Gatineau, Quebec.
winnipeg | Winnipeg is where the Red River and the Assiniboine River meet.
calgary | Calgary is where the Bow River and the Elbow River meet.
brisbane | Brisbane is on the Brisbane River.
perth | Perth is on the Swan River.
melbourne | Melbourne is on the Yarra River.
"""

# code-ish name as typed | answer   (time zones as of 2025)
TIMES = r"""
japan | Japan uses Japan Standard Time, 9 hours ahead of UTC, all year. It doesn't use daylight saving time.
south korea | South Korea uses Korea Standard Time, 9 hours ahead of UTC, all year.
china | China uses one time zone for the whole country, Beijing Time, 8 hours ahead of UTC, all year.
india | India uses India Standard Time, 5 and a half hours ahead of UTC, all year.
pakistan | Pakistan uses Pakistan Standard Time, 5 hours ahead of UTC, all year.
bangladesh | Bangladesh is 6 hours ahead of UTC, all year.
sri lanka | Sri Lanka is 5 and a half hours ahead of UTC, the same as India, all year.
singapore | Singapore is 8 hours ahead of UTC, all year.
malaysia | Malaysia is 8 hours ahead of UTC, all year.
the philippines | The Philippines is 8 hours ahead of UTC, all year.
thailand | Thailand is 7 hours ahead of UTC, all year.
vietnam | Vietnam is 7 hours ahead of UTC, all year.
indonesia | Indonesia has three time zones: Western Indonesia Time (7 hours ahead of UTC, including Jakarta), Central Indonesia Time (8 hours ahead, including Bali) and Eastern Indonesia Time (9 hours ahead).
the uae | The United Arab Emirates is 4 hours ahead of UTC, all year.
saudi arabia | Saudi Arabia is 3 hours ahead of UTC, all year.
qatar | Qatar is 3 hours ahead of UTC, all year.
kenya | Kenya uses East Africa Time, 3 hours ahead of UTC, all year.
ethiopia | Ethiopia uses East Africa Time, 3 hours ahead of UTC. Many Ethiopians also count hours starting at sunrise, so 7 in the morning is called 1 o'clock.
nigeria | Nigeria uses West Africa Time, 1 hour ahead of UTC, all year.
ghana | Ghana uses UTC, the same as London in winter, all year.
south africa | South Africa uses South Africa Standard Time, 2 hours ahead of UTC, all year.
argentina | Argentina is 3 hours behind UTC, all year.
peru | Peru is 5 hours behind UTC, all year.
colombia | Colombia is 5 hours behind UTC, all year.
iceland | Iceland uses UTC all year, with no daylight saving time.
turkey | Turkey has used Turkey Time, 3 hours ahead of UTC, all year since 2016.
afghanistan | Afghanistan is 4 and a half hours ahead of UTC, all year.
iran | As of 2025, Iran is 3 and a half hours ahead of UTC all year, after it stopped using daylight saving time in 2022.
myanmar | Myanmar is 6 and a half hours ahead of UTC, all year.
venezuela | Venezuela is 4 hours behind UTC, all year.
kazakhstan | Kazakhstan has used one time zone, 5 hours ahead of UTC, since March 2024. Before that, it had two.
mexico | As of 2025, most of Mexico, including Mexico City, uses Central Time, 6 hours behind UTC, all year. Mexico stopped daylight saving time in most places in 2022, and it has four time zones.
the uk | The United Kingdom uses Greenwich Mean Time (UTC) in winter and British Summer Time, 1 hour ahead, in summer.
ireland | Ireland uses UTC in winter and Irish Standard Time, 1 hour ahead, in summer.
portugal | Mainland Portugal uses UTC in winter and is 1 hour ahead in summer, the same as the UK. The Azores are 1 hour behind that.
france | Mainland France uses Central European Time, 1 hour ahead of UTC, and moves to 2 hours ahead in summer. With its overseas lands, France covers 12 time zones.
germany | Germany uses Central European Time, 1 hour ahead of UTC, and moves to 2 hours ahead in summer.
spain | Mainland Spain uses Central European Time, 1 hour ahead of UTC, and 2 hours ahead in summer. The Canary Islands are 1 hour behind the mainland.
italy | Italy uses Central European Time, 1 hour ahead of UTC, and moves to 2 hours ahead in summer.
greece | Greece uses Eastern European Time, 2 hours ahead of UTC, and moves to 3 hours ahead in summer.
finland | Finland uses Eastern European Time, 2 hours ahead of UTC, and moves to 3 hours ahead in summer.
egypt | As of 2025, Egypt is 2 hours ahead of UTC in winter and 3 hours ahead in summer, after it brought back daylight saving time in 2023.
brazil | Brazil has four time zones. Brasília Time, used in Rio de Janeiro and São Paulo, is 3 hours behind UTC, and Brazil stopped using daylight saving time in 2019.
new zealand | New Zealand is 12 hours ahead of UTC, and 13 hours ahead in summer with daylight saving time. It's one of the first countries to start each new day.
chile | Most of Chile is 4 hours behind UTC in winter and 3 hours behind in summer. Easter Island is 2 hours behind the mainland.
north korea | North Korea is 9 hours ahead of UTC, the same as South Korea, since 2018.
nepal | Nepal is 5 hours and 45 minutes ahead of UTC, all year.
"""


def main():
    w = Writer(["gen_city_rivers.txt", "gen_country_time.txt"])
    for line in RIVERS.strip().splitlines():
        q, ans = [x.strip() for x in line.split("|", 1)]
        rng = rng_for("river-city", q)
        rest = [f"what river runs through {q}", f"which river flows through {q}", f"river in {q}"]
        rng.shuffle(rest)
        w.add("gen_city_rivers.txt", "geo.city.river", [f"what river is {q} on"] + rest, ans, limit=3)
    for line in TIMES.strip().splitlines():
        q, ans = [x.strip() for x in line.split("|", 1)]
        rng = rng_for("tz", q)
        rest = [f"{q} time zone", f"what is the utc offset of {q}",
                f"does {q} have daylight saving time"]
        rng.shuffle(rest)
        w.add("gen_country_time.txt", "geo.timezone", [f"what time zone is {q} in"] + rest, ans, limit=3)
    w.save("""Generated by tools/knowledge/gen/geo_more.py. Do not edit by hand.
Data: hand-written tables of rivers in cities and country time zones (as of 2025).""")
    for d in w.dropped:
        print("  dropped:", d)


if __name__ == "__main__":
    main()
