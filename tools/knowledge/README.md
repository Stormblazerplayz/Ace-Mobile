# Ace's knowledge pack

Ace (an offline iPad assistant) answers from a built-in bank. This folder holds the sources for the big
knowledge pack. `tools/knowledge/build_knowledge.py` turns them into the files in `Ace/Resources`.

Who asks: Storm, 12, a solo app and game developer. Storm types or talks casually, all lowercase, often
short ("whats the capital of peru", "how do i make a part spin in roblox", "why is my pc lagging").
Storm uses Roblox Studio Lua, Swift, Python, C++, Arduino, a gaming PC, an iPad, Minecraft, 3D printing,
drones and DaVinci Resolve, and does school homework (math, science, history, geography, English).

## Q&A files: `data/<area>/<topic>.txt`

```
# tag: school.math
how do you find the area of a circle | area of a circle formula | how to get a circles area => The area of a circle is pi times the radius squared (A = πr²). With a radius of 3 cm that's about 28.3 cm².
```

- `# tag: area.topic` before the entries. Lowercase, dots between parts.
- Left of `=>`: 2 to 6 ways to ask, split with ` | `. Lowercase, no question marks, the way a 12-year-old
  types or says it. Make them really different (different words, short and long), not tiny rewrites.
- Right of `=>`: the answer, 1 to 3 sentences, plain words, under about 350 characters. A second answer
  can follow ` || ` but isn't needed. Start with the answer itself, not "Great question".
- Every fact must be true. If you aren't sure of a fact, leave the entry out. No made-up numbers,
  names, block names, API names or keyboard shortcuts.
- Facts that change (populations, records, leaders, prices, newest versions) say when: "As of 2025, ...".
- No em dashes or en dashes. Use commas or periods.
- One entry per real question. Never add the same question twice with different words.
  Different facts about the same thing are different entries ("what do pandas eat", "how long do pandas live").
- Be useful: what a kid would actually ask for school, coding, fixing their PC, games, cooking and life.
  No filler like "what is 7 times 8" (Ace has a calculator) or "what day comes after monday".
- Ace already has math, unit conversion, timers, weather, translation and dates as skills, so skip those.

Check your files: `python3 tools/knowledge/check_data.py data/<area>`
It catches format problems and questions that are already in the bank (including Ace's older 3,000).

## Generated data: `gen/<name>.py`

When a trusted data set exists (country lists, the periodic table, Minecraft game data, Pokémon data,
WordNet), write a generator in `gen/` that reads it and writes `data/<area>/gen_<name>.txt` in the
same format. Download into `tools/knowledge/.cache/` (not committed). Commit the generator and its
output. Say where the data came from and its license at the top of the generator.

## Other files

- `recipes/*.json`: `{"recipes": [...]}` in the same shape as `Ace/Resources/recipes.json`.
- `trivia/*.json`: `{"questions": [...]}` like `Ace/Resources/trivia.json` (4 choices, `answer` is 0 to 3,
  categories: Space, Animals, Science, Earth, Human Body, History, Geography, Sports, Technology, Food).
- `twenty/*.json`: `{"questions": [...], "things": [...]}` like `Ace/Resources/twenty_questions.json`.
  Every thing answers every question with 0, 0.5 or 1.
- `phrases/*.json`: `{"entries": [...]}` like `Ace/Resources/phrasebook.json` (all 12 languages).

Scripts live in `tools/scripts/` (see `tools/build_scripts.py`).
