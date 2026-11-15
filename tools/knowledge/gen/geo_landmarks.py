#!/usr/bin/env python3
"""Generates landmark and wonder Q&A for Ace: data/geo/gen_landmarks.txt

Source: hand-written table below from general knowledge, checked against standard references.
Heights and dates are rounded or given as commonly cited.

Run from the repo root:  python3 tools/knowledge/gen/geo_landmarks.py
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from geo_common import Writer, rng_for  # noqa: E402

# q | where answer | built answer (who and when) | fact answer      (blank = skip)
TABLE = r"""
eiffel tower | The Eiffel Tower is in Paris, France, on the Champ de Mars next to the Seine River. | The Eiffel Tower was built from 1887 to 1889 by Gustave Eiffel's engineering company, for the 1889 World's Fair in Paris. | The Eiffel Tower is about 330 meters (1,083 feet) tall. Many Parisians first hated it, and it was supposed to be taken down after 20 years, but it was kept because it was useful as a radio tower.
statue of liberty | The Statue of Liberty is on Liberty Island in New York Harbor, in New York City. | The Statue of Liberty was designed by Frédéric Auguste Bartholdi, with an iron frame by Gustave Eiffel. It was a gift from France and was dedicated in 1886. | The Statue of Liberty is made of copper and turned green over time from weathering. She holds a torch and a tablet with the date of the Declaration of Independence, 4 July 1776.
great wall of china | The Great Wall of China stretches across northern China, from the Bohai Sea in the east into the Gobi Desert in the west. | The Great Wall was built over about 2,000 years by many Chinese dynasties. Most of the wall people visit today was built by the Ming dynasty, from the 1300s to the 1600s. | All its sections together add up to more than 21,000 kilometers (13,000 miles). Contrary to the popular myth, you can't see it with your bare eyes from space.
taj mahal | The Taj Mahal is in Agra, in northern India, on the bank of the Yamuna River. | The Taj Mahal was built by the Mughal emperor Shah Jahan as a tomb for his wife Mumtaz Mahal. Work started in 1632 and took about 20 years. | The Taj Mahal is made of white marble decorated with precious stones, and its color seems to change from pink to white to golden during the day.
colosseum | The Colosseum is in the center of Rome, Italy. | The Colosseum was built by Roman emperors Vespasian and his son Titus, and it opened in 80 AD. | The Colosseum could hold about 50,000 people, who watched gladiator fights and animal hunts. It's the biggest amphitheater ever built.
machu picchu | Machu Picchu is high in the Andes Mountains in Peru, above the Urubamba River valley near Cusco. | Machu Picchu was built by the Inca around the 1450s, probably as an estate for the emperor Pachacuti. | Machu Picchu was hidden from the Spanish conquerors, and it became world famous after Hiram Bingham visited it in 1911. Its stone walls fit together so tightly that no mortar was needed.
christ the redeemer | Christ the Redeemer stands on top of Corcovado mountain in Rio de Janeiro, Brazil. | Christ the Redeemer was designed by Brazilian engineer Heitor da Silva Costa and French sculptor Paul Landowski, and it was finished in 1931. | Christ the Redeemer is about 30 meters (98 feet) tall, with arms about 28 meters (92 feet) wide. It gets struck by lightning several times a year.
petra | Petra is in the desert of southern Jordan. | Petra was carved into rose-colored rock cliffs by the Nabataeans, starting more than 2,000 years ago. | Petra's most famous building, the Treasury, appears in the movie Indiana Jones and the Last Crusade. Petra is called the Rose City because of the color of its stone.
chichen itza | Chichén Itzá is on the Yucatán Peninsula in Mexico. | Chichén Itzá was built by the Maya, and it was a big city from about 600 to 1200 AD. | Chichén Itzá's pyramid, El Castillo, has 365 steps in all, one for each day of the year. At the spring and fall equinoxes, a shadow like a snake slides down its stairs.
great pyramid of giza | The Great Pyramid of Giza is just outside Cairo, Egypt. | The Great Pyramid was built for the pharaoh Khufu around 2560 BC, by thousands of skilled workers. | The Great Pyramid was the tallest building in the world for more than 3,800 years, and it's the only one of the Seven Wonders of the Ancient World still standing.
sphinx | The Great Sphinx is next to the pyramids at Giza, near Cairo, Egypt. | The Great Sphinx was carved from limestone around 4,500 years ago, probably for the pharaoh Khafre. | The Great Sphinx has the body of a lion and the head of a king. It's about 73 meters (240 feet) long, and its nose has been missing for hundreds of years.
stonehenge | Stonehenge is on Salisbury Plain in Wiltshire, in southern England. | Stonehenge was built in stages by ancient people in Britain, starting about 5,000 years ago. | Some of Stonehenge's smaller bluestones came from Wales, more than 200 kilometers (140 miles) away. On the summer solstice, the sun rises in line with the stones.
big ben | Big Ben is at the Houses of Parliament in Westminster, London, England. | The clock tower that holds Big Ben was finished in 1859, designed by Augustus Pugin. | Big Ben is really the name of the giant bell inside, but people use it for the whole tower, which was renamed the Elizabeth Tower in 2012.
tower of london | The Tower of London is on the north bank of the River Thames in London, England. | The Tower of London was started by William the Conqueror after 1066. The White Tower in the middle was built in the 1070s and 1080s. | The Tower of London has been a palace, a prison and a treasury. It keeps the Crown Jewels, and ravens live there because legend says the kingdom will fall if they leave.
tower bridge | Tower Bridge crosses the River Thames in London, next to the Tower of London. | Tower Bridge was built from 1886 to 1894. | Tower Bridge has two roads that lift up so tall ships can pass. People often mistake it for London Bridge, which is a plainer bridge nearby.
buckingham palace | Buckingham Palace is in Westminster, in central London, England. | Buckingham Palace started as a house built in 1703 for the Duke of Buckingham. King George III bought it in 1761, and Queen Victoria was the first monarch to live there, from 1837. | Buckingham Palace has 775 rooms, and the Changing of the Guard happens outside it.
leaning tower of pisa | The Leaning Tower of Pisa is in Pisa, in the Tuscany region of Italy. | Building on the Leaning Tower of Pisa started in 1173 and took almost 200 years. | The tower started leaning while it was still being built, because the soft ground under it sank on one side. Engineers straightened it a little from 1990 to 2001 so it wouldn't fall.
sagrada familia | The Sagrada Família is in Barcelona, Spain. | The Sagrada Família was designed by architect Antoni Gaudí, and building started in 1882. Work on it is still going on more than 140 years later. | Gaudí worked on the Sagrada Família for more than 40 years until he died in 1926. As of 2025, its central tower, for Jesus, makes it the tallest church in the world.
acropolis | The Acropolis is on a rocky hill above the city of Athens, Greece. | The Acropolis's most famous buildings, including the Parthenon, were built in the 400s BC, when Pericles led Athens. | The Parthenon on the Acropolis was a temple to Athena, the goddess the city of Athens is named after.
parthenon | The Parthenon stands on the Acropolis in Athens, Greece. | The Parthenon was built from 447 to 432 BC by the ancient Athenians. | The Parthenon was a temple to the goddess Athena. It was damaged in 1687 when gunpowder stored inside exploded during a war.
notre dame | Notre-Dame Cathedral is on the Île de la Cité, an island in the Seine River in Paris, France. | Notre-Dame was built mostly from 1163 to about 1260. | A fire in April 2019 destroyed Notre-Dame's roof and spire. It was rebuilt and reopened in December 2024.
louvre | The Louvre is in the center of Paris, France, by the Seine River. | The Louvre started as a fortress around 1200, became a royal palace, and opened as a museum in 1793. Its glass pyramid was added in 1989. | The Louvre is the most visited museum in the world, and it holds the Mona Lisa and the Venus de Milo.
arc de triomphe | The Arc de Triomphe is at the top of the Champs-Élysées in Paris, France. | Napoleon ordered the Arc de Triomphe in 1806 to honor his army, and it was finished in 1836. | The Tomb of the Unknown Soldier from World War I lies under the Arc de Triomphe, with a flame that's relit every evening.
palace of versailles | The Palace of Versailles is in Versailles, just west of Paris, France. | King Louis XIV turned a hunting lodge into the giant Palace of Versailles, mostly from the 1660s to the 1680s. | Versailles has the Hall of Mirrors, with 357 mirrors. The treaty that ended World War I was signed there in 1919.
mont saint michel | Mont-Saint-Michel is a small rocky island off the coast of Normandy, in France. | The abbey on Mont-Saint-Michel was built over hundreds of years, starting in the 700s. | At high tide, Mont-Saint-Michel becomes an island, and at low tide you can walk to it across the sand.
neuschwanstein castle | Neuschwanstein Castle is in Bavaria, in southern Germany, near the Alps. | Neuschwanstein was built for King Ludwig II of Bavaria, starting in 1869. | Neuschwanstein Castle helped inspire Sleeping Beauty's castle at Disneyland.
brandenburg gate | The Brandenburg Gate is in the center of Berlin, Germany. | The Brandenburg Gate was built from 1788 to 1791 for King Frederick William II of Prussia. | The Brandenburg Gate stood right by the Berlin Wall. Now it's a symbol of Germany being united again.
berlin wall | The Berlin Wall ran through and around West Berlin, in Germany. | East Germany built the Berlin Wall in 1961 to stop people from escaping to the West. | The Berlin Wall fell on 9 November 1989, and Germany was reunited in 1990. Some pieces still stand as a memorial.
kremlin | The Kremlin is in the center of Moscow, Russia, next to Red Square. | The Kremlin's red brick walls and towers were built from 1485 to 1495, though a fortress stood there long before. | The Kremlin is where Russia's president works. Kremlin means fortress inside a city.
st basils cathedral | St. Basil's Cathedral is on Red Square in Moscow, Russia. | St. Basil's Cathedral was built from 1555 to 1561 on orders from Ivan the Terrible. | St. Basil's is famous for its colorful onion-shaped domes. A legend says Ivan had the builders blinded, but historians say it's not true.
forbidden city | The Forbidden City is in the center of Beijing, China. | The Forbidden City was built from 1406 to 1420 by the Ming dynasty emperor Yongle. | The Forbidden City was the palace of Chinese emperors for almost 500 years. It has about 980 buildings, and ordinary people couldn't enter without permission.
terracotta army | The Terracotta Army is near Xi'an, in Shaanxi province, China. | The Terracotta Army was made for Qin Shi Huang, the first emperor of China, who died in 210 BC. | The Terracotta Army has thousands of life-size clay soldiers, each with a different face. Farmers found it by accident in 1974 while digging a well.
angkor wat | Angkor Wat is near the city of Siem Reap, in Cambodia. | Angkor Wat was built in the early 1100s by the Khmer king Suryavarman II. | Angkor Wat is the biggest religious monument in the world. It was built as a Hindu temple and later became Buddhist, and it's on Cambodia's flag.
burj khalifa | The Burj Khalifa is in Dubai, in the United Arab Emirates. | The Burj Khalifa was built from 2004 to 2010. | The Burj Khalifa is about 828 meters (2,717 feet) tall, the tallest building in the world as of 2025. It has more than 160 floors.
sydney opera house | The Sydney Opera House is on Sydney Harbour in Sydney, Australia. | The Sydney Opera House was designed by Danish architect Jørn Utzon and opened in 1973. | The Sydney Opera House's roof looks like sails or shells. It took 14 years to build and cost far more than planned.
sydney harbour bridge | The Sydney Harbour Bridge crosses Sydney Harbour in Sydney, Australia. | The Sydney Harbour Bridge opened in 1932. | The Sydney Harbour Bridge is nicknamed the Coathanger because of its arch shape, and people can climb to the top.
uluru | Uluru is in the desert of the Northern Territory, in central Australia. | Uluru is a natural rock that formed over hundreds of millions of years. | Uluru is a giant sandstone rock that glows red at sunrise and sunset. It's sacred to the Aṉangu, the Aboriginal people of the area, and climbing it was banned in 2019.
golden gate bridge | The Golden Gate Bridge is in San Francisco, California, crossing the strait where San Francisco Bay meets the Pacific Ocean. | The Golden Gate Bridge was built from 1933 to 1937, with Joseph Strauss as chief engineer. | The Golden Gate Bridge is painted a color called International Orange, so it's easy to see in fog. When it opened, it was the longest suspension bridge in the world.
mount rushmore | Mount Rushmore is in the Black Hills of South Dakota. | Mount Rushmore was carved from 1927 to 1941 by sculptor Gutzon Borglum and his son Lincoln Borglum, with about 400 workers. | Mount Rushmore shows the faces of four presidents: George Washington, Thomas Jefferson, Theodore Roosevelt and Abraham Lincoln. Each face is about 18 meters (60 feet) tall.
empire state building | The Empire State Building is in Midtown Manhattan, in New York City. | The Empire State Building was built in only about 13 months and opened in 1931. | The Empire State Building is about 443 meters (1,454 feet) tall with its antenna, and it was the tallest building in the world for almost 40 years.
white house | The White House is at 1600 Pennsylvania Avenue in Washington, DC. | The White House was designed by James Hoban and built from 1792 to 1800. John Adams was the first president to live there. | The British burned the White House in 1814 during the War of 1812, and it was rebuilt. It has 132 rooms.
lincoln memorial | The Lincoln Memorial is at the west end of the National Mall in Washington, DC. | The Lincoln Memorial was designed by Henry Bacon and dedicated in 1922. | The Lincoln Memorial has a giant statue of Abraham Lincoln sitting down. Martin Luther King Jr. gave his "I Have a Dream" speech on its steps in 1963.
washington monument | The Washington Monument is on the National Mall in Washington, DC. | Building on the Washington Monument started in 1848, stopped during the Civil War, and finished in 1884. | The Washington Monument is about 169 meters (555 feet) tall. You can see a line partway up where the color of the stone changes, because the builders had to use stone from a different quarry after the pause.
gateway arch | The Gateway Arch is in St. Louis, Missouri, by the Mississippi River. | The Gateway Arch was designed by architect Eero Saarinen and finished in 1965. | The Gateway Arch is 192 meters (630 feet) tall and just as wide, the tallest arch in the world. Tiny tram cars carry people to the top.
space needle | The Space Needle is in Seattle, Washington. | The Space Needle was built for the 1962 World's Fair in Seattle. | The Space Needle is about 184 meters (605 feet) tall, and it has a glass floor that turns around at the top.
hollywood sign | The Hollywood Sign is on Mount Lee, in the Hollywood Hills of Los Angeles, California. | The Hollywood Sign was put up in 1923 by real estate developers as an ad for a housing area called Hollywoodland. The "land" part was taken off in 1949. | Each letter of the Hollywood Sign is about 14 meters (45 feet) tall.
alamo | The Alamo is in San Antonio, Texas. | The Alamo was built as a Spanish mission church starting in the 1700s. | In 1836, Texan fighters, including Davy Crockett and Jim Bowie, were defeated at the Alamo by the Mexican army. "Remember the Alamo" became a battle cry.
liberty bell | The Liberty Bell is in Philadelphia, Pennsylvania, in a building across from Independence Hall. | The Liberty Bell was made in London and arrived in Philadelphia in 1752. It cracked and was recast in Philadelphia in 1753. | The Liberty Bell is famous for its big crack, and it became a symbol of freedom for people working to end slavery.
hoover dam | The Hoover Dam is on the Colorado River, on the border between Nevada and Arizona, near Las Vegas. | The Hoover Dam was built from 1931 to 1936 during the Great Depression. | The Hoover Dam is about 221 meters (726 feet) tall and makes electricity for millions of people. It holds back Lake Mead.
cn tower | The CN Tower is in Toronto, Ontario, Canada. | The CN Tower was built from 1973 to 1976. | The CN Tower is about 553 meters (1,815 feet) tall. It was the tallest free-standing structure in the world for over 30 years, and brave visitors can walk around the outside of it on a ledge.
chateau frontenac | The Château Frontenac is in Quebec City, Canada. | The Château Frontenac hotel opened in 1893. | The Château Frontenac is said to be the most photographed hotel in the world.
easter island statues | The moai statues are on Easter Island, in the Pacific Ocean, which belongs to Chile. | The moai were carved by the Rapa Nui people, mostly between about 1250 and 1500. | There are almost 1,000 moai. Many have bodies buried under the ground, not just heads.
great barrier reef | The Great Barrier Reef is in the Coral Sea, off the coast of Queensland in northeastern Australia. | The Great Barrier Reef was built by billions of tiny coral animals over thousands of years. | The Great Barrier Reef is the biggest coral reef system in the world, more than 2,300 kilometers (1,400 miles) long, and it's made by living things.
grand canyon | The Grand Canyon is in northern Arizona, in the United States. | The Grand Canyon was carved by the Colorado River over millions of years. | The Grand Canyon is about 446 kilometers (277 miles) long and up to about 1,800 meters (6,000 feet) deep. Its rock layers show almost 2 billion years of Earth's history.
victoria peak | Victoria Peak is on Hong Kong Island, in Hong Kong, China. | | Victoria Peak is the highest hill on Hong Kong Island, and a tram called the Peak Tram has carried people up since 1888.
mecca | Mecca is in western Saudi Arabia. | | Mecca is the holiest city in Islam. Muslims face toward the Kaaba in Mecca when they pray, and millions visit every year for the Hajj.
kaaba | The Kaaba is in the middle of the Great Mosque in Mecca, Saudi Arabia. | | The Kaaba is a cube-shaped building covered in black cloth with gold writing. It's the holiest place in Islam.
western wall | The Western Wall is in the Old City of Jerusalem. | The Western Wall is part of a wall built around the Jewish Temple in Jerusalem by King Herod, about 2,000 years ago. | The Western Wall is the holiest place where Jews can pray. People tuck written prayers into cracks in the wall.
hagia sophia | Hagia Sophia is in Istanbul, Turkey. | Hagia Sophia was built by the Byzantine emperor Justinian I and finished in 537 AD. | Hagia Sophia was a church for about 900 years, then a mosque, then a museum, and became a mosque again in 2020. Its giant dome amazed people for centuries.
blue mosque | The Blue Mosque, also called the Sultan Ahmed Mosque, is in Istanbul, Turkey. | The Blue Mosque was built from 1609 to 1616 for Sultan Ahmed I. | The Blue Mosque is named for the blue tiles inside it, and it has six minarets.
alhambra | The Alhambra is in Granada, in southern Spain. | The Alhambra was built mostly in the 1200s and 1300s by the Nasrid rulers, the last Muslim kingdom in Spain. | The Alhambra is famous for its detailed carvings, tiles and fountains. Its name means the red one in Arabic.
pantheon | The Pantheon is in the center of Rome, Italy. | The Pantheon was rebuilt by the Roman emperor Hadrian around 125 AD. | The Pantheon's concrete dome is still the biggest unreinforced concrete dome in the world, with a round hole at the top called the oculus that lets in light and rain.
trevi fountain | The Trevi Fountain is in Rome, Italy. | The Trevi Fountain was designed by Nicola Salvi and finished in 1762. | People throw coins over their shoulder into the Trevi Fountain for luck. Thousands of euros are collected each week and given to charity.
st peters basilica | St. Peter's Basilica is in Vatican City, inside Rome, Italy. | St. Peter's Basilica was built from 1506 to 1626, with designs by artists including Michelangelo, who designed its dome. | St. Peter's Basilica is one of the biggest churches in the world, and the Pope leads big services there.
sistine chapel | The Sistine Chapel is in Vatican City, inside Rome. | The Sistine Chapel was built from 1473 to 1481. Michelangelo painted its ceiling from 1508 to 1512. | The Sistine Chapel's ceiling has Michelangelo's famous painting of God reaching out to Adam. Cardinals meet there to choose a new pope.
venice canals | Venice is in northeastern Italy, built on islands in a lagoon off the Adriatic Sea. | | Venice has about 150 canals and over 400 bridges, and people get around by boats like gondolas and water buses instead of cars.
atomium | The Atomium is in Brussels, Belgium. | The Atomium was built for the 1958 World's Fair in Brussels. | The Atomium is shaped like a giant iron crystal, made 165 billion times bigger, with nine steel balls connected by tubes.
little mermaid statue | The Little Mermaid statue is on the waterfront in Copenhagen, Denmark. | The Little Mermaid statue was made by Edvard Eriksen and put up in 1913. | The Little Mermaid statue is based on the fairy tale by Danish writer Hans Christian Andersen, and it's only about 1.25 meters (4 feet) tall.
edinburgh castle | Edinburgh Castle sits on Castle Rock, an old volcano, in Edinburgh, Scotland. | People have lived on Castle Rock for thousands of years, and the oldest building in Edinburgh Castle, St. Margaret's Chapel, is from the 1100s. | Edinburgh Castle holds the Crown Jewels of Scotland and the Stone of Destiny, and a gun is fired from it at 1 o'clock most days.
giants causeway | The Giant's Causeway is on the north coast of Northern Ireland. | The Giant's Causeway formed naturally about 50 to 60 million years ago when lava cooled and cracked. | The Giant's Causeway has about 40,000 six-sided stone columns. A legend says the giant Finn McCool built it to cross the sea to Scotland.
cliffs of moher | The Cliffs of Moher are on the west coast of Ireland, in County Clare. | | The Cliffs of Moher rise up to about 214 meters (702 feet) above the Atlantic Ocean, and they were in a Harry Potter movie.
borobudur | Borobudur is on the island of Java, in Indonesia. | Borobudur was built in the 700s and 800s AD by the Sailendra dynasty. | Borobudur is the biggest Buddhist temple in the world, with more than 500 Buddha statues and over 2,600 carved panels.
potala palace | The Potala Palace is in Lhasa, Tibet, in China. | The Potala Palace was built mostly in the 1600s, under the fifth Dalai Lama. | The Potala Palace was the home of the Dalai Lama until 1959. It has more than 1,000 rooms and sits high on a hill at about 3,700 meters (12,100 feet).
golden temple | The Golden Temple, or Harmandir Sahib, is in Amritsar, in Punjab, India. | The Golden Temple was founded in the 1500s. Its gold covering was added in the early 1800s by Maharaja Ranjit Singh. | The Golden Temple is the holiest place for Sikhs. Its free kitchen serves meals to as many as 100,000 people a day, no matter who they are.
red fort | The Red Fort is in Old Delhi, India. | The Red Fort was built for the Mughal emperor Shah Jahan from 1639 to 1648. | Every year on India's Independence Day, the Prime Minister raises the flag at the Red Fort and gives a speech.
gateway of india | The Gateway of India is on the waterfront in Mumbai, India. | The Gateway of India was finished in 1924, built to remember King George V's visit in 1911. | The last British soldiers to leave India marched through the Gateway of India in 1948.
marina bay sands | Marina Bay Sands is in Singapore. | Marina Bay Sands opened in 2010. | Marina Bay Sands has three hotel towers joined at the top by a giant platform shaped like a ship, with a long swimming pool on the roof.
petronas towers | The Petronas Towers are in Kuala Lumpur, Malaysia. | The Petronas Towers were finished in 1998. | The Petronas Towers were the tallest buildings in the world from 1998 to 2004. A sky bridge connects the two towers.
tokyo skytree | The Tokyo Skytree is in Tokyo, Japan. | The Tokyo Skytree was finished in 2012. | The Tokyo Skytree is 634 meters (2,080 feet) tall, the tallest tower in the world.
tokyo tower | Tokyo Tower is in Tokyo, Japan. | Tokyo Tower was finished in 1958. | Tokyo Tower looks like the Eiffel Tower but is painted orange and white for airplane safety. It's about 333 meters (1,092 feet) tall.
fushimi inari | Fushimi Inari Shrine is in Kyoto, Japan. | | Fushimi Inari Shrine has thousands of bright orange gates called torii that make tunnels up a mountain.
itsukushima shrine | Itsukushima Shrine is on Miyajima island, near Hiroshima, Japan. | | Itsukushima Shrine has a giant orange torii gate that looks like it's floating on the water at high tide.
panama canal | The Panama Canal cuts across Panama in Central America, connecting the Atlantic and Pacific oceans. | The Panama Canal was started by France in 1881, but they gave up. The United States built it from 1904 to 1914. | Ships going through the Panama Canal avoid sailing all the way around South America. Locks lift ships about 26 meters (85 feet) up and back down.
suez canal | The Suez Canal is in Egypt, connecting the Mediterranean Sea to the Red Sea. | The Suez Canal was built from 1859 to 1869 by a company led by Frenchman Ferdinand de Lesseps. | The Suez Canal lets ships go between Europe and Asia without sailing around Africa. In 2021, a giant ship called the Ever Given got stuck in it for six days.
channel tunnel | The Channel Tunnel runs under the English Channel between Folkestone in England and Coquelles near Calais in France. | The Channel Tunnel was built from 1988 to 1994. | The Channel Tunnel is about 50 kilometers (31 miles) long, with the longest undersea section of any tunnel in the world. Trains carry cars and passengers through it.
palm jumeirah | Palm Jumeirah is in Dubai, in the United Arab Emirates. | Palm Jumeirah was built starting in 2001 by piling up sand from the sea floor. | Palm Jumeirah is an artificial island shaped like a palm tree, and you can see it from space.
red square | Red Square is in the center of Moscow, Russia, next to the Kremlin. | | Red Square's name comes from an old Russian word that meant both red and beautiful. St. Basil's Cathedral and Lenin's tomb are there.
times square | Times Square is in Midtown Manhattan, in New York City. | | Times Square is famous for giant glowing billboards, and about a million people gather there to watch the ball drop on New Year's Eve.
central park | Central Park is in the middle of Manhattan, in New York City. | Central Park was designed by Frederick Law Olmsted and Calvert Vaux and opened in the 1850s and 1860s. | Central Park is about 341 hectares (843 acres), with lakes, a zoo, and ice rinks. It's bigger than the country of Monaco.
independence hall | Independence Hall is in Philadelphia, Pennsylvania. | Independence Hall was built from 1732 to 1753 as the Pennsylvania State House. | Both the Declaration of Independence and the US Constitution were signed in Independence Hall.
pearl harbor | Pearl Harbor is on the island of Oahu in Hawaii, near Honolulu. | | Japan attacked the US Navy base at Pearl Harbor on 7 December 1941, which brought the United States into World War II. The USS Arizona Memorial sits over the sunken battleship.
ellis island | Ellis Island is in New York Harbor, near the Statue of Liberty. | | From 1892 to 1954, about 12 million immigrants entered the United States through Ellis Island. Today it's a museum about immigration.
old faithful | Old Faithful is in Yellowstone National Park, in Wyoming. | | Old Faithful is a geyser that shoots hot water into the air about every 60 to 110 minutes, which is how it got its name.
pyramids of giza | The Pyramids of Giza are on the Giza Plateau, just outside Cairo, Egypt. | The three main pyramids of Giza were built for the pharaohs Khufu, Khafre and Menkaure, around 2600 to 2500 BC. | The Pyramids of Giza are lined up almost perfectly with north, south, east and west.
abu simbel | Abu Simbel is in southern Egypt, near the border with Sudan, by Lake Nasser. | Abu Simbel's two temples were carved into a mountain for the pharaoh Ramesses II around 1260 BC. | In the 1960s, Abu Simbel was cut into giant blocks and moved uphill to save it from the water of a new dam.
"""

TEMPL = dict(
    where=["where is the {q}", "what country is the {q} in", "what city is the {q} in", "{q} location"],
    built=["who built the {q}", "when was the {q} built", "how old is the {q}", "who made the {q}"],
    fact=["what is the {q}", "facts about the {q}", "why is the {q} famous", "tell me about the {q}"],
)
NO_CITY = {"mecca", "venice canals", "great wall of china", "great barrier reef", "grand canyon", "uluru", "stonehenge",
           "machu picchu", "panama canal", "suez canal", "channel tunnel", "berlin wall", "cliffs of moher",
           "giants causeway", "easter island statues", "mont saint michel", "neuschwanstein castle", "chichen itza",
           "petra", "hoover dam", "mount rushmore", "old faithful", "abu simbel", "pyramids of giza",
           "great pyramid of giza", "sphinx", "palace of versailles", "borobudur", "angkor wat", "pearl harbor",
           "ellis island", "itsukushima shrine", "palm jumeirah"}
# names that read naturally with "the" in front
WITH_THE = {"eiffel tower", "statue of liberty", "great wall of china", "great pyramid of giza", "sphinx",
            "tower of london", "leaning tower of pisa", "arc de triomphe", "palace of versailles", "burj khalifa",
            "sydney harbour bridge", "panama canal", "suez canal", "channel tunnel", "pyramids of giza",
            "little mermaid statue", "colosseum", "parthenon", "acropolis", "pantheon", "trevi fountain",
            "sistine chapel", "alhambra", "blue mosque", "kaaba", "western wall", "forbidden city", "terracotta army",
            "potala palace", "golden temple", "red fort", "gateway of india", "petronas towers", "brandenburg gate",
            "berlin wall", "atomium", "cliffs of moher", "taj mahal", "kremlin", "louvre", "alamo", "white house",
            "space needle", "hollywood sign", "liberty bell", "great barrier reef", "grand canyon",
            "golden gate bridge", "empire state building", "lincoln memorial", "washington monument", "gateway arch",
            "cn tower", "chateau frontenac", "hoover dam", "sagrada familia", "easter island statues", "giants causeway"}


def main():
    w = Writer(["gen_landmarks.txt"])
    for line in TABLE.strip().splitlines():
        parts = [x.strip() for x in line.split("|")] + ["", "", ""]
        q, answers = parts[0], dict(zip(["where", "built", "fact"], parts[1:4]))
        rng = rng_for("landmark", q)
        for key in ("where", "built", "fact"):
            ans = answers[key]
            if not ans or ans.startswith("See "):
                continue
            ts = list(TEMPL[key])
            first, rest = ts[:1], ts[1:]
            rng.shuffle(rest)
            words = []
            for i, t in enumerate(first + rest):
                if q in WITH_THE:
                    # mix "the eiffel tower" and "eiffel tower", the way kids type
                    s = t.format(q=q) if i % 2 == 0 else t.replace("the {q}", "{q}").format(q=q)
                else:
                    s = t.replace("the {q}", "{q}").format(q=q)
                words.append(s)
            if key == "where" and q in NO_CITY:
                words = [x for x in words if "city" not in x]
            w.add("gen_landmarks.txt", "geo.landmark", words, ans, limit=4)
    w.save("""Generated by tools/knowledge/gen/geo_landmarks.py. Do not edit by hand.
Data: hand-written table of world landmarks and wonders.""")
    for d in w.dropped:
        print("  dropped:", d)


if __name__ == "__main__":
    main()
