#!/usr/bin/env python3
"""Writes data/science/gen_planets.txt, gen_moons.txt and gen_stars.txt.

Data sources (all values hand-checked, rounded for kids):
  - NASA Planetary Fact Sheet (https://nssdc.gsfc.nasa.gov/planetary/factsheet/, public domain):
    diameters, masses, gravity, distances from the Sun, mean temperatures, axial tilts.
  - NASA Solar System Exploration pages (public domain) for moons, dwarf planets and missions.
  - IAU list of the 88 constellations (https://www.iau.org/public/themes/constellations/).
  - Star distances: rounded values from the Hipparcos and Gaia catalogues as given on
    NASA and Wikipedia. Stars whose distance is poorly known are described as such.
Facts that change (moon counts, missions) say "as of 2025".
Light travel times are worked out from the mean distance and the speed of light.

Run from the repo root:  python3 tools/knowledge/gen/science_space.py
"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.normpath(os.path.join(HERE, "..", "data", "science"))
C_KM_S = 299792.458

# name: diameter km, mass in Earths, gravity m/s2, mean distance from Sun (million km), AU,
# temperature text, named-after text, atmosphere text, color text, rings text, surface text,
# made-of text, visits text, tilt text, discovery text, live text
PLANETS = [
    dict(name="mercury", d=4879, mass="about 0.055 times Earth's mass, so about 18 Mercurys would weigh as much as Earth",
         g=3.7, dist=57.9, au=0.39,
         temp="Mercury swings from about 430 °C (800 °F) in the day to about -180 °C (-290 °F) at night. With almost no air, it can't hold onto heat.",
         named="Mercury is named after the Roman messenger god, who was super fast, just like the planet zips around the Sun.",
         atmos="Mercury has almost no atmosphere, just a very thin layer of atoms knocked off its surface by the Sun. You couldn't breathe there.",
         color="Mercury is mostly gray and covered in craters, a lot like our Moon.",
         rings="No, Mercury has no rings and no moons.",
         made="Mercury is a rocky planet with a huge iron core that takes up most of its inside.",
         visits="Mariner 10 flew past Mercury in 1974 and 1975, and MESSENGER orbited it from 2011 to 2015. BepiColombo, from Europe and Japan, launched in 2018 to orbit it.",
         tilt="Mercury is barely tilted at all, only about 0.03 degrees, so it has no real seasons.",
         disc="Nobody discovered Mercury. It's bright enough to see without a telescope, so ancient people knew it thousands of years ago.",
         live="No, people couldn't live on Mercury. It's scorching in the day, freezing at night, and has no air."),
    dict(name="venus", d=12104, mass="about 0.82 times Earth's mass, so it's almost Earth's twin in size and weight",
         g=8.9, dist=108.2, au=0.72,
         temp="Venus is about 465 °C (870 °F) on average, hot enough to melt lead. Its thick carbon dioxide air traps heat, making it the hottest planet.",
         named="Venus is named after the Roman goddess of love and beauty, because it shines so brightly in the sky.",
         atmos="Venus has a very thick atmosphere, mostly carbon dioxide, with clouds of sulfuric acid. The pressure at the surface is about 90 times Earth's.",
         color="Venus looks pale yellowish white because of its thick clouds of sulfuric acid.",
         rings="No, Venus has no rings and no moons.",
         made="Venus is a rocky planet, a lot like Earth inside, with an iron core, a rocky mantle and a crust covered in volcanic plains.",
         visits="The Soviet Venera 7 made the first landing on Venus in 1970, and later Venera landers sent back photos. NASA's Magellan mapped it with radar in the 1990s.",
         tilt="Venus is tilted about 177 degrees, which means it's basically upside down and spins backward compared to most planets.",
         disc="Nobody discovered Venus. It's the brightest planet in the night sky, so people have known it since ancient times.",
         live="No, people couldn't live on Venus. The surface is hot enough to melt lead and the air would crush you."),
    dict(name="earth", d=12756, mass=None, g=9.8, dist=149.6, au=1.0,
         temp="Earth's average surface temperature is about 15 °C (59 °F). The record high is about 57 °C and the record low is about -89 °C.",
         named="Earth's name comes from old English and Germanic words meaning ground or soil. It's the only planet not named after a god.",
         atmos=None, color=None,
         rings="No, Earth doesn't have rings. It has one natural moon.",
         made="Earth is a rocky planet with an iron and nickel core, a thick rocky mantle and a thin crust. About 71% of the surface is covered by water.",
         visits=None,
         tilt="Earth is tilted about 23.4 degrees. That tilt is what gives us seasons.",
         disc=None, live=None),
    dict(name="mars", d=6792, mass="about 0.11 times Earth's mass, so you'd need about 9 Marses to equal one Earth",
         g=3.7, dist=227.9, au=1.52,
         temp="Mars averages about -65 °C (-85 °F). A summer day near the equator can reach about 20 °C, but nights drop below -70 °C.",
         named="Mars is named after the Roman god of war, because its red color reminded people of blood.",
         atmos="Mars has a thin atmosphere, about 1% as thick as Earth's, and it's about 95% carbon dioxide. You'd need a spacesuit to breathe.",
         color=None,
         rings="No, Mars has no rings. It has two small moons, Phobos and Deimos.",
         made="Mars is a rocky planet with an iron core, a rocky mantle and a dusty crust rich in iron oxide, which is rust.",
         visits="Lots of spacecraft have explored Mars. Viking 1 landed in 1976, and rovers like Sojourner, Spirit, Opportunity, Curiosity and Perseverance have driven on it.",
         tilt="Mars is tilted about 25 degrees, close to Earth's 23.4, so it has seasons too. Each one lasts about twice as long as ours.",
         disc="Nobody discovered Mars. You can see it without a telescope as a reddish dot, so ancient people knew it.",
         live="Not without a lot of help. Mars is freezing, has thin unbreathable air and strong radiation, so people would need sealed habitats and spacesuits."),
    dict(name="jupiter", d=142984, mass="about 318 times Earth's mass. It's more than twice as heavy as all the other planets put together",
         g=23.1, dist=778.5, au=5.2,
         temp="The cloud tops of Jupiter are about -110 °C (-166 °F). Deep inside it gets much hotter, thousands of degrees.",
         named="Jupiter is named after the king of the Roman gods, which fits since it's the biggest planet.",
         atmos="Jupiter's atmosphere is mostly hydrogen and helium, with colorful clouds of ammonia. The Great Red Spot is a storm bigger than Earth.",
         color="Jupiter has stripes of white, orange, brown and red, made by bands of clouds blowing in different directions.",
         rings="Yes, Jupiter has rings, but they're thin and faint, made of dust. They were discovered by Voyager 1 in 1979.",
         made="Jupiter is a gas giant, made mostly of hydrogen and helium. Deep down the pressure squeezes hydrogen into a liquid metal.",
         visits="Pioneer 10 flew by Jupiter first in 1973. Galileo orbited it from 1995 to 2003, and Juno has orbited it since 2016.",
         tilt="Jupiter is tilted only about 3 degrees, so it has almost no seasons.",
         disc="Nobody discovered Jupiter. It's one of the brightest things in the night sky, so ancient people knew it. Galileo found its four biggest moons in 1610.",
         live="No. Jupiter has no solid surface to stand on, crushing pressure and deadly radiation."),
    dict(name="saturn", d=120536, mass="about 95 times Earth's mass",
         g=9.0, dist=1432.0, au=9.5,
         temp="Saturn's cloud tops are about -140 °C (-220 °F).",
         named="Saturn is named after the Roman god of farming, who was the father of Jupiter.",
         atmos="Saturn's atmosphere is mostly hydrogen and helium. Its winds can blow at about 1,800 km/h, and it has a six sided storm at its north pole.",
         color="Saturn looks pale yellow and butterscotch colored, from ammonia clouds in its upper atmosphere.",
         rings="Yes, Saturn has the biggest and brightest rings of any planet. They're made of billions of chunks of ice and rock, but they're only about 10 meters thick in most places.",
         made="Saturn is a gas giant, made mostly of hydrogen and helium. It's the only planet less dense than water.",
         visits="Pioneer 11 and both Voyagers flew past Saturn. Cassini orbited it from 2004 to 2017 and dropped the Huygens probe onto its moon Titan.",
         tilt="Saturn is tilted about 27 degrees, so it has seasons that each last about 7 Earth years.",
         disc="Nobody discovered Saturn. It's visible without a telescope, so ancient people knew it. Galileo first saw its rings in 1610 but couldn't tell what they were.",
         live="No. Saturn has no solid surface, and its pressure, cold and winds would destroy any spacecraft that sank in."),
    dict(name="uranus", d=51118, mass="about 14.5 times Earth's mass",
         g=8.7, dist=2867.0, au=19.2,
         temp="Uranus is about -195 °C (-320 °F) at its cloud tops. It has recorded the coldest temperatures of any planet, around -224 °C.",
         named="Uranus is named after Ouranos, the Greek god of the sky. It's the only planet named after a Greek god instead of a Roman one.",
         atmos="Uranus has an atmosphere of hydrogen, helium and methane. The methane soaks up red light, which makes the planet look blue green.",
         color="Uranus is pale blue green. Methane gas in its air absorbs red light and reflects blue and green.",
         rings="Yes, Uranus has 13 known rings. They're thin and dark and were found in 1977.",
         made="Uranus is an ice giant. Under its gas layers is a thick slushy layer of water, ammonia and methane ices around a small rocky core.",
         visits="Only one spacecraft has visited Uranus: Voyager 2 flew past it in 1986.",
         tilt="Uranus is tilted about 98 degrees, so it basically rolls around the Sun on its side. Each pole gets about 42 years of sunlight, then 42 years of darkness.",
         disc="William Herschel discovered Uranus in 1781 with a telescope. It was the first planet found that ancient people didn't know about.",
         live="No. Uranus has no solid surface, it's freezing cold, and its air isn't breathable."),
    dict(name="neptune", d=49528, mass="about 17 times Earth's mass",
         g=11.0, dist=4515.0, au=30.1,
         temp="Neptune's cloud tops are about -200 °C (-330 °F).",
         named="Neptune is named after the Roman god of the sea, because of its deep blue color.",
         atmos="Neptune's atmosphere is hydrogen, helium and methane. It has the fastest winds in the solar system, about 2,000 km/h.",
         color="Neptune is a deep blue, partly from methane gas in its air, which absorbs red light.",
         rings="Yes, Neptune has 5 main rings. They're faint, dark and made of dust and ice.",
         made="Neptune is an ice giant, with a thick layer of water, ammonia and methane ices around a rocky core.",
         visits="Only Voyager 2 has visited Neptune. It flew past in 1989 and found its Great Dark Spot storm.",
         tilt="Neptune is tilted about 28 degrees, a bit more than Earth. Its seasons each last about 40 years.",
         disc="Neptune was discovered in 1846 by Johann Galle, using math predictions by Urbain Le Verrier. John Couch Adams made similar predictions too.",
         live="No. Neptune has no solid surface, it's freezing, and it has violent winds."),
]


def light_time(mkm):
    secs = mkm * 1e6 / C_KM_S
    mins = secs / 60
    if mins < 100:
        return f"about {round(mins)} minutes" if mins >= 10 else f"about {mins:.1f} minutes"
    hrs = mins / 60
    return f"about {hrs:.1f} hours"


def planets(add):
    for p in PLANETS:
        n = p["name"]
        N = n.capitalize()
        # size
        ratio = p["d"] / 12756
        if n == "earth":
            a = "Earth is about 12,756 km (7,926 miles) wide at the equator. It's the biggest of the four rocky planets."
        else:
            if ratio > 1.2:
                cmp = f"about {ratio:.1f} times as wide as Earth" if ratio < 9 else f"about {round(ratio)} times as wide as Earth"
            elif ratio > 0.9:
                cmp = "almost the same size as Earth"
            else:
                cmp = f"about {round(ratio * 100)}% as wide as Earth"
            miles = round(p["d"] * 0.621371, -1)
            a = f"{N} is about {p['d']:,} km ({int(miles):,} miles) wide, {cmp}."
        add([f"how big is {n}", f"how wide is {n}", f"diameter of {n}", f"what size is {n}",
             f"is {n} bigger than earth" if n != "earth" else "how wide is the earth"], a)
        # gravity and weight
        if n != "earth":
            r = p["g"] / 9.8
            ex = round(40 * r)
            a = (f"Gravity on {N} is about {p['g']} m/s², {round(r * 100)}% of Earth's. Someone who weighs 40 kg on Earth "
                 f"would feel like they weigh about {ex} kg there.")
            if n in ("jupiter", "saturn", "uranus", "neptune"):
                a += " That's measured at the cloud tops, since there's no ground."
            add([f"how strong is gravity on {n}", f"how much would i weigh on {n}", f"gravity on {n}",
                 f"what is the gravity of {n}"], a)
        else:
            add(["how strong is gravity on earth", "what is earth's gravity", "gravity on earth in m/s2"],
                "Gravity on Earth pulls with about 9.8 m/s². That means a falling object speeds up by about 9.8 meters per second every second, if you ignore air.")
        # temperature
        add([f"how hot is {n}", f"how cold is {n}", f"what is the temperature on {n}", f"{n} temperature"],
            p["temp"])
        # distance from Sun
        miles = round(p["dist"] * 0.621371)
        a = (f"{N} is about {p['dist']:,} million km ({miles:,} million miles) from the Sun on average. "
             f"That's {p['au']} AU, where 1 AU is Earth's distance from the Sun.")
        if n == "earth":
            a = "Earth is about 150 million km (93 million miles) from the Sun on average. That distance is called 1 astronomical unit (AU)."
        add([f"how far is {n} from the sun", f"distance from the sun to {n}", f"how far away is {n} from the sun"], a)
        # light time
        if n != "earth":
            add([f"how long does sunlight take to reach {n}", f"how long does light from the sun take to get to {n}",
                 f"light travel time to {n}"],
                f"Sunlight takes {light_time(p['dist'])} to reach {N}, traveling at about 300,000 km per second.")
        # name
        add([f"why is {n} called {n}", f"who named {n}", f"what is {n} named after", f"where did {n} get its name"],
            p["named"])
        # atmosphere
        if p["atmos"]:
            add([f"does {n} have an atmosphere", f"what is the air like on {n}", f"can you breathe on {n}",
                 f"what is {n}s atmosphere made of"], p["atmos"])
        if p["color"]:
            add([f"what color is {n}", f"why is {n} that color", f"what does {n} look like"], p["color"])
        add([f"does {n} have rings", f"how many rings does {n} have", f"{n} rings"], p["rings"])
        add([f"what is {n} made of", f"is {n} rocky or gas", f"what is inside {n}", f"is {n} solid"], p["made"])
        if p["visits"]:
            add([f"what spacecraft have visited {n}", f"has anything landed on {n}", f"missions to {n}",
                 f"who has been to {n}"], p["visits"])
        add([f"how tilted is {n}", f"what is the axial tilt of {n}", f"does {n} have seasons"], p["tilt"])
        if p["disc"]:
            qs = [f"who discovered {n}", f"when was {n} discovered", f"who found {n}"]
            if n == "mercury":
                qs = ["who discovered the planet mercury", "when was the planet mercury discovered", "who found planet mercury"]
            add(qs, p["disc"])
        if p["live"]:
            add([f"can humans live on {n}", f"could we live on {n}", f"can you survive on {n}",
                 f"could people go to {n}"], p["live"])
        if p["mass"]:
            add([f"how heavy is {n}", f"what is the mass of {n}", f"how much mass does {n} have"],
                f"{N} has {p['mass']}.")


# Big planets: how many Earths fit
FIT = [("jupiter", "About 1,300 Earths could fit inside Jupiter."),
       ("saturn", "About 760 Earths could fit inside Saturn, not counting its rings."),
       ("uranus", "About 63 Earths could fit inside Uranus."),
       ("neptune", "About 57 Earths could fit inside Neptune."),
       ("mars", "Mars is about half as wide as Earth. By volume, you could fit about 6 or 7 Mars-sized planets inside Earth.")]

DWARFS = [
    ("pluto", [
        (["how big is pluto", "how wide is pluto", "is pluto smaller than the moon"],
         "Pluto is about 2,377 km wide. That's smaller than Earth's Moon, which is about 3,475 km wide."),
        (["who discovered pluto", "when was pluto discovered", "who found pluto"],
         "Clyde Tombaugh discovered Pluto in 1930 at Lowell Observatory in Arizona, by comparing photos of the sky."),
        (["who named pluto", "why is pluto called pluto", "what is pluto named after"],
         "Pluto was named by Venetia Burney, an 11-year-old girl in England, in 1930. Pluto is the Roman god of the underworld."),
        (["how many moons does pluto have", "what are plutos moons", "pluto moons"],
         "Pluto has 5 known moons: Charon, Styx, Nix, Kerberos and Hydra. Charon is so big that Pluto and Charon orbit a point between them."),
        (["how long is a year on pluto", "how long does pluto take to orbit the sun", "pluto orbit time"],
         "A year on Pluto lasts about 248 Earth years. Since it was found in 1930, it hasn't finished even half an orbit."),
        (["how long is a day on pluto", "how fast does pluto spin", "pluto day length"],
         "A day on Pluto lasts about 6.4 Earth days, and it spins backward compared to Earth."),
        (["how cold is pluto", "what is the temperature on pluto", "how hot is pluto"],
         "Pluto is about -230 °C (-380 °F), cold enough to freeze nitrogen and methane into ice."),
        (["when was pluto demoted", "when did pluto stop being a planet", "who decided pluto isnt a planet"],
         "In 2006 the International Astronomical Union decided Pluto is a dwarf planet, because it hasn't cleared other objects out of its orbit."),
        (["what is the heart on pluto", "does pluto have a heart", "what is tombaugh regio"],
         "Pluto's heart is a big bright area called Tombaugh Regio. Its left half, Sputnik Planitia, is a huge plain of frozen nitrogen."),
        (["what spacecraft visited pluto", "what is new horizons", "has anything been to pluto"],
         "NASA's New Horizons flew past Pluto in July 2015 and sent back the first close up pictures. It launched in 2006."),
        (["how far is pluto from the sun", "distance to pluto", "how far away is pluto"],
         "Pluto is on average about 5.9 billion km (3.7 billion miles) from the Sun, about 40 times farther than Earth."),
    ]),
    ("ceres", [
        (["what is ceres", "is ceres a planet", "where is ceres"],
         "Ceres is a dwarf planet in the asteroid belt between Mars and Jupiter. It's the biggest object there, about 940 km wide."),
        (["who discovered ceres", "when was ceres discovered", "who found ceres"],
         "Giuseppe Piazzi discovered Ceres in 1801. It was called a planet at first, then an asteroid, and since 2006 a dwarf planet."),
        (["has anything visited ceres", "what is the dawn mission", "dawn spacecraft"],
         "NASA's Dawn spacecraft orbited the asteroid Vesta and then Ceres, from 2015 to 2018. It found bright salt deposits in Ceres' craters."),
    ]),
    ("eris", [
        (["what is eris", "how big is eris", "is eris bigger than pluto"],
         "Eris is a dwarf planet far beyond Pluto. It's about 2,330 km wide, just a bit smaller than Pluto but more massive."),
        (["who discovered eris", "when was eris discovered", "why is eris important"],
         "Eris was found in 2005 by Mike Brown, Chad Trujillo and David Rabinowitz. Finding it led to Pluto being renamed a dwarf planet in 2006."),
        (["what is eris named after", "why is eris called eris", "eris name meaning"],
         "Eris is named after the Greek goddess of strife and discord, because its discovery caused a big argument about what counts as a planet."),
    ]),
    ("haumea", [
        (["what is haumea", "why is haumea shaped like an egg", "haumea dwarf planet"],
         "Haumea is a dwarf planet beyond Neptune. It spins so fast, once every 4 hours, that it's stretched into an egg shape. It also has a ring."),
    ]),
    ("makemake", [
        (["what is makemake", "makemake dwarf planet", "how do you say makemake"],
         "Makemake is a dwarf planet in the Kuiper belt, found in 2005. It's named after a creator god of the people of Rapa Nui (Easter Island), and it's said MAH-kay-MAH-kay."),
    ]),
]

# moon name, entries
MOONS = [
    ("the moon", [
        (["how was the moon formed", "where did the moon come from", "how did the moon get there"],
         "Most scientists think the Moon formed about 4.5 billion years ago when a Mars-sized object called Theia smashed into the young Earth. The debris clumped into the Moon."),
        (["how old is the moon", "age of the moon", "how many years old is the moon"],
         "The Moon is about 4.5 billion years old, only a little younger than Earth."),
        (["what is the moon made of", "is the moon made of rock", "what are moon rocks made of"],
         "The Moon is made of rock, with a small iron core. Its surface is covered in a dusty layer called regolith."),
        (["how strong is gravity on the moon", "how much would i weigh on the moon", "moon gravity"],
         "Gravity on the Moon is about 1.6 m/s², around one sixth of Earth's. Someone who weighs 60 kg on Earth would feel like 10 kg there."),
        (["does the moon have an atmosphere", "is there air on the moon", "can you breathe on the moon"],
         "The Moon has almost no atmosphere, so there's no air to breathe and the sky is black even in daytime."),
        (["how hot is the moon", "how cold is the moon", "temperature on the moon"],
         "The Moon's surface gets to about 120 °C (250 °F) in sunlight and drops to about -130 °C (-208 °F) at night. Some dark craters are even colder."),
        (["why does the moon have craters", "what made the craters on the moon", "moon craters"],
         "Asteroids and comets hit the Moon over billions of years. With no air, wind or rain to wear them away, the craters stay for ages."),
        (["what are the dark spots on the moon", "what are the maria on the moon", "what is the man in the moon"],
         "The dark patches are called maria, Latin for seas. They're plains of old hardened lava, not water. People see faces or a rabbit in them."),
        (["is the moon moving away from earth", "is the moon getting farther away", "how fast is the moon drifting away"],
         "Yes. The Moon moves about 3.8 cm farther from Earth each year, about as fast as your fingernails grow."),
        (["how long does the moon take to orbit earth", "how long is a lunar month", "moon orbit time"],
         "The Moon orbits Earth in about 27.3 days. A full cycle of phases, from new moon to new moon, takes about 29.5 days."),
        (["is there water on the moon", "does the moon have ice", "water ice on the moon"],
         "Yes, there's water ice on the Moon, mostly hidden in very cold, always shadowed craters near the poles. That's why missions want to go to the south pole."),
        (["why is the moon sometimes out in the day", "why can i see the moon during the day", "moon in the daytime"],
         "The Moon is up during the day for part of most months. It's bright enough to see because it reflects sunlight, even when the sky is blue."),
        (["why does the moon look bigger near the horizon", "what is the moon illusion", "why is the moon huge tonight"],
         "That's the moon illusion. The Moon isn't actually bigger near the horizon. Your brain just judges its size differently when it's near trees and buildings."),
        (["what is a supermoon", "why is the moon so big sometimes", "supermoon meaning"],
         "A supermoon is a full moon that happens when the Moon is near its closest point to Earth. It looks up to about 14% bigger and 30% brighter than the smallest full moon."),
        (["what is a blue moon", "is a blue moon really blue", "once in a blue moon meaning"],
         "A blue moon usually means the second full moon in one calendar month. It isn't actually blue. It happens about every 2 to 3 years."),
        (["does the moon have earthquakes", "what are moonquakes", "are there moonquakes"],
         "Yes, the Moon has moonquakes. Seismometers left by the Apollo astronauts recorded them for years."),
        (["how many people have walked on the moon", "how many astronauts went to the moon", "people who walked on the moon"],
         "Twelve people have walked on the Moon, all American astronauts on six Apollo missions from 1969 to 1972."),
        (["who was the last person on the moon", "last man on the moon", "when did people last go to the moon"],
         "Eugene Cernan was the last person to walk on the Moon, on Apollo 17 in December 1972."),
    ]),
    ("io", [
        (["what is io", "tell me about io moon", "io jupiter moon"],
         "Io is one of Jupiter's four big moons. It's the most volcanic place in the solar system, with hundreds of active volcanoes."),
        (["why is io so volcanic", "why does io have volcanoes", "io volcanoes"],
         "Jupiter's huge gravity, plus tugs from the other moons, squeezes and stretches Io. That flexing heats its inside and powers its volcanoes."),
    ]),
    ("europa", [
        (["what is europa", "tell me about europa moon", "europa jupiter moon"],
         "Europa is one of Jupiter's big moons, a bit smaller than our Moon. It's covered in ice, with a salty ocean underneath."),
        (["could there be life on europa", "does europa have an ocean", "is there water on europa"],
         "Europa likely has a salty ocean under its ice with about twice as much water as all of Earth's oceans. That makes it one of the best places to look for life."),
        (["what is europa clipper", "europa clipper mission", "when will europa clipper get to jupiter"],
         "Europa Clipper is a NASA spacecraft that launched in October 2024. It's set to reach Jupiter in 2030 and fly past Europa many times to study its ocean."),
    ]),
    ("ganymede", [
        (["what is ganymede", "what is the biggest moon in the solar system", "largest moon"],
         "Ganymede, a moon of Jupiter, is the biggest moon in the solar system. At about 5,268 km wide, it's even bigger than the planet Mercury."),
        (["does ganymede have a magnetic field", "ganymede facts", "what is special about ganymede"],
         "Ganymede is the only moon known to have its own magnetic field. It probably has a salty ocean buried under its ice too."),
    ]),
    ("callisto", [
        (["what is callisto", "callisto moon", "tell me about callisto"],
         "Callisto is Jupiter's second biggest moon. It's one of the most heavily cratered objects in the solar system, and its surface is very old."),
    ]),
    ("galilean", [
        (["what are the galilean moons", "who discovered jupiters moons", "jupiters four big moons"],
         "The Galilean moons are Jupiter's four biggest moons: Io, Europa, Ganymede and Callisto. Galileo Galilei discovered them in 1610 with an early telescope."),
        (["what is the biggest moon of jupiter", "jupiter biggest moon", "largest moon of jupiter"],
         "Ganymede is Jupiter's biggest moon, and the biggest moon in the whole solar system."),
    ]),
    ("titan", [
        (["what is titan", "tell me about titan moon", "titan saturn moon"],
         "Titan is Saturn's biggest moon and the second biggest in the solar system. It's the only moon with a thick atmosphere."),
        (["does titan have lakes", "what are the lakes on titan made of", "is there liquid on titan"],
         "Yes, Titan has lakes and seas, but they're filled with liquid methane and ethane, not water. It even rains methane there."),
        (["who discovered titan", "when was titan discovered", "who found saturns moon titan"],
         "Christiaan Huygens discovered Titan in 1655."),
        (["what is dragonfly", "dragonfly mission to titan", "nasa drone to titan"],
         "Dragonfly is a NASA drone, like a car sized quadcopter, planned to fly around Titan. As of 2025, it's set to launch in 2028."),
        (["what is the biggest moon of saturn", "saturn biggest moon", "largest moon of saturn"],
         "Titan is Saturn's biggest moon. It's bigger than the planet Mercury."),
    ]),
    ("enceladus", [
        (["what is enceladus", "tell me about enceladus", "enceladus geysers"],
         "Enceladus is a small, icy moon of Saturn. It shoots geysers of water vapor and ice from cracks near its south pole, from an ocean underneath."),
        (["could there be life on enceladus", "does enceladus have an ocean", "is there water on enceladus"],
         "Enceladus has a salty ocean under its ice. Cassini flew through its spray and found water, salt and simple organic chemicals, so it's a top place to search for life."),
    ]),
    ("mimas", [
        (["what is mimas", "why does mimas look like the death star", "mimas moon"],
         "Mimas is a small moon of Saturn with a giant crater called Herschel. The crater makes it look a lot like the Death Star from Star Wars."),
    ]),
    ("iapetus", [
        (["what is iapetus", "why is iapetus two colors", "iapetus moon"],
         "Iapetus is a moon of Saturn with one side dark as coal and the other bright as snow. It also has a strange ridge around its middle."),
    ]),
    ("triton", [
        (["what is triton", "tell me about triton", "neptunes biggest moon"],
         "Triton is Neptune's biggest moon. It orbits backward, which means it was probably a captured object from the Kuiper belt. It has geysers of nitrogen."),
        (["who discovered triton", "when was triton discovered", "who found neptunes moon"],
         "William Lassell discovered Triton in 1846, just 17 days after Neptune itself was discovered."),
    ]),
    ("charon", [
        (["what is charon", "plutos biggest moon", "how big is charon"],
         "Charon is Pluto's biggest moon, about 1,212 km wide, roughly half the size of Pluto. They face each other with the same side all the time."),
    ]),
    ("phobos", [
        (["what is phobos", "tell me about phobos", "is phobos going to crash into mars"],
         "Phobos is the bigger of Mars's two moons, about 22 km wide and lumpy like a potato. It's slowly spiraling inward and will break apart or crash in about 50 million years."),
    ]),
    ("deimos", [
        (["what is deimos", "tell me about deimos", "mars smaller moon"],
         "Deimos is the smaller of Mars's two moons, only about 12 km wide. Both moons were discovered by Asaph Hall in 1877."),
        (["what are the moons of mars called", "names of mars moons", "phobos and deimos meaning"],
         "Mars's moons are Phobos and Deimos, which mean fear and panic in Greek. They're named after the sons of Ares, the Greek god of war."),
    ]),
    ("miranda", [
        (["what is miranda", "miranda moon of uranus", "what is the biggest cliff in the solar system"],
         "Miranda is a small moon of Uranus with a jumbled surface. It has Verona Rupes, a cliff about 20 km tall, one of the tallest known."),
    ]),
    ("titania", [
        (["what is the biggest moon of uranus", "what is titania", "uranus biggest moon"],
         "Titania is the biggest moon of Uranus, about 1,577 km wide. Uranus's moons are named after characters from Shakespeare and Alexander Pope."),
        (["why are uranus moons named after shakespeare", "how are uranus moons named", "uranus moon names"],
         "Uranus's moons are named after characters from Shakespeare plays and Alexander Pope's poem, like Titania, Oberon, Miranda, Ariel and Puck."),
    ]),
]

STARS = [
    # name, constellation, distance text, type text, extra
    ("sirius", "Canis Major", "about 8.6 light years", "a hot white main sequence star with a tiny white dwarf partner",
     "It's the brightest star in the night sky, and it's nicknamed the Dog Star."),
    ("canopus", "Carina", "about 310 light years", "a giant white star", "It's the second brightest star in the night sky and is mostly seen from the Southern Hemisphere."),
    ("alpha centauri", "Centaurus", "about 4.37 light years", "a system of three stars: Alpha Centauri A, B and Proxima Centauri",
     "It's the closest star system to the Sun and the third brightest star in the night sky."),
    ("proxima centauri", "Centaurus", "about 4.24 light years", "a small, dim red dwarf",
     "It's the closest star to the Sun, but it's too faint to see without a telescope. At least one planet orbits it."),
    ("arcturus", "Bootes", "about 37 light years", "an orange giant star", "It's the brightest star in the northern half of the sky."),
    ("vega", "Lyra", "about 25 light years", "a bright blue white star", "It's one of the three stars of the Summer Triangle, with Deneb and Altair."),
    ("capella", "Auriga", "about 43 light years", "actually two pairs of stars, with two yellow giants that look like one", "It's one of the brightest stars in winter skies in the north."),
    ("rigel", "Orion", "roughly 860 light years", "a blue supergiant, thousands of times brighter than the Sun", "It marks Orion's foot."),
    ("procyon", "Canis Minor", "about 11.5 light years", "a white star with a white dwarf partner", "It's one of the closest bright stars to us."),
    ("betelgeuse", "Orion", "roughly 500 to 700 light years (it's hard to measure)", "a red supergiant, so big it would reach past Mars if it replaced the Sun",
     "It marks Orion's shoulder and will explode as a supernova someday, probably within the next 100,000 years."),
    ("altair", "Aquila", "about 17 light years", "a white star that spins so fast it bulges at the middle", "It's part of the Summer Triangle."),
    ("aldebaran", "Taurus", "about 65 light years", "an orange giant star", "It's the red orange eye of Taurus the bull."),
    ("antares", "Scorpius", "roughly 550 light years", "a red supergiant", "Its name means rival of Mars, because it's red like Mars. It's the heart of the scorpion."),
    ("spica", "Virgo", "about 250 light years", "a pair of hot blue stars orbiting very close together", "It's the brightest star in Virgo."),
    ("pollux", "Gemini", "about 34 light years", "an orange giant star with at least one planet", "It's one of the twin stars of Gemini, with Castor."),
    ("deneb", "Cygnus", "very far, probably well over 1,500 light years", "a white supergiant, one of the most powerful stars we can see without a telescope",
     "It forms the tail of Cygnus the swan and is part of the Summer Triangle."),
    ("regulus", "Leo", "about 79 light years", "a hot blue white star that spins very fast", "It marks the heart of Leo the lion."),
    ("fomalhaut", "Piscis Austrinus", "about 25 light years", "a white star surrounded by a ring of dust", "It's sometimes called the loneliest star because there are no other bright stars near it."),
    ("barnards star", "Ophiuchus", "about 6 light years", "a small red dwarf", "It's the closest single star to the Sun and moves across the sky faster than any other star."),
    ("castor", "Gemini", "about 51 light years", "six stars in three pairs that look like one point", "It's one of the twin stars of Gemini, with Pollux."),
]

# (name, other names, meaning, brightest star or None)
CONSTELLATIONS = [
    ("andromeda", [], "a chained princess from Greek myths, the daughter of Cassiopeia", "Alpheratz"),
    ("antlia", [], "an air pump, named in the 1750s", None),
    ("apus", [], "a bird of paradise", None),
    ("aquarius", ["the water bearer"], "a water bearer pouring water from a jar", "Sadalsuud"),
    ("aquila", ["the eagle"], "an eagle, which carried Zeus's thunderbolts in Greek myths", "Altair"),
    ("ara", [], "an altar", None),
    ("aries", ["the ram"], "a ram with a golden fleece from Greek myths", "Hamal"),
    ("auriga", ["the charioteer"], "a charioteer", "Capella"),
    ("bootes", ["the herdsman"], "a herdsman or ox driver", "Arcturus"),
    ("caelum", [], "a chisel used by sculptors", None),
    ("camelopardalis", [], "a giraffe", None),
    ("cancer", ["the crab"], "a crab that pinched Hercules in Greek myths", None),
    ("canes venatici", [], "two hunting dogs held by Bootes", "Cor Caroli"),
    ("canis major", ["the great dog"], "a big dog, one of Orion's hunting dogs", "Sirius"),
    ("canis minor", ["the little dog"], "a small dog, Orion's other hunting dog", "Procyon"),
    ("capricornus", ["capricorn", "the sea goat"], "a sea goat, half goat and half fish", "Deneb Algedi"),
    ("carina", [], "the keel of a ship, part of the old giant ship constellation Argo Navis", "Canopus"),
    ("cassiopeia", [], "a vain queen from Greek myths, sitting on her throne. Her stars make a W or M shape", None),
    ("centaurus", [], "a centaur, half human and half horse", "Alpha Centauri"),
    ("cepheus", [], "a king from Greek myths, Cassiopeia's husband", "Alderamin"),
    ("cetus", [], "a sea monster, often drawn as a whale", "Diphda"),
    ("chamaeleon", [], "a chameleon", None),
    ("circinus", [], "a drawing compass", None),
    ("columba", [], "a dove", "Phact"),
    ("coma berenices", [], "the hair of Queen Berenice of Egypt", None),
    ("corona australis", [], "a southern crown", None),
    ("corona borealis", ["the northern crown"], "a northern crown, a half circle of stars", "Alphecca"),
    ("corvus", [], "a crow", None),
    ("crater", [], "a cup", None),
    ("crux", ["the southern cross", "southern cross"], "a cross. It's the smallest constellation and is used to find south", "Acrux"),
    ("cygnus", ["the swan", "the northern cross"], "a swan flying along the Milky Way", "Deneb"),
    ("delphinus", [], "a dolphin", None),
    ("dorado", [], "a dolphinfish (mahi-mahi) or swordfish. It holds most of the Large Magellanic Cloud", None),
    ("draco", ["the dragon"], "a dragon that winds between the two bears", "Eltanin"),
    ("equuleus", [], "a little horse. It's the second smallest constellation", None),
    ("eridanus", [], "a long river", "Achernar"),
    ("fornax", [], "a chemist's furnace", None),
    ("gemini", ["the twins"], "the twins Castor and Pollux from Greek myths", "Pollux"),
    ("grus", [], "a crane, the bird", "Alnair"),
    ("hercules", [], "the hero Hercules from Greek myths", None),
    ("horologium", [], "a pendulum clock", None),
    ("hydra", [], "a water snake. It's the biggest of all 88 constellations", "Alphard"),
    ("hydrus", [], "a small water snake", None),
    ("indus", [], "an Indigenous person of the Americas, as named by early European mapmakers", None),
    ("lacerta", [], "a lizard", None),
    ("leo", ["the lion"], "a lion, the Nemean lion beaten by Hercules", "Regulus"),
    ("leo minor", [], "a little lion", None),
    ("lepus", [], "a hare, sitting at Orion's feet", "Arneb"),
    ("libra", ["the scales"], "a set of balance scales", None),
    ("lupus", [], "a wolf", None),
    ("lynx", [], "a lynx. It was named because you need eyes like a lynx to see its faint stars", None),
    ("lyra", ["the lyre"], "a lyre, a small harp played by Orpheus in Greek myths", "Vega"),
    ("mensa", [], "Table Mountain in South Africa. It's the faintest constellation", None),
    ("microscopium", [], "a microscope", None),
    ("monoceros", [], "a unicorn", None),
    ("musca", [], "a fly", None),
    ("norma", [], "a carpenter's square", None),
    ("octans", [], "an octant, an old navigation tool. The south celestial pole is in it", None),
    ("ophiuchus", ["the serpent bearer"], "a man holding a snake, often linked to the healer Asclepius", "Rasalhague"),
    ("orion", ["the hunter"], "Orion, a great hunter from Greek myths, with a belt of three stars", "Rigel"),
    ("pavo", [], "a peacock", "Peacock"),
    ("pegasus", [], "Pegasus, the winged horse from Greek myths", "Enif"),
    ("perseus", [], "the hero Perseus, who beat Medusa and saved Andromeda", "Mirfak"),
    ("phoenix", [], "a phoenix, the bird that is reborn from fire", "Ankaa"),
    ("pictor", [], "a painter's easel", None),
    ("pisces", ["the fish", "the fishes"], "two fish tied together with a cord", None),
    ("piscis austrinus", [], "a southern fish", "Fomalhaut"),
    ("puppis", [], "the stern (back) of a ship, part of the old Argo Navis", "Naos"),
    ("pyxis", [], "a ship's compass", None),
    ("reticulum", [], "a reticle, the crosshairs in a telescope eyepiece", None),
    ("sagitta", [], "an arrow. It's the third smallest constellation", None),
    ("sagittarius", ["the archer"], "an archer, a centaur aiming a bow. Its main stars look like a teapot", "Kaus Australis"),
    ("scorpius", ["scorpio", "the scorpion"], "a scorpion, which in Greek myths killed Orion", "Antares"),
    ("sculptor", [], "a sculptor's studio", None),
    ("scutum", [], "a shield", None),
    ("serpens", [], "a snake held by Ophiuchus. It's the only constellation split into two parts", "Unukalhai"),
    ("sextans", [], "a sextant, a tool for measuring angles", None),
    ("taurus", ["the bull"], "a bull. It includes the Pleiades and Hyades star clusters", "Aldebaran"),
    ("telescopium", [], "a telescope", None),
    ("triangulum", [], "a triangle", None),
    ("triangulum australe", [], "a southern triangle", "Atria"),
    ("tucana", [], "a toucan. It holds the Small Magellanic Cloud", None),
    ("ursa major", ["the great bear", "the big bear"], "a great bear. Its seven brightest stars make the Big Dipper", "Alioth"),
    ("ursa minor", ["the little bear"], "a little bear. Its stars make the Little Dipper, with Polaris at the end of the handle", "Polaris"),
    ("vela", [], "the sails of a ship, part of the old Argo Navis", None),
    ("virgo", ["the maiden"], "a maiden, often linked to the goddess of the harvest. It's the second biggest constellation", "Spica"),
    ("volans", [], "a flying fish", None),
    ("vulpecula", [], "a little fox", None),
]


class Writer:
    def __init__(self, path, header):
        self.path, self.lines, self.count = path, [header], 0

    def tag(self, t):
        self.lines.append(f"# tag: {t}")

    def add(self, qs, a):
        out = []
        for q in qs:
            q = q.lower().strip().replace("'", "")
            if q not in out:
                out.append(q)
        assert 2 <= len(out) <= 6, qs
        assert len(a) < 420 and "—" not in a and "–" not in a, a
        self.lines.append(" | ".join(out) + " => " + a)
        self.count += 1

    def save(self):
        with open(self.path, "w", encoding="utf-8") as f:
            f.write("\n".join(self.lines) + "\n")
        print(f"wrote {self.count} entries to {self.path}")


def main():
    hdr = "# Generated by tools/knowledge/gen/science_space.py. Do not edit by hand."
    w = Writer(os.path.join(DATA, "gen_planets.txt"), hdr)
    w.tag("science.space.planet")
    planets(w.add)
    for n, a in FIT:
        w.add([f"how many earths fit inside {n}", f"how many earths can fit in {n}", f"is {n} bigger than earth by a lot"]
              if n != "mars" else ["how many mars fit inside earth", "how much smaller is mars than earth",
                                   "is mars half the size of earth"], a)
    w.tag("science.space.dwarf-planet")
    for _, entries in DWARFS:
        for qs, a in entries:
            w.add(qs, a)
    w.save()

    w = Writer(os.path.join(DATA, "gen_moons.txt"), hdr)
    w.tag("science.space.moon")
    for _, entries in MOONS:
        for qs, a in entries:
            w.add(qs, a)
    w.save()

    w = Writer(os.path.join(DATA, "gen_stars.txt"), hdr)
    w.tag("science.space.star")
    for name, con, dist, kind, extra in STARS:
        N = " ".join(x.capitalize() for x in name.split())
        if name == "barnards star":
            N = "Barnard's Star"
        w.add([f"what is {name}", f"tell me about {name}", f"what kind of star is {name}",
               f"{name} star facts"], f"{N} is {kind}. {extra}")
        w.add([f"how far away is {name}", f"how far is {name} from earth", f"distance to {name}"],
              f"{N} is {dist} away from us, in the constellation {con}.")
        if name not in ("alpha centauri", "proxima centauri", "barnards star"):
            w.add([f"what constellation is {name} in", f"where is {name} in the sky", f"how do i find {name}"],
                  f"{N} is in the constellation {con}. {extra}")
    w.tag("science.space.constellation")
    for name, alts, meaning, bright in CONSTELLATIONS:
        N = " ".join(x.capitalize() for x in name.split())
        qs = [f"what does {name} represent", f"what is the {name} constellation", f"{name} constellation meaning",
              f"what does the constellation {name} look like"]
        qs += [f"what is {a} constellation" for a in alts[:2]]
        w.add(qs, f"{N} represents {meaning}.")
        if bright:
            w.add([f"what is the brightest star in {name}", f"brightest star of {name} constellation",
                   f"{name} brightest star"], f"The brightest star in {N} is {bright}.")
    w.save()


if __name__ == "__main__":
    main()
