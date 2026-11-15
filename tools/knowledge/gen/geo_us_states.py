#!/usr/bin/env python3
"""Generates US state Q&A for Ace: data/geo/gen_us_states.txt

Source: hand-written table below, from general knowledge, checked against standard references
(US Census Bureau 2020 census counts and regions, state admission dates, official state nicknames
and state birds). Capitals and postal abbreviations are already in Ace's older bank, so they are
not repeated here.

Run from the repo root:  python3 tools/knowledge/gen/geo_us_states.py
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from geo_common import Writer, rng_for  # noqa: E402

# abbr | state | nickname | largest city | admitted | order | region | borders | pop 2020 (millions) | state bird | known for
TABLE = r"""
AL | Alabama | the Yellowhammer State (also the Heart of Dixie) | Huntsville | December 14, 1819 | 22 | South | Florida, Georgia, Tennessee and Mississippi | 5.02 | the yellowhammer (northern flicker) | Alabama is known for the US Space and Rocket Center in Huntsville, where rockets for NASA were built, and for the civil rights movement in Montgomery and Birmingham.
AK | Alaska | the Last Frontier | Anchorage | January 3, 1959 | 49 | West | no other states. It borders Canada | 0.73 | the willow ptarmigan | Alaska is the biggest state by far, known for Denali (the tallest mountain in North America), glaciers, grizzly bears, the northern lights and the Iditarod sled dog race.
AZ | Arizona | the Grand Canyon State | Phoenix | February 14, 1912 | 48 | West | California, Nevada, Utah and New Mexico, and it touches Colorado at the Four Corners | 7.15 | the cactus wren | Arizona is known for the Grand Canyon, saguaro cactuses, the Sonoran Desert and very hot summers.
AR | Arkansas | the Natural State | Little Rock | June 15, 1836 | 25 | South | Missouri, Tennessee, Mississippi, Louisiana, Texas and Oklahoma | 3.01 | the northern mockingbird | Arkansas is known for Hot Springs National Park, the Ozark Mountains, and Crater of Diamonds State Park, where you can dig for real diamonds.
CA | California | the Golden State | Los Angeles | September 9, 1850 | 31 | West | Oregon, Nevada and Arizona | 39.54 | the California quail | California has the most people of any state and is known for Hollywood, Silicon Valley, the Golden Gate Bridge, Disneyland, redwood trees and Yosemite.
CO | Colorado | the Centennial State | Denver | August 1, 1876 | 38 | West | Wyoming, Nebraska, Kansas, Oklahoma, New Mexico and Utah, and it touches Arizona at the Four Corners | 5.77 | the lark bunting | Colorado is known for the Rocky Mountains, skiing, and having the highest average elevation of any state. Denver is called the Mile High City.
CT | Connecticut | the Constitution State | Bridgeport | January 9, 1788 | 5 | Northeast | New York, Massachusetts and Rhode Island | 3.61 | the American robin | Connecticut is known for Yale University, Mystic Seaport, and making the first nuclear-powered submarine.
DE | Delaware | the First State | Wilmington | December 7, 1787 | 1 | South | Maryland, Pennsylvania and New Jersey | 0.99 | the Delaware Blue Hen chicken | Delaware was the first state to approve the US Constitution, which is why it's called the First State, and it's the second smallest state.
FL | Florida | the Sunshine State | Jacksonville | March 3, 1845 | 27 | South | Alabama and Georgia | 21.54 | the northern mockingbird | Florida is known for Walt Disney World, beaches, the Everglades, alligators, oranges, and rocket launches at Cape Canaveral.
GA | Georgia | the Peach State | Atlanta | January 2, 1788 | 4 | South | Florida, Alabama, Tennessee, North Carolina and South Carolina | 10.71 | the brown thrasher | Georgia is known for peaches, peanuts, Atlanta's busy airport, Coca-Cola, which was invented in Atlanta, and the birthplace of Martin Luther King Jr.
HI | Hawaii | the Aloha State | Honolulu | August 21, 1959 | 50 | West | no other states. It's a chain of islands in the Pacific Ocean | 1.46 | the nēnē (Hawaiian goose) | Hawaii is the only state made entirely of islands, known for volcanoes like Kīlauea, surfing, beaches, hula and Pearl Harbor.
ID | Idaho | the Gem State | Boise | July 3, 1890 | 43 | West | Montana, Wyoming, Utah, Nevada, Oregon and Washington | 1.84 | the mountain bluebird | Idaho is famous for potatoes, and it also has mountains, rivers for rafting, and Hells Canyon, one of the deepest canyons in North America.
IL | Illinois | the Prairie State (also the Land of Lincoln) | Chicago | December 3, 1818 | 21 | Midwest | Wisconsin, Iowa, Missouri, Kentucky and Indiana | 12.81 | the northern cardinal | Illinois is known for Chicago, deep-dish pizza, the Willis Tower, and being where Abraham Lincoln started his career.
IN | Indiana | the Hoosier State | Indianapolis | December 11, 1816 | 19 | Midwest | Illinois, Michigan, Ohio and Kentucky | 6.79 | the northern cardinal | Indiana is known for the Indianapolis 500 car race, basketball, and corn fields.
IA | Iowa | the Hawkeye State | Des Moines | December 28, 1846 | 29 | Midwest | Minnesota, Wisconsin, Illinois, Missouri, Nebraska and South Dakota | 3.19 | the eastern goldfinch | Iowa is known for corn and pigs, the Iowa State Fair, and the Iowa caucuses that start presidential election seasons.
KS | Kansas | the Sunflower State | Wichita | January 29, 1861 | 34 | Midwest | Nebraska, Missouri, Oklahoma and Colorado | 2.94 | the western meadowlark | Kansas is known for wheat fields, flat prairies, tornadoes, and being the home of Dorothy in The Wizard of Oz.
KY | Kentucky | the Bluegrass State | Louisville | June 1, 1792 | 15 | South | Illinois, Indiana, Ohio, West Virginia, Virginia, Tennessee and Missouri | 4.51 | the northern cardinal | Kentucky is known for the Kentucky Derby horse race, horse farms, Mammoth Cave (the longest known cave system in the world), and fried chicken.
LA | Louisiana | the Pelican State | New Orleans | April 30, 1812 | 18 | South | Texas, Arkansas and Mississippi | 4.66 | the brown pelican | Louisiana is known for New Orleans, Mardi Gras, jazz music, bayous, alligators, and Cajun and Creole food like gumbo and jambalaya.
ME | Maine | the Pine Tree State | Portland | March 15, 1820 | 23 | Northeast | New Hampshire (it's the only state that borders just one other state) | 1.36 | the black-capped chickadee | Maine is known for lobsters, lighthouses, pine forests, blueberries and Acadia National Park.
MD | Maryland | the Old Line State | Baltimore | April 28, 1788 | 7 | South | Pennsylvania, Delaware, Virginia and West Virginia, plus Washington, D.C. | 6.18 | the Baltimore oriole | Maryland is known for blue crabs, the Chesapeake Bay, and Fort McHenry, where "The Star-Spangled Banner" was written.
MA | Massachusetts | the Bay State | Boston | February 6, 1788 | 6 | Northeast | Rhode Island, Connecticut, New York, Vermont and New Hampshire | 7.03 | the black-capped chickadee | Massachusetts is known for Boston, Harvard University, the Pilgrims at Plymouth, the Boston Tea Party, and Cape Cod.
MI | Michigan | the Great Lakes State (also the Wolverine State) | Detroit | January 26, 1837 | 26 | Midwest | Ohio, Indiana and Wisconsin | 10.08 | the American robin | Michigan touches four of the five Great Lakes and is shaped like a mitten. It's known for Detroit, the Motor City, where the US car industry grew.
MN | Minnesota | the North Star State (also the Land of 10,000 Lakes) | Minneapolis | May 11, 1858 | 32 | Midwest | North Dakota, South Dakota, Iowa and Wisconsin | 5.71 | the common loon | Minnesota is known for its thousands of lakes, cold winters, the Mall of America, and the start of the Mississippi River at Lake Itasca.
MS | Mississippi | the Magnolia State | Jackson | December 10, 1817 | 20 | South | Louisiana, Arkansas, Tennessee and Alabama | 2.96 | the northern mockingbird | Mississippi is named after the Mississippi River and is known for blues music, catfish farms, and being the birthplace of Elvis Presley.
MO | Missouri | the Show-Me State | Kansas City | August 10, 1821 | 24 | Midwest | Iowa, Illinois, Kentucky, Tennessee, Arkansas, Oklahoma, Kansas and Nebraska | 6.15 | the eastern bluebird | Missouri is known for the Gateway Arch in St. Louis, Kansas City barbecue, and the writer Mark Twain.
MT | Montana | the Treasure State (also Big Sky Country) | Billings | November 8, 1889 | 41 | West | North Dakota, South Dakota, Wyoming and Idaho | 1.08 | the western meadowlark | Montana is known for Glacier National Park, wide open spaces, ranches, dinosaur fossils, and part of Yellowstone.
NE | Nebraska | the Cornhusker State | Omaha | March 1, 1867 | 37 | Midwest | South Dakota, Iowa, Missouri, Kansas, Colorado and Wyoming | 1.96 | the western meadowlark | Nebraska is known for corn, cattle ranches, Chimney Rock on the Oregon Trail, and huge flocks of sandhill cranes in spring.
NV | Nevada | the Silver State | Las Vegas | October 31, 1864 | 36 | West | Oregon, Idaho, Utah, Arizona and California | 3.10 | the mountain bluebird | Nevada is known for Las Vegas, casinos, deserts, the Hoover Dam, and Area 51.
NH | New Hampshire | the Granite State | Manchester | June 21, 1788 | 9 | Northeast | Maine, Massachusetts and Vermont | 1.38 | the purple finch | New Hampshire is known for the White Mountains, fall leaves, maple syrup, and holding the first presidential primary election.
NJ | New Jersey | the Garden State | Newark | December 18, 1787 | 3 | Northeast | New York, Pennsylvania and Delaware | 9.29 | the eastern goldfinch | New Jersey is known for the Jersey Shore beaches, boardwalks, diners, and being the state with the most people per square mile.
NM | New Mexico | the Land of Enchantment | Albuquerque | January 6, 1912 | 47 | West | Arizona, Colorado, Oklahoma and Texas, and it touches Utah at the Four Corners | 2.12 | the greater roadrunner | New Mexico is known for its hot air balloon fiesta, adobe buildings, green chile, Carlsbad Caverns, and Roswell's UFO legend.
NY | New York | the Empire State | New York City | July 26, 1788 | 11 | Northeast | Vermont, Massachusetts, Connecticut, New Jersey and Pennsylvania | 20.20 | the eastern bluebird | New York is known for New York City, the Statue of Liberty, Times Square, Broadway, Niagara Falls, and the Adirondack Mountains.
NC | North Carolina | the Tar Heel State | Charlotte | November 21, 1789 | 12 | South | Virginia, Tennessee, Georgia and South Carolina | 10.44 | the northern cardinal | North Carolina is where the Wright brothers made the first airplane flight in 1903, at Kitty Hawk, and it's known for the Outer Banks and the Great Smoky Mountains.
ND | North Dakota | the Peace Garden State | Fargo | November 2, 1889 | 39 | Midwest | Minnesota, South Dakota and Montana | 0.78 | the western meadowlark | North Dakota is known for wheat and sunflower fields, Theodore Roosevelt National Park, and oil.
OH | Ohio | the Buckeye State | Columbus | March 1, 1803 | 17 | Midwest | Pennsylvania, West Virginia, Kentucky, Indiana and Michigan | 11.80 | the northern cardinal | Ohio is known for the Rock and Roll Hall of Fame, the Pro Football Hall of Fame, roller coasters at Cedar Point, and being home to eight US presidents.
OK | Oklahoma | the Sooner State | Oklahoma City | November 16, 1907 | 46 | South | Kansas, Missouri, Arkansas, Texas, New Mexico and Colorado | 3.96 | the scissor-tailed flycatcher | Oklahoma is known for tornadoes, oil, cowboy history, and many Native American nations, which have their headquarters there.
OR | Oregon | the Beaver State | Portland | February 14, 1859 | 33 | West | Washington, Idaho, Nevada and California | 4.24 | the western meadowlark | Oregon is known for Crater Lake (the deepest lake in the US), forests, the rainy coast, the Oregon Trail, and Nike, which started there.
PA | Pennsylvania | the Keystone State | Philadelphia | December 12, 1787 | 2 | Northeast | New York, New Jersey, Delaware, Maryland, West Virginia and Ohio | 13.00 | the ruffed grouse | Pennsylvania is known for Philadelphia, the Liberty Bell, Independence Hall, Gettysburg, Hershey chocolate and cheesesteaks.
RI | Rhode Island | the Ocean State | Providence | May 29, 1790 | 13 | Northeast | Connecticut and Massachusetts | 1.10 | the Rhode Island Red chicken | Rhode Island is the smallest state, known for its beaches, sailing, and big old mansions in Newport.
SC | South Carolina | the Palmetto State | Charleston | May 23, 1788 | 8 | South | North Carolina and Georgia | 5.12 | the Carolina wren | South Carolina is known for Charleston's old streets, Myrtle Beach, and Fort Sumter, where the first shots of the Civil War were fired.
SD | South Dakota | the Mount Rushmore State | Sioux Falls | November 2, 1889 | 40 | Midwest | North Dakota, Minnesota, Iowa, Nebraska, Wyoming and Montana | 0.89 | the ring-necked pheasant | South Dakota is known for Mount Rushmore, the Badlands, the Black Hills, and the Crazy Horse Memorial.
TN | Tennessee | the Volunteer State | Nashville | June 1, 1796 | 16 | South | Kentucky, Virginia, North Carolina, Georgia, Alabama, Mississippi, Arkansas and Missouri | 6.91 | the northern mockingbird | Tennessee is known for country music in Nashville, Elvis Presley's Graceland in Memphis, and the Great Smoky Mountains.
TX | Texas | the Lone Star State | Houston | December 29, 1845 | 28 | South | New Mexico, Oklahoma, Arkansas and Louisiana | 29.15 | the northern mockingbird | Texas is the biggest state in the lower 48, known for cowboys, the Alamo, NASA's Johnson Space Center in Houston, barbecue and Tex-Mex food.
UT | Utah | the Beehive State | Salt Lake City | January 4, 1896 | 45 | West | Idaho, Wyoming, Colorado, Arizona and Nevada, and it touches New Mexico at the Four Corners | 3.27 | the California gull | Utah is known for five national parks like Arches and Zion, red rock canyons, the Great Salt Lake, and skiing.
VT | Vermont | the Green Mountain State | Burlington | March 4, 1791 | 14 | Northeast | New York, New Hampshire and Massachusetts | 0.64 | the hermit thrush | Vermont is known for maple syrup, fall colors, the Green Mountains, and Ben and Jerry's ice cream.
VA | Virginia | the Old Dominion | Virginia Beach | June 25, 1788 | 10 | South | Maryland, West Virginia, Kentucky, Tennessee and North Carolina, plus Washington, D.C. | 8.63 | the northern cardinal | Virginia is known for Jamestown, the first lasting English colony, Mount Vernon (George Washington's home), and being the birthplace of eight US presidents.
WA | Washington | the Evergreen State | Seattle | November 11, 1889 | 42 | West | Idaho and Oregon | 7.71 | the willow goldfinch (American goldfinch) | Washington State is known for Seattle and its Space Needle, Mount Rainier, apples, rain, and companies like Microsoft, Amazon and Boeing.
WV | West Virginia | the Mountain State | Charleston | June 20, 1863 | 35 | South | Ohio, Pennsylvania, Maryland, Virginia and Kentucky | 1.79 | the northern cardinal | West Virginia split from Virginia during the Civil War. It's known for the Appalachian Mountains, coal mining, and the New River Gorge Bridge.
WI | Wisconsin | the Badger State | Milwaukee | May 29, 1848 | 30 | Midwest | Michigan, Minnesota, Iowa and Illinois | 5.89 | the American robin | Wisconsin is known as America's Dairyland, for cheese, the Green Bay Packers football team, and lots of lakes.
WY | Wyoming | the Equality State (also the Cowboy State) | Cheyenne | July 10, 1890 | 44 | West | Montana, South Dakota, Nebraska, Colorado, Utah and Idaho | 0.58 | the western meadowlark | Wyoming has the fewest people of any state, and it's known for Yellowstone, the first national park, Grand Teton, and Devils Tower.
"""

ORD = {1: "1st", 2: "2nd", 3: "3rd"}
EXTRA_REGION = {
    "CT": "New England", "ME": "New England", "MA": "New England", "NH": "New England", "RI": "New England",
    "VT": "New England", "WA": "the Pacific Northwest", "OR": "the Pacific Northwest", "AZ": "the Southwest",
    "NM": "the Southwest", "AK": "the Pacific coast, far to the northwest", "HI": "the Pacific Ocean",
}
CAPITALS = {}


def ordinal(n):
    if 10 <= n % 100 <= 20:
        return f"{n}th"
    return f"{n}" + {1: "st", 2: "nd", 3: "rd"}.get(n % 10, "th")


def main():
    w = Writer(["gen_us_states.txt"])
    f = "gen_us_states.txt"
    for line in TABLE.strip().splitlines():
        ab, st, nick, big, date, order, region, borders, pop, bird, known = [x.strip() for x in line.split("|")]
        n = st.lower()
        rng = rng_for(ab)
        qn = n if n not in ("washington", "georgia", "new york") else {
            "washington": "washington state", "georgia": "georgia the state", "new york": "new york state"}[n]
        S = "Washington State" if ab == "WA" else st

        def Q(ts):
            first, rest = ts[:1], ts[1:]
            rng.shuffle(rest)
            return [t.format(n=qn) for t in first + rest]

        w.add(f, "geo.us.nickname", Q(["what is the nickname of {n}", "{n} state nickname",
                                       "what do people call {n} as a nickname"]),
              f"{S}'s nickname is {nick}.")
        core = nick.split(" (")[0]
        core_q = core.lower().replace("the ", "", 1) if core.lower().startswith("the ") else core.lower()
        w.add(f, "geo.us.nickname.reverse", [f"which state is the {core_q}", f"what state is called the {core_q}",
                                             f"what state is known as the {core_q}"],
              f"{S} is {core}.")
        if ab not in ("AK", "HI"):
            w.add(f, "geo.us.borders", Q(["what states border {n}", "which states are next to {n}",
                                          "what states touch {n}", "{n} neighboring states"]),
                  f"{S} borders {borders}.")
        else:
            w.add(f, "geo.us.borders", Q(["what states border {n}", "which states are next to {n}",
                                          "does {n} touch any other states"]),
                  f"{S} doesn't border any other states. " + (
                      "It borders Canada, and the lower 48 states are on the other side of Canada."
                      if ab == "AK" else "It's a chain of islands in the Pacific Ocean, about 2,400 miles from California."))
        cap_city = None
        w.add(f, "geo.us.largestcity", Q(["what is the biggest city in {n}", "largest city in {n}",
                                          "{n} biggest city", "which city in {n} has the most people"]),
              f"The biggest city in {S} is {big}.")
        o = int(order)
        ans = f"{S} became the {ordinal(o)} state on {date}."
        if ab in ("ND", "SD"):
            ans = (f"{S} became a state on {date}, the same day as its neighbor. By tradition, North Dakota is "
                   f"counted as the 39th state and South Dakota as the 40th.")
        if o <= 13:
            ans += " It was one of the original 13 states."
        w.add(f, "geo.us.statehood", Q(["when did {n} become a state", "what year did {n} join the union",
                                        "when was {n} admitted to the us", "{n} statehood date"]), ans)
        reg = f"{S} is in the {region} region of the United States."
        if ab in EXTRA_REGION:
            reg = f"{S} is in the {region} region of the United States, in {EXTRA_REGION[ab]}."
        w.add(f, "geo.us.region", Q(["what region is {n} in", "which us region is {n} in", "what part of the us is {n} in",
                                     "where is {n} in the us"]), reg)
        p = float(pop)
        ptxt = f"about {p:.1f} million" if p >= 1 else f"about {int(round(p * 1000, -1))},000"
        w.add(f, "geo.us.population", Q(["how many people live in {n}", "what is the population of {n}",
                                         "{n} population", "how many people are in {n} state"]),
              f"{S} had {ptxt} people in the 2020 census.")
        w.add(f, "geo.us.bird", Q(["what is the state bird of {n}", "{n} state bird", "whats {n}s official bird"]),
              f"The state bird of {S} is {bird}.")
        w.add(f, "geo.us.knownfor", Q(["what is {n} known for", "what is {n} famous for", "fun facts about {n}",
                                       "whats special about {n}"]), known)
    w.save("""Generated by tools/knowledge/gen/geo_us_states.py. Do not edit by hand.
Data: hand-written table (2020 census, admission dates, official nicknames and state birds).""")
    for d in w.dropped:
        print("  dropped:", d)


if __name__ == "__main__":
    main()
