#!/usr/bin/env python3
"""Generates Q&A about major world cities: data/geo/gen_cities.txt

Source: hand-written table below from general knowledge, checked against standard references.
Country capitals already have "what country is X in" questions in Ace's older bank, so for capitals
only the "known for" question is added.

Run from the repo root:  python3 tools/knowledge/gen/geo_cities.py
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.normpath(os.path.join(HERE, "..", "..")))
from geo_common import Writer, ascii_fold, rng_for  # noqa: E402
import qa_data_world as OLD  # noqa: E402

# City | where ("Country" or "US:State" or "CA:Province" or "AU:State") | known for ("" = skip)
TABLE = r"""
New York City | US:New York | New York City is the biggest city in the US, known for Times Square, the Statue of Liberty, Central Park, Broadway, the Empire State Building and yellow taxis.
Los Angeles | US:California | Los Angeles is known for Hollywood and the movie industry, the Hollywood sign, beaches like Santa Monica, and lots of traffic.
Chicago | US:Illinois | Chicago is known for deep-dish pizza, the Willis Tower, the Bean sculpture in Millennium Park, and its spot on Lake Michigan. It's nicknamed the Windy City.
Houston | US:Texas | Houston is the biggest city in Texas, known for NASA's Johnson Space Center (Mission Control) and the oil and energy industry.
Phoenix | US:Arizona | Phoenix is the capital of Arizona, known for its desert heat, with summer days often over 110°F, and nearby saguaro cactuses.
Philadelphia | US:Pennsylvania | Philadelphia is where the Declaration of Independence and the Constitution were signed, and it's known for the Liberty Bell and cheesesteaks.
San Antonio | US:Texas | San Antonio is known for the Alamo and the River Walk.
San Diego | US:California | San Diego is known for its beaches, the San Diego Zoo, perfect weather, and the Navy.
Dallas | US:Texas | Dallas is a big city in Texas, known for the Dallas Cowboys, business, and the place where President John F. Kennedy was assassinated in 1963.
Austin | US:Texas | Austin is the capital of Texas, known for live music, tech companies, and the slogan "Keep Austin Weird".
San Francisco | US:California | San Francisco is known for the Golden Gate Bridge, cable cars, Alcatraz Island, steep hills, fog, and being next to Silicon Valley.
Seattle | US:Washington | Seattle is known for the Space Needle, rain, coffee shops (Starbucks started there), and companies like Microsoft and Amazon.
Denver | US:Colorado | Denver is the Mile High City, about one mile above sea level, at the edge of the Rocky Mountains.
Boston | US:Massachusetts | Boston is one of the oldest US cities, known for the Boston Tea Party, the Freedom Trail, Harvard and MIT nearby, and the Red Sox.
Las Vegas | US:Nevada | Las Vegas is known for casinos, big hotels on the Las Vegas Strip, shows, and bright lights in the middle of the desert.
Miami | US:Florida | Miami is known for its beaches, Cuban culture and food, Art Deco buildings, and warm weather all year.
Orlando | US:Florida | Orlando is known for theme parks like Walt Disney World and Universal Orlando.
Atlanta | US:Georgia | Atlanta is known for one of the busiest airports in the world, Coca-Cola's headquarters, CNN, and Martin Luther King Jr.'s birthplace.
Nashville | US:Tennessee | Nashville is called Music City, the center of country music, with the Grand Ole Opry.
Memphis | US:Tennessee | Memphis is known for blues music, barbecue, and Graceland, Elvis Presley's home.
New Orleans | US:Louisiana | New Orleans is known for jazz music, Mardi Gras, the French Quarter, and Cajun and Creole food.
Detroit | US:Michigan | Detroit is the Motor City, where Ford, General Motors and Chrysler made the US car industry famous. It's also the home of Motown music.
Minneapolis | US:Minnesota | Minneapolis is known for its lakes, cold winters, and its twin city, Saint Paul.
Portland | US:Oregon | Portland, Oregon is known for bridges, food trucks, bikes, rain, and Powell's, one of the biggest bookstores in the world.
Salt Lake City | US:Utah | Salt Lake City is near the Great Salt Lake, it hosted the 2002 Winter Olympics, and it's close to great ski resorts.
Honolulu | US:Hawaii | Honolulu is on the island of Oahu, known for Waikiki Beach, Diamond Head, and nearby Pearl Harbor.
Anchorage | US:Alaska | Anchorage is Alaska's biggest city, surrounded by mountains, with moose sometimes walking through town.
St. Louis | US:Missouri | St. Louis is known for the Gateway Arch, the tallest arch in the world, and its spot on the Mississippi River.
Kansas City | US:Missouri | Kansas City is known for barbecue, jazz, and lots of fountains. Part of it, Kansas City, Kansas, is across the state line.
Pittsburgh | US:Pennsylvania | Pittsburgh is known as the Steel City, with three rivers and more than 400 bridges.
Baltimore | US:Maryland | Baltimore is known for its Inner Harbor, blue crabs, and Fort McHenry, where the US national anthem was written.
Cleveland | US:Ohio | Cleveland is known for the Rock and Roll Hall of Fame, on Lake Erie.
Indianapolis | US:Indiana | Indianapolis is known for the Indianapolis 500 car race, held every May.
Charlotte | US:North Carolina | Charlotte is the biggest city in North Carolina, known for banking and NASCAR.
Albuquerque | US:New Mexico | Albuquerque is known for its International Balloon Fiesta, one of the biggest hot air balloon events in the world.
Tucson | US:Arizona | Tucson is in the Sonoran Desert, surrounded by saguaro cactuses.
Sacramento | US:California | Sacramento is the capital of California and grew during the Gold Rush of 1849.
Milwaukee | US:Wisconsin | Milwaukee is on Lake Michigan and is known for Harley-Davidson motorcycles and the Milwaukee Brewers.
Jacksonville | US:Florida | Jacksonville is the biggest city in Florida by area and population, on the Atlantic coast.
Toronto | CA:Ontario | Toronto is Canada's biggest city, known for the CN Tower, the Toronto Raptors and Maple Leafs, and being one of the most diverse cities in the world.
Montreal | CA:Quebec | Montreal is the biggest French-speaking city in North America, known for bagels, poutine, festivals and its underground city.
Vancouver | CA:British Columbia | Vancouver is on Canada's Pacific coast, surrounded by mountains and ocean, and it hosted the 2010 Winter Olympics.
Calgary | CA:Alberta | Calgary is known for the Calgary Stampede rodeo and being close to Banff and the Rocky Mountains.
Quebec City | CA:Quebec | Quebec City has the only old city walls still standing in North America north of Mexico, and the famous Château Frontenac hotel.
Sydney | AU:New South Wales | Sydney is Australia's biggest city, known for the Sydney Opera House, the Harbour Bridge and Bondi Beach.
Melbourne | AU:Victoria | Melbourne is known for coffee, sports like the Australian Open tennis and Aussie rules football, and street art in its laneways.
Brisbane | AU:Queensland | Brisbane is the capital of Queensland, and it will host the 2032 Summer Olympics.
Perth | AU:Western Australia | Perth is one of the most isolated big cities in the world, on Australia's west coast, and nearby Rottnest Island has cute quokkas.
Auckland | New Zealand | Auckland is New Zealand's biggest city, built on old volcanoes, and known for the Sky Tower and sailing.
Rio de Janeiro | Brazil | Rio de Janeiro is known for the Christ the Redeemer statue, Sugarloaf Mountain, Copacabana Beach and its huge Carnival.
São Paulo | Brazil | São Paulo is the biggest city in Brazil and in the Southern Hemisphere, known for business, food and skyscrapers.
Buenos Aires | Argentina | Buenos Aires is the capital of Argentina, known for tango dancing, steak, soccer, and wide avenues.
Lima | Peru | Lima is the capital of Peru, on the Pacific coast, known for its food, especially ceviche.
Bogotá | Colombia | Bogotá is the capital of Colombia, high in the Andes at about 2,600 meters (8,500 feet), known for its Gold Museum.
Mexico City | Mexico | Mexico City is the capital of Mexico, built on top of the old Aztec city of Tenochtitlan, and it's one of the biggest cities in the world.
Cancún | Mexico | Cancún is a beach resort city on Mexico's Caribbean coast, near Maya ruins like Chichén Itzá and Tulum.
Guadalajara | Mexico | Guadalajara is Mexico's second biggest city, known as the home of mariachi music.
Monterrey | Mexico | Monterrey is a big industrial city in northern Mexico, surrounded by mountains.
Havana | Cuba | Havana is the capital of Cuba, known for colorful old buildings, classic 1950s cars and the seaside Malecón.
Cusco | Peru | Cusco was the capital of the Inca Empire, and it's the starting point for trips to Machu Picchu.
La Paz | Bolivia | La Paz is the seat of Bolivia's government and the highest seat of government in the world, at about 3,600 meters (11,800 feet). It has cable car lines as public transport.
Santiago | Chile | Santiago is the capital of Chile, with the snowy Andes right behind the city.
Quito | Ecuador | Quito is the capital of Ecuador, one of the highest capitals in the world, and very close to the equator.
London | United Kingdom | London is the capital of the UK, known for Big Ben, Buckingham Palace, the Tower of London, the London Eye, red buses and the Underground (the Tube).
Paris | France | Paris is the capital of France, known for the Eiffel Tower, the Louvre and the Mona Lisa, Notre-Dame, cafés and fashion. It's called the City of Light.
Rome | Italy | Rome is the capital of Italy, known for the Colosseum, the Roman Forum, the Trevi Fountain, and Vatican City inside it. It's called the Eternal City.
Venice | Italy | Venice is a city in Italy built on more than 100 small islands, with canals instead of roads and gondolas for boats.
Milan | Italy | Milan is Italy's fashion and business capital, known for its huge cathedral and Leonardo da Vinci's painting The Last Supper.
Florence | Italy | Florence is the birthplace of the Renaissance, known for Michelangelo's statue of David and its cathedral dome.
Naples | Italy | Naples is the birthplace of pizza, and it's near the volcano Mount Vesuvius and the ruins of Pompeii.
Barcelona | Spain | Barcelona is known for Gaudí's buildings like La Sagrada Família and Park Güell, beaches, and FC Barcelona.
Madrid | Spain | Madrid is the capital of Spain, known for the Prado art museum, the Royal Palace and Real Madrid.
Seville | Spain | Seville is known for flamenco dancing, orange trees, and its huge cathedral.
Lisbon | Portugal | Lisbon is the capital of Portugal, built on hills, known for its old yellow trams and custard tarts.
Berlin | Germany | Berlin is the capital of Germany, known for the Brandenburg Gate, the remains of the Berlin Wall, and museums.
Munich | Germany | Munich is known for Oktoberfest, beer gardens, BMW, and being close to the Alps.
Hamburg | Germany | Hamburg is Germany's second biggest city and has one of Europe's biggest ports. It's said to have more bridges than Venice and Amsterdam combined.
Amsterdam | Netherlands | Amsterdam is the capital of the Netherlands, known for canals, bicycles, Anne Frank's House and the Van Gogh Museum.
Brussels | Belgium | Brussels is the capital of Belgium and the home of the European Union's main offices. It's known for waffles, chocolate and the Atomium.
Vienna | Austria | Vienna is the capital of Austria, known for classical music, Mozart, palaces and cafés.
Prague | Czechia | Prague is the capital of Czechia, known for Prague Castle, the Charles Bridge and its old astronomical clock.
Budapest | Hungary | Budapest is the capital of Hungary, split by the Danube into Buda and Pest, and known for thermal baths.
Warsaw | Poland | Warsaw is the capital of Poland. Its old town was rebuilt after being destroyed in World War II.
Kraków | Poland | Kraków is known for its beautiful old town, Wawel Castle, and a legendary dragon.
Athens | Greece | Athens is the capital of Greece and one of the oldest cities in the world, known for the Acropolis and Parthenon.
Istanbul | Turkey | Istanbul is Turkey's biggest city and is split between Europe and Asia by the Bosphorus. It's known for the Hagia Sophia and the Grand Bazaar.
Moscow | Russia | Moscow is the capital of Russia, known for Red Square, the Kremlin and St. Basil's Cathedral with its colorful domes.
St. Petersburg | Russia | St. Petersburg is Russia's second biggest city, known for the Hermitage Museum, canals, and white nights in summer when it barely gets dark.
Stockholm | Sweden | Stockholm is the capital of Sweden, built on 14 islands, and known for the Vasa ship museum and the Nobel Prize ceremony.
Oslo | Norway | Oslo is the capital of Norway, where the Nobel Peace Prize is given out.
Copenhagen | Denmark | Copenhagen is the capital of Denmark, known for the Little Mermaid statue, Tivoli Gardens, colorful Nyhavn harbor and bikes.
Helsinki | Finland | Helsinki is the capital of Finland, on the Baltic Sea, known for saunas and design.
Reykjavík | Iceland | Reykjavík is the capital of Iceland and the northernmost capital of a country in the world.
Dublin | Ireland | Dublin is the capital of Ireland, known for Trinity College, the Book of Kells, and St. Patrick's Day parades.
Edinburgh | UK:Scotland | Edinburgh is the capital of Scotland, known for Edinburgh Castle on an old volcano and its big summer arts festival.
Glasgow | UK:Scotland | Glasgow is Scotland's biggest city, known for its music scene and football rivalry between Celtic and Rangers.
Cardiff | UK:Wales | Cardiff is the capital of Wales, known for Cardiff Castle and the Principality Stadium for rugby.
Belfast | UK:Northern Ireland | Belfast is the capital of Northern Ireland, where the Titanic was built.
Manchester | UK:England | Manchester is a big city in England known for football clubs Manchester United and Manchester City, and the Industrial Revolution.
Liverpool | UK:England | Liverpool is known for the Beatles, its port, and Liverpool FC.
Oxford | UK:England | Oxford is home to the University of Oxford, the oldest university in the English-speaking world.
Zurich | Switzerland | Zurich is Switzerland's biggest city, known for banks, its lake, and chocolate shops.
Geneva | Switzerland | Geneva is known for the United Nations offices, the Red Cross, CERN (with the Large Hadron Collider) nearby, and its giant lake fountain.
Dubrovnik | Croatia | Dubrovnik is a walled old city on Croatia's coast, used for filming Game of Thrones.
Monte Carlo | Monaco | Monte Carlo is a part of Monaco known for its casino and the Monaco Grand Prix.
Kyiv | Ukraine | Kyiv is the capital of Ukraine, known for golden-domed churches like St. Sophia's Cathedral.
Tokyo | Japan | Tokyo is the capital of Japan and one of the biggest city areas in the world, known for neon lights, Shibuya Crossing, Tokyo Tower, sushi, anime shops and bullet trains.
Kyoto | Japan | Kyoto was Japan's capital for over 1,000 years, and it's known for old temples, shrines, geishas and the Fushimi Inari gates.
Osaka | Japan | Osaka is Japan's third biggest city, known for street food like takoyaki and Universal Studios Japan.
Hiroshima | Japan | Hiroshima was the first city hit by an atomic bomb, on 6 August 1945. Today it has a Peace Memorial Park.
Seoul | South Korea | Seoul is the capital of South Korea, known for K-pop, palaces like Gyeongbokgung, and huge tech companies.
Busan | South Korea | Busan is South Korea's second biggest city and biggest port, known for beaches and seafood.
Beijing | China | Beijing is the capital of China, known for the Forbidden City, Tiananmen Square, and being close to the Great Wall.
Shanghai | China | Shanghai is China's biggest city, known for its skyline of skyscrapers like the Shanghai Tower, and the riverside Bund.
Hong Kong | China | Hong Kong is a special region of China, known for its skyscrapers, Victoria Harbour, Disneyland, and being a big money center.
Shenzhen | China | Shenzhen grew from a small town to a giant tech city in about 40 years, and lots of electronics are made there.
Xi'an | China | Xi'an was an ancient capital of China and the start of the Silk Road, and it's home to the Terracotta Army.
Chengdu | China | Chengdu is famous for its giant panda breeding center and spicy Sichuan food.
Taipei | Taiwan | Taipei is the capital of Taiwan, known for the Taipei 101 skyscraper and night markets.
Singapore | Singapore | Singapore is a city that is also a country, known for Marina Bay Sands, Gardens by the Bay and hawker food centers.
Bangkok | Thailand | Bangkok is the capital of Thailand, known for temples like Wat Arun, floating markets, tuk-tuks and street food.
Ho Chi Minh City | Vietnam | Ho Chi Minh City, which used to be called Saigon, is Vietnam's biggest city, full of motorbikes and street food.
Hanoi | Vietnam | Hanoi is the capital of Vietnam, known for its Old Quarter, lakes, and pho noodle soup.
Kuala Lumpur | Malaysia | Kuala Lumpur is the capital of Malaysia, known for the Petronas Twin Towers.
Jakarta | Indonesia | Jakarta is the capital of Indonesia and one of the biggest cities in the world. It's sinking, so the government is building a new capital called Nusantara.
Bali | Indonesia | Bali is an island in Indonesia, not a city, known for beaches, rice terraces, temples and surfing.
Manila | Philippines | Manila is the capital of the Philippines, one of the most crowded cities in the world, on Manila Bay.
Mumbai | India | Mumbai is India's biggest city, home of Bollywood movies and the Gateway of India.
Delhi | India | Delhi is a huge city in India that includes New Delhi, the capital. It's known for the Red Fort, Qutub Minar and India Gate.
Agra | India | Agra is the city in India where the Taj Mahal is.
Bengaluru | India | Bengaluru, also called Bangalore, is known as the Silicon Valley of India for its tech companies.
Kolkata | India | Kolkata, once called Calcutta, was the capital of British India until 1911, and it's known for its yellow taxis and sweets.
Jaipur | India | Jaipur is called the Pink City for its pink-painted old buildings and palaces like the Hawa Mahal.
Karachi | Pakistan | Karachi is Pakistan's biggest city and main port, on the Arabian Sea.
Dhaka | Bangladesh | Dhaka is the capital of Bangladesh, one of the most crowded cities on Earth, famous for its colorful cycle rickshaws.
Kathmandu | Nepal | Kathmandu is the capital of Nepal, the starting point for trips to Mount Everest, with many old temples.
Dubai | United Arab Emirates | Dubai is a city in the United Arab Emirates known for the Burj Khalifa (the tallest building in the world), huge malls, and man-made palm-shaped islands.
Abu Dhabi | United Arab Emirates | Abu Dhabi is the capital of the UAE, known for the Sheikh Zayed Grand Mosque and Ferrari World.
Doha | Qatar | Doha is the capital of Qatar, which hosted the 2022 FIFA World Cup.
Mecca | Saudi Arabia | Mecca is the holiest city in Islam, where millions of Muslims go for the Hajj pilgrimage, and only Muslims are allowed to enter.
Jerusalem | Israel | Jerusalem is a holy city for Jews, Christians and Muslims, with the Western Wall, the Church of the Holy Sepulchre and the Dome of the Rock.
Tel Aviv | Israel | Tel Aviv is a beach city in Israel known for its tech companies and white Bauhaus buildings.
Tehran | Iran | Tehran is the capital of Iran, with the Alborz Mountains rising behind it.
Baghdad | Iraq | Baghdad is the capital of Iraq, on the Tigris River. Over 1,000 years ago it was one of the biggest and most important cities in the world.
Cairo | Egypt | Cairo is the capital of Egypt and the biggest city in the Arab world, right next to the Pyramids of Giza.
Alexandria | Egypt | Alexandria was founded by Alexander the Great and was home to the ancient Library of Alexandria and the Lighthouse of Alexandria.
Marrakesh | Morocco | Marrakesh is known for its busy main square, Jemaa el-Fnaa, its souks (markets) and red walls.
Casablanca | Morocco | Casablanca is Morocco's biggest city, known for the Hassan II Mosque, which has one of the tallest minarets in the world.
Lagos | Nigeria | Lagos is Nigeria's biggest city and one of the biggest cities in Africa, known for Afrobeats music and busy markets.
Nairobi | Kenya | Nairobi is the capital of Kenya, and it has a national park inside the city where you can see lions and giraffes with skyscrapers behind them.
Cape Town | South Africa | Cape Town is known for Table Mountain, penguins at Boulders Beach, and Robben Island, where Nelson Mandela was in prison.
Johannesburg | South Africa | Johannesburg is South Africa's biggest city, founded during a gold rush in 1886.
Addis Ababa | Ethiopia | Addis Ababa is the capital of Ethiopia and the home of the African Union.
Timbuktu | Mali | Timbuktu is an old city in Mali that was a famous center of trade and learning, with ancient mud mosques and libraries.
Zanzibar | Tanzania | Zanzibar is an island off Tanzania known for spices, beaches and the old Stone Town.
Accra | Ghana | Accra is the capital of Ghana, on the Gulf of Guinea.
Kinshasa | Democratic Republic of the Congo | Kinshasa is the capital of the DR Congo and the biggest French-speaking city in the world.
Santa Fe | US:New Mexico | Santa Fe is the capital of New Mexico and the oldest state capital city in the US, founded by the Spanish around 1610. It's known for adobe buildings and art.
Key West | US:Florida | Key West is at the end of the Florida Keys, known for its marker of the southernmost point in the Lower 48, its sunsets, and Ernest Hemingway's house full of six-toed cats.
Gettysburg | US:Pennsylvania | Gettysburg is where the biggest battle of the Civil War was fought in 1863, and where Abraham Lincoln gave the Gettysburg Address.
Roswell | US:New Mexico | Roswell is famous for a 1947 crash that some people believe was a UFO, and it has a UFO museum. The US government said it was a secret balloon project.
Anaheim | US:California | Anaheim is home to Disneyland, which opened in 1955.
Hershey | US:Pennsylvania | Hershey is known as Chocolate Town, home of the Hershey chocolate company and the Hersheypark amusement park. Its streetlights look like Hershey's Kisses.
Tombstone | US:Arizona | Tombstone is an old Wild West town famous for the Gunfight at the O.K. Corral in 1881, with Wyatt Earp and Doc Holliday.
Annapolis | US:Maryland | Annapolis is the capital of Maryland, known for the US Naval Academy and sailing on the Chesapeake Bay.
Buffalo | US:New York | Buffalo is known for Buffalo wings, which were invented there, lots of snow, and being close to Niagara Falls.
Savannah | US:Georgia | Savannah is Georgia's oldest city, founded in 1733, known for its leafy squares, Spanish moss and old houses.
Reno | US:Nevada | Reno calls itself the Biggest Little City in the World, and it's known for casinos and being near Lake Tahoe.
Omaha | US:Nebraska | Omaha is Nebraska's biggest city, known for the Henry Doorly Zoo and the College World Series of baseball.
Oklahoma City | US:Oklahoma | Oklahoma City is the capital and biggest city of Oklahoma, and it even has oil wells on the grounds of the state capitol.
Tampa | US:Florida | Tampa is on Florida's Gulf Coast, known for Busch Gardens and the Tampa Bay Buccaneers.
Raleigh | US:North Carolina | Raleigh is the capital of North Carolina and part of the Research Triangle, with Durham and Chapel Hill, known for universities and tech companies.
Fort Worth | US:Texas | Fort Worth calls itself the city where the West begins, known for cattle drives, rodeos and the historic Stockyards.
Juneau | US:Alaska | Juneau is the capital of Alaska, and you can't drive there from the rest of North America. You have to arrive by plane or boat.
Fairbanks | US:Alaska | Fairbanks is one of the best places in the US to see the northern lights, and winters there can drop below minus 40 degrees.
Halifax | CA:Nova Scotia | Halifax is the capital of Nova Scotia, known for its big harbor. Many Titanic victims are buried there, and a huge ship explosion destroyed part of the city in 1917.
Edmonton | CA:Alberta | Edmonton is the capital of Alberta, known for West Edmonton Mall, one of the biggest malls in North America, and the Edmonton Oilers hockey team.
Winnipeg | CA:Manitoba | Winnipeg is the capital of Manitoba, known for very cold winters. The bear who inspired Winnie-the-Pooh was named after the city.
Banff | CA:Alberta | Banff is a mountain town inside Banff National Park, Canada's first national park, near turquoise lakes like Lake Louise and Moraine Lake.
Adelaide | AU:South Australia | Adelaide is the capital of South Australia, known for festivals, nearby wine regions and a city center surrounded by parks.
Darwin | AU:Northern Territory | Darwin is the capital of the Northern Territory, known for saltwater crocodiles, a tropical wet and dry season, and being close to Asia.
Hobart | AU:Tasmania | Hobart is the capital of Tasmania and Australia's second oldest city, known for kunanyi / Mount Wellington and the MONA art museum.
Cairns | AU:Queensland | Cairns is a city in tropical northern Queensland, known as a gateway to the Great Barrier Reef and the Daintree Rainforest.
Alice Springs | AU:Northern Territory | Alice Springs is a town in the middle of Australia's outback, about 450 kilometers (280 miles) by road from Uluru.
Gold Coast | AU:Queensland | Gold Coast is a city in Queensland known for surfing beaches, skyscrapers along the sand, and theme parks.
York | UK:England | York is an old city in northern England with Roman and Viking history, medieval city walls and York Minster, a huge cathedral.
Canterbury | UK:England | Canterbury is known for Canterbury Cathedral, one of the oldest and most famous churches in England, and for Chaucer's Canterbury Tales.
Inverness | UK:Scotland | Inverness is called the capital of the Scottish Highlands, and it's close to Loch Ness.
Marseille | France | Marseille is France's oldest city, founded by Greek sailors about 2,600 years ago, and a big port on the Mediterranean.
Lyon | France | Lyon is one of France's biggest cities, known as a capital of French food and as the place where the Lumière brothers made some of the first movies.
Salzburg | Austria | Salzburg is the birthplace of Mozart and the setting of the movie The Sound of Music.
Pisa | Italy | Pisa is known for its Leaning Tower.
Verona | Italy | Verona is the setting of Shakespeare's Romeo and Juliet, and it has an old Roman arena still used for operas.
Pompeii | Italy | Pompeii is an ancient Roman city near Naples that was buried by Mount Vesuvius in 79 AD. Its ruins show what Roman life was like.
Granada | Spain | Granada is in southern Spain, known for the Alhambra palace and the Sierra Nevada mountains nearby.
Bruges | Belgium | Bruges is a medieval city in Belgium known for canals, old buildings and chocolate shops.
Antwerp | Belgium | Antwerp is known as the diamond capital of the world, where much of the world's rough diamonds are traded, and for its huge port.
Rotterdam | Netherlands | Rotterdam has the biggest port in Europe and is known for modern buildings like the Cube Houses.
Lucerne | Switzerland | Lucerne is known for its wooden Chapel Bridge, first built in the 1300s, and its lake surrounded by mountains.
Bergen | Norway | Bergen is Norway's second biggest city, known for colorful wooden buildings on the Bryggen wharf and lots of rain.
Medellín | Colombia | Medellín is called the City of Eternal Spring because it's mild all year, and it's known for cable cars that carry people up the hillsides.
Valparaíso | Chile | Valparaíso is a port city in Chile known for colorful houses on steep hills, street art and old funicular elevators.
Ushuaia | Argentina | Ushuaia is often called the southernmost city in the world, and many trips to Antarctica start there.
Acapulco | Mexico | Acapulco is a beach city on Mexico's Pacific coast, famous for cliff divers who jump about 35 meters (115 feet) into the sea.
Tijuana | Mexico | Tijuana is just across the border from San Diego, and the crossing between them is one of the busiest border crossings in the world.
Chennai | India | Chennai is a big city on India's southeast coast, known for its long Marina Beach and as a center of Tamil culture and movies.
Goa | India | Goa is India's smallest state, known for beaches and old churches. It was a Portuguese colony until 1961.
Lahore | Pakistan | Lahore is Pakistan's second biggest city and the capital of Punjab province, known for the Badshahi Mosque and its food.
Chiang Mai | Thailand | Chiang Mai is in the mountains of northern Thailand, known for hundreds of Buddhist temples, elephant sanctuaries and its lantern festival.
Phuket | Thailand | Phuket is Thailand's biggest island, known for its beaches.
Siem Reap | Cambodia | Siem Reap is the town next to the temples of Angkor, including Angkor Wat.
Hoi An | Vietnam | Hoi An is an old trading town in central Vietnam known for its colorful lanterns and its Japanese Covered Bridge.
Yogyakarta | Indonesia | Yogyakarta is on the island of Java, known for batik art and as the base for visiting the Borobudur and Prambanan temples.
Guangzhou | China | Guangzhou is a giant city in southern China, known for Cantonese food like dim sum and the huge Canton Fair for trade.
Hangzhou | China | Hangzhou is known for West Lake, Longjing (Dragon Well) tea, and big tech companies.
Guilin | China | Guilin is famous for its tall limestone hills along the Li River, which appear on China's 20 yuan bill.
Lhasa | China | Lhasa is the capital of Tibet, high on the Tibetan Plateau, known for the Potala Palace. It's one of the highest cities in the world.
Harbin | China | Harbin, in northeastern China, is known for its giant Ice and Snow Festival, with whole buildings carved from ice.
Macau | China | Macau is a special region of China that was a Portuguese colony until 1999. It's known for casinos and Portuguese-style buildings.
Sapporo | Japan | Sapporo is the biggest city on Hokkaido, known for its Snow Festival, ramen and the 1972 Winter Olympics.
Nara | Japan | Nara was Japan's first permanent capital, and it's famous for more than 1,000 friendly deer that bow to people for crackers.
Luxor | Egypt | Luxor is built where ancient Thebes stood, near the Valley of the Kings, where Tutankhamun's tomb was found, and the Karnak temples.
Aswan | Egypt | Aswan is on the Nile in southern Egypt, known for the Aswan High Dam, which made Lake Nasser.
Fez | Morocco | Fez has one of the biggest old walled medinas in the world, with tiny streets where donkeys still carry goods, and famous leather tanneries.
Mombasa | Kenya | Mombasa is Kenya's biggest port and one of its oldest cities, on the Indian Ocean, known for Fort Jesus and its beaches.
Durban | South Africa | Durban is a big port city on South Africa's Indian Ocean coast, known for surfing and for its big Indian South African community and curries.
Medina | Saudi Arabia | Medina is the second holiest city in Islam, where the Prophet Muhammad is buried.
Bethlehem | the West Bank | Bethlehem is the town where, according to Christian tradition, Jesus was born. The Church of the Nativity stands there.
Samarkand | Uzbekistan | Samarkand is one of the oldest cities in Central Asia and was a big stop on the Silk Road, known for its blue-tiled Registan square.
Isfahan | Iran | Isfahan is known for its huge Naqsh-e Jahan Square, beautiful blue-tiled mosques and old bridges.
"""

NICKNAMES = r"""
the big apple | New York City | New York City is called the Big Apple.
the windy city | Chicago | Chicago is called the Windy City.
the city of angels | Los Angeles | Los Angeles is called the City of Angels, because "Los Angeles" means "the angels" in Spanish.
the big easy | New Orleans | New Orleans is called the Big Easy.
sin city | Las Vegas | Las Vegas is often called Sin City.
the mile high city | Denver | Denver is called the Mile High City, because it's about one mile above sea level.
the motor city | Detroit | Detroit is called the Motor City, or Motown, because of its car factories.
music city | Nashville | Nashville is called Music City.
the city of light | Paris | Paris is called the City of Light.
the eternal city | Rome | Rome is called the Eternal City.
the big smoke | London | London is sometimes called the Big Smoke, from the days when coal smoke filled its air.
the pink city | Jaipur | Jaipur, in India, is called the Pink City.
the emerald city | Seattle | Seattle is nicknamed the Emerald City because of its green forests.
the city of brotherly love | Philadelphia | Philadelphia is called the City of Brotherly Love, which is what its Greek name means.
the steel city | Pittsburgh | Pittsburgh is called the Steel City because it used to make huge amounts of steel.
the magic city | Miami | Miami is called the Magic City because it grew so fast.
beantown | Boston | Boston is nicknamed Beantown, from the baked beans it was famous for.
the city that never sleeps | New York City | New York City is called the city that never sleeps.
"""

US_STATE_Q = {"New York": "new york state", "Washington": "washington state", "Georgia": "georgia"}


def main():
    f = "gen_cities.txt"
    w = Writer([f])
    caps = {ascii_fold(c) for _, c, _ in OLD.COUNTRIES}
    caps |= {"washington, d.c."}
    for line in TABLE.strip().splitlines():
        city, where, known = [x.strip() for x in line.split("|")]
        q = ascii_fold(city).replace(".", "")
        rng = rng_for(city)
        if where.startswith(("US:", "CA:", "AU:", "UK:")):
            kind, region = where.split(":")
            country = {"US": "the United States", "CA": "Canada", "AU": "Australia", "UK": "the United Kingdom"}[kind]
            word = {"US": "state", "CA": "province", "AU": "state", "UK": "country"}[kind]
            if kind == "UK":
                ans = f"{city} is in {region}, which is part of the United Kingdom."
            else:
                ans = f"{city} is in {region}, in {country}."
            rest = [f"where is {q}", f"{q} is in what {word}", f"which {word} is {q} in"]
            rng.shuffle(rest)
            w.add(f, "geo.city.where", [f"what {word} is {q} in"] + rest, ans, limit=4)
            if kind != "UK":
                rest = [f"is {q} in {'america' if kind == 'US' else country.lower()}", f"{q} is in what country"]
                w.add(f, "geo.city.where", [f"what country is {q} in"] + rest, f"{city} is in {country}, in the {word} of {region}.", limit=3)
        elif ascii_fold(city) not in caps:
            the = where if where in ("Singapore",) else where
            disp = {"Democratic Republic of the Congo": "the Democratic Republic of the Congo",
                    "United Arab Emirates": "the United Arab Emirates", "United Kingdom": "the United Kingdom",
                    "Netherlands": "the Netherlands", "Philippines": "the Philippines"}.get(where, the)
            rest = [f"where is {q}", f"{q} is in what country", f"which country is {q} in"]
            rng.shuffle(rest)
            ans = f"{city} is in {disp}."
            if city == "Hong Kong":
                ans = "Hong Kong is a special administrative region of China. It was a British colony until 1997."
            w.add(f, "geo.city.where", [f"what country is {q} in"] + rest, ans, limit=4)
        if known:
            rest = [f"what is {q} famous for", f"why is {q} famous", f"tell me about the city of {q}"]
            rng.shuffle(rest)
            w.add(f, "geo.city.knownfor", [f"what is {q} known for"] + rest, known, limit=4)
    for line in NICKNAMES.strip().splitlines():
        nick, city, ans = [x.strip() for x in line.split("|")]
        w.add(f, "geo.city.nickname", [f"what city is called {nick}", f"which city is {nick}",
                                       f"what city is known as {nick}", f"{nick} nickname city"], ans, limit=4)
    w.save("""Generated by tools/knowledge/gen/geo_cities.py. Do not edit by hand.
Data: hand-written table of world cities.""")
    for d in w.dropped:
        print("  dropped:", d)


if __name__ == "__main__":
    main()
