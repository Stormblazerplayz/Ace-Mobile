#!/usr/bin/env python3
"""Generates US school geography Q&A for Ace: data/geo/gen_us_geo.txt, gen_us_parks.txt, gen_nature_wonders.txt

  - state flowers and time zones for all 50 states
  - US geography facts for school (regions, borders, territories, superlatives)
  - US national parks and world natural wonders

Source: hand-written tables below from general knowledge, checked against standard references
(official state flowers, US time zone maps, National Park Service). Run from the repo root:
  python3 tools/knowledge/gen/geo_us_school.py
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from geo_common import Writer, add_block, rng_for  # noqa: E402

# state | flower | time zone answer
STATES = r"""
Alabama | the camellia | Alabama is in the Central Time Zone.
Alaska | the forget-me-not | Most of Alaska uses Alaska Time, one hour behind Pacific Time. The far western Aleutian Islands use Hawaii-Aleutian Time.
Arizona | the saguaro cactus blossom | Arizona is in the Mountain Time Zone, but most of it doesn't use daylight saving time, so in summer it matches Pacific Time. The Navajo Nation does change its clocks.
Arkansas | the apple blossom | Arkansas is in the Central Time Zone.
California | the California poppy | California is in the Pacific Time Zone.
Colorado | the Rocky Mountain columbine | Colorado is in the Mountain Time Zone.
Connecticut | the mountain laurel | Connecticut is in the Eastern Time Zone.
Delaware | the peach blossom | Delaware is in the Eastern Time Zone.
Florida | the orange blossom | Most of Florida is in the Eastern Time Zone, but the western part of the Panhandle, including Pensacola, is in the Central Time Zone.
Georgia | the Cherokee rose | Georgia is in the Eastern Time Zone.
Hawaii | the yellow hibiscus | Hawaii uses Hawaii-Aleutian Standard Time all year, because it doesn't use daylight saving time.
Idaho | the syringa | Southern Idaho, including Boise, is in the Mountain Time Zone, and the northern panhandle is in the Pacific Time Zone.
Illinois | the violet | Illinois is in the Central Time Zone.
Indiana | the peony | Most of Indiana is in the Eastern Time Zone, but some counties in the northwest, near Chicago, and the southwest, near Evansville, are in the Central Time Zone.
Iowa | the wild prairie rose | Iowa is in the Central Time Zone.
Kansas | the sunflower | Almost all of Kansas is in the Central Time Zone, except four counties on the western edge that use Mountain Time.
Kentucky | the goldenrod | Kentucky is split: the eastern half, including Louisville and Lexington, is in the Eastern Time Zone, and the western half is in the Central Time Zone.
Louisiana | the magnolia | Louisiana is in the Central Time Zone.
Maine | the white pine cone and tassel | Maine is in the Eastern Time Zone.
Maryland | the black-eyed Susan | Maryland is in the Eastern Time Zone.
Massachusetts | the mayflower | Massachusetts is in the Eastern Time Zone.
Michigan | the apple blossom | Almost all of Michigan is in the Eastern Time Zone, except four counties in the Upper Peninsula next to Wisconsin, which use Central Time.
Minnesota | the pink and white lady's slipper | Minnesota is in the Central Time Zone.
Mississippi | the magnolia | Mississippi is in the Central Time Zone.
Missouri | the hawthorn | Missouri is in the Central Time Zone.
Montana | the bitterroot | Montana is in the Mountain Time Zone.
Nebraska | the goldenrod | Most of Nebraska is in the Central Time Zone, but the western part is in the Mountain Time Zone.
Nevada | the sagebrush | Nevada is in the Pacific Time Zone, except the small border city of West Wendover, which uses Mountain Time.
New Hampshire | the purple lilac | New Hampshire is in the Eastern Time Zone.
New Jersey | the common meadow violet | New Jersey is in the Eastern Time Zone.
New Mexico | the yucca flower | New Mexico is in the Mountain Time Zone.
New York | the rose | New York is in the Eastern Time Zone.
North Carolina | the flowering dogwood | North Carolina is in the Eastern Time Zone.
North Dakota | the wild prairie rose | Most of North Dakota is in the Central Time Zone, but the southwestern part is in the Mountain Time Zone.
Ohio | the red carnation | Ohio is in the Eastern Time Zone.
Oklahoma | the Oklahoma rose (and mistletoe is its floral emblem) | Oklahoma is in the Central Time Zone.
Oregon | the Oregon grape | Almost all of Oregon is in the Pacific Time Zone, except most of Malheur County on the eastern edge, which uses Mountain Time.
Pennsylvania | the mountain laurel | Pennsylvania is in the Eastern Time Zone.
Rhode Island | the violet | Rhode Island is in the Eastern Time Zone.
South Carolina | the yellow jessamine | South Carolina is in the Eastern Time Zone.
South Dakota | the pasque flower | South Dakota is split: the eastern half is in the Central Time Zone, and the western half, including Rapid City and Mount Rushmore, is in the Mountain Time Zone.
Tennessee | the iris | Tennessee is split: East Tennessee, including Knoxville and Chattanooga, is in the Eastern Time Zone, and Middle and West Tennessee, including Nashville and Memphis, are in the Central Time Zone.
Texas | the bluebonnet | Almost all of Texas is in the Central Time Zone, except El Paso and Hudspeth counties in the far west, which use Mountain Time.
Utah | the sego lily | Utah is in the Mountain Time Zone.
Vermont | the red clover | Vermont is in the Eastern Time Zone.
Virginia | the American dogwood | Virginia is in the Eastern Time Zone.
Washington | the coast rhododendron | Washington State is in the Pacific Time Zone.
West Virginia | the rhododendron | West Virginia is in the Eastern Time Zone.
Wisconsin | the wood violet | Wisconsin is in the Central Time Zone.
Wyoming | the Indian paintbrush | Wyoming is in the Mountain Time Zone.
"""
QNAME = {"Washington": "washington state", "Georgia": "georgia the state", "New York": "new york state"}

US_GEO = r"""
## geo.us
what are the 48 contiguous states | what does contiguous united states mean | what is the lower 48 => The 48 contiguous states, or Lower 48, are all the US states that touch each other. Only Alaska and Hawaii are separate.
is washington dc a state | why isnt dc a state => No, Washington, DC, isn't a state. It's a federal district made to be the capital, so it doesn't belong to any one state. Its people can vote for president but have no voting member in Congress.
what are the us territories | how many territories does the us have => The United States has five territories where people live: Puerto Rico, Guam, the US Virgin Islands, the Northern Mariana Islands and American Samoa. It also has several tiny islands where no one lives.
what are the four corners | which states meet at the four corners => The Four Corners is the only place where four states meet at one point: Arizona, Colorado, New Mexico and Utah. You can stand in all four at once at a monument there.
what is the mason dixon line | where is the mason dixon line | mason dixon line history => The Mason-Dixon Line is a border surveyed in the 1760s between Pennsylvania and Maryland. Before the Civil War, it became a symbol of the line between free states and slave states.
what is the continental divide | where is the continental divide | continental divide meaning => The Continental Divide is a line along the Rocky Mountains. Rain that falls west of it flows toward the Pacific, and rain east of it flows toward the Atlantic or the Gulf.
what are the great plains | where are the great plains | great plains states => The Great Plains are a huge, flat grassland in the middle of North America, east of the Rocky Mountains, from Texas up into Canada. It's great for wheat and cattle.
what is tornado alley | which states are in tornado alley | tornado alley states => Tornado Alley is the part of the central US where tornadoes are most common, mainly Texas, Oklahoma, Kansas and Nebraska, plus nearby states.
what states are in new england | new england states | is maine in new england => New England has six states: Maine, New Hampshire, Vermont, Massachusetts, Rhode Island and Connecticut.
what states are in the midwest | midwest states | how many states are in the midwest | is ohio in the midwest => The Midwest has 12 states: Ohio, Indiana, Illinois, Michigan, Wisconsin, Minnesota, Iowa, Missouri, North Dakota, South Dakota, Nebraska and Kansas.
what states are in the pacific northwest | pacific northwest states | is idaho in the pacific northwest => The Pacific Northwest usually means Washington, Oregon and Idaho, and sometimes British Columbia in Canada.
what states are in the southwest | southwest states | is texas in the southwest => The Southwest usually means Arizona and New Mexico, plus parts of Texas, Oklahoma, Nevada, Utah, Colorado and California.
which states border canada | how many states border canada | states on the canadian border => Thirteen states border Canada: Alaska, Washington, Idaho, Montana, North Dakota, Minnesota, Michigan, Ohio, Pennsylvania, New York, Vermont, New Hampshire and Maine. Ohio and Pennsylvania touch it only across Lake Erie.
which states border mexico | how many states border mexico | states on the mexican border => Four states border Mexico: California, Arizona, New Mexico and Texas. Texas has the longest stretch.
which states are on the gulf of mexico | gulf coast states => Five states are on the Gulf of Mexico: Texas, Louisiana, Mississippi, Alabama and Florida.
which states are on the pacific ocean | west coast states => Five states touch the Pacific Ocean: Washington, Oregon, California, Alaska and Hawaii.
which states border the most other states | state with the most neighbors => Tennessee and Missouri each border eight other states, more than any other state.
which state borders only one other state | state with one neighbor => Maine is the only state that borders just one other state, New Hampshire.
which states touch the great lakes | great lakes states | states next to the great lakes => Eight states touch the Great Lakes: Minnesota, Wisconsin, Illinois, Indiana, Michigan, Ohio, Pennsylvania and New York.
which state has two peninsulas | why is michigan shaped like a mitten => Michigan is made of two peninsulas. The Lower Peninsula is shaped like a mitten, and the Upper Peninsula is across the Straits of Mackinac, joined by the Mackinac Bridge.
which state has the longest coastline | state with the most coastline => Alaska has the longest coastline of any state, longer than all the other states put together.
which is the northernmost state | most northern state => Alaska is the northernmost state. In the Lower 48, it's Minnesota, because of a small area called the Northwest Angle.
which is the southernmost state | most southern state => Hawaii is the southernmost state. In the Lower 48, it's Florida, with Key West near the tip.
which is the easternmost state | most eastern state => Maine is the easternmost state in the Lower 48. Technically, Alaska's Aleutian Islands cross the 180th meridian, so Alaska is the most western and, in a way, the most eastern state too.
which is the westernmost state | most western state => Alaska is the westernmost state. In the Lower 48, it's Washington.
which state has the most people | most populated state => California has the most people of any state, about 39 million as of 2024.
which state has the fewest people | least populated state => Wyoming has the fewest people of any state, about 590,000 as of 2024.
which state is the flattest | flattest state | is kansas the flattest state => Florida is the flattest state, with the lowest highest point. Kansas is famous for being flat, but by some measures it's not the flattest.
which state is the highest | which state has the highest average elevation => Colorado has the highest average elevation of any state, about 2,070 meters (6,800 feet). Alaska has the highest single point, Denali.
what is the highest point in the lower 48 | tallest mountain in the contiguous us => Mount Whitney in California, about 4,421 meters (14,505 feet), is the highest point in the Lower 48.
what is the geographic center of the united states | center of the us => The geographic center of all 50 states is near Belle Fourche, South Dakota. The center of the Lower 48 is near Lebanon, Kansas.
what are the states named after people | which states are named after people | states named after kings and queens => States named after people include Washington (George Washington), Virginia and West Virginia (Queen Elizabeth I), Maryland (Queen Henrietta Maria), Georgia (King George II), the Carolinas (King Charles I), Pennsylvania (William Penn's father) and Louisiana (King Louis XIV).
which states start with new | how many states start with new | states with new in the name => Four states start with New: New Hampshire, New Jersey, New Mexico and New York.
which state names come from native american words | state names from native languages => About half the states have names from Native American words, like Alabama, Alaska, Arizona, Connecticut, Illinois, Kentucky, Massachusetts, Michigan, Minnesota, Mississippi, Ohio, Oklahoma, Texas, Utah and Wisconsin.
what does texas mean | where does the name texas come from => Texas comes from táysha, a Caddo word meaning friends or allies.
what does ohio mean | where does the name ohio come from => Ohio comes from a Seneca word meaning great river.
what does mississippi mean | where does the name mississippi come from => Mississippi comes from an Ojibwe word meaning great river.
what does connecticut mean | where does the name connecticut come from => Connecticut comes from a Mohegan word meaning long tidal river.
what does nevada mean | where does the name nevada come from => Nevada is Spanish for snow-covered, from the snowy Sierra Nevada mountains.
what does montana mean | where does the name montana come from => Montana comes from the Spanish word montaña, meaning mountain.
what does colorado mean | where does the name colorado come from => Colorado is Spanish for colored red, after the reddish Colorado River.
what does florida mean | where does the name florida come from => Florida means flowery in Spanish. Juan Ponce de León named it in 1513, around Easter, which Spanish speakers called Pascua Florida.
what does vermont mean | where does the name vermont come from => Vermont comes from the French words for green mountain.
what does minnesota mean | where does the name minnesota come from => Minnesota comes from a Dakota word meaning cloudy or sky-tinted water.
what does alaska mean | where does the name alaska come from => Alaska comes from an Aleut word meaning mainland, or the object toward which the sea pushes.
what does hawaii mean | where does the name hawaii come from => No one is sure. Hawaii may be named after Hawaiʻiloa, a legendary Polynesian navigator, or come from an old word for homeland.
how many states are there | how many states are in the us => There are 50 states in the United States. Hawaii was the last to join, in 1959.
what is the newest state | last state to join the us | youngest us state => Hawaii was the newest state, admitted on 21 August 1959, a few months after Alaska.
what are the biggest states | five biggest states by area => The five biggest states by area are Alaska, Texas, California, Montana and New Mexico.
what are the smallest states | five smallest states by area => The five smallest states by area are Rhode Island, Delaware, Connecticut, Hawaii and New Jersey.
how many states have a coastline | how many states are landlocked => 23 states touch an ocean or the Gulf of Mexico. The other 27 have no ocean coast, though some touch the Great Lakes.
which state has the most lakes | land of 10000 lakes => Minnesota is called the Land of 10,000 Lakes and really has more than 11,000. Alaska has even more, about 3 million.
which state grows the most corn | corn belt states => Iowa grows the most corn of any state, followed by Illinois and Nebraska. These Midwest states are called the Corn Belt.
which state has the most volcanoes | does the us have active volcanoes | alaska volcanoes => Alaska has the most volcanoes of any state, more than 50 that have been active in the last few hundred years. Hawaii, Washington, Oregon and California have active ones too.
what is the sun belt | which states are in the sun belt => The Sun Belt is the warm southern part of the US, from Florida and Georgia across Texas to Arizona and Southern California.
what is the rust belt | which states are in the rust belt => The Rust Belt is an area around the Great Lakes, in states like Ohio, Michigan, Pennsylvania and Indiana, where many old factories and steel mills closed.
what is appalachia | what states are in appalachia => Appalachia is the region around the Appalachian Mountains, including all of West Virginia and parts of states like Kentucky, Tennessee, Virginia, North Carolina, Pennsylvania and Ohio.
what is the bible belt | which states are in the bible belt => The Bible Belt is a nickname for the southern and south central US, where many people go to Protestant churches.
which states have counties called parishes and boroughs | does louisiana have counties => Louisiana calls its counties parishes, and Alaska calls its biggest areas boroughs.
how many counties are in the us | which state has the most counties => The United States has about 3,000 counties and county-like areas. Texas has the most, 254.
which river separates the east and west of the us | biggest river in the us => The Mississippi River roughly splits the United States into east and west, and it drains water from parts of 31 states.
"""

PARKS = r"""
yellowstone | Yellowstone National Park is mostly in Wyoming, with parts in Montana and Idaho. | Yellowstone became the first national park in the world in 1872. It has half of the world's geysers, including Old Faithful, plus bison, wolves and grizzly bears.
yosemite | Yosemite National Park is in the Sierra Nevada mountains of California. | Yosemite is famous for giant granite cliffs like El Capitan and Half Dome, tall waterfalls, and giant sequoia trees.
zion | Zion National Park is in southwestern Utah. | Zion has huge red and cream sandstone cliffs, and its hike called the Narrows goes right up a river between canyon walls.
great smoky mountains | Great Smoky Mountains National Park is on the border of Tennessee and North Carolina. | The Great Smoky Mountains is the most visited national park in the US. It's named for the blue fog that often hangs over the mountains, and it has lots of black bears and synchronous fireflies.
everglades | Everglades National Park is in southern Florida. | The Everglades is a giant wetland, often called a river of grass, and it's the only place where alligators and crocodiles live side by side.
glacier | Glacier National Park is in northwestern Montana, on the border with Canada. | Glacier National Park has rugged mountains, bright blue lakes and the Going-to-the-Sun Road. Its glaciers are shrinking fast as the climate warms.
acadia | Acadia National Park is on the coast of Maine, mostly on Mount Desert Island. | Cadillac Mountain in Acadia is one of the first places in the US to see the sunrise for much of the year.
arches | Arches National Park is in eastern Utah, near the town of Moab. | Arches has more than 2,000 natural stone arches, including the famous Delicate Arch.
bryce canyon | Bryce Canyon National Park is in southern Utah. | Bryce Canyon is famous for hoodoos, thousands of tall, thin rock spires in orange, red and white.
death valley | Death Valley National Park is in eastern California, with a small part in Nevada. | Death Valley is the hottest, driest and lowest national park. It holds the record for the hottest air temperature, 56.7 degrees Celsius (134 degrees Fahrenheit), and it's the biggest national park in the Lower 48.
wrangell st elias | Wrangell-St. Elias National Park is in southeastern Alaska, on the border with Canada. | Wrangell-St. Elias is the biggest national park in the United States, bigger than Switzerland.
denali national park | Denali National Park is in central Alaska. | Denali National Park has North America's tallest mountain, plus grizzly bears, moose, caribou and wolves. Its sled dogs work as park rangers in winter.
olympic | Olympic National Park is on the Olympic Peninsula in Washington State. | Olympic National Park has three different worlds: snowy mountains, rocky Pacific beaches, and the Hoh Rainforest, one of the wettest places in the Lower 48.
rocky mountain | Rocky Mountain National Park is in northern Colorado. | Rocky Mountain National Park has Trail Ridge Road, the highest continuous paved road in the US, and lots of elk.
mammoth cave | Mammoth Cave National Park is in central Kentucky. | Mammoth Cave is the longest known cave system in the world, with more than 680 kilometers (420 miles) mapped so far.
carlsbad caverns | Carlsbad Caverns National Park is in southeastern New Mexico. | Carlsbad Caverns has a giant underground room called the Big Room, and hundreds of thousands of bats fly out of the cave on summer evenings.
sequoia | Sequoia National Park is in the southern Sierra Nevada of California. | Sequoia National Park has General Sherman, the biggest tree on Earth by volume.
redwood | Redwood National and State Parks are on the far northern coast of California. | Redwood National Park has the tallest trees on Earth. The tallest known tree, Hyperion, is about 116 meters (380 feet) tall.
hawaii volcanoes | Hawaii Volcanoes National Park is on the Big Island of Hawaii. | Hawaii Volcanoes National Park has two of the world's most active volcanoes, Kīlauea and Mauna Loa.
badlands | Badlands National Park is in southwestern South Dakota. | The Badlands has striped rock layers carved into sharp ridges, and it's one of the richest places for fossils of ancient mammals.
joshua tree | Joshua Tree National Park is in southern California, where the Mojave and Colorado deserts meet. | Joshua Tree is named after its spiky Joshua trees and is famous for rock climbing and very dark, starry skies.
grand teton | Grand Teton National Park is in northwestern Wyoming, just south of Yellowstone. | Grand Teton has jagged mountains that rise straight up from flat valleys and lakes, with no foothills in between.
mesa verde | Mesa Verde National Park is in southwestern Colorado. | Mesa Verde has cliff dwellings, villages built into cliffs by Ancestral Puebloan people about 800 years ago.
shenandoah | Shenandoah National Park is in the Blue Ridge Mountains of Virginia. | Shenandoah's Skyline Drive runs along the mountain tops for about 170 kilometers (105 miles).
saguaro | Saguaro National Park is in southern Arizona, around Tucson. | Saguaro National Park protects giant saguaro cactuses, which can grow taller than 12 meters (40 feet) and live more than 150 years.
white sands | White Sands National Park is in southern New Mexico. | White Sands has the biggest gypsum dune field in the world. The white sand stays cool to touch even on hot days, and people sled down the dunes.
petrified forest | Petrified Forest National Park is in northeastern Arizona. | Petrified Forest has logs more than 200 million years old that turned to colorful stone.
big bend | Big Bend National Park is in West Texas, along the Rio Grande and the border with Mexico. | Big Bend is named after the big curve of the Rio Grande, and it has desert, mountains and canyons in one park.
glacier bay | Glacier Bay National Park is in southeastern Alaska. | Glacier Bay has huge glaciers that crash into the sea, and humpback whales feed there in summer.
crater lake national park | Crater Lake National Park is in southern Oregon. | Crater Lake National Park protects the deepest lake in the US, which formed inside a collapsed volcano.
grand canyon national park | Grand Canyon National Park is in northern Arizona. | Grand Canyon National Park gets millions of visitors a year, and people hike, raft the Colorado River and ride mules down into the canyon.
gateway arch national park | Gateway Arch National Park is in St. Louis, Missouri. | Gateway Arch National Park is the smallest national park in the US, and it's mostly the giant steel arch and its museum.
"""

WONDERS = r"""
amazon rainforest | The Amazon rainforest covers much of northern South America, mostly in Brazil, with parts in Peru, Colombia and six other countries. | The Amazon is the biggest rainforest on Earth. It's home to about one in ten known species, including jaguars, sloths, macaws and poison dart frogs.
serengeti | The Serengeti is in northern Tanzania, stretching into Kenya, where it's called the Masai Mara. | The Serengeti has the Great Migration, when more than a million wildebeest, plus zebras and gazelles, travel in a giant loop every year looking for grass.
ha long bay | Ha Long Bay is in northern Vietnam, on the Gulf of Tonkin. | Ha Long Bay has about 1,600 limestone islands rising out of green water. Its name means descending dragon.
pamukkale | Pamukkale is in southwestern Turkey. | Pamukkale has white terraces of rock made by hot spring water, which look like frozen waterfalls. Its name means cotton castle.
cappadocia | Cappadocia is in central Turkey. | Cappadocia has fairy chimneys, tall rock towers people carved homes into, plus underground cities and hot-air balloon rides.
salar de uyuni | Salar de Uyuni is in southwestern Bolivia, high in the Andes. | Salar de Uyuni is the biggest salt flat in the world. After rain, it turns into a giant mirror that reflects the sky.
plitvice lakes | Plitvice Lakes National Park is in central Croatia. | Plitvice has 16 turquoise lakes connected by waterfalls and wooden walkways.
geirangerfjord | Geirangerfjord is in western Norway. | Geirangerfjord is one of the most famous fjords in the world, with steep cliffs and waterfalls like the Seven Sisters.
great rift valley | The Great Rift Valley runs through East Africa, from Ethiopia down to Mozambique, and up into the Middle East. | The Great Rift Valley is a giant crack in Earth's crust where Africa is slowly splitting apart. Many early human fossils were found there.
okavango delta | The Okavango Delta is in northern Botswana. | The Okavango Delta is a giant inland delta where a river spreads out into the Kalahari Desert instead of reaching the sea, making a huge oasis for elephants, lions and hippos.
ngorongoro crater | Ngorongoro Crater is in northern Tanzania. | Ngorongoro Crater is the biggest unbroken volcanic caldera in the world, and about 25,000 big animals live inside it.
sundarbans | The Sundarbans are on the coast of Bangladesh and India, where the Ganges reaches the sea. | The Sundarbans is the biggest mangrove forest in the world, and it's home to Bengal tigers that swim between islands.
zhangjiajie | Zhangjiajie is in Hunan province, in China. | Zhangjiajie has thousands of tall sandstone pillars that helped inspire the floating mountains in the movie Avatar.
son doong cave | Son Doong Cave is in Phong Nha-Kẻ Bàng National Park, in central Vietnam. | Son Doong is the biggest cave passage in the world. It has its own jungle and clouds inside, and a whole city block could fit in parts of it.
great blue hole | The Great Blue Hole is off the coast of Belize, in the Caribbean Sea. | The Great Blue Hole is a giant round sinkhole in the sea, about 300 meters (1,000 feet) across and over 120 meters (400 feet) deep.
antelope canyon | Antelope Canyon is in northern Arizona, on Navajo land. | Antelope Canyon is a slot canyon with swirling orange walls carved by flash floods. Light beams shine down into it at midday.
monument valley | Monument Valley is on the Arizona and Utah border, on Navajo Nation land. | Monument Valley has giant red sandstone buttes that have appeared in many Western movies.
torres del paine | Torres del Paine National Park is in Patagonia, in southern Chile. | Torres del Paine is named after three granite towers, and it has glaciers, blue lakes and guanacos.
perito moreno glacier | The Perito Moreno Glacier is in Los Glaciares National Park, in southern Argentina. | The Perito Moreno Glacier ends in a wall of ice about 70 meters (230 feet) high, and big chunks crash off it into the lake with a roar.
pantanal | The Pantanal is mostly in western Brazil, with parts in Bolivia and Paraguay. | The Pantanal is the biggest tropical wetland in the world, and it's one of the best places to see jaguars.
daintree rainforest | The Daintree Rainforest is in northern Queensland, Australia. | The Daintree is thought to be one of the oldest rainforests on Earth, about 180 million years old, and it meets the Great Barrier Reef at the coast.
kruger national park | Kruger National Park is in northeastern South Africa. | Kruger National Park is one of Africa's biggest wildlife parks, where you can see the Big Five: lions, leopards, elephants, rhinos and buffalo.
waitomo glowworm caves | The Waitomo Caves are on the North Island of New Zealand. | The Waitomo Caves have thousands of glowworms on the ceiling that glow like stars, and visitors float under them in boats.
black forest | The Black Forest is in southwestern Germany. | The Black Forest has thick, dark pine forests, and it's famous for cuckoo clocks, Black Forest cake and old fairy tales.
mount roraima | Mount Roraima is where Venezuela, Brazil and Guyana meet. | Mount Roraima is a giant flat-topped mountain called a tepui, with cliffs on all sides. It inspired the book The Lost World.
puerto princesa underground river | The Puerto Princesa Underground River is on the island of Palawan, in the Philippines. | The Puerto Princesa Underground River flows through a cave for about 8 kilometers (5 miles) before reaching the sea, and boats take visitors inside.
jeju island | Jeju Island is off the south coast of South Korea. | Jeju is a volcanic island with Hallasan, South Korea's highest mountain, lava tube caves, and famous women divers called haenyeo.
"""

WONDERS_LISTS = r"""
## geo.wonders
what are the seven wonders of the ancient world | list the 7 ancient wonders => The Seven Wonders of the Ancient World were the Great Pyramid of Giza, the Hanging Gardens of Babylon, the Statue of Zeus at Olympia, the Temple of Artemis at Ephesus, the Mausoleum at Halicarnassus, the Colossus of Rhodes and the Lighthouse of Alexandria.
which ancient wonder is still standing | which of the seven wonders still exists => The Great Pyramid of Giza is the only one of the Seven Wonders of the Ancient World still standing.
what are the new seven wonders of the world | list the new 7 wonders => The New Seven Wonders of the World, chosen in a worldwide vote in 2007, are the Great Wall of China, Petra, Christ the Redeemer, Machu Picchu, Chichén Itzá, the Colosseum and the Taj Mahal.
what are the seven natural wonders of the world | natural wonders of the world list => One popular list of the Seven Natural Wonders is Mount Everest, the Great Barrier Reef, the Grand Canyon, Victoria Falls, the harbor of Rio de Janeiro, Parícutin volcano and the northern lights.
what are the new seven wonders of nature | new 7 wonders of nature list => The New Seven Wonders of Nature, picked in a vote in 2011, are the Amazon rainforest, Ha Long Bay, Iguazu Falls, Jeju Island, Komodo National Park, the Puerto Princesa Underground River and Table Mountain.
what was the hanging gardens of babylon | were the hanging gardens real => The Hanging Gardens of Babylon were said to be terraced gardens in Babylon, in what is now Iraq. No one has found clear proof they existed, so some historians think they were somewhere else or a legend.
what was the colossus of rhodes | how big was the colossus of rhodes => The Colossus of Rhodes was a giant bronze statue of the sun god Helios on the Greek island of Rhodes, about 33 meters (108 feet) tall. An earthquake knocked it down about 54 years after it was built.
what was the lighthouse of alexandria | how tall was the lighthouse of alexandria => The Lighthouse of Alexandria, or Pharos, was a giant lighthouse in Egypt, probably more than 100 meters (330 feet) tall. Earthquakes badly damaged it in the 1300s, and it later fell into ruins.
what is a world heritage site | what is unesco => A World Heritage Site is a place UNESCO, part of the United Nations, lists as so important to humanity that it should be protected, like the Great Wall or Yellowstone. There are more than 1,200.
which country has the most world heritage sites | most unesco sites => Italy has the most UNESCO World Heritage Sites, with China close behind, as of 2025.
"""


def main():
    w = Writer(["gen_us_geo.txt", "gen_us_parks.txt", "gen_nature_wonders.txt"])
    for line in STATES.strip().splitlines():
        state, flower, tz = [x.strip() for x in line.split("|")]
        q = QNAME.get(state, state.lower())
        rng = rng_for("usflower", state)
        flower_ans = f"The state flower of {state} is {flower}."
        if state == "Washington":
            flower_ans = f"The state flower of Washington State is {flower}."
        rest = [f"{q} state flower", f"which flower represents {q}", f"official flower of {q}"]
        rng.shuffle(rest)
        w.add("gen_us_geo.txt", "geo.us.flower", [f"what is the state flower of {q}"] + rest, flower_ans, limit=4)
        rest = [f"{q} time zone", f"what time is it in {q}", f"is {q} in central or eastern time",
                f"is {q} on pacific or mountain time"]
        rng.shuffle(rest)
        tzq = [f"what time zone is {q} in", rest[0], rest[1]]
        w.add("gen_us_geo.txt", "geo.us.timezone", tzq, tz, limit=3)
    add_block(w, "gen_us_geo.txt", US_GEO)
    for line in PARKS.strip().splitlines():
        q, where, fact = [x.strip() for x in line.split("|")]
        base = q if "park" in q else q + " national park"
        rng = rng_for("park", q)
        r1 = [f"what state is {base} in", f"{base} location", f"where can i find {base}"]
        rng.shuffle(r1)
        w.add("gen_us_parks.txt", "geo.us.park", [f"where is {base}"] + r1, where, limit=4)
        r2 = [f"facts about {base}", f"why is {base} famous", f"tell me about {base}"]
        rng.shuffle(r2)
        w.add("gen_us_parks.txt", "geo.us.park", [f"what is {base} known for"] + r2, fact, limit=4)
    add_block(w, "gen_us_parks.txt", r"""
## geo.us.park
how many national parks are there in the us | how many national parks does america have => As of 2025, the United States has 63 national parks. The newest is New River Gorge in West Virginia, made a national park in 2020.
what was the first national park | oldest national park in the world => Yellowstone was the first national park in the world, created in 1872.
which state has the most national parks | state with the most national parks | does california have the most national parks => California has the most national parks, nine as of 2025. Alaska has eight and Utah has five.
what is the biggest national park | largest national park in the us => Wrangell-St. Elias in Alaska is the biggest US national park, at about 53,000 square kilometers (20,600 square miles).
what is the most visited national park | busiest national park => Great Smoky Mountains is the most visited US national park, with more than 12 million visits a year.
""")
    for line in WONDERS.strip().splitlines():
        q, where, fact = [x.strip() for x in line.split("|")]
        rng = rng_for("wonder", q)
        r1 = [f"what country is {q} in", f"{q} location", f"where can i see {q}"]
        rng.shuffle(r1)
        w.add("gen_nature_wonders.txt", "geo.wonders", [f"where is {q}"] + r1, where, limit=4)
        r2 = [f"facts about {q}", f"why is {q} famous", f"tell me about {q}"]
        rng.shuffle(r2)
        w.add("gen_nature_wonders.txt", "geo.wonders", [f"what is {q} known for"] + r2, fact, limit=4)
    add_block(w, "gen_nature_wonders.txt", WONDERS_LISTS)
    w.save("""Generated by tools/knowledge/gen/geo_us_school.py. Do not edit by hand.
Data: hand-written tables of state flowers, state time zones, US geography, national parks and natural wonders.""")
    for d in w.dropped:
        print("  dropped:", d)


if __name__ == "__main__":
    main()
