#!/usr/bin/env python3
"""Writes data/science/gen_elements.txt: facts about all 118 chemical elements.

Data sources
  1. mendeleev (Python package, MIT license, https://github.com/lmmentel/mendeleev):
     atomic weights, groups, periods, blocks, radioactivity, isotope abundances,
     melting and boiling points (phasetransitions table).
     Install with: pip install mendeleev
  2. Bowserinator/Periodic-Table-JSON (data taken from Wikipedia, CC BY-SA 3.0,
     https://github.com/Bowserinator/Periodic-Table-JSON), downloaded to
     tools/knowledge/.cache/PeriodicTableJSON.json: melting and boiling points,
     electron shells, electron configurations.
  Melting and boiling points are only used when both sources agree within 4% (in kelvin),
  so a value that one source has wrong is left out.
  3. Hand-checked tables in this file: who discovered each element and when, where each
     name comes from, and what common elements are used for. Disputed or unsure facts
     were left out rather than guessed.

Already in Ace's older bank (so not written here): symbol, atomic number and state at
room temperature for every element.

Run from the repo root:  python3 tools/knowledge/gen/science_elements.py
"""
import json
import math
import os
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
KN = os.path.normpath(os.path.join(HERE, ".."))
CACHE = os.path.join(KN, ".cache")
OUT = os.path.join(KN, "data", "science", "gen_elements.txt")
WIKI_URL = "https://raw.githubusercontent.com/Bowserinator/Periodic-Table-JSON/master/PeriodicTableJSON.json"

# Other spellings people use. The older bank uses the British ones.
ALT = {"Aluminum": ["aluminium"], "Cesium": ["caesium"], "Sulfur": ["sulphur"]}
BANK_NAME = {"Aluminum": "Aluminium", "Cesium": "Caesium"}

# Who discovered it and when. "ancient" means known since ancient times.
DISCOVERY = {
    1: "Henry Cavendish identified hydrogen as an element in 1766. Antoine Lavoisier gave it its name in 1783.",
    2: "Helium was first spotted in the Sun's light in 1868 by Pierre Janssen and Norman Lockyer. William Ramsay found it on Earth in 1895.",
    3: "Johan August Arfwedson discovered lithium in 1817, in Sweden.",
    4: "Louis Nicolas Vauquelin discovered beryllium in 1798 in the gem beryl. Friedrich Wöhler and Antoine Bussy first made the pure metal in 1828.",
    5: "Boron was isolated in 1808 by Humphry Davy, and separately by Joseph Louis Gay-Lussac and Louis Jacques Thénard.",
    6: "Carbon has been known since ancient times as charcoal and soot. Antoine Lavoisier showed it was an element in the 1700s.",
    7: "Daniel Rutherford discovered nitrogen in 1772, in Scotland.",
    8: "Oxygen was discovered by Carl Wilhelm Scheele around 1772 and by Joseph Priestley in 1774, working separately. Antoine Lavoisier named it.",
    9: "Henri Moissan first isolated fluorine in 1886 and later won a Nobel Prize for it. Many chemists had been hurt trying before him.",
    10: "William Ramsay and Morris Travers discovered neon in 1898 in London.",
    11: "Humphry Davy discovered sodium in 1807 by passing electricity through melted caustic soda.",
    12: "Joseph Black recognized magnesium as an element in 1755, and Humphry Davy first isolated it in 1808.",
    13: "Hans Christian Ørsted first made aluminium metal in 1825. Friedrich Wöhler improved the method a couple of years later.",
    14: "Jöns Jacob Berzelius first isolated silicon in about 1824.",
    15: "Hennig Brand discovered phosphorus in 1669 while boiling down urine. It was the first element found by a known person.",
    16: "Sulfur has been known since ancient times. It's the brimstone mentioned in old writings.",
    17: "Carl Wilhelm Scheele discovered chlorine in 1774. Humphry Davy proved it was an element in 1810.",
    18: "Lord Rayleigh and William Ramsay discovered argon in 1894. It was the first noble gas found.",
    19: "Humphry Davy discovered potassium in 1807, using electricity on melted potash. It was the first metal isolated by electrolysis.",
    20: "Humphry Davy isolated calcium in 1808 using electrolysis.",
    21: "Lars Fredrik Nilson discovered scandium in 1879. Mendeleev had predicted it years earlier.",
    22: "William Gregor discovered titanium in 1791 in a mineral in Cornwall, England. Martin Klaproth named it in 1795.",
    23: "Andrés Manuel del Río first found vanadium in 1801, but was told he was wrong. Nils Gabriel Sefström rediscovered and named it in 1830.",
    24: "Louis Nicolas Vauquelin discovered chromium in 1797, in a red lead mineral called crocoite.",
    25: "Johan Gottlieb Gahn first isolated manganese in 1774.",
    26: "Iron has been known since ancient times. People have smelted it for over 3,000 years, which started the Iron Age.",
    27: "Georg Brandt discovered cobalt in the 1730s. It was the first metal found that wasn't known in ancient times.",
    28: "Axel Fredrik Cronstedt discovered nickel in 1751, in Sweden.",
    29: "Copper has been used since ancient times, for about 10,000 years. It was one of the first metals people worked.",
    30: "Zinc was made in India and China long ago. Andreas Marggraf isolated it in Europe in 1746.",
    31: "Paul Émile Lecoq de Boisbaudran discovered gallium in 1875. Mendeleev had predicted it, calling it eka-aluminium.",
    32: "Clemens Winkler discovered germanium in 1886. Mendeleev had predicted it, calling it eka-silicon.",
    33: "Arsenic compounds were known in ancient times. Albertus Magnus is often credited with isolating the element around 1250.",
    34: "Jöns Jacob Berzelius discovered selenium in 1817.",
    35: "Antoine Jérôme Balard discovered bromine in 1826 in seawater salts. Carl Löwig found it about the same time.",
    36: "William Ramsay and Morris Travers discovered krypton in 1898.",
    37: "Robert Bunsen and Gustav Kirchhoff discovered rubidium in 1861 using a spectroscope.",
    38: "Adair Crawford recognized strontium as new in 1790, and Humphry Davy isolated it in 1808.",
    39: "Johan Gadolin discovered yttrium in 1794, from a mineral found near Ytterby, Sweden.",
    40: "Martin Heinrich Klaproth discovered zirconium in 1789.",
    41: "Charles Hatchett discovered niobium in 1801. He called it columbium.",
    42: "Carl Wilhelm Scheele recognized molybdenum in 1778, and Peter Jacob Hjelm isolated it in 1781.",
    43: "Carlo Perrier and Emilio Segrè discovered technetium in 1937. It was the first element made artificially.",
    44: "Karl Ernst Claus discovered ruthenium in 1844, in Russia.",
    45: "William Hyde Wollaston discovered rhodium in 1803 while working with platinum ore.",
    46: "William Hyde Wollaston discovered palladium in 1803.",
    47: "Silver has been known since ancient times. People mined it more than 5,000 years ago.",
    48: "Friedrich Stromeyer discovered cadmium in 1817 as an impurity in zinc.",
    49: "Ferdinand Reich and Hieronymus Theodor Richter discovered indium in 1863 by its bright indigo spectrum line.",
    50: "Tin has been known since ancient times. Mixing it with copper made bronze, which started the Bronze Age.",
    51: "Antimony has been known since ancient times. Egyptians used its compound stibnite as black eye makeup.",
    52: "Franz Joseph Müller von Reichenstein discovered tellurium in 1782.",
    53: "Bernard Courtois discovered iodine in 1811 while making gunpowder ingredients from seaweed ash.",
    54: "William Ramsay and Morris Travers discovered xenon in 1898.",
    55: "Robert Bunsen and Gustav Kirchhoff discovered caesium in 1860. It was the first element found with a spectroscope.",
    56: "Humphry Davy isolated barium in 1808. Carl Wilhelm Scheele had spotted it in 1774.",
    57: "Carl Gustaf Mosander discovered lanthanum in 1839.",
    58: "Cerium was discovered in 1803 by Jöns Jacob Berzelius and Wilhelm Hisinger, and separately by Martin Klaproth.",
    59: "Carl Auer von Welsbach discovered praseodymium in 1885.",
    60: "Carl Auer von Welsbach discovered neodymium in 1885.",
    61: "Promethium was discovered in 1945 by Jacob Marinsky, Lawrence Glendenin and Charles Coryell at Oak Ridge.",
    62: "Paul Émile Lecoq de Boisbaudran discovered samarium in 1879.",
    63: "Eugène Anatole Demarçay discovered europium in 1901.",
    64: "Jean Charles Galissard de Marignac discovered gadolinium in 1880.",
    65: "Carl Gustaf Mosander discovered terbium in 1843.",
    66: "Paul Émile Lecoq de Boisbaudran discovered dysprosium in 1886.",
    67: "Per Teodor Cleve discovered holmium in 1878. Marc Delafontaine and Jacques Louis Soret spotted it the same year.",
    68: "Carl Gustaf Mosander discovered erbium in 1843.",
    69: "Per Teodor Cleve discovered thulium in 1879.",
    70: "Jean Charles Galissard de Marignac discovered ytterbium in 1878.",
    71: "Georges Urbain discovered lutetium in 1907. Carl Auer von Welsbach and Charles James found it at about the same time.",
    72: "Dirk Coster and George de Hevesy discovered hafnium in 1923 in Copenhagen.",
    73: "Anders Gustaf Ekeberg discovered tantalum in 1802.",
    74: "Brothers Juan José and Fausto Elhuyar first isolated tungsten in 1783, in Spain.",
    75: "Walter Noddack, Ida Tacke and Otto Berg discovered rhenium in 1925. It was the last stable element found.",
    76: "Smithson Tennant discovered osmium in 1803.",
    77: "Smithson Tennant discovered iridium in 1803, at the same time as osmium.",
    78: "Platinum was used by people in South America long before Europeans knew of it. Antonio de Ulloa described it in 1748.",
    79: "Gold has been known since ancient times. It's one of the first metals people ever used, thousands of years ago.",
    80: "Mercury has been known since ancient times. It was found in Egyptian tombs from about 1500 BC.",
    81: "William Crookes discovered thallium in 1861 by its bright green spectrum line.",
    82: "Lead has been known since ancient times. The Romans used it a lot, even for water pipes.",
    83: "Bismuth was known by the 1400s, but people mixed it up with lead and tin. Claude François Geoffroy showed it was its own element in 1753.",
    84: "Marie and Pierre Curie discovered polonium in 1898. Marie named it after her home country, Poland.",
    85: "Dale Corson, Kenneth MacKenzie and Emilio Segrè made astatine in 1940 at Berkeley.",
    86: "Friedrich Ernst Dorn found radon in 1900 as a gas given off by radium.",
    87: "Marguerite Perey discovered francium in 1939, in Paris. It was the last element found in nature.",
    88: "Marie and Pierre Curie discovered radium in 1898.",
    89: "André Louis Debierne discovered actinium in 1899.",
    90: "Jöns Jacob Berzelius identified thorium in 1829 in a rock sent to him from Norway.",
    91: "Kasimir Fajans and Oswald Göhring first found protactinium in 1913. Otto Hahn and Lise Meitner found a longer lasting form in 1917.",
    92: "Martin Heinrich Klaproth discovered uranium in 1789. Henri Becquerel found it was radioactive in 1896.",
    93: "Edwin McMillan and Philip Abelson made neptunium in 1940 at Berkeley. It was the first element heavier than uranium.",
    94: "Glenn Seaborg's team at Berkeley first made plutonium in 1940, led with Edwin McMillan, Joseph Kennedy and Arthur Wahl.",
    95: "Glenn Seaborg's team at the University of Chicago made americium in 1944.",
    96: "Glenn Seaborg, Ralph James and Albert Ghiorso made curium in 1944.",
    97: "Stanley Thompson, Albert Ghiorso and Glenn Seaborg made berkelium in 1949 at Berkeley.",
    98: "A Berkeley team with Stanley Thompson, Kenneth Street, Albert Ghiorso and Glenn Seaborg made californium in 1950.",
    99: "Einsteinium was found in 1952 in the debris of the first hydrogen bomb test. Albert Ghiorso led the team that identified it.",
    100: "Fermium was found in 1952 in the debris of the first hydrogen bomb test, along with einsteinium.",
    101: "Albert Ghiorso, Glenn Seaborg and their team at Berkeley made mendelevium in 1955, just 17 atoms at first.",
    102: "Teams in Sweden, the US and the Soviet Union all claimed nobelium from 1957 on. Credit went to the lab in Dubna, Russia.",
    103: "Albert Ghiorso's team at Berkeley first made lawrencium in 1961.",
    104: "Rutherfordium was first made in the 1960s by labs in Dubna, Soviet Union, and Berkeley, US, which argued over who was first.",
    105: "Dubnium was first made around 1968 to 1970 by labs in Dubna, Soviet Union, and Berkeley, US, which both claimed it.",
    106: "Albert Ghiorso's team at Berkeley made seaborgium in 1974.",
    107: "Bohrium was first made in 1981 at the GSI lab in Darmstadt, Germany.",
    108: "Hassium was first made in 1984 at the GSI lab in Darmstadt, Germany.",
    109: "Meitnerium was first made in 1982 at the GSI lab in Darmstadt, Germany.",
    110: "Darmstadtium was first made in 1994 at the GSI lab in Darmstadt, Germany.",
    111: "Roentgenium was first made in 1994 at the GSI lab in Darmstadt, Germany.",
    112: "Copernicium was first made in 1996 at the GSI lab in Darmstadt, Germany.",
    113: "Nihonium was made in 2004 by a team at RIKEN in Japan led by Kosuke Morita. It was the first element found in Asia.",
    114: "Flerovium was first made in 1998 at the Joint Institute for Nuclear Research in Dubna, Russia.",
    115: "Moscovium was first made in 2003 by scientists in Dubna, Russia, working with Lawrence Livermore lab in the US.",
    116: "Livermorium was first made in 2000 by scientists in Dubna, Russia, working with Lawrence Livermore lab in the US.",
    117: "Tennessine was first made in 2010 by scientists from Dubna, Russia, and US labs including Oak Ridge in Tennessee.",
    118: "Oganesson was first made in 2002 in Dubna, Russia, by a team working with Lawrence Livermore lab. Only a few atoms have ever been made.",
}

# Where the name comes from.
NAME_ORIGIN = {
    1: "Hydrogen comes from Greek words meaning 'water maker', because it makes water when it burns.",
    2: "Helium comes from helios, the Greek word for the Sun, because it was first found in sunlight.",
    3: "Lithium comes from lithos, the Greek word for stone, because it was found in a mineral.",
    4: "Beryllium is named after the gem beryl, where it was found.",
    5: "Boron is named after borax, the mineral it was made from.",
    6: "Carbon comes from carbo, the Latin word for coal or charcoal.",
    7: "Nitrogen means 'niter maker', because it's found in niter (saltpeter).",
    8: "Oxygen comes from Greek words meaning 'acid maker'. Lavoisier wrongly thought all acids contain oxygen.",
    9: "Fluorine is named after the mineral fluorite, which comes from the Latin fluere, to flow.",
    10: "Neon comes from neos, the Greek word for new.",
    11: "Sodium comes from soda. Its symbol Na comes from its Latin name, natrium.",
    12: "Magnesium is named after Magnesia, a region in Greece.",
    13: "Aluminium is named after alum, a salt that contains it.",
    14: "Silicon comes from silex, the Latin word for flint.",
    15: "Phosphorus comes from a Greek word meaning 'light bringer', because white phosphorus glows in the dark.",
    16: "Sulfur comes from the Latin word sulfur. Old texts also called it brimstone, meaning burning stone.",
    17: "Chlorine comes from chloros, the Greek word for pale green, the color of the gas.",
    18: "Argon comes from argos, the Greek word for lazy, because it barely reacts with anything.",
    19: "Potassium comes from potash. Its symbol K comes from its Latin name, kalium.",
    20: "Calcium comes from calx, the Latin word for lime.",
    21: "Scandium is named after Scandinavia, where it was found.",
    22: "Titanium is named after the Titans, giants from Greek myths.",
    23: "Vanadium is named after Vanadís, another name for the Norse goddess Freyja, because its compounds have beautiful colors.",
    24: "Chromium comes from chroma, the Greek word for color, because its compounds are so colorful.",
    26: "Iron is an old English word. Its symbol Fe comes from the Latin ferrum.",
    27: "Cobalt comes from kobold, a German word for a goblin. Miners blamed goblins for ore that gave them trouble.",
    28: "Nickel comes from the German kupfernickel, meaning roughly 'devil's copper', because miners couldn't get copper out of the ore.",
    29: "Copper comes from the Latin cuprum, after the island of Cyprus where the Romans got it. That's why its symbol is Cu.",
    31: "Gallium comes from Gallia, the Latin name for France, the discoverer's country.",
    32: "Germanium is named after Germany, the discoverer's country.",
    34: "Selenium comes from selene, the Greek word for the Moon.",
    35: "Bromine comes from bromos, the Greek word for stench, because it smells awful.",
    36: "Krypton comes from kryptos, the Greek word for hidden.",
    37: "Rubidium comes from rubidus, Latin for deep red, the color of its spectrum lines.",
    38: "Strontium is named after Strontian, a village in Scotland where its mineral was found.",
    39: "Yttrium is named after Ytterby, a village in Sweden. Four elements are named after it.",
    40: "Zirconium is named after the mineral zircon.",
    41: "Niobium is named after Niobe, daughter of Tantalus in Greek myths, because it's found with tantalum.",
    42: "Molybdenum comes from molybdos, the Greek word for lead, because its ore was mixed up with lead ore.",
    43: "Technetium comes from technetos, Greek for artificial, because it was the first element made by people.",
    44: "Ruthenium comes from Ruthenia, an old Latin name for Russia.",
    45: "Rhodium comes from rhodon, the Greek word for rose, because its salts are pink.",
    46: "Palladium is named after the asteroid Pallas, which had just been discovered.",
    47: "Silver is an old English word. Its symbol Ag comes from the Latin argentum.",
    48: "Cadmium comes from cadmia, the Latin name for calamine, a zinc ore.",
    49: "Indium is named after the indigo blue line in its spectrum.",
    50: "Tin is an old English word. Its symbol Sn comes from the Latin stannum.",
    51: "Antimony's symbol Sb comes from stibium, the Latin name for the mineral stibnite.",
    52: "Tellurium comes from tellus, the Latin word for Earth.",
    53: "Iodine comes from iodes, the Greek word for violet, the color of its vapor.",
    54: "Xenon comes from xenos, the Greek word for stranger or foreigner.",
    55: "Caesium comes from caesius, Latin for sky blue, the color of its spectrum lines.",
    56: "Barium comes from barys, the Greek word for heavy.",
    57: "Lanthanum comes from lanthanein, Greek for to lie hidden, because it hid in another mineral.",
    58: "Cerium is named after Ceres, which had just been discovered and is now called a dwarf planet.",
    59: "Praseodymium comes from Greek words meaning 'green twin'.",
    60: "Neodymium comes from Greek words meaning 'new twin'.",
    61: "Promethium is named after Prometheus, who stole fire from the gods in Greek myths.",
    62: "Samarium is named after the mineral samarskite, which was named after a Russian mining official, Vasili Samarsky-Bykhovets.",
    63: "Europium is named after Europe.",
    64: "Gadolinium is named after Johan Gadolin, a Finnish chemist.",
    65: "Terbium is named after Ytterby, a village in Sweden.",
    66: "Dysprosium comes from dysprositos, Greek for hard to get at.",
    67: "Holmium comes from Holmia, the Latin name for Stockholm.",
    68: "Erbium is named after Ytterby, a village in Sweden.",
    69: "Thulium comes from Thule, an old name for the far north of Europe.",
    70: "Ytterbium is named after Ytterby, a village in Sweden.",
    71: "Lutetium comes from Lutetia, the Latin name for Paris.",
    72: "Hafnium comes from Hafnia, the Latin name for Copenhagen.",
    73: "Tantalum is named after Tantalus from Greek myths, because it can't soak up acid, like Tantalus couldn't drink.",
    74: "Tungsten comes from Swedish words meaning 'heavy stone'. Its symbol W comes from its other name, wolfram.",
    75: "Rhenium comes from Rhenus, the Latin name for the river Rhine.",
    76: "Osmium comes from osme, the Greek word for smell, because its oxide smells strong.",
    77: "Iridium is named after Iris, the Greek goddess of the rainbow, because its salts have many colors.",
    78: "Platinum comes from platina, Spanish for little silver.",
    79: "Gold is an old English word. Its symbol Au comes from the Latin aurum.",
    80: "Mercury is named after the planet Mercury. Its symbol Hg comes from hydrargyrum, Greek for liquid silver.",
    81: "Thallium comes from thallos, the Greek word for a green shoot, because of its bright green spectrum line.",
    82: "Lead is an old English word. Its symbol Pb comes from the Latin plumbum, which is also where the word plumber comes from.",
    84: "Polonium is named after Poland, Marie Curie's home country.",
    85: "Astatine comes from astatos, the Greek word for unstable.",
    86: "Radon is named after radium, which gives it off.",
    87: "Francium is named after France, where it was discovered.",
    88: "Radium comes from radius, the Latin word for ray.",
    89: "Actinium comes from aktis, the Greek word for ray.",
    90: "Thorium is named after Thor, the Norse god of thunder.",
    91: "Protactinium means 'before actinium', because it decays into actinium.",
    92: "Uranium is named after the planet Uranus, which had been discovered a few years earlier.",
    93: "Neptunium is named after the planet Neptune, the next planet after Uranus, just like it comes after uranium.",
    94: "Plutonium is named after Pluto, which comes after Neptune.",
    95: "Americium is named after the Americas.",
    96: "Curium is named after Marie and Pierre Curie.",
    97: "Berkelium is named after Berkeley, California, where it was made.",
    98: "Californium is named after California.",
    99: "Einsteinium is named after Albert Einstein.",
    100: "Fermium is named after Enrico Fermi, who built the first nuclear reactor.",
    101: "Mendelevium is named after Dmitri Mendeleev, who made the periodic table.",
    102: "Nobelium is named after Alfred Nobel, who started the Nobel Prizes.",
    103: "Lawrencium is named after Ernest Lawrence, who invented the cyclotron.",
    104: "Rutherfordium is named after Ernest Rutherford, who discovered the atomic nucleus.",
    105: "Dubnium is named after Dubna, the Russian town with a big nuclear research lab.",
    106: "Seaborgium is named after Glenn Seaborg. He was still alive when it was named, which was very rare.",
    107: "Bohrium is named after Niels Bohr, who made a famous model of the atom.",
    108: "Hassium is named after Hesse, the German state where it was made.",
    109: "Meitnerium is named after Lise Meitner, who helped discover nuclear fission.",
    110: "Darmstadtium is named after Darmstadt, the German city where it was made.",
    111: "Roentgenium is named after Wilhelm Röntgen, who discovered X-rays.",
    112: "Copernicium is named after Nicolaus Copernicus, who said the Earth goes around the Sun.",
    113: "Nihonium comes from Nihon, a Japanese name for Japan.",
    114: "Flerovium is named after the Flerov Laboratory in Dubna, Russia, named for physicist Georgy Flyorov.",
    115: "Moscovium is named after the Moscow region of Russia.",
    116: "Livermorium is named after Lawrence Livermore National Laboratory in California.",
    117: "Tennessine is named after the US state of Tennessee, home of Oak Ridge lab.",
    118: "Oganesson is named after Yuri Oganessian, a Russian physicist who was still alive when it was named.",
}

USES = {
    1: "Hydrogen is used to make ammonia for fertilizer, to process fuels, and as rocket fuel. It can also power fuel cell cars.",
    2: "Helium fills balloons and blimps, and liquid helium cools the magnets in MRI machines. Divers also breathe it mixed with oxygen.",
    3: "Lithium is used in rechargeable batteries for phones, laptops and electric cars. It's also used in some medicines.",
    4: "Beryllium is light and stiff, so it's used in spacecraft, satellites and the mirrors of the James Webb Space Telescope.",
    5: "Boron is used in borosilicate glass like Pyrex, in cleaning products like borax, and in strong magnets.",
    6: "Carbon is in all living things. It's used as graphite in pencils, as diamonds in jewelry and cutting tools, and in steel and fuels.",
    7: "Nitrogen is used to make fertilizer, and liquid nitrogen freezes things very fast. It also fills chip bags to keep them fresh.",
    8: "We breathe oxygen to live. Hospitals give it to patients, and it's used for welding, making steel and burning rocket fuel.",
    9: "Fluorine is used in fluoride toothpaste to protect teeth, in nonstick pan coatings like Teflon, and in refrigerants.",
    10: "Neon is used in bright glowing signs, which shine red orange. It's also used in some lasers.",
    11: "Sodium is part of table salt. Sodium vapor lamps light streets with a yellow glow, and sodium compounds make soap and baking soda.",
    12: "Magnesium makes light, strong alloys for cars, bikes and laptops. It burns with a bright white light in fireworks and flares.",
    13: "Aluminium is used in cans, foil, airplanes, cars, window frames and power lines because it's light and doesn't rust.",
    14: "Silicon is used to make computer chips and solar panels. As sand (silica), it's used to make glass and concrete.",
    15: "Phosphorus is used in fertilizers and on the striking strip of matchboxes. It's also in your bones and DNA.",
    16: "Sulfur is used to make sulfuric acid, rubber tires, fertilizers and matches. It's also used to kill fungus on crops.",
    17: "Chlorine keeps swimming pools and drinking water clean. It's also used to make PVC plastic and bleach.",
    18: "Argon fills light bulbs and is used as a shield gas in welding. It's also used between the panes of double glazed windows.",
    19: "Potassium is mostly used in fertilizers. Your body needs it for nerves and muscles, and bananas are a good source.",
    20: "Calcium builds bones and teeth. Calcium compounds make cement, chalk, plaster and antacid tablets.",
    21: "Scandium is mixed with aluminium to make light, strong parts for aircraft and sports gear like bike frames.",
    22: "Titanium is used in planes, spacecraft, artificial joints and bike frames. Titanium dioxide is the white in paint and sunscreen.",
    23: "Vanadium is added to steel to make it tough, for tools like wrenches. It's also used in big batteries for storing power.",
    24: "Chromium makes stainless steel rustproof and gives car parts and taps their shiny chrome plating.",
    25: "Manganese is mostly used to make steel stronger. It's also in many regular batteries.",
    26: "Iron is used to make steel for buildings, cars, bridges and tools. Your blood also uses iron to carry oxygen.",
    27: "Cobalt is used in rechargeable batteries, tough alloys for jet engines, and blue glass and paint.",
    28: "Nickel is used in stainless steel, coins and rechargeable batteries.",
    29: "Copper is used in electrical wires, water pipes, coins and motors because it conducts electricity and heat very well.",
    30: "Zinc coats steel to stop rust (called galvanizing). It's also used in batteries, brass, sunscreen and coins.",
    31: "Gallium is used in LEDs, lasers and computer chips. It melts in your hand at about 30 °C.",
    32: "Germanium is used in fiber optics, infrared camera lenses and some electronics.",
    33: "Arsenic is very poisonous. Small amounts are used in some computer chips and once in wood preservatives.",
    34: "Selenium is used in glass making, electronics and dandruff shampoo. Your body needs a tiny bit of it.",
    35: "Bromine is used in flame retardants, pool and hot tub cleaners, and some medicines.",
    36: "Krypton is used in some flash lamps for photography, high efficiency windows and certain lights.",
    37: "Rubidium is used in very accurate atomic clocks and in research.",
    38: "Strontium makes the bright red color in fireworks and road flares.",
    39: "Yttrium is used in LEDs, lasers and the screens of old color TVs. It's also used in some superconductors.",
    40: "Zirconium is used in nuclear reactors because it doesn't soak up neutrons. Zirconia is used for fake diamonds and dental crowns.",
    41: "Niobium is used in superconducting magnets, like the ones in MRI machines, and in strong steel for pipelines.",
    42: "Molybdenum is added to steel to make it very strong at high temperatures. It's also used in lubricants.",
    43: "Technetium is used in medical scans. Doctors inject a tiny radioactive amount to see inside organs and bones.",
    44: "Ruthenium is used in electronics like hard drives and to make platinum and palladium harder.",
    45: "Rhodium is used in catalytic converters to clean car exhaust, and to coat jewelry so it shines.",
    46: "Palladium is used in catalytic converters in cars, in electronics, dentistry and jewelry.",
    47: "Silver is used in jewelry, coins, mirrors and electronics. It's the best conductor of electricity of all metals.",
    48: "Cadmium was used in rechargeable batteries and yellow paints. It's toxic, so its use has been cut back.",
    49: "Indium is used in touchscreens and flat screens as indium tin oxide, which conducts electricity and is see-through.",
    50: "Tin coats steel in tin cans so they don't rust, and it's the main metal in solder for electronics.",
    51: "Antimony is used in flame retardants and in lead alloys for car batteries.",
    52: "Tellurium is used in some solar panels and to make steel and copper easier to machine.",
    53: "Iodine is added to salt because your thyroid needs it. It's also used as an antiseptic to clean cuts.",
    54: "Xenon is used in very bright lamps like car headlights and movie projectors, and in ion engines for spacecraft.",
    55: "Caesium is used in atomic clocks, which define the length of a second, and in drilling fluids for oil wells.",
    56: "Barium sulfate is swallowed before X-rays so doctors can see the stomach. Barium also makes green fireworks.",
    57: "Lanthanum is used in camera lenses and in batteries for hybrid cars.",
    58: "Cerium is used in lighter flints, to polish glass, and in catalytic converters.",
    59: "Praseodymium is used in strong magnets and in welders' goggles that block bright yellow light.",
    60: "Neodymium makes the strongest permanent magnets, used in headphones, hard drives, electric motors and wind turbines.",
    61: "Promethium has been used in special long lasting batteries and in glowing paint. It's very rare because it's radioactive.",
    62: "Samarium is used in strong magnets that work at high temperatures, and in some cancer treatments.",
    63: "Europium makes the red and blue glow in some screens and LED lights, and it's in the anti fake marks on euro banknotes.",
    64: "Gadolinium is injected for some MRI scans to make pictures clearer.",
    65: "Terbium is used in green phosphors for screens and in some magnets and sensors.",
    66: "Dysprosium is added to neodymium magnets so they keep working in hot motors, like in electric cars.",
    67: "Holmium is used in medical lasers and in very strong magnets.",
    68: "Erbium boosts the light signals in fiber optic internet cables, and it's used in lasers and pink glass.",
    69: "Thulium is used in some portable X-ray machines and lasers.",
    70: "Ytterbium is used in some lasers and in super accurate atomic clocks used in research.",
    71: "Lutetium is used in PET scan detectors and in some cancer treatments.",
    72: "Hafnium is used in nuclear reactor control rods and in computer chips.",
    73: "Tantalum is used in tiny capacitors in phones and computers, and in implants because the body accepts it.",
    74: "Tungsten has the highest melting point of any metal. It's used in old light bulb filaments, drill bits and heavy alloys.",
    75: "Rhenium is used in jet engine parts that get extremely hot.",
    76: "Osmium is used in very hard alloys, like old fountain pen tips and electrical contacts.",
    77: "Iridium is used in spark plugs and in very hard alloys. A layer of it in rocks helped show an asteroid wiped out the dinosaurs.",
    78: "Platinum is used in catalytic converters, jewelry, lab equipment and some cancer drugs.",
    79: "Gold is used in jewelry, coins and electronics because it never rusts or tarnishes. It also coats astronaut visors.",
    80: "Mercury was used in thermometers and some lights, but it's toxic, so it has mostly been replaced.",
    81: "Thallium is very toxic. Small amounts are used in electronics and some medical heart scans.",
    82: "Lead is used in car batteries and in shields that block X-rays. It's toxic, so it was taken out of paint and petrol.",
    83: "Bismuth is used in stomach medicine like Pepto-Bismol, and as a less toxic swap for lead. Its crystals grow in rainbow colors.",
    84: "Polonium is very radioactive. It has been used to remove static in factories and to power some early space probes.",
    86: "Radon has few uses because it's radioactive. It can build up in basements, so many homes test for it.",
    88: "Radium was once used in glow in the dark watch dials, until people learned how dangerous it is.",
    90: "Thorium has been used in gas lantern mantles and is studied as a nuclear fuel.",
    92: "Uranium is the fuel in nuclear power plants. It was also used in the first atomic bombs.",
    94: "Plutonium is used in nuclear weapons and as a power source for space probes like Voyager and Curiosity.",
    95: "Americium is used in most home smoke detectors. A tiny bit of it helps detect smoke.",
    98: "Californium is used to start up nuclear reactors and to find gold and oil in rocks, because it gives off neutrons.",
}

# Extra spoken phrases kids use for an element ("whats gold used for").
USE_TEMPLATES = ["what is {n} used for", "{n} uses", "what do we use {n} for", "why is {n} useful"]

CATEGORY = {
    "Nonmetals": ("a nonmetal", "nonmetal"),
    "Noble gases": ("a noble gas, so it hardly reacts with anything", "nonmetal"),
    "Alkali metals": ("an alkali metal, a soft and very reactive metal", "metal"),
    "Alkaline earth metals": ("an alkaline earth metal", "metal"),
    "Metalloids": ("a metalloid, with some properties of metals and some of nonmetals", "metalloid"),
    "Halogens": ("a halogen, a very reactive nonmetal", "nonmetal"),
    "Poor metals": ("a post-transition metal (sometimes called a poor metal)", "metal"),
    "Transition metals": ("a transition metal", "metal"),
    "Lanthanides": ("a lanthanide, one of the rare earth metals", "metal"),
    "Actinides": ("an actinide, a radioactive metal", "metal"),
}


def k_to_c(k):
    return k - 273.15


def fmt_temp(k):
    c = k_to_c(k)
    f = c * 9 / 5 + 32
    if abs(c) >= 100:
        cs, fs = round(c), round(f)
    else:
        cs, fs = round(c, 1), round(f, 1)

    def show(x):
        if float(x).is_integer():
            return f"{int(x):,}"
        return f"{x:.1f}"
    return f"{show(cs)} °C ({show(fs)} °F)"


def fmt_mass(w):
    s = f"{w:.3f}".rstrip("0").rstrip(".")
    return s


def load():
    from mendeleev.fetch import fetch_table
    el = fetch_table("elements")
    series = fetch_table("series").set_index("id")["name"].to_dict()
    pt = fetch_table("phasetransitions")
    iso = fetch_table("isotopes")
    os.makedirs(CACHE, exist_ok=True)
    wp = os.path.join(CACHE, "PeriodicTableJSON.json")
    if not os.path.exists(wp):
        urllib.request.urlretrieve(WIKI_URL, wp)
    wiki = {int(e["number"]): e for e in json.load(open(wp, encoding="utf-8"))["elements"]}
    return el, series, pt, iso, wiki


def phase_row(pt, z):
    rows = pt[pt.atomic_number == z]
    if rows.empty:
        return None
    pref = {15: "white", 16: "rhombic", 50: "white", 34: "gray"}
    if z in pref:
        r = rows[rows.allotrope == pref[z]]
        if not r.empty:
            return r.iloc[0]
    return rows.iloc[0]


def agree(a, b):
    try:
        a, b = float(a), float(b)
    except (TypeError, ValueError):
        return False
    if math.isnan(a) or math.isnan(b):
        return False
    return abs(a - b) / b <= 0.04


def main():
    el, series, pt, iso, wiki = load()
    lines = ["# Generated by tools/knowledge/gen/science_elements.py. Do not edit by hand.",
             "# Sources: mendeleev (MIT), Periodic-Table-JSON from Wikipedia (CC BY-SA 3.0), hand-checked tables.",
             "# tag: science.chem.element"]
    count = 0

    def add(qs, a):
        nonlocal count
        seen, out = set(), []
        for q in qs:
            q = q.lower().strip()
            if q and q not in seen:
                seen.add(q)
                out.append(q)
        out = out[:6]
        assert 2 <= len(out), qs
        assert "—" not in a and "–" not in a
        lines.append(" | ".join(out) + " => " + a)
        count += 1

    for _, r in el.sort_values("atomic_number").iterrows():
        z = int(r.atomic_number)
        name = r["name"]
        bank = BANK_NAME.get(name, name)
        disp = bank  # name in answers, matching the older bank's spelling
        n = name.lower()
        names = [n] + ALT.get(name, [])
        n2 = names[-1]  # alternate spelling for one wording when it exists
        sym = r.symbol
        wk = wiki[z]
        ser = series[int(r.series_id)]
        if 57 <= z <= 71:
            ser = "Lanthanides"
        if 89 <= z <= 103:
            ser = "Actinides"
        radioactive = bool(r.is_radioactive)

        # 1. atomic mass
        if z <= 103:
            if z in (43, 61) or z >= 84 and z not in (90, 91, 92):
                a = (f"{disp} has no stable isotopes, so it has no standard atomic mass. Periodic tables usually list "
                     f"[{round(r.atomic_weight)}], the mass number of one of its longest lasting isotopes.")
            else:
                a = (f"The atomic mass of {n} is about {fmt_mass(r.atomic_weight)} u (atomic mass units). "
                     f"That's the average mass of its atoms as found in nature.")
            add([f"what is the atomic mass of {n}", f"{n} atomic mass", f"atomic weight of {n2}",
                 f"how heavy is a {n} atom", f"whats the mass of {n} on the periodic table"], a)

        # 2. where on the table
        if 57 <= z <= 71 or 89 <= z <= 103:
            row = "first" if z <= 71 else "second"
            a = (f"{disp} is in period {int(r.period)}, in the {ser.lower()[:-1]} series. That's the {row} of the "
                 f"two separate rows usually drawn below the main periodic table.")
        else:
            a = f"{disp} is in group {int(r.group_id)} and period {int(r.period)} of the periodic table, in the {r.block}-block."
        add([f"what group is {n} in", f"what period is {n} in", f"where is {n2} on the periodic table",
             f"{n} group and period"], a)

        # 3. category and metal or not
        desc, kind = CATEGORY[ser]
        if z == 84:
            a = "Polonium is usually called a metalloid or a post-transition metal. Charts don't all agree, but it behaves mostly like a metal."
        elif z >= 109:
            a = (f"{disp} is expected to be {desc}, but only a few atoms have ever been made, so scientists can't test "
                 f"it properly.")
        else:
            if kind == "metal":
                a = f"Yes, {n} is a metal. It's {desc}."
            elif kind == "nonmetal":
                a = f"No, {n} is a nonmetal. It's {desc}."
            else:
                a = f"{disp} is {desc}."
            if z == 1:
                a = ("Hydrogen is a nonmetal gas. It sits above the alkali metals in group 1, but it doesn't act like "
                     "them at normal conditions.")
        add([f"is {n} a metal", f"what type of element is {n}", f"is {n} a metal or nonmetal",
             f"what family is {n2} in", f"{n} element category"], a)

        # 4. protons and electrons
        pl = "s" if z != 1 else ""
        a = f"{disp} has {z} proton{pl} in its nucleus. A neutral {n} atom also has {z} electron{pl}."
        add([f"how many protons does {n} have", f"how many electrons does {n} have",
             f"{n} protons and electrons", f"number of protons in {n2}"], a)

        # 5. neutrons, using the most common natural isotope
        nat = iso[(iso.atomic_number == z) & iso.abundance.notna()]
        if not nat.empty and z <= 92:
            top = nat.sort_values("abundance", ascending=False).iloc[0]
            mnum = int(top.mass_number)
            pct = float(top.abundance)
            neu = mnum - z
            if pct > 99.5:
                share = "almost all of it in nature"
            elif pct >= 50:
                share = f"about {round(pct)}% of it in nature"
            else:
                share = f"the most common form, about {round(pct)}% of it in nature"
            a = (f"Most {n} atoms are {n}-{mnum} ({share}), which has {neu} neutron{'s' if neu != 1 else ''}. "
                 f"Other isotopes of {n} have different numbers of neutrons.")
            if z == 1:
                a = ("Most hydrogen atoms have 0 neutrons, just one proton and one electron. Rare forms called "
                     "deuterium and tritium have 1 and 2 neutrons.")
            add([f"how many neutrons does {n} have", f"number of neutrons in {n}", f"{n2} neutrons"], a)

        # 6. discovery
        if z in DISCOVERY:
            add([f"who discovered {n}", f"when was {n} discovered", f"who found {n2}",
                 f"{n} discovery"], DISCOVERY[z])

        # 7. name origin
        if z in NAME_ORIGIN:
            add([f"where does the name {n} come from", f"why is {n} called {n}", f"what does {n} mean",
                 f"how did {n2} get its name"], NAME_ORIGIN[z])

        # 8. uses
        if z in USES:
            add([t.format(n=n) for t in USE_TEMPLATES] + ([f"what is {n2} used for"] if n2 != n else []), USES[z])

        # 9 and 10. melting and boiling points (only when both sources agree)
        ph = phase_row(pt, z)
        if z <= 92 and ph is not None and z not in (2, 6, 33, 85, 87):
            if agree(wk.get("melt"), ph.melting_point):
                k = float(wk["melt"])
                a = f"{disp} melts at about {fmt_temp(k)}."
                if z == 80:
                    a = "Mercury melts (and freezes) at about -38.8 °C (-37.9 °F). That's why it's a liquid at room temperature."
                elif z == 31:
                    a = "Gallium melts at about 29.8 °C (85.6 °F), so it melts in your hand."
                elif k < 293:
                    bk = float(wk["boil"]) if wk.get("boil") not in (None, "None") else 999
                    a += " It's a gas at room temperature." if bk < 293 else " It's a liquid at room temperature."
                add([f"what is the melting point of {n}", f"at what temperature does {n} melt",
                     f"how hot does {n} have to be to melt", f"{n2} melting point"], a)
            if agree(wk.get("boil"), ph.boiling_point):
                k = float(wk["boil"])
                a = f"{disp} boils at about {fmt_temp(k)}."
                if k < 293:
                    a += " That's why it's a gas at room temperature."
                add([f"what is the boiling point of {n}", f"at what temperature does {n} boil",
                     f"when does {n} turn into a gas", f"{n2} boiling point"], a)

        # 11. density (solids and liquids only)
        if z <= 99 and str(wk.get("phase")) != "Gas" and not math.isnan(r.density):
            d = float(r.density)
            ds = f"{d:.2f}".rstrip("0").rstrip(".") if d < 10 else f"{d:.1f}".rstrip("0").rstrip(".")
            if d < 1:
                cmp = "That's less dense than water, so a piece would float."
            elif d < 1.5:
                cmp = f"That's about {d:.1f} times as dense as water."
            else:
                cmp = f"That's about {round(d, 1) if d < 10 else round(d)} times as dense as water."
            if z == 76:
                cmp = "It's the densest element of all, about 22.6 times as dense as water."
            add([f"what is the density of {n}", f"how dense is {n}", f"is {n} heavy for its size",
                 f"{n2} density"], f"{disp} has a density of about {ds} g/cm³. {cmp}")

        # 12. electron shells (Bohr model)
        if z <= 86:
            shells = json.loads(wk["shells"]) if isinstance(wk["shells"], str) else wk["shells"]
            sh = ", ".join(str(x) for x in shells)
            if len(shells) == 1:
                a = f"{disp} has 1 electron shell, holding {shells[0]} electron{'s' if shells[0] > 1 else ''}."
            else:
                a = (f"{disp} has {len(shells)} electron shells. The electrons are arranged {sh}, "
                     f"from the inside out.")
            add([f"how many electron shells does {n} have", f"{n} bohr model", f"electron arrangement of {n}",
                 f"how are the electrons arranged in {n2}"], a)

            # 13. electron configuration
            cfg = wk["electron_configuration_semantic"].strip()
            add([f"what is the electron configuration of {n}", f"{n} electron configuration",
                 f"{n2} electron config"], f"The electron configuration of {disp} is {cfg}.")

            # 14. valence electrons for main group elements
            g = None if math.isnan(r.group_id) else int(r.group_id)
            if g in (1, 2) or (g is not None and 13 <= g <= 18):
                v = g if g <= 2 else g - 10
                if z == 2:
                    v = 2
                a = f"{disp} has {v} valence electron{'s' if v != 1 else ''}, {'the electrons' if v != 1 else 'the electron'} in its outer shell."
                if g == 18:
                    a += " Its outer shell is full, which is why it hardly reacts."
                elif g == 1 and z != 1:
                    a += " It easily gives that one away, which makes it very reactive."
                elif g == 17:
                    a += " It wants one more to fill its shell, so it reacts easily."
                add([f"how many valence electrons does {n} have", f"{n} valence electrons",
                     f"outer electrons in {n2}"], a)

        # 15. radioactive or not
        if radioactive:
            if z in (90, 92):
                a = (f"Yes, {n} is radioactive, but only weakly. It decays so slowly that a lot of the {n} "
                     f"made before Earth formed is still around.")
            elif z >= 93:
                a = f"Yes, {n} is radioactive. All its isotopes are unstable, and it's made by people in labs or reactors."
            else:
                a = f"Yes, {n} is radioactive. None of its isotopes are stable, so it slowly turns into other elements."
        elif z == 83:
            a = ("Bismuth is technically radioactive, but its half-life is over a billion times the age of the "
                 "universe, so it's treated as stable and safe.")
        else:
            a = f"No, {n} is not radioactive in its normal form. It has at least one stable isotope."
            if z == 19:
                a = ("Normal potassium is very slightly radioactive because a tiny part of it is potassium-40. It's "
                     "harmless, and even bananas have some.")
            elif z == 6:
                a = ("Normal carbon is not radioactive. A tiny amount of radioactive carbon-14 exists, which "
                     "scientists use to date old things.")
            elif z == 1:
                a = ("Normal hydrogen is not radioactive. A rare form called tritium is radioactive and is used in "
                     "glowing watch dials and exit signs.")
        add([f"is {n} radioactive", f"does {n2} have radiation", f"does {n} give off radiation"], a)

    with open(OUT, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print(f"wrote {count} entries to {OUT}")


if __name__ == "__main__":
    main()
