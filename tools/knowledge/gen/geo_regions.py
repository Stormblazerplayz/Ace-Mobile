#!/usr/bin/env python3
"""Generates Q&A about the states and provinces of big countries: data/geo/gen_regions.txt

Source: hand-written tables below from general knowledge, checked against standard references.
Covers Canadian provinces and territories, Australian states and territories, Indian states,
German states, Mexican states, Brazilian states and Chinese provinces. Uncertain items are left out
(for example Andhra Pradesh, whose capital has changed more than once).

Run from the repo root:  python3 tools/knowledge/gen/geo_regions.py
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from geo_common import Writer, ascii_fold, rng_for  # noqa: E402

# name | how people type it | capital | biggest city ("" = same) | extra fact ("" = none)
CANADA = r"""
Ontario | ontario | Toronto | | Ontario has more people than any other province, and it's home to both Toronto and Ottawa, the capital of Canada. It joined Canada at Confederation in 1867.
Quebec | quebec | Quebec City | Montreal | Quebec is the only province where French is the only official language, and it joined Canada at Confederation in 1867.
Nova Scotia | nova scotia | Halifax | | Nova Scotia was one of the four original provinces in 1867, and its name means New Scotland in Latin.
New Brunswick | new brunswick | Fredericton | Moncton | New Brunswick is Canada's only officially bilingual province (English and French). It was one of the four original provinces in 1867.
Manitoba | manitoba | Winnipeg | | Manitoba joined Canada in 1870, and the town of Churchill there is famous for polar bears.
British Columbia | british columbia | Victoria | Vancouver | British Columbia joined Canada in 1871. It's on the Pacific coast and known for mountains, forests and Vancouver.
Prince Edward Island | prince edward island | Charlottetown | | Prince Edward Island is Canada's smallest province. It joined in 1873 and is famous for potatoes and Anne of Green Gables.
Alberta | alberta | Edmonton | Calgary | Alberta joined Canada in 1905, and it's known for the Rocky Mountains, Banff National Park, oil, and the Calgary Stampede.
Saskatchewan | saskatchewan | Regina | Saskatoon | Saskatchewan joined Canada in 1905 and grows a huge share of Canada's wheat.
Newfoundland and Labrador | newfoundland | St. John's | | Newfoundland and Labrador was the last province to join Canada, in 1949. Vikings landed there about 1,000 years ago, at L'Anse aux Meadows.
Northwest Territories | northwest territories | Yellowknife | | The Northwest Territories is one of Canada's three territories, and Yellowknife is one of the best places to see the northern lights.
Yukon | yukon | Whitehorse | | Yukon is one of Canada's three territories, famous for the Klondike Gold Rush of the 1890s.
Nunavut | nunavut | Iqaluit | | Nunavut is Canada's newest and biggest territory, created in 1999. Most people who live there are Inuit.
"""
AUSTRALIA = r"""
New South Wales | new south wales | Sydney | | New South Wales has the most people of any Australian state, and it's home to Sydney and the Blue Mountains.
Victoria | victoria australia | Melbourne | | Victoria is Australia's smallest mainland state, known for Melbourne and the Great Ocean Road.
Queensland | queensland | Brisbane | | Queensland is known for the Great Barrier Reef, the Gold Coast, and the Daintree Rainforest.
Western Australia | western australia | Perth | | Western Australia is the biggest Australian state, covering about a third of the country.
South Australia | south australia | Adelaide | | South Australia is known for Adelaide, Kangaroo Island, and the Barossa Valley.
Tasmania | tasmania | Hobart | | Tasmania is an island state south of the mainland, and it's the only place where Tasmanian devils live in the wild.
Northern Territory | northern territory | Darwin | | The Northern Territory is home to Uluru (Ayers Rock) and Kakadu National Park.
Australian Capital Territory | australian capital territory | Canberra | | The Australian Capital Territory was created to hold Canberra, the national capital.
"""
INDIA = r"""
Arunachal Pradesh | arunachal pradesh | Itanagar | |
Assam | assam | Dispur | Guwahati | Assam is famous for Assam tea and one-horned rhinos in Kaziranga National Park.
Bihar | bihar | Patna | |
Chhattisgarh | chhattisgarh | Raipur | |
Goa | goa | Panaji | | Goa is India's smallest state by area, known for its beaches and Portuguese-style churches.
Gujarat | gujarat | Gandhinagar | Ahmedabad | Gujarat is where Mahatma Gandhi was born, and it's home to the Statue of Unity, the tallest statue in the world.
Haryana | haryana | Chandigarh | |
Himachal Pradesh | himachal pradesh | Shimla | |
Jharkhand | jharkhand | Ranchi | |
Karnataka | karnataka | Bengaluru | | Karnataka's capital Bengaluru (Bangalore) is called the Silicon Valley of India.
Kerala | kerala | Thiruvananthapuram | | Kerala is known for its backwaters, houseboats, coconut trees and spices.
Madhya Pradesh | madhya pradesh | Bhopal | Indore |
Maharashtra | maharashtra | Mumbai | | Maharashtra's capital, Mumbai, is India's biggest city and the home of Bollywood.
Manipur | manipur | Imphal | |
Meghalaya | meghalaya | Shillong | | Meghalaya has some of the rainiest places on Earth, like Mawsynram and Cherrapunji, and bridges made of living tree roots.
Mizoram | mizoram | Aizawl | |
Nagaland | nagaland | Kohima | |
Odisha | odisha | Bhubaneswar | |
Punjab | punjab india | Chandigarh | Ludhiana | Punjab is the home of the Golden Temple in Amritsar, the holiest place in Sikhism.
Rajasthan | rajasthan | Jaipur | | Rajasthan is India's biggest state by area, known for the Thar Desert, forts, palaces and Jaipur, the Pink City.
Sikkim | sikkim | Gangtok | |
Tamil Nadu | tamil nadu | Chennai | | Tamil Nadu is known for huge old Hindu temples and the Tamil language.
Telangana | telangana | Hyderabad | | Telangana became India's newest state in 2014, and its capital Hyderabad is famous for biryani.
Tripura | tripura | Agartala | |
Uttar Pradesh | uttar pradesh | Lucknow | | Uttar Pradesh has the most people of any Indian state, and it's home to the Taj Mahal in Agra.
Uttarakhand | uttarakhand | Dehradun | |
West Bengal | west bengal | Kolkata | | West Bengal's capital, Kolkata, used to be the capital of British India.
"""
GERMANY = r"""
Baden-Württemberg | baden-wurttemberg | Stuttgart | | Baden-Württemberg is home to the Black Forest and car makers Mercedes-Benz and Porsche.
Bavaria | bavaria | Munich | | Bavaria is Germany's biggest state by area, known for Oktoberfest, the Alps, and Neuschwanstein Castle.
Brandenburg | brandenburg | Potsdam | | Brandenburg completely surrounds Berlin.
Hesse | hesse | Wiesbaden | Frankfurt |
Lower Saxony | lower saxony | Hanover | |
Mecklenburg-Western Pomerania | mecklenburg-western pomerania | Schwerin | Rostock |
North Rhine-Westphalia | north rhine-westphalia | Düsseldorf | Cologne | North Rhine-Westphalia has the most people of any German state.
Rhineland-Palatinate | rhineland-palatinate | Mainz | |
Saarland | saarland | Saarbrücken | |
Saxony | saxony germany | Dresden | Leipzig |
Saxony-Anhalt | saxony-anhalt | Magdeburg | |
Schleswig-Holstein | schleswig-holstein | Kiel | |
Thuringia | thuringia | Erfurt | |
"""
MEXICO = r"""
Aguascalientes | aguascalientes | Aguascalientes | |
Baja California | baja california | Mexicali | Tijuana |
Baja California Sur | baja california sur | La Paz | |
Campeche | campeche | Campeche | |
Chiapas | chiapas | Tuxtla Gutiérrez | |
Chihuahua | chihuahua mexico | Chihuahua | Ciudad Juárez | Chihuahua is Mexico's biggest state by area, and the tiny chihuahua dog is named after it.
Coahuila | coahuila | Saltillo | |
Colima | colima | Colima | |
Durango | durango | Durango | |
Guanajuato | guanajuato | Guanajuato | León |
Guerrero | guerrero | Chilpancingo | Acapulco |
Hidalgo | hidalgo mexico | Pachuca | |
Jalisco | jalisco | Guadalajara | | Jalisco is the home of mariachi music and tequila.
State of Mexico | state of mexico | Toluca | Ecatepec | The State of Mexico has the most people of any Mexican state, and it wraps around most of Mexico City.
Michoacán | michoacan | Morelia | | Michoacán is where millions of monarch butterflies spend the winter.
Morelos | morelos | Cuernavaca | |
Nayarit | nayarit | Tepic | |
Nuevo León | nuevo leon | Monterrey | |
Oaxaca | oaxaca | Oaxaca | | Oaxaca is known for mole sauce, Day of the Dead celebrations, and the ancient ruins of Monte Albán.
Puebla | puebla | Puebla | |
Querétaro | queretaro | Querétaro | |
Quintana Roo | quintana roo | Chetumal | Cancún | Quintana Roo is home to Cancún, Tulum and lots of Caribbean beaches.
San Luis Potosí | san luis potosi | San Luis Potosí | |
Sinaloa | sinaloa | Culiacán | |
Sonora | sonora | Hermosillo | |
Tabasco | tabasco | Villahermosa | |
Tamaulipas | tamaulipas | Ciudad Victoria | Reynosa |
Tlaxcala | tlaxcala | Tlaxcala | | Tlaxcala is Mexico's smallest state.
Veracruz | veracruz | Xalapa | Veracruz |
Yucatán | yucatan | Mérida | | Yucatán is home to Chichén Itzá and lots of cenotes, natural swimming holes in the limestone.
Zacatecas | zacatecas | Zacatecas | |
"""
BRAZIL = r"""
Acre | acre brazil | Rio Branco | |
Alagoas | alagoas | Maceió | |
Amapá | amapa | Macapá | |
Amazonas | amazonas brazil | Manaus | | Amazonas is Brazil's biggest state, mostly covered by the Amazon rainforest.
Bahia | bahia | Salvador | | Bahia's capital, Salvador, was Brazil's first capital.
Ceará | ceara | Fortaleza | |
Espírito Santo | espirito santo | Vitória | |
Goiás | goias | Goiânia | |
Maranhão | maranhao | São Luís | |
Mato Grosso | mato grosso | Cuiabá | |
Mato Grosso do Sul | mato grosso do sul | Campo Grande | |
Minas Gerais | minas gerais | Belo Horizonte | |
Pará | para brazil | Belém | |
Paraíba | paraiba | João Pessoa | |
Paraná | parana brazil | Curitiba | |
Pernambuco | pernambuco | Recife | |
Piauí | piaui | Teresina | |
Rio de Janeiro | rio de janeiro state | Rio de Janeiro | |
Rio Grande do Norte | rio grande do norte | Natal | |
Rio Grande do Sul | rio grande do sul | Porto Alegre | |
Rondônia | rondonia | Porto Velho | |
Roraima | roraima | Boa Vista | |
Santa Catarina | santa catarina | Florianópolis | Joinville |
São Paulo | sao paulo state | São Paulo | | São Paulo has the most people of any Brazilian state.
Sergipe | sergipe | Aracaju | |
Tocantins | tocantins | Palmas | |
"""
CHINA = r"""
Anhui | anhui | Hefei | |
Fujian | fujian | Fuzhou | |
Gansu | gansu | Lanzhou | |
Guangdong | guangdong | Guangzhou | | Guangdong has the most people of any Chinese province.
Guizhou | guizhou | Guiyang | |
Hainan | hainan | Haikou | | Hainan is China's tropical island province.
Hebei | hebei | Shijiazhuang | |
Heilongjiang | heilongjiang | Harbin | | Heilongjiang's capital Harbin holds a famous ice and snow festival every winter.
Henan | henan | Zhengzhou | |
Hubei | hubei | Wuhan | |
Hunan | hunan | Changsha | |
Jiangsu | jiangsu | Nanjing | Suzhou |
Jiangxi | jiangxi | Nanchang | |
Jilin | jilin | Changchun | |
Liaoning | liaoning | Shenyang | |
Qinghai | qinghai | Xining | |
Shaanxi | shaanxi | Xi'an | | Shaanxi's capital, Xi'an, is home to the Terracotta Army.
Shandong | shandong | Jinan | Qingdao |
Shanxi | shanxi | Taiyuan | |
Sichuan | sichuan | Chengdu | | Sichuan is famous for giant pandas and spicy food with Sichuan peppercorns.
Yunnan | yunnan | Kunming | |
Zhejiang | zhejiang | Hangzhou | |
Tibet | tibet | Lhasa | | Tibet is an autonomous region on the Tibetan Plateau, the highest plateau in the world.
Xinjiang | xinjiang | Ürümqi | | Xinjiang is China's biggest region by area.
Inner Mongolia | inner mongolia | Hohhot | |
Guangxi | guangxi | Nanning | |
Ningxia | ningxia | Yinchuan | |
"""

GROUPS = [
    (CANADA, "Canada", "Canadian province", "geo.canada"),
    (AUSTRALIA, "Australia", "Australian state", "geo.australia"),
    (INDIA, "India", "Indian state", "geo.india"),
    (GERMANY, "Germany", "German state", "geo.germany"),
    (MEXICO, "Mexico", "Mexican state", "geo.mexico"),
    (BRAZIL, "Brazil", "Brazilian state", "geo.brazil"),
    (CHINA, "China", "Chinese province", "geo.china"),
]
TERRITORY = {"Northwest Territories": "Canadian territory", "Yukon": "Canadian territory", "Nunavut": "Canadian territory",
             "Northern Territory": "Australian territory", "Australian Capital Territory": "Australian territory",
             "Tibet": "Chinese autonomous region", "Xinjiang": "Chinese autonomous region",
             "Inner Mongolia": "Chinese autonomous region", "Guangxi": "Chinese autonomous region",
             "Ningxia": "Chinese autonomous region"}


def main():
    f = "gen_regions.txt"
    w = Writer([f])
    for table, country, kind, tag in GROUPS:
        for line in table.strip().splitlines():
            parts = [x.strip() for x in line.split("|")] + [""] * 5
            name, q, capital, big, fact = parts[:5]
            kd = TERRITORY.get(name, kind)
            rng = rng_for(name)
            rest = [f"capital of {q}", f"{q} capital city", f"whats the capital city of {q}",
                    f"what city is the capital of {q}"]
            rng.shuffle(rest)
            if capital == name.replace("State of ", "") or ascii_fold(capital) == ascii_fold(name):
                ans = f"The capital of {name}, {'an' if kd[0] in 'AEIOU' else 'a'} {kd}, is the city of {capital}."
            else:
                ans = f"The capital of {name}, {'an' if kd[0] in 'AEIOU' else 'a'} {kd}, is {capital}."
            w.add(f, tag, [f"what is the capital of {q}"] + rest, ans, limit=4)
            if big:
                rest = [f"largest city in {q}", f"{q} biggest city", f"which city in {q} has the most people"]
                rng.shuffle(rest)
                w.add(f, tag, [f"what is the biggest city in {q}"] + rest,
                      f"The biggest city in {name} is {big}, not the capital, {capital}.", limit=4)
            if fact:
                rest = [f"what is {q} known for", f"tell me something about {q}", f"what is {q} famous for"]
                rng.shuffle(rest)
                w.add(f, tag, [f"facts about {q} {country.lower()}"] + rest, fact, limit=4)
    w.save("""Generated by tools/knowledge/gen/geo_regions.py. Do not edit by hand.
Data: hand-written tables of states and provinces.""")
    for d in w.dropped:
        print("  dropped:", d)


if __name__ == "__main__":
    main()
