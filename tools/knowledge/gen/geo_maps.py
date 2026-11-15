#!/usr/bin/env python3
"""Generates map skills, landform words and time zone Q&A for Ace: data/geo/gen_maps.txt, gen_landforms.txt

Source: hand-written below from general knowledge (standard school geography), checked against references.
Run from the repo root:  python3 tools/knowledge/gen/geo_maps.py
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from geo_common import Writer, add_block  # noqa: E402

MAPS = r"""
## geo.map-skills
what is latitude | what are lines of latitude | latitude meaning => Latitude tells how far north or south a place is from the equator, in degrees. Lines of latitude run east to west around the Earth and are also called parallels.
what is longitude | what are lines of longitude | longitude meaning => Longitude tells how far east or west a place is from the prime meridian, in degrees. Lines of longitude run from the North Pole to the South Pole and are also called meridians.
how do you remember latitude and longitude | latitude vs longitude trick | difference between latitude and longitude => Latitude lines are flat, like the rungs of a ladder (lat sounds like ladder), and measure north and south. Longitude lines are long, running from pole to pole, and measure east and west.
what is the prime meridian | where is the prime meridian => The prime meridian is the line of 0 degrees longitude. It runs from the North Pole to the South Pole through Greenwich, in London, England.
why is the prime meridian in greenwich | who decided the prime meridian => In 1884, countries at a meeting in Washington, DC, chose the line through the Royal Observatory in Greenwich, London, as the prime meridian, partly because many sea charts already used it.
what is the international date line | where is the international date line | what happens when you cross the date line => The International Date Line runs roughly along 180 degrees longitude in the Pacific Ocean. When you cross it going west, you skip ahead a day, and going east, you go back a day.
what latitude is the equator | how many degrees is the equator => The equator is at 0 degrees latitude.
what latitude is the north pole | how many degrees is the north pole => The North Pole is at 90 degrees north latitude, the farthest north you can go.
what is the highest latitude | what is the biggest longitude number => Latitude goes from 0 degrees at the equator up to 90 degrees at each pole. Longitude goes from 0 degrees at the prime meridian up to 180 degrees east or west.
what is the tropic of cancer | where is the tropic of cancer => The Tropic of Cancer is the line of latitude about 23.4 degrees north of the equator. It's the farthest north the sun can be straight overhead, which happens around 21 June.
what is the tropic of capricorn | where is the tropic of capricorn => The Tropic of Capricorn is the line of latitude about 23.4 degrees south of the equator. It's the farthest south the sun can be straight overhead, which happens around 21 December.
what are the tropics | where are the tropics => The tropics are the warm area of Earth between the Tropic of Cancer and the Tropic of Capricorn, around the equator.
what is the arctic circle | where is the arctic circle => The Arctic Circle is the line of latitude about 66.5 degrees north. North of it, there's at least one day a year when the sun doesn't set and one when it doesn't rise.
what is the antarctic circle | where is the antarctic circle => The Antarctic Circle is the line of latitude about 66.5 degrees south. South of it, the sun stays up all day in midsummer and stays down all day in midwinter.
what are the four hemispheres | what is a hemisphere => A hemisphere is half of the Earth. The equator splits it into the Northern and Southern Hemispheres, and the prime meridian and 180th meridian split it into the Eastern and Western Hemispheres.
which hemisphere do most people live in | which hemisphere has more land => About 90 percent of people live in the Northern Hemisphere, which also has most of Earth's land.
what is a compass rose | what does a compass rose show => A compass rose is the symbol on a map that shows the directions north, south, east and west.
what are the cardinal directions | what are the four main directions => The four cardinal directions are north, east, south and west. A trick to remember the order going around is Never Eat Soggy Waffles.
what are intermediate directions | what is northeast | what are the in between directions => The intermediate directions are northeast, southeast, southwest and northwest. They're halfway between the cardinal directions.
what is a map key | what is a map legend | what does a legend on a map do => A map key, or legend, is a box that explains what the symbols and colors on a map mean, like a blue line for a river or a star for a capital city.
what is a map scale | how do you use a map scale => A map scale shows how distance on the map compares to real distance, like 1 centimeter equals 10 kilometers. You measure on the map and use the scale to work out the real distance.
what is a grid on a map | how do map grids work => A map grid is a set of lines that divide a map into squares labeled with letters and numbers, like B4, so you can find places quickly.
what is a coordinate | what are coordinates on a map => Coordinates are a pair of numbers that give an exact location, usually latitude and longitude, like 40.7 degrees north, 74 degrees west for New York City.
what is a political map | political map meaning => A political map shows borders between countries, states and provinces, plus cities and capitals. It usually colors each country differently.
what is a physical map | physical map meaning => A physical map shows natural features like mountains, rivers, lakes, deserts and oceans, often using colors to show how high the land is.
what is a topographic map | what are contour lines => A topographic map uses contour lines to show the shape and height of the land. Each line joins places at the same height, and lines close together mean steep slopes.
what is a thematic map | examples of thematic maps => A thematic map shows one topic about a place, like rainfall, population, languages or where crops grow.
what is a road map | what is a road map used for => A road map shows roads and highways, towns, and sometimes gas stations and rest stops, to help people plan driving trips.
what is a globe | why is a globe better than a map => A globe is a round model of the Earth. It shows sizes, shapes and distances correctly, while a flat map always stretches some parts.
why are maps wrong | why do maps stretch things | what is a map projection => A map projection is a way of drawing the round Earth on flat paper. Every projection stretches or squishes something, like size, shape or distance.
what is the mercator projection | why does greenland look so big on maps => The Mercator projection is a common flat map that keeps directions right for sailors but makes places near the poles look huge. Greenland looks as big as Africa on it, but Africa is about 14 times bigger.
what is the robinson projection | what is the best map projection => The Robinson projection is a flat map that balances size and shape so the whole world looks about right, though nothing is perfectly accurate. No projection is best for everything.
what is an atlas | what is a gazetteer => An atlas is a book of maps. A gazetteer is like a dictionary of places, listing where they are and facts about them.
what is a cartographer | what is a person who makes maps called => A cartographer is a person who makes maps. Making maps is called cartography.
what is the oldest map in the world | oldest world map => One of the oldest known world maps is the Babylonian Map of the World, a clay tablet from about 2,500 years ago, now in the British Museum.
how does gps work | what is gps => GPS, the Global Positioning System, uses signals from satellites in space. Your device measures how long signals from at least four satellites take to arrive and works out exactly where you are.
what is magnetic north | is magnetic north the same as true north => True north is the direction of the North Pole. Magnetic north is where a compass needle points, and it's in a slightly different place that slowly moves over time.
how does a compass work | why does a compass point north => A compass needle is a small magnet that lines up with Earth's magnetic field, so one end points toward magnetic north.
how do you find north without a compass | how to tell direction with the sun => The sun rises in the east and sets in the west, and at midday it's in the south if you're in the Northern Hemisphere. At night, the North Star, Polaris, shows north.
what is the north star | how do you find the north star => The North Star, Polaris, sits almost right above the North Pole, so it shows which way is north. You can find it using the two end stars of the Big Dipper's cup.
what is sea level | what does above sea level mean => Sea level is the average height of the ocean's surface. Heights of mountains and places are measured from it, so a place 100 meters above sea level is 100 meters higher than the ocean.
what is elevation | what is altitude => Elevation is how high a place on land is above sea level. Altitude usually means how high something is in the air, like an airplane.
what is relief on a map | what does relief mean in geography => Relief is the difference in height between high and low places in an area. Maps show it with shading, colors or contour lines.
what does the color blue mean on a map | what do colors on a physical map mean => On most physical maps, blue means water, green means low land, and yellow, brown and white mean higher land and mountains.
what is absolute location | what is relative location => Absolute location is an exact spot, like a street address or latitude and longitude. Relative location describes where something is compared to other places, like next to the library.
what are the five themes of geography => The five themes of geography are location, place, human-environment interaction, movement and region.
what is human geography | what is physical geography => Physical geography studies natural things like landforms, climate and rivers. Human geography studies people, like where they live, cities, cultures and how they use the land.
what is gis | what is a geographic information system => GIS, a geographic information system, is computer software that layers different kinds of map data, like roads, rivers and population, to study places and plan things.
what is a satellite map | how are satellite maps made => Satellite maps are made from photos taken by satellites orbiting Earth. Apps stitch many photos together so you can zoom in on almost anywhere.
what is a time zone | why do we have time zones => A time zone is an area that uses the same clock time. Time zones exist so that noon happens around the middle of the day everywhere, since the sun lights different parts of Earth at different times.
how many time zones are there | how many time zones in the world => There are 24 main time zones, one for each hour of the day, but some places use half-hour or 45-minute offsets, so there are actually about 38 local times in use.
which country has the most time zones | country with the most time zones => France has the most time zones, 12, because of its overseas territories around the world. Russia has the most in one connected stretch of land, 11.
how many time zones does russia have | russia time zones => Russia has 11 time zones, from Kaliningrad in the west to Kamchatka in the east.
how many time zones does the us have | us time zones => The United States uses 6 time zones in its states: Eastern, Central, Mountain, Pacific, Alaska and Hawaii-Aleutian. With its territories, it has 9 official time zones, or 11 if you count tiny islands where no one lives.
how many time zones does canada have | canada time zones => Canada has 6 time zones, including Newfoundland Time, which is half an hour different from its neighbors.
how many time zones does china have | why does china have one time zone => China uses just one time zone, Beijing Time, even though it's wide enough for about five. So in western China, the sun can rise as late as 10 in the morning.
how many time zones does australia have | australia time zones => Australia has three main time zones: Western, Central and Eastern. Central Australia is half an hour off the others.
what time zone is india in | is india half an hour off => India uses one time zone, India Standard Time, which is 5 and a half hours ahead of UTC.
what time zone is nepal | why is nepal 45 minutes off => Nepal's time is 5 hours and 45 minutes ahead of UTC, one of the few places with a 45-minute offset.
what is utc | what is gmt => UTC, Coordinated Universal Time, is the world's standard clock time, used to set every time zone. It's basically the same as GMT, Greenwich Mean Time, the time in London in winter.
what is daylight saving time | why do we change the clocks => Daylight saving time means moving clocks one hour forward in spring and back in fall, so evenings stay lighter longer in summer. Not every place does it.
which states dont use daylight saving time | does arizona change its clocks => Hawaii and most of Arizona don't use daylight saving time. The Navajo Nation in Arizona does use it.
which country is first to see the new year | first place to celebrate new year => Kiribati's Line Islands, like Kiritimati, are among the first places to reach the new year, at 14 hours ahead of UTC. Samoa and Tonga are also very early.
which place is last to see the new year | last place to celebrate new year => The last inhabited places to reach the new year are American Samoa and the Pacific island of Niue, 11 hours behind UTC.
why is it day here and night on the other side of the world | why do different places have different times => Earth spins once every 24 hours, so as one side faces the sun and has day, the other side faces away and has night.
why are the seasons opposite in australia | is it summer in australia at christmas => Earth is tilted, so when the Northern Hemisphere leans toward the sun and has summer, the Southern Hemisphere leans away and has winter. That's why Christmas is in summer in Australia.
what is the midnight sun | where can you see the midnight sun => The midnight sun is when the sun stays up all night in summer. It happens north of the Arctic Circle and south of the Antarctic Circle, in places like northern Norway, Alaska and Antarctica.
what is polar night | where does the sun not rise in winter => Polar night is when the sun doesn't rise for at least a whole day in winter. It happens north of the Arctic Circle and south of the Antarctic Circle.
where can you see the northern lights | best places to see the aurora => The northern lights are best seen near the Arctic Circle, in places like northern Norway, Sweden, Finland, Iceland, Canada and Alaska, on dark winter nights.
what is the solstice | when is the longest day of the year => A solstice is when the sun reaches its farthest point north or south. In the Northern Hemisphere, the summer solstice around 21 June is the longest day, and the winter solstice around 21 December is the shortest.
what is an equinox | when is day and night the same length => An equinox happens around 20 March and 22 September, when the sun is right above the equator and day and night are about the same length everywhere.
what is a climate zone | what are the climate zones => Climate zones are areas with similar weather over many years. The main ones are tropical, dry, temperate, continental and polar.
what is the difference between weather and climate | weather vs climate => Weather is what's happening in the sky today, like rain or sun. Climate is the usual weather of a place over many years.
what is a biome | what are the main biomes => A biome is a big area with a similar climate, plants and animals, like rainforest, desert, grassland, tundra, taiga and ocean.
what is population density | what is the most crowded country => Population density is how many people live in an area, like people per square kilometer. Monaco is the most crowded country, and Bangladesh is the most crowded big country.
what is the least crowded country | country with the fewest people per square mile => Mongolia is the least crowded country, with only about 2 people per square kilometer. Greenland, a territory, is even emptier.
what is an urban area | what is a rural area | urban vs rural => An urban area is a city or town with lots of people and buildings close together. A rural area is the countryside, with farms, forests and small villages.
what is a suburb | what is a metropolitan area => A suburb is a neighborhood or town just outside a big city where many people live and travel into the city. A metropolitan area is a city plus all its suburbs.
what is a megacity | how many megacities are there => A megacity is a city area with more than 10 million people. There are more than 30 of them, like Tokyo, Delhi, Shanghai, São Paulo, Cairo and Mexico City.
what is a landlocked country | how many countries are landlocked => A landlocked country has no coastline on the ocean. There are about 44 landlocked countries, depending on which ones you count, like Switzerland, Bolivia, Mongolia and Ethiopia.
what is a doubly landlocked country | which countries are double landlocked => A doubly landlocked country is surrounded only by other landlocked countries, so you must cross two borders to reach the sea. There are only two: Liechtenstein and Uzbekistan.
what is an enclave | which countries are inside another country => An enclave is a place completely surrounded by another country. Lesotho is inside South Africa, and San Marino and Vatican City are inside Italy.
what is an exclave | what is kaliningrad => An exclave is a part of a country that's cut off from the rest of it. Kaliningrad is a part of Russia between Poland and Lithuania, and Alaska is an exclave of the United States.
what is a territory | what is a dependency => A territory or dependency is a place that belongs to or is protected by another country but isn't fully a part of it, like Puerto Rico (USA), Greenland (Denmark) and Bermuda (UK).
what is a border | what is a boundary in geography => A border is the line where one country, state or area ends and another begins. Some follow rivers or mountains, and others are straight lines drawn on maps.
which country has the longest border | longest border between two countries => The border between Canada and the United States is the longest in the world, about 8,890 kilometers (5,525 miles), including the Alaska border.
which countries have the most neighbors | country that borders the most countries => China and Russia each border 14 countries, more than any others.
which country has the longest coastline | longest coastline in the world => Canada has the longest coastline of any country, more than 200,000 kilometers (125,000 miles), because of its thousands of islands.
which countries have no coastline and no rivers | what is the only country with no rivers => Saudi Arabia is the biggest country with no permanent rivers. Several small countries, like Monaco and Vatican City, have none either.
what is the most southern city in the world | southernmost city => Ushuaia, Argentina, is often called the southernmost city in the world. Puerto Williams in Chile is a little farther south but is much smaller.
what is the northernmost town in the world | northernmost city => Longyearbyen, on Norway's Svalbard islands, is the northernmost town with more than 1,000 people.
what is the highest capital city | highest city in the world => La Paz, Bolivia, at about 3,640 meters (11,940 feet), is the highest seat of government in the world. Quito, Ecuador, at about 2,850 meters (9,350 feet), is the highest official capital city.
which capital is farthest south | southernmost capital => Wellington, New Zealand, is the southernmost capital city of a country.
which capital is farthest north | northernmost capital => Reykjavík, Iceland, is the northernmost capital city of a country.
what is the coldest capital city | coldest capital in the world => Ulaanbaatar, Mongolia, is the coldest capital city of a country, with winter temperatures often below minus 30 degrees Celsius.
what is the most remote place on earth | most remote island with people => Tristan da Cunha, in the South Atlantic, is the most remote inhabited island. It's about 2,400 kilometers (1,500 miles) from the nearest mainland, South Africa.
what is point nemo | farthest point from land => Point Nemo is the spot in the South Pacific Ocean farthest from any land, about 2,700 kilometers (1,670 miles) from the nearest island. Old spacecraft are sometimes crashed there on purpose.
what is the center of the earth made of | how far is the center of the earth => Earth's center is a solid iron and nickel inner core, about 6,370 kilometers (3,960 miles) below the surface, surrounded by a liquid outer core.
how big around is the earth | what is the circumference of the earth => Earth is about 40,075 kilometers (24,901 miles) around at the equator.
how much of the earth is water | how much of the world is ocean => About 71 percent of Earth's surface is covered by water, almost all of it ocean.
how much of earths water is fresh | how much water can we drink => Only about 3 percent of Earth's water is fresh water, and most of that is frozen in ice caps and glaciers.
what is the hottest place on earth | hottest temperature ever recorded => The hottest air temperature ever officially recorded was 56.7 degrees Celsius (134 degrees Fahrenheit) in Death Valley, California, in 1913, though some scientists doubt it.
what is the wettest place on earth | rainiest place in the world => Mawsynram and nearby Cherrapunji, in northeast India, are among the wettest places on Earth, getting more than 11 meters (about 39 feet) of rain in a typical year.
what is the windiest place on earth | windiest continent => Antarctica is the windiest continent, and Commonwealth Bay there has winds that often blow over 240 kilometers per hour (150 miles per hour).
what is the sunniest place on earth | sunniest country => Yuma, Arizona, is often called the sunniest place on Earth, with sun about 90 percent of daytime hours. Parts of the Sahara are very sunny too.
"""

LANDFORMS = r"""
## geo.landform
what is a peninsula | peninsula meaning => A peninsula is land surrounded by water on three sides and joined to the mainland on one side, like Florida or Italy.
what is an isthmus | isthmus meaning => An isthmus is a narrow strip of land that connects two bigger pieces of land and has water on both sides, like the Isthmus of Panama.
what is an archipelago | archipelago meaning => An archipelago is a group or chain of islands, like Hawaii, Japan, the Philippines and Indonesia.
what is a strait | strait meaning => A strait is a narrow stretch of water that connects two bigger bodies of water, like the Strait of Gibraltar.
what is a bay | bay meaning => A bay is a part of the sea or a lake that curves into the land, partly surrounded by land.
what is a gulf | gulf meaning | difference between a bay and a gulf => A gulf is a large part of the ocean that goes deep into the land, like the Gulf of Mexico. Gulfs are usually bigger and more closed in than bays.
what is a delta | river delta meaning => A delta is flat land at a river's mouth, made of mud and sand the river drops as it slows down. Many are shaped like a triangle, like the Greek letter delta.
what is a plateau | plateau meaning => A plateau is a large, flat area of land that's raised up high, like a giant table. The Tibetan Plateau is the biggest and highest.
what is a mesa | what is a butte | difference between mesa and butte => A mesa is a flat-topped hill with steep sides, wider than it is tall. A butte is like a mesa but smaller and taller than it is wide. Both are common in the US Southwest.
what is a canyon | canyon meaning => A canyon is a deep valley with steep sides, usually cut by a river over millions of years, like the Grand Canyon.
what is a valley | valley meaning => A valley is a low area of land between hills or mountains, often with a river running through it.
what is a fjord | where are fjords => A fjord is a long, narrow inlet of the sea with steep cliffs on both sides, carved by glaciers. Norway, New Zealand, Chile, Greenland and Canada have famous fjords.
what is a glacier | how do glaciers move => A glacier is a huge, slow-moving river of ice made from snow that piled up over many years. It slides downhill under its own weight, often just centimeters a day.
what is tundra | where is the tundra => Tundra is a cold, treeless land where the ground below the surface stays frozen all year, called permafrost. It's found in the far north, like northern Canada, Alaska and Siberia.
what is a savanna | where are savannas => A savanna is a warm grassland with scattered trees, with a wet season and a dry season. The African savanna is home to lions, zebras and elephants.
what is a steppe | where is the steppe => A steppe is a huge, dry, grassy plain with few trees. The Eurasian Steppe stretches from Ukraine across Kazakhstan to Mongolia.
what is a rainforest | where are rainforests => A rainforest is a thick forest that gets lots of rain all year. Tropical rainforests are near the equator, like the Amazon, and have more kinds of plants and animals than anywhere else.
what is the taiga | what is a boreal forest => The taiga, or boreal forest, is a huge cold forest of pine, spruce and fir trees across Canada, Alaska, Scandinavia and Russia. It's the biggest land biome on Earth.
what is an oasis | oasis meaning => An oasis is a green place in a desert where water comes up from underground, so plants can grow and people can live.
what is an atoll | how does an atoll form => An atoll is a ring-shaped coral island around a lagoon. It forms when coral grows around a volcanic island that slowly sinks away.
what is a lagoon | lagoon meaning => A lagoon is a shallow body of water separated from the sea by a strip of sand, coral or rock.
what is an estuary | estuary meaning => An estuary is where a river meets the sea, and fresh water mixes with salt water. Estuaries are great homes for fish and birds.
what is a tributary | tributary meaning => A tributary is a smaller river or stream that flows into a bigger river. The Missouri is a tributary of the Mississippi.
what is the source of a river | what is the mouth of a river => The source is where a river begins, like a spring, lake or melting glacier. The mouth is where it ends, flowing into a sea, lake or another river.
what is a watershed | what is a drainage basin => A watershed, or drainage basin, is all the land where rain and snow drain into the same river, lake or sea.
what is a cape | cape meaning in geography => A cape is a point of land that sticks out into the sea, like the Cape of Good Hope in South Africa.
what is a basin in geography | basin meaning => A basin is a low area of land shaped like a bowl, often where rivers drain, like the Amazon Basin.
what is a plain | plain meaning in geography => A plain is a large area of flat or gently rolling land with few trees, like the Great Plains of North America.
difference between a hill and a mountain | when is a hill a mountain => There's no single rule, but in many places a hill becomes a mountain at about 300 to 600 meters (1,000 to 2,000 feet) tall, with steeper slopes and a peak.
what is a mountain range | what is a mountain chain => A mountain range is a line or group of mountains connected together, like the Rockies or the Himalayas.
what is a cliff | how are cliffs formed => A cliff is a steep, high wall of rock. Sea cliffs form when waves wear away the bottom of the land.
what is a cave | how are caves formed => A cave is a natural hole underground. Most form when water slowly dissolves limestone rock over thousands of years.
what are stalactites and stalagmites | difference between stalactite and stalagmite => Stalactites hang from a cave's ceiling, and stalagmites grow up from the floor. A trick: stalactites hold tight to the ceiling, and stalagmites might reach it one day.
what is a sinkhole | how do sinkholes form => A sinkhole is a hole that opens in the ground when water dissolves rock underneath and the surface caves in. Florida has lots of them.
what is a geyser | how does a geyser work => A geyser is a hot spring that shoots water and steam into the air. Underground water gets heated by hot rock until the pressure blasts it out.
what is a hot spring | where do hot springs come from => A hot spring is water that comes out of the ground warm because it was heated by hot rock deep underground. Iceland and Japan have many.
what is a dune | how do sand dunes form => A dune is a hill of sand piled up by the wind. Dunes slowly move as the wind blows sand over them.
what is a reef | what is a coral reef => A coral reef is an underwater structure built by tiny animals called coral polyps. Reefs are home to about a quarter of all sea creatures.
what is a marsh | what is a swamp | what is a wetland => Wetlands are land soaked with water. Marshes have mostly grasses and reeds, and swamps have trees, like the Everglades and the bayous of Louisiana.
what is a bayou | where are bayous => A bayou is a slow-moving, marshy stream or river, especially in Louisiana and along the Gulf Coast.
what is a moraine | what do glaciers leave behind => A moraine is a pile of rocks and dirt that a glacier pushed along and left behind when it melted.
what is an iceberg | how much of an iceberg is underwater => An iceberg is a big chunk of ice that broke off a glacier or ice shelf and floats in the sea. About 90 percent of it is hidden under the water.
what is permafrost | where is permafrost => Permafrost is ground that stays frozen for at least two years in a row. It covers much of Siberia, northern Canada and Alaska.
what is a floodplain | why do people farm on floodplains => A floodplain is flat land beside a river that gets flooded when the river rises. The floods leave rich soil, so it's great for farming.
what is an inlet | inlet meaning => An inlet is a narrow strip of water that goes from the sea into the land, like a small bay.
what is a channel in geography | channel meaning => A channel is a wide strait of water between two pieces of land, like the English Channel, or the deep path a river flows in.
what is a continental shelf | continental shelf meaning => A continental shelf is the shallow edge of a continent under the sea, before the ocean floor drops down steeply.
what is an ocean trench | what is the deepest trench => An ocean trench is a long, deep valley on the sea floor where one tectonic plate slides under another. The Mariana Trench in the Pacific is the deepest.
what is a mid ocean ridge | what is the mid atlantic ridge => A mid-ocean ridge is an underwater mountain chain where tectonic plates pull apart and new sea floor forms. The Mid-Atlantic Ridge runs down the middle of the Atlantic Ocean.
what is an island | what is the difference between an island and a continent => An island is land completely surrounded by water. Continents are surrounded by water too, but they're much bigger, so Australia is called a continent and Greenland is the biggest island.
what is a mainland | mainland meaning => The mainland is the main land of a country or continent, not its islands. For example, Hawaii is not on the US mainland.
what is a coast | coastline meaning => The coast is where land meets the sea. The coastline is the outline of that edge.
what is a gorge | gorge meaning => A gorge is a narrow valley between steep rock walls, usually with a river at the bottom. It's like a small, narrow canyon.
what is a waterfall | how are waterfalls formed => A waterfall forms where a river flows over a ledge of hard rock. The water wears away softer rock below, making a drop.
what is a volcano | how do volcanoes form => A volcano is an opening in Earth's crust where melted rock, called magma, gas and ash come out. Over time, eruptions can pile up into mountains.
what is a crater | what is a caldera => A crater is the bowl-shaped hole at the top of a volcano. A caldera is a much bigger hollow that forms when a volcano collapses after a huge eruption.
"""

STRAITS = r"""
## geo.water-passage
where is the strait of gibraltar | how wide is the strait of gibraltar => The Strait of Gibraltar separates Spain in Europe from Morocco in Africa and connects the Atlantic Ocean to the Mediterranean Sea. It's only about 14 kilometers (9 miles) wide at its narrowest.
where is the bering strait | how wide is the bering strait => The Bering Strait separates Russia and Alaska and connects the Pacific to the Arctic Ocean. It's about 82 kilometers (51 miles) wide, and people think the first Americans crossed from Asia near there.
where is the strait of hormuz | why is the strait of hormuz important => The Strait of Hormuz connects the Persian Gulf to the Arabian Sea, between Iran and Oman. About a fifth of the world's oil passes through it.
where is the strait of malacca | why is the strait of malacca important => The Strait of Malacca runs between Malaysia and the Indonesian island of Sumatra, connecting the Indian Ocean to the Pacific. It's one of the busiest shipping routes in the world.
what is the bosporus | where is the bosporus | facts about the bosporus => The Bosporus is a narrow strait running through Istanbul, Turkey. It connects the Black Sea to the Sea of Marmara and separates Europe from Asia.
what are the dardanelles | where are the dardanelles | facts about the dardanelles => The Dardanelles is a narrow strait in Turkey connecting the Sea of Marmara to the Aegean Sea. Together with the Bosporus, it links the Black Sea to the Mediterranean.
what is the strait of magellan | where is the strait of magellan | facts about the strait of magellan => The Strait of Magellan cuts across the southern tip of South America in Chile, connecting the Atlantic and Pacific. Ferdinand Magellan sailed through it in 1520.
what is the drake passage | why is the drake passage so rough => The Drake Passage is the stretch of sea between the tip of South America and Antarctica. It has some of the roughest seas on Earth because winds and currents swirl around Antarctica with no land to stop them.
where is cook strait | what is cook strait | facts about cook strait => Cook Strait separates New Zealand's North Island and South Island.
where is the bass strait | what is bass strait | facts about the bass strait => The Bass Strait separates Tasmania from mainland Australia.
where is the taiwan strait | what is the taiwan strait | facts about the taiwan strait => The Taiwan Strait separates the island of Taiwan from mainland China. It's about 130 kilometers (80 miles) wide at its narrowest.
what is the strait of dover | narrowest part of the english channel => The Strait of Dover is the narrowest part of the English Channel, about 33 kilometers (21 miles) wide. On clear days, you can see France from the white cliffs of Dover.
where is the strait of messina | what is the strait of messina | facts about the strait of messina => The Strait of Messina separates the island of Sicily from the toe of mainland Italy.
what is the isthmus of panama | why is the isthmus of panama important => The Isthmus of Panama is the narrow strip of land joining North and South America. When it formed about 3 million years ago, animals could walk between the two continents.
what is the kiel canal | where is the kiel canal | facts about the kiel canal => The Kiel Canal crosses northern Germany and connects the North Sea to the Baltic Sea. It's one of the busiest artificial waterways in the world.
what is the grand canal of china | longest canal in the world => The Grand Canal in China is the longest canal in the world, about 1,800 kilometers (1,100 miles) long. Parts of it are more than 2,500 years old.
what is the corinth canal | where is the corinth canal | facts about the corinth canal => The Corinth Canal cuts through a narrow strip of land in Greece. It's only about 21 meters (70 feet) wide at the bottom, so big modern ships can't fit through it.
what is the cape of good hope | where is the cape of good hope | facts about the cape of good hope => The Cape of Good Hope is a rocky point near Cape Town, South Africa. Sailors going around Africa passed it, though Cape Agulhas nearby is Africa's true southern tip.
what is cape horn | why is cape horn dangerous => Cape Horn is the southern tip of South America, in Chile. Its huge waves, strong winds and icebergs made it one of the most dangerous places for sailing ships.
what is cape canaveral | where is cape canaveral | facts about cape canaveral => Cape Canaveral is on Florida's Atlantic coast. NASA's Kennedy Space Center is next to it, and rockets to the Moon launched from there.
what is the arabian peninsula | biggest peninsula in the world => The Arabian Peninsula is the biggest peninsula in the world. It holds Saudi Arabia, Yemen, Oman, the UAE, Qatar, Bahrain and Kuwait.
what is the iberian peninsula | where is the iberian peninsula | facts about the iberian peninsula => The Iberian Peninsula is in southwestern Europe and holds Spain, Portugal, Andorra and Gibraltar.
what is the scandinavian peninsula | which countries are on the scandinavian peninsula => The Scandinavian Peninsula in northern Europe holds Norway, Sweden and part of Finland. It's the biggest peninsula in Europe.
what is the balkan peninsula | where is the balkan peninsula | facts about the balkan peninsula => The Balkan Peninsula is in southeastern Europe, between the Adriatic, Aegean and Black Seas, with Greece at its southern tip.
what is the korean peninsula | which countries are on the korean peninsula => The Korean Peninsula in East Asia holds North Korea and South Korea.
what is the indochinese peninsula | what is indochina | facts about the indochinese peninsula => The Indochinese Peninsula in Southeast Asia holds Myanmar, Thailand, Laos, Cambodia, Vietnam and part of Malaysia.
what is the malay peninsula | where is the malay peninsula | facts about the malay peninsula => The Malay Peninsula stretches south from Thailand and Myanmar and holds mainland Malaysia, with Singapore at its tip.
what is the kamchatka peninsula | where is kamchatka | facts about the kamchatka peninsula => The Kamchatka Peninsula is in far eastern Russia. It's full of volcanoes, geysers and brown bears.
what is the yucatan peninsula | where is the yucatan | facts about the yucatan peninsula => The Yucatán Peninsula is in southeastern Mexico, with parts of Guatemala and Belize. It has Maya ruins like Chichén Itzá and beaches like Cancún.
what is baja california | where is baja california | facts about baja california => Baja California is a long, thin peninsula in northwestern Mexico, between the Pacific Ocean and the Gulf of California.
what is jutland | where is jutland | facts about jutland => Jutland is the peninsula that makes up mainland Denmark and part of northern Germany.
what is the crimean peninsula | where is crimea | facts about the crimean peninsula => Crimea is a peninsula on the north coast of the Black Sea. It's part of Ukraine, but Russia took control of it in 2014, and most countries don't accept that.
what is the sinai peninsula | where is the sinai | facts about the sinai peninsula => The Sinai Peninsula is a triangle of land in Egypt between the Mediterranean Sea and the Red Sea. It's the part of Egypt that's in Asia.
what is anatolia | what is asia minor | facts about anatolia => Anatolia, also called Asia Minor, is the big peninsula that makes up most of Turkey, between the Black Sea and the Mediterranean.
what is the florida peninsula | is florida a peninsula | facts about the florida peninsula => Yes, most of Florida is a peninsula, with the Gulf of Mexico on the west and the Atlantic Ocean on the east.
what is the upper peninsula | what is the u p of michigan | facts about the upper peninsula => The Upper Peninsula is the northern part of Michigan, between Lake Superior and Lakes Michigan and Huron. People from there are nicknamed Yoopers.
what is the delmarva peninsula | why is it called delmarva => The Delmarva Peninsula on the US East Coast holds most of Delaware and parts of Maryland and Virginia. Its name joins the three states' names.
what is the indian subcontinent | why is india called a subcontinent => The Indian subcontinent is the big piece of South Asia south of the Himalayas, with India, Pakistan, Bangladesh, Nepal, Bhutan and Sri Lanka. It sits on its own tectonic plate, which is why it's called a subcontinent.
"""


def main():
    w = Writer(["gen_maps.txt", "gen_landforms.txt"])
    add_block(w, "gen_maps.txt", MAPS)
    add_block(w, "gen_landforms.txt", LANDFORMS)
    add_block(w, "gen_landforms.txt", STRAITS)
    w.save("""Generated by tools/knowledge/gen/geo_maps.py. Do not edit by hand.
Data: hand-written map skills, time zones, landform words, straits, canals, capes and peninsulas.""")
    for d in w.dropped:
        print("  dropped:", d)


if __name__ == "__main__":
    main()
