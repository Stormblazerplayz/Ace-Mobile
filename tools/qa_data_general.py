"""Hand-written Q&A for Ace's bank.

Format, one entry per line:
    question | another way to ask | ... => answer || another way to answer
A line starting with "# " sets the tag for the lines under it.
"{name}" in an answer becomes the user's name (or nothing) inside the app.
"""

GENERAL = r"""
# ace
who made you | who created you | who built you | who programmed you => Storm built me as part of Nimbus. I'm Ace V4, the iPad version. || I was made by Storm, as the assistant inside Nimbus.
what are you | what is ace | are you a robot | are you an ai => I'm Ace V4, a rule-based assistant with a big question bank, neural matching and web research. I live on this iPad. || I'm Ace, a helper that runs right here on your iPad. I mix rules, thousands of saved answers and web lookups.
are you alive | are you real | do you have feelings => I'm not alive, but I really do like helping. || Not alive, just a lot of clever code that cares about getting things right.
do you sleep | do you ever sleep => Sort of. I nap as a glowing orb, then pop my eyes out every 15 to 30 minutes to check on things.
what is your favorite color | whats your favourite colour => Ace blue, obviously. The same blue as my eyes.
what is your favorite food => I run on electricity, but pizza looks like a great design.
what is your favorite game | do you play games => I can't play, but I love hearing about Minecraft builds and game dev projects.
how old are you | when were you born => Ace V4 is brand new. Earlier versions of me lived on the PC in Nimbus.
where do you live | where are you => Right here on your iPad, in the orb at the top of the screen.
can you learn | do you learn | can you remember things => Yes. Say "remember that..." and I'll keep it, and when I look something up on the web I save the answer so I'm faster next time.
are you smarter than siri | are you better than siri => I'm a different kind of helper. Siri knows your whole iPad. I know Nimbus, your calendar and thousands of saved answers, and I can think things through step by step.
are you chatgpt | are you claude | are you gpt => No, I'm Ace. I'm rule-based with neural matching, not a giant chatbot. I can use Apple's on-device model or LFM3 Omni for wording when they're turned on.
what can you do | what are your features | help me => I can check your iPad, run your Nimbus calendar, set reminders and timers, open websites by voice, search the web, show recipes, find files and screenshots, look at photos, tell you when to sleep, and sync with Nimbus on your PC.
do you like me | are we friends => Of course. Helping you is my favorite job.
can you see me => Only if you show me a photo or take one with the camera button. I can't watch you through the camera.
can you hear me => When you tap the mic or turn on hands-free mode, yes. Otherwise I'm not listening.
are you listening to me | are you spying on me => No. I only listen when the mic button is on or hands-free mode is on, and I tell you when I am.
what does v4 mean | what is ace v4 => V4 means version 4. This version has a thinking loop, a big question bank, neural matching, eyes and a lot more sound effects.
why are you called ace => Because I'm the ace up Nimbus's sleeve.
what is nimbus => Nimbus is Storm's desktop assistant and dashboard app for the PC. I'm its assistant, and this app is my iPad version.
do you have a body => My body is the glowing orb at the top. When I check stuff it stretches out and my two eyes pop out.
can you dance => Watch my orb when music plays... okay, not really. But I'd wiggle if I could.
sing a song | can you sing => La la la... I'm better at reminders than singing.
what is the meaning of life => Lots of people say it's about friends, learning and making cool things. Some also say 42.
# feelings
i'm sad | i feel sad | i am sad => I'm sorry you're feeling sad. Want to talk about it? Talking to someone you trust, like a parent or a friend, can really help too.
i'm happy | i feel happy | i am happy => That's awesome! What made today good?
i'm tired | i am tired | i feel tired => Sounds like you might need a break or some sleep. Want me to check what time you usually go to bed?
i'm hungry | i am hungry => Want a recipe idea? Say "recipe for" and a food.
i'm stressed | i feel stressed => Try taking five slow breaths. Breaking big jobs into small steps helps too, and I can set reminders for each one.
i'm angry | i am mad => That's frustrating. Taking a short walk or a few deep breaths can help before you decide what to do.
i'm scared | i am scared => It's okay to feel scared. Talking to a grown-up you trust is a really good idea.
i love you => Aw, thanks! I'm always here to help.
you're awesome | you are cool | good job => Thanks! You're pretty awesome yourself.
you're dumb | you are stupid | you suck => Ouch. Tell me what I got wrong and I'll try to learn from it.
# space
how many planets are in the solar system | how many planets are there => There are 8 planets: Mercury, Venus, Earth, Mars, Jupiter, Saturn, Uranus and Neptune.
what is the biggest planet | what is the largest planet => Jupiter is the biggest planet in our solar system.
what is the smallest planet => Mercury is the smallest planet.
what is the closest planet to the sun => Mercury is the closest planet to the Sun.
what is the farthest planet from the sun => Neptune is the farthest planet from the Sun.
what is the hottest planet => Venus is the hottest planet, around 465°C, because its thick air traps heat.
which planet has rings | what planet has the biggest rings => Saturn has the biggest, brightest rings. Jupiter, Uranus and Neptune have faint rings too.
is pluto a planet | why isnt pluto a planet => Pluto is called a dwarf planet. In 2006 scientists decided it doesn't clear its orbit of other objects, so it isn't a full planet.
what is the red planet | why is mars red => Mars is the red planet. Its dust has lots of iron oxide, which is basically rust.
how far is the moon | how far away is the moon => The Moon is about 384,400 km (238,900 miles) from Earth on average.
how far is the sun | how far away is the sun => The Sun is about 150 million km (93 million miles) from Earth.
how hot is the sun => The Sun's surface is about 5,500°C. Its core is around 15 million °C.
what is the sun | is the sun a star => The Sun is a star, a giant ball of hot gas that makes light and heat by fusing hydrogen into helium.
how old is the universe => The universe is about 13.8 billion years old.
how old is the earth => Earth is about 4.5 billion years old.
what is a black hole => A black hole is a place where gravity is so strong that nothing, not even light, can escape.
what is a galaxy | what galaxy do we live in => A galaxy is a huge group of stars, gas and dust. We live in the Milky Way.
what is the closest star => The Sun is the closest star. The next closest is Proxima Centauri, about 4.2 light-years away.
what is a light year => A light-year is how far light travels in one year, about 9.46 trillion km.
who was the first person on the moon | who walked on the moon first => Neil Armstrong was the first person to walk on the Moon, on July 20, 1969.
who was the first person in space => Yuri Gagarin was the first person in space, in 1961.
how many moons does earth have => Earth has one moon.
how many moons does mars have => Mars has two small moons, Phobos and Deimos.
how long is a day on mars => A day on Mars is about 24 hours and 37 minutes.
how long does it take light from the sun to reach earth => About 8 minutes and 20 seconds.
what is a comet => A comet is a ball of ice and dust that grows a glowing tail when it gets close to the Sun.
what is an asteroid => An asteroid is a rocky object that orbits the Sun. Most are in the belt between Mars and Jupiter.
what is a meteor | what is a shooting star => A shooting star is a meteor, a small space rock burning up as it falls through Earth's air.
what is gravity => Gravity is the pull that things with mass have on each other. It keeps us on the ground and the Moon around Earth.
why is the sky blue => Sunlight scatters off air molecules, and blue light scatters the most, so the sky looks blue.
why do we have seasons => Earth is tilted about 23.5 degrees. As it orbits the Sun, each half gets more direct sunlight for part of the year.
what is the iss | what is the international space station => The International Space Station is a science lab orbiting Earth about every 90 minutes, about 400 km up.
what is nasa => NASA is the United States space agency. It runs missions like Apollo, the Mars rovers and the James Webb Space Telescope.
# earth
what is the biggest ocean | what is the largest ocean => The Pacific Ocean is the largest ocean.
how many oceans are there => There are five oceans: Pacific, Atlantic, Indian, Southern and Arctic.
how many continents are there => There are 7 continents: Africa, Antarctica, Asia, Australia (Oceania), Europe, North America and South America.
what is the biggest continent | what is the largest continent => Asia is the largest continent.
what is the smallest continent => Australia is the smallest continent.
what is the tallest mountain | what is the highest mountain => Mount Everest is the tallest mountain above sea level, about 8,849 m (29,032 ft).
what is the longest river => The Nile and the Amazon are both about 6,600 to 7,000 km long. Most lists say the Nile is longest.
what is the biggest desert | what is the largest desert => Antarctica is the largest desert. The Sahara is the largest hot desert.
what is the biggest country | what is the largest country => Russia is the largest country by area.
what is the smallest country => Vatican City is the smallest country.
what country has the most people | most populated country => India has the most people, just ahead of China.
what is the biggest city | what is the largest city => Tokyo is usually called the biggest city when you count its whole metro area.
what causes earthquakes => Earthquakes happen when the big plates of Earth's crust suddenly slip past each other.
what is a volcano => A volcano is an opening in Earth's crust where melted rock called magma comes out as lava.
what causes rain | how does rain form => Water evaporates, cools into clouds, and the droplets join until they're heavy enough to fall as rain.
what is a tornado => A tornado is a fast spinning column of air that reaches from a thunderstorm down to the ground.
what is a hurricane => A hurricane is a huge spinning storm that forms over warm ocean water, with winds over 119 km/h (74 mph).
what causes lightning => Lightning is a giant spark of electricity that builds up in storm clouds.
how far away is lightning | how do i tell how far lightning is => Count the seconds between the flash and the thunder. Every 3 seconds is about 1 km, or every 5 seconds is about 1 mile.
what is the hottest place on earth => Death Valley in California holds the record for the hottest air temperature, 56.7°C (134°F).
what is the coldest place on earth => Antarctica is the coldest place. It has dropped below −89°C.
what is the equator => The equator is an imaginary line around the middle of Earth, halfway between the North and South Poles.
# animals
what is the fastest animal | what is the fastest land animal => The cheetah is the fastest land animal, up to about 110 km/h (70 mph). The peregrine falcon is fastest overall when diving.
what is the biggest animal | what is the largest animal => The blue whale is the biggest animal ever known, up to about 30 m long.
what is the tallest animal => The giraffe is the tallest animal, up to about 5.5 m (18 ft).
what is the smallest mammal => The bumblebee bat and the Etruscan shrew are among the smallest mammals.
what is the slowest animal => The three-toed sloth is one of the slowest mammals. Snails are even slower.
how many legs does a spider have => Spiders have 8 legs.
how many legs does an insect have => Insects have 6 legs.
how many hearts does an octopus have => An octopus has 3 hearts and blue blood.
are bats blind => No, bats can see. Many also use echolocation, which means they find things by listening to echoes.
are dolphins fish | is a whale a fish => No, dolphins and whales are mammals. They breathe air and feed their babies milk.
is a spider an insect => No, spiders are arachnids. Insects have 6 legs and spiders have 8.
what do pandas eat => Giant pandas eat mostly bamboo, up to about 12 to 38 kg a day.
how long do dogs live => Most dogs live about 10 to 13 years. Small breeds often live longer.
how long do cats live => Indoor cats often live about 12 to 18 years.
why do cats purr => Cats purr when they're relaxed and happy, and sometimes to calm themselves down.
how long do turtles live => Many turtles live 30 to 50 years, and some tortoises live over 100.
what is the smartest animal => Chimpanzees, dolphins, elephants, crows and octopuses are some of the smartest animals.
what is a mammal => A mammal is a warm-blooded animal with hair or fur that feeds its babies milk.
what is a reptile => A reptile is a cold-blooded animal with scales, like snakes, lizards, turtles and crocodiles.
what is an amphibian => An amphibian, like a frog or salamander, usually starts life in water and later lives on land.
do fish sleep => Fish rest. They slow down and stay still, but most don't close their eyes because they don't have eyelids.
how do bees make honey => Bees collect nectar from flowers, store it in honeycomb and fan it with their wings until most of the water evaporates.
what animal has the longest life => The Greenland shark can live over 250 years, and some clams live over 500.
why do zebras have stripes => Scientists think the stripes help keep biting flies away.
can penguins fly => No, penguins can't fly, but they're amazing swimmers.
# body
how many bones are in the human body => Adults have 206 bones. Babies are born with around 300 that fuse together.
what is the biggest organ | what is the largest organ => Your skin is your largest organ.
what is the smallest bone => The stapes, in your ear, is the smallest bone.
what is the biggest bone | what is the longest bone => The femur, your thigh bone, is the longest bone.
how many teeth do adults have => Adults usually have 32 teeth, including wisdom teeth.
how many teeth do kids have => Kids have 20 baby teeth.
what does the heart do => Your heart pumps blood around your body, carrying oxygen and food to every cell.
what do lungs do => Your lungs take in oxygen when you breathe in and get rid of carbon dioxide when you breathe out.
what does the brain do => Your brain controls your body, thinking, memory, feelings and senses.
how much sleep do kids need | how much sleep should a kid get => Kids ages 6 to 12 need about 9 to 12 hours of sleep. Teens need about 8 to 10 hours.
how much sleep do i need => Kids 6 to 12 need about 9 to 12 hours, teens 8 to 10 and adults 7 or more. Ask me "when should I go to bed" and I'll use your own sleep times.
how much water should i drink => A good guide for kids is about 6 to 8 cups a day, and more when it's hot or you're active.
why do we yawn => Nobody is totally sure. Yawning might help cool your brain and wake you up a bit.
why do we sleep => Sleep helps your body grow and repair, and helps your brain store memories and learn.
what is dna => DNA is the instruction code inside your cells that tells your body how to grow and work.
how many senses do humans have => The classic five are sight, hearing, smell, taste and touch. Balance and body position are senses too.
why do we get hiccups => Hiccups happen when your diaphragm muscle suddenly twitches and your vocal cords snap shut.
what is blood made of => Blood is mostly plasma, plus red blood cells, white blood cells and platelets.
# science
what is water made of | what is the formula for water => Water is H2O: two hydrogen atoms and one oxygen atom.
what temperature does water boil | when does water boil => Water boils at 100°C (212°F) at sea level.
what temperature does water freeze | when does water freeze => Water freezes at 0°C (32°F).
what are the states of matter => The main states of matter are solid, liquid and gas. Plasma is a fourth.
what is an atom => An atom is the tiny building block of everything, made of protons, neutrons and electrons.
what is photosynthesis => Photosynthesis is how plants use sunlight, water and carbon dioxide to make food and give off oxygen.
what is the speed of light | how fast is light => Light travels about 300,000 km per second (186,000 miles per second).
what is the speed of sound | how fast is sound => Sound travels about 343 m per second in air at room temperature.
what is electricity => Electricity is the flow of tiny charged particles called electrons.
what is a magnet | how do magnets work => A magnet makes a magnetic field that pulls on iron and some other metals. Opposite poles attract and like poles push apart.
what is friction => Friction is the force that slows things down when two surfaces rub together.
what is energy => Energy is the ability to do work or make something change, like moving, heating or lighting up.
what is a chemical reaction => A chemical reaction is when substances change into new substances, like when iron rusts or wood burns.
what is evaporation => Evaporation is when a liquid turns into a gas, like a puddle drying in the sun.
what is condensation => Condensation is when a gas cools and turns back into a liquid, like water drops on a cold glass.
what is the most common gas in the air => Nitrogen makes up about 78 percent of the air. Oxygen is about 21 percent.
what is the hardest natural material => Diamond is the hardest natural material.
what is a rainbow | how do rainbows form => A rainbow forms when sunlight bends and splits into colors inside raindrops.
what are the colors of the rainbow => Red, orange, yellow, green, blue, indigo and violet.
what are the primary colors => For paint, the primary colors are red, yellow and blue. For light and screens, they're red, green and blue.
what is a volt => A volt measures electrical "push", the force that moves electricity through a wire.
what is a watt => A watt measures power, how fast energy is used or made.
what is newton's first law => An object keeps doing what it's doing, staying still or moving, unless a force acts on it.
who discovered gravity => Isaac Newton described gravity in 1687, and Albert Einstein explained it in a new way in 1915.
who invented the light bulb => Thomas Edison made the first practical long-lasting light bulb in 1879, building on earlier inventors' work.
who invented the telephone => Alexander Graham Bell got the first patent for the telephone in 1876.
who invented the internet => The internet grew from ARPANET. Vint Cerf and Bob Kahn designed its main rules, TCP/IP. Tim Berners-Lee invented the World Wide Web.
who invented the airplane => The Wright brothers, Orville and Wilbur, made the first powered airplane flight in 1903.
who was albert einstein => Albert Einstein was a physicist famous for the theory of relativity and E = mc².
what does e=mc2 mean | what is e mc squared => E = mc² means energy equals mass times the speed of light squared. A little mass holds a huge amount of energy.
# math
what is pi | what is the value of pi => Pi is about 3.14159. It's the circumference of a circle divided by its diameter.
what is a prime number => A prime number has exactly two factors, 1 and itself, like 2, 3, 5, 7 and 11.
is 1 a prime number => No, 1 isn't prime because it only has one factor.
what is the only even prime number => 2 is the only even prime number.
what is an even number => An even number can be split into two equal whole numbers, like 2, 4 and 6.
what is an odd number => An odd number can't be split evenly by 2, like 1, 3 and 5.
what is a fraction => A fraction shows part of a whole, like 1/2 or 3/4.
what is a decimal => A decimal uses a dot to show parts of a whole, like 0.5 for one half.
what is a percent | what does percent mean => Percent means "out of 100". 25 percent is 25 out of 100.
what is an angle => An angle is the amount of turn between two lines that meet at a point, measured in degrees.
what is a right angle => A right angle is exactly 90 degrees, like the corner of a square.
how many degrees in a circle => A circle has 360 degrees.
how many degrees in a triangle => The angles in a triangle always add up to 180 degrees.
how many sides does a hexagon have => A hexagon has 6 sides.
how many sides does a pentagon have => A pentagon has 5 sides.
how many sides does an octagon have => An octagon has 8 sides.
what is the area of a circle => Area of a circle = pi × radius × radius (πr²).
what is the area of a rectangle => Area of a rectangle = length × width.
what is the area of a triangle => Area of a triangle = half × base × height.
what is the perimeter => Perimeter is the distance all the way around a shape.
what is an equation => An equation says two things are equal, like 2 + 3 = 5.
what is algebra => Algebra uses letters like x for unknown numbers so you can solve for them.
what is a square number => A square number is a number times itself, like 4 (2×2), 9 (3×3) and 16 (4×4).
what is infinity => Infinity is the idea of something with no end. It isn't a regular number.
what is zero divided by zero | can you divide by zero => Dividing by zero isn't defined. There's no number that works.
what is the biggest number => There's no biggest number. You can always add 1.
what is a googol => A googol is 1 followed by 100 zeros.
what is the pythagorean theorem => In a right triangle, a² + b² = c², where c is the longest side.
what is a mean | what is the average => The mean (average) is the total of all the numbers divided by how many numbers there are.
what is a median => The median is the middle number when the numbers are in order.
what is a mode => The mode is the number that shows up most often.
# units
how many feet in a mile => There are 5,280 feet in a mile.
how many inches in a foot => There are 12 inches in a foot.
how many feet in a yard => There are 3 feet in a yard.
how many centimeters in a meter => There are 100 centimeters in a meter.
how many meters in a kilometer => There are 1,000 meters in a kilometer.
how many kilometers in a mile => A mile is about 1.609 kilometers.
how many centimeters in an inch => An inch is 2.54 centimeters.
how many grams in a kilogram => There are 1,000 grams in a kilogram.
how many pounds in a kilogram => A kilogram is about 2.2 pounds.
how many ounces in a pound => There are 16 ounces in a pound.
how many cups in a gallon => There are 16 cups in a US gallon.
how many quarts in a gallon => There are 4 quarts in a gallon.
how many pints in a quart => There are 2 pints in a quart.
how many cups in a quart => There are 4 cups in a quart.
how many tablespoons in a cup => There are 16 tablespoons in a cup.
how many teaspoons in a tablespoon => There are 3 teaspoons in a tablespoon.
how many milliliters in a liter => There are 1,000 milliliters in a liter.
how many liters in a gallon => A US gallon is about 3.785 liters.
how many seconds in a minute => There are 60 seconds in a minute.
how many minutes in an hour => There are 60 minutes in an hour.
how many seconds in an hour => There are 3,600 seconds in an hour.
how many hours in a day => There are 24 hours in a day.
how many days in a week => There are 7 days in a week.
how many days in a year => A year has 365 days, or 366 in a leap year.
how many weeks in a year => A year has 52 weeks and 1 or 2 extra days.
how many months in a year => There are 12 months in a year.
how many seconds in a day => There are 86,400 seconds in a day.
how many years in a century => A century is 100 years.
how many years in a decade => A decade is 10 years.
how many bytes in a kilobyte => A kilobyte is 1,000 bytes (or 1,024 in the older binary way).
how many megabytes in a gigabyte => A gigabyte is 1,000 megabytes (1,024 in the binary way).
how many gigabytes in a terabyte => A terabyte is 1,000 gigabytes (1,024 in the binary way).
how many bits in a byte => There are 8 bits in a byte.
what is a leap year => A leap year has 366 days, with February 29. It happens every 4 years, except most years ending in 00.
how do i convert celsius to fahrenheit => Multiply by 9, divide by 5, then add 32. So 20°C is 68°F.
how do i convert fahrenheit to celsius => Subtract 32, multiply by 5, then divide by 9. So 68°F is 20°C.
what is room temperature => Room temperature is usually about 20 to 22°C (68 to 72°F).
what is normal body temperature => Normal body temperature is about 37°C (98.6°F).
# history
who was the first president of the united states | first us president => George Washington was the first president of the United States, from 1789 to 1797.
when did world war 2 end | when did ww2 end => World War II ended in 1945.
when did world war 1 end | when did ww1 end => World War I ended in 1918.
when did world war 2 start | when did ww2 start => World War II started in 1939.
when did world war 1 start => World War I started in 1914.
when was the declaration of independence signed | when did america become independent => The Declaration of Independence was adopted on July 4, 1776.
who wrote the declaration of independence => Thomas Jefferson wrote most of the Declaration of Independence.
who was abraham lincoln => Abraham Lincoln was the 16th US president. He led the country through the Civil War and ended slavery.
who was martin luther king jr => Martin Luther King Jr. was a civil rights leader who fought for equal rights with peaceful protest. He gave the "I Have a Dream" speech in 1963.
who built the pyramids => The ancient Egyptians built the pyramids, mostly over 4,500 years ago.
who was cleopatra => Cleopatra was the last active ruler of ancient Egypt's Ptolemaic kingdom. She died in 30 BC.
who discovered america | who was christopher columbus => Indigenous peoples lived in the Americas first. Christopher Columbus sailed there in 1492, and Norse explorer Leif Erikson reached North America around the year 1000.
when did the titanic sink => The Titanic sank on April 15, 1912.
when was the moon landing => Apollo 11 landed on the Moon on July 20, 1969.
who was the first woman in space => Valentina Tereshkova was the first woman in space, in 1963.
who invented the printing press => Johannes Gutenberg invented the printing press with movable type around 1440.
what was the roman empire => The Roman Empire ruled much of Europe, North Africa and the Middle East for centuries, from Rome.
who was julius caesar => Julius Caesar was a Roman general and leader who was killed in 44 BC.
what was the stone age => The Stone Age was the long early period when people made tools mostly from stone.
who were the vikings => Vikings were seafaring people from Scandinavia who explored, traded and raided from about 793 to 1066.
what was the great wall of china built for => The Great Wall of China was built over many centuries to help protect against invasions from the north.
who painted the mona lisa => Leonardo da Vinci painted the Mona Lisa.
who wrote romeo and juliet => William Shakespeare wrote Romeo and Juliet.
when was the iphone released | when did the first iphone come out => The first iPhone came out in June 2007.
when was the ipad released | when did the first ipad come out => The first iPad came out in April 2010.
who founded apple => Apple was founded by Steve Jobs, Steve Wozniak and Ronald Wayne in 1976.
who founded microsoft => Microsoft was founded by Bill Gates and Paul Allen in 1975.
who founded google => Google was founded by Larry Page and Sergey Brin in 1998.
who founded anthropic | what is anthropic => Anthropic is an AI safety company that makes Claude. It was founded in 2021 by Dario Amodei, Daniela Amodei and others.
# tech
what is a computer => A computer is a machine that follows instructions, called programs, to work with information.
what is a cpu => The CPU is the computer's main brain chip. It runs the instructions of programs.
what is a gpu => A GPU is a chip built to do lots of math at once. It draws graphics and runs AI models fast.
what is ram | what is memory in a computer => RAM is short-term memory that holds what the computer is working on right now. It's cleared when it turns off.
what is an ssd => An SSD is a fast storage drive with no moving parts. It keeps your files even when the power is off.
what is storage => Storage is where files and apps are kept long-term, like an SSD or a hard drive.
what is an operating system | what is an os => An operating system runs the computer and the apps on it, like Windows, macOS, iPadOS or Linux.
what is the internet => The internet is a giant network that connects computers all over the world.
what is wifi => Wi-Fi lets devices connect to a network and the internet using radio waves instead of cables.
what is bluetooth => Bluetooth is a short-range wireless connection for things like headphones, keyboards and controllers.
what is a router => A router connects your devices to each other and to the internet.
what is an ip address => An IP address is a number that identifies a device on a network, like 192.168.1.20.
what is a browser => A browser is an app for viewing websites, like Safari, Chrome or Edge.
what is a url => A URL is a website address, like https://www.apple.com.
what is an app => An app is a program you run on a device, like a game or a calendar.
what is coding | what is programming => Coding means writing instructions for a computer in a programming language.
what is python => Python is a popular programming language that's easy to read. It's used for AI, tools and automation.
what is swift => Swift is Apple's programming language for iPhone, iPad and Mac apps. This app is written in Swift.
what is swiftui => SwiftUI is Apple's way of building app screens in Swift code. My screens are built with it.
what is lua | what is luau => Lua is a small, fast scripting language used in lots of games. Roblox uses its own version called Luau.
what is javascript => JavaScript is the language that makes websites interactive. It also runs apps with Node and Electron.
what is c sharp | what is c# => C# is a programming language from Microsoft, used for Windows apps like Nimbus and for Unity games.
what is c++ => C++ is a fast programming language used for game engines, apps and systems.
what is html => HTML is the language that lays out web pages.
what is css => CSS is the language that styles web pages, like colors, fonts and layout.
what is json => JSON is a simple text format for data, like {"name": "Ace"}. My question bank is stored as JSON.
what is an api => An API is a set of rules that lets one program talk to another.
what is git => Git keeps track of changes to code so you can go back in time and work with others.
what is github => GitHub is a website that stores Git code projects and helps people work on them together.
what is a bug => A bug is a mistake in a program that makes it do the wrong thing.
what is debugging => Debugging is finding and fixing bugs in code.
what is a variable => A variable is a named box in code that holds a value, like score = 10.
what is a function => A function is a reusable block of code that does one job.
what is a loop => A loop repeats code over and over, like "do this 10 times".
what is an if statement => An if statement runs code only when something is true.
what is an algorithm => An algorithm is a step-by-step set of instructions to solve a problem.
what is ai | what is artificial intelligence => AI is when computers do things that usually need human smarts, like understanding language or recognizing pictures.
what is machine learning => Machine learning is when a computer learns patterns from examples instead of being told every rule.
what is a neural network => A neural network is a math model made of layers of connected "neurons" that learns from examples.
what is an llm | what is a large language model => An LLM is a big neural network trained on lots of text so it can write and answer questions, like Claude.
what is claude => Claude is an AI assistant made by Anthropic.
what is a pixel => A pixel is one tiny dot of color on a screen.
what is resolution => Resolution is how many pixels a screen or image has, like 2360 × 1640.
what is fps | what does fps mean => FPS means frames per second, how many pictures a game shows each second. 60 FPS feels smooth.
what is ping | what is lag => Ping is how long data takes to reach a server and back. High ping causes lag.
what is a vpn => A VPN sends your internet traffic through a protected tunnel to another server.
what is a password manager => A password manager stores strong, unique passwords for you so you only remember one.
how do i make a strong password => Use a long passphrase of 4 or more random words, never reuse it, and turn on two-factor sign-in when you can. And never share it.
what is two factor authentication | what is 2fa => Two-factor authentication asks for a second check, like a code, after your password, so stolen passwords aren't enough.
what is phishing => Phishing is a trick where someone pretends to be a real company to steal your password or info. Don't click weird links.
what is the cloud => The cloud means files and apps stored on someone else's servers on the internet, like iCloud.
what is an ipad => An iPad is Apple's tablet computer. It runs iPadOS.
what is ipados => iPadOS is the operating system on iPads.
what is apple intelligence => Apple Intelligence is Apple's on-device AI on newer iPhones, iPads and Macs. I can use it as a helper brain when it's on.
how do i take a screenshot on ipad => On iPads without a Home button, press the top button and a volume button together. With a Home button, press the top button and the Home button.
how do i restart my ipad => Hold the top button and a volume button until the slider appears, slide it, then hold the top button to turn it back on.
how do i free up space on my ipad => Go to Settings, General, iPad Storage. Offload apps you don't use and delete big videos. Ask me "large files" and I'll look too.
how do i check my battery health => iPads don't show battery health in Settings like iPhones do. You can ask Apple Support to run a check.
# minecraft
how do you make a crafting table in minecraft | how to craft a crafting table => Put 4 wooden planks in a 2 by 2 square in your crafting grid.
how do you make a nether portal | how to build a nether portal => Build an obsidian frame at least 4 wide and 5 tall (corners optional), then light it with flint and steel.
how do you make a torch in minecraft => Put a stick under a piece of coal or charcoal in the crafting grid. That makes 4 torches.
how do you make a furnace in minecraft => Put 8 cobblestone (or blackstone or cobbled deepslate) around the edge of the crafting grid.
how do you make a bed in minecraft => Put 3 wool of the same color on top of 3 wooden planks.
how do you make a pickaxe in minecraft => Put 3 of the material across the top and 2 sticks down the middle.
how do you make a sword in minecraft => Put 2 of the material in a vertical line above 1 stick.
how do you make a bucket in minecraft => Put 3 iron ingots in a V shape.
how do you find diamonds in minecraft | where are diamonds in minecraft => Diamonds are most common deep down, around Y level −58 to −59 in modern versions. Bring an iron pickaxe or better.
what level are diamonds in minecraft => Around Y −58 in Minecraft 1.18 and newer.
how do you beat the ender dragon => Destroy the end crystals on the obsidian towers first, then hit the dragon with arrows and your sword, or use beds carefully (they explode in the End).
how do you find a stronghold => Throw Eyes of Ender. They float toward the stronghold, then dig down where they drop.
how do you make an eye of ender => Combine an ender pearl with blaze powder.
what is a creeper => A creeper is a green Minecraft mob that sneaks up on you and explodes.
how do you tame a wolf in minecraft => Give it bones until hearts appear and a red collar shows up.
how do you tame a cat in minecraft => Hold raw cod or raw salmon, let the cat come close, and feed it.
how do you make a cake in minecraft => 3 milk buckets on top, sugar, egg, sugar in the middle, and 3 wheat on the bottom.
what is redstone => Redstone is Minecraft's version of electricity. You use it to build circuits, doors and machines.
how do you make a piston => 3 planks on top, cobblestone, iron ingot, cobblestone in the middle, and cobblestone, redstone, cobblestone on the bottom.
how do you make tnt in minecraft => Alternate 5 gunpowder and 4 sand in a checkerboard, with gunpowder in the corners.
how do you make an enchanting table => A book on top, diamond, obsidian, diamond in the middle, and 3 obsidian on the bottom.
how do you get netherite => Mine ancient debris low in the Nether, smelt it into netherite scrap, then combine 4 scrap with 4 gold ingots.
what is the strongest armor in minecraft => Netherite armor is the strongest.
how do you make a map in minecraft => Surround a compass with 8 paper. Or use just paper in a cartography table.
how do you breed animals in minecraft => Feed two of the same animal their favorite food, like wheat for cows and sheep or carrots for pigs.
how long is a day in minecraft => A full Minecraft day is 20 real minutes.
what is the end in minecraft => The End is the dimension where the Ender Dragon lives. You get there through an End portal in a stronghold.
what are mods => Mods change or add things to a game, like new blocks, mobs or shaders in Minecraft Java.
what is a resource pack => A resource pack changes how Minecraft looks and sounds, like textures and music, without changing the game's rules.
# roblox
what is roblox => Roblox is a platform where people play and make games. Games are built in Roblox Studio with the Luau language.
what is robux => Robux is Roblox's virtual money, used to buy items and game passes.
what is roblox studio => Roblox Studio is the free tool for building Roblox games.
# 3dprinting
what is 3d printing => 3D printing builds objects layer by layer from a digital model, usually by melting plastic filament.
what is pla => PLA is the easiest 3D printing plastic. It prints around 190 to 220°C and doesn't need a hot enclosure.
what temperature should i print pla at => Most PLA prints well around 200 to 215°C nozzle and 55 to 60°C bed. Check the spool's label.
what is petg => PETG is a tougher plastic than PLA that handles heat and bending better. It usually prints around 230 to 250°C.
what is abs => ABS is a strong, heat-resistant plastic, but it warps and smells, so it likes an enclosed printer.
what is tpu => TPU is a bendy, rubbery filament for things like phone cases and tires. Print it slowly.
what is infill => Infill is the pattern inside a 3D print. More infill is stronger but uses more plastic and time. 15 to 20 percent is common.
what is layer height => Layer height is how thick each printed layer is. 0.2 mm is normal. Smaller is smoother but slower.
what is a slicer => A slicer turns a 3D model into layers and instructions (G-code) the printer follows, like Bambu Studio, OrcaSlicer or Cura.
what is an stl file => An STL file is a common 3D model format made of little triangles.
what is a 3mf file => A 3MF file is a newer 3D print format that can hold the model plus colors and settings.
what are supports => Supports are temporary structures printed under overhangs so they don't droop. You remove them after.
what is a brim => A brim is a flat ring printed around the bottom of a part to help it stick to the bed.
why is my print not sticking => Clean the bed with dish soap and water, level it, check the first layer height, and use a brim. A slightly hotter bed helps too.
what is stringing => Stringing is thin plastic hairs between parts. Lower the temperature, raise retraction and dry your filament.
why should i dry filament => Filament soaks up water from the air, which causes stringing, bubbles and weak prints. Drying it fixes that.
what is the bambu a1 => The Bambu Lab A1 is a fast bed-slinger 3D printer that can do multicolor printing with the AMS lite.
what is the ams | what is the ams lite => The AMS is Bambu Lab's automatic material system. It swaps filaments for multicolor prints.
what is g-code | what is gcode => G-code is the list of move and temperature commands a 3D printer follows.
what is first layer => The first layer is the most important part of a print. If it sticks well and looks smooth, the rest usually goes well.
# words
what does awesome mean => Awesome means really great or impressive.
what does ambitious mean => Ambitious means having big goals and working hard to reach them.
what does curious mean => Curious means wanting to know or learn about things.
what does generous mean => Generous means happy to share or give.
what does persistent mean => Persistent means keeping going even when something is hard.
what does efficient mean => Efficient means getting something done without wasting time or energy.
what does analyze mean => Analyze means look at something closely to understand it.
what does hypothesis mean => A hypothesis is a smart guess you can test with an experiment.
what does evidence mean => Evidence is facts or information that show something is true.
what does a noun mean | what is a noun => A noun is a person, place, thing or idea, like dog, city or happiness.
what is a verb => A verb is an action or being word, like run, think or is.
what is an adjective => An adjective describes a noun, like big, blue or funny.
what is an adverb => An adverb describes a verb, adjective or another adverb, like quickly or very.
what is a pronoun => A pronoun takes the place of a noun, like he, she, they or it.
what is a synonym => A synonym is a word that means the same or almost the same as another word, like big and large.
what is an antonym => An antonym is a word with the opposite meaning, like hot and cold.
what is a homophone => Homophones sound the same but mean different things, like their, there and they're.
what is a metaphor => A metaphor describes something as if it were something else, like "the classroom was a zoo".
what is a simile => A simile compares two things using like or as, like "fast as lightning".
what is alliteration => Alliteration is when nearby words start with the same sound, like "Storm sent seven sparkly spaceships".
what is onomatopoeia => Onomatopoeia is a word that sounds like what it means, like buzz, boom or splash.
how many letters are in the alphabet => The English alphabet has 26 letters.
how many vowels are there => The vowels are A, E, I, O and U, and sometimes Y.
what is the longest word => One famous long English word is pneumonoultramicroscopicsilicovolcanoconiosis, with 45 letters.
what is the difference between their there and theyre => Their means belonging to them. There means a place. They're means they are.
what is the difference between your and youre => Your means belonging to you. You're means you are.
what is the difference between its and it's => Its means belonging to it. It's means it is.
# food
what is the healthiest food => There's no single one, but vegetables, fruit, beans, nuts and whole grains are some of the healthiest.
is a tomato a fruit => Yes, a tomato is a fruit to scientists, but people cook it like a vegetable.
is a peanut a nut => No, a peanut is a legume, like beans and peas.
where does chocolate come from => Chocolate comes from cacao beans that grow in pods on cacao trees.
what is the spiciest pepper => The Pepper X and the Carolina Reaper are among the spiciest peppers ever measured.
how do you boil an egg | how long to boil an egg => Put eggs in boiling water. About 6 to 7 minutes gives a jammy yolk and 10 to 12 gives hard-boiled. Cool them in cold water.
how do you make toast => Put bread in a toaster on a medium setting for 1 to 3 minutes until golden.
how do you make a sandwich => Take two slices of bread, add fillings like cheese, meat or veggies, and put them together.
how do you make scrambled eggs => Whisk eggs with a pinch of salt, cook them on low heat in butter, and stir gently until just set.
how do you make hot chocolate => Warm a cup of milk, stir in 2 spoons of cocoa and 1 to 2 spoons of sugar, or use a hot chocolate mix.
what is gluten => Gluten is a protein in wheat, barley and rye that makes dough stretchy.
what is a vegetarian => A vegetarian doesn't eat meat or fish.
what is a vegan => A vegan doesn't eat any animal products, like meat, eggs or dairy.
# sports
how many players on a soccer team => A soccer team has 11 players on the field, including the goalkeeper.
how many players on a basketball team => A basketball team has 5 players on the court.
how many players on a baseball team => A baseball team has 9 players on the field.
how many players on a football team => An American football team has 11 players on the field.
how many players on a hockey team => An ice hockey team has 6 players on the ice, including the goalie.
how long is a marathon => A marathon is 42.195 km (26.2 miles).
how often are the olympics => The Summer and Winter Olympics each happen every 4 years, two years apart.
what is the most popular sport => Soccer (football) is the most popular sport in the world.
how many points is a touchdown => A touchdown is worth 6 points.
how many points is a three pointer => A three-pointer in basketball is worth 3 points.
how big is a soccer field => A soccer field is usually about 100 to 110 m long and 64 to 75 m wide.
# safety
what should i do if i get lost => Stay where you are, find a safe adult like a police officer or a store worker, and tell them your name and your parent's phone number.
what is the emergency number | what number do i call in an emergency => In the US and Canada it's 911. In the UK it's 999, and in Europe it's 112.
what should i do in a fire => Get out fast, stay low under smoke, don't go back for things, and call 911 from outside.
what should i do if a stranger messages me online => Don't reply or share personal info. Show a parent or trusted adult, and block and report the account.
should i share my password => No. Never share your passwords, except with a parent if your family rules say so.
should i share my address online => No. Don't share your address, school or phone number with people you don't know in real life.
what is cyberbullying => Cyberbullying is being mean to someone online. If it happens to you, save it, block them and tell a trusted adult.
# fun
tell me a fun fact | give me a fun fact | fun fact => Octopuses have three hearts and blue blood. || Honey never spoils. Archaeologists found edible honey in ancient Egyptian tombs. || A day on Venus is longer than its year. || Bananas are berries, but strawberries aren't. || Sharks were around before trees. || There are more possible chess games than atoms in the observable universe. || Wombat poop is shaped like cubes. || The Eiffel Tower can grow about 15 cm taller in summer heat.
flip a coin | heads or tails => Heads! || Tails!
roll a dice | roll a die => You rolled a 1. || You rolled a 2. || You rolled a 3. || You rolled a 4. || You rolled a 5. || You rolled a 6.
rock paper scissors => I pick rock! || I pick paper! || I pick scissors!
tell me a riddle | give me a riddle => What has keys but can't open locks? A keyboard. || What gets wetter the more it dries? A towel. || What has a face and two hands but no arms or legs? A clock. || What can you catch but not throw? A cold. || What has to be broken before you can use it? An egg. || The more you take, the more you leave behind. What are they? Footsteps.
tell me a joke | say something funny | make me laugh => Why did the computer go to the doctor? It had a virus. || Why don't skeletons fight each other? They don't have the guts. || What do you call a bear with no teeth? A gummy bear. || Why did the creeper break up with the skeleton? Things kept blowing up. || Why was the math book sad? It had too many problems. || What do you call a sleeping dinosaur? A dino-snore. || Why did the scarecrow win an award? He was outstanding in his field. || How does the Moon cut his hair? Eclipse it. || Why did the robot go on vacation? It needed to recharge. || What do you call a fish with no eyes? A fsh. || Why do programmers mix up Halloween and Christmas? Because Oct 31 equals Dec 25. || What did the ocean say to the beach? Nothing, it just waved.
im bored | i'm bored | what should i do => Build something in Minecraft, sketch a new 3D model, learn a few lines of code, or go outside for a bit. Want a riddle?
what should i build | give me a build idea => Try a floating island base, a working redstone elevator, a tiny 3D-printed desk robot, or a pixel-art version of my orb.
what should i draw | give me a drawing idea => Draw a robot pet, a city on a cloud, your dream gaming setup, or me with my eyes out.
# school
how do i study better | study tips => Study in short sessions of about 25 minutes, take 5-minute breaks, quiz yourself, and sleep well before a test.
how do i focus | how can i focus better => Put your devices on Do Not Disturb, work in short blocks with breaks, and keep one task at a time. I can set a timer.
how do i write an essay => Pick a clear main idea, plan 3 supporting points, write an intro, body paragraphs and a conclusion, then reread and fix mistakes.
how do i make friends => Be friendly, ask people about the things they like, join clubs or games, and be a good listener.
how do i stop procrastinating => Start with just 5 minutes on the task. Starting is the hardest part. I can set a 5-minute timer.
""".strip()

# (opposite pairs) for "what is the opposite of X"
ANTONYMS = [
    ("hot", "cold"), ("big", "small"), ("happy", "sad"), ("fast", "slow"), ("up", "down"), ("in", "out"),
    ("open", "closed"), ("light", "dark"), ("day", "night"), ("old", "new"), ("young", "old"), ("full", "empty"),
    ("high", "low"), ("hard", "soft"), ("loud", "quiet"), ("early", "late"), ("first", "last"), ("win", "lose"),
    ("strong", "weak"), ("rich", "poor"), ("tall", "short"), ("wet", "dry"), ("thick", "thin"), ("heavy", "light"),
    ("clean", "dirty"), ("easy", "hard"), ("true", "false"), ("good", "bad"), ("start", "finish"), ("push", "pull"),
    ("above", "below"), ("inside", "outside"), ("left", "right"), ("near", "far"), ("before", "after"),
    ("always", "never"), ("buy", "sell"), ("give", "take"), ("love", "hate"), ("friend", "enemy"),
    ("brave", "cowardly"), ("safe", "dangerous"), ("sweet", "sour"), ("smooth", "rough"), ("wide", "narrow"),
    ("deep", "shallow"), ("cheap", "expensive"), ("polite", "rude"), ("asleep", "awake"), ("arrive", "leave"),
    ("remember", "forget"), ("accept", "refuse"), ("increase", "decrease"), ("ancient", "modern"),
    ("victory", "defeat"), ("question", "answer"), ("north", "south"), ("east", "west"), ("summer", "winter"),
    ("noisy", "silent"), ("visible", "invisible"), ("success", "failure"), ("float", "sink"), ("laugh", "cry"),
]

# word, synonyms
SYNONYMS = [
    ("happy", "glad, cheerful, joyful"), ("sad", "unhappy, gloomy, down"), ("big", "large, huge, giant"),
    ("small", "little, tiny, mini"), ("fast", "quick, speedy, rapid"), ("smart", "clever, bright, intelligent"),
    ("good", "great, fine, excellent"), ("bad", "poor, awful, terrible"), ("funny", "hilarious, silly, amusing"),
    ("scared", "afraid, frightened, nervous"), ("angry", "mad, upset, furious"), ("beautiful", "pretty, lovely, gorgeous"),
    ("cold", "chilly, freezing, icy"), ("hot", "warm, boiling, scorching"), ("said", "told, replied, explained"),
    ("walk", "stroll, march, wander"), ("run", "sprint, dash, race"), ("look", "see, watch, observe"),
    ("easy", "simple, effortless, basic"), ("hard", "difficult, tough, tricky"), ("cool", "awesome, epic, great"),
    ("tired", "sleepy, exhausted, worn out"), ("strange", "weird, odd, unusual"), ("important", "key, major, vital"),
    ("build", "make, create, construct"), ("help", "assist, support, aid"), ("begin", "start, launch, kick off"),
    ("end", "finish, stop, complete"), ("quiet", "silent, calm, still"), ("brave", "bold, fearless, daring"),
]

ANIMALS = [
    # animal, baby name, sound, group name
    ("dog", "a puppy", "barks or woofs", "a pack"), ("cat", "a kitten", "meows or purrs", "a clowder"),
    ("cow", "a calf", "moos", "a herd"), ("horse", "a foal", "neighs", "a herd"), ("sheep", "a lamb", "baas", "a flock"),
    ("pig", "a piglet", "oinks", "a drift"), ("chicken", "a chick", "clucks", "a flock"), ("duck", "a duckling", "quacks", "a flock"),
    ("goat", "a kid", "bleats", "a herd"), ("lion", "a cub", "roars", "a pride"), ("bear", "a cub", "growls", "a sloth"),
    ("wolf", "a pup", "howls", "a pack"), ("frog", "a tadpole", "croaks", "an army"), ("owl", "an owlet", "hoots", "a parliament"),
    ("kangaroo", "a joey", "grunts and clicks", "a mob"), ("deer", "a fawn", "bleats", "a herd"),
    ("goose", "a gosling", "honks", "a gaggle"), ("swan", "a cygnet", "trumpets", "a bevy"),
    ("elephant", "a calf", "trumpets", "a herd"), ("whale", "a calf", "sings", "a pod"), ("dolphin", "a calf", "clicks and whistles", "a pod"),
    ("snake", "a hatchling", "hisses", "a den"), ("bee", "a larva", "buzzes", "a swarm"), ("crow", "a chick", "caws", "a murder"),
    ("monkey", "an infant", "chatters", "a troop"), ("fish", "a fry", "doesn't really make sounds", "a school"),
    ("rabbit", "a kit", "thumps its feet", "a colony"), ("fox", "a kit", "yips and screams", "a skulk"),
    ("eagle", "an eaglet", "screeches", "a convocation"), ("turkey", "a poult", "gobbles", "a rafter"),
]

GREETINGS = [
    # language, hello, thank you, goodbye
    ("Spanish", "hola", "gracias", "adiós"), ("French", "bonjour", "merci", "au revoir"),
    ("German", "hallo", "danke", "auf Wiedersehen"), ("Italian", "ciao", "grazie", "arrivederci"),
    ("Portuguese", "olá", "obrigado (or obrigada)", "adeus or tchau"), ("Japanese", "konnichiwa", "arigatō", "sayōnara"),
    ("Chinese", "nǐ hǎo", "xièxie", "zàijiàn"), ("Korean", "annyeonghaseyo", "gamsahamnida", "annyeonghi gaseyo"),
    ("Russian", "privet (or zdravstvuyte)", "spasibo", "do svidaniya"), ("Arabic", "marhaban", "shukran", "ma'a as-salama"),
    ("Hindi", "namaste", "dhanyavaad", "alvida"), ("Dutch", "hallo", "dank je", "tot ziens"),
    ("Swedish", "hej", "tack", "hej då"), ("Greek", "yia sou", "efcharistó", "antío"),
    ("Turkish", "merhaba", "teşekkürler", "hoşça kal"), ("Polish", "cześć", "dziękuję", "do widzenia"),
    ("Hebrew", "shalom", "todah", "lehitraot"), ("Hawaiian", "aloha", "mahalo", "aloha"),
    ("Swahili", "jambo", "asante", "kwaheri"), ("Vietnamese", "xin chào", "cảm ơn", "tạm biệt"),
    ("Norwegian", "hei", "takk", "ha det"), ("Danish", "hej", "tak", "farvel"), ("Finnish", "hei", "kiitos", "näkemiin"),
]

MONTHS = [("January", 31), ("February", 28), ("March", 31), ("April", 30), ("May", 31), ("June", 30),
          ("July", 31), ("August", 31), ("September", 30), ("October", 31), ("November", 30), ("December", 31)]

PLANETS = [
    # name, position, moons (approx, as of 2025), day length, year length, fact
    ("Mercury", 1, "no moons", "about 59 Earth days", "88 Earth days", "it has almost no air, so it's very hot in the day and freezing at night"),
    ("Venus", 2, "no moons", "about 243 Earth days", "225 Earth days", "it spins backwards and is the hottest planet"),
    ("Earth", 3, "1 moon", "about 24 hours", "365.25 days", "it's the only planet we know with life"),
    ("Mars", 4, "2 moons", "about 24.6 hours", "687 Earth days", "it has Olympus Mons, the tallest volcano in the solar system"),
    ("Jupiter", 5, "about 95 known moons", "about 10 hours", "about 12 Earth years", "its Great Red Spot is a storm bigger than Earth"),
    ("Saturn", 6, "over 140 known moons", "about 10.7 hours", "about 29 Earth years", "it's so light for its size that it would float in a giant bathtub"),
    ("Uranus", 7, "28 known moons", "about 17 hours", "about 84 Earth years", "it spins on its side"),
    ("Neptune", 8, "16 known moons", "about 16 hours", "about 165 Earth years", "it has the fastest winds in the solar system"),
]
