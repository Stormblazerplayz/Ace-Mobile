# @title Mad Libs Story
# @category Basics
# @kind Console program
# @where Save as madlibs.py and run: python3 madlibs.py
# @keywords python mad libs, python silly story, python input strings, python word game
# @about Asks you for silly words and puts them into a funny story.

print("Let's make a silly story! Answer each question.\n")

# Ask for each word and store it in a dictionary
blanks = ["adjective", "animal", "verb ending in -ing", "food", "place", "number", "exclamation"]
words = {}
for blank in blanks:
    answer = input(f"Give me a {blank}: ").strip()
    words[blank] = answer or "banana"  # if they skip, use banana

story = (
    f"Yesterday a {words['adjective']} {words['animal']} came to my house. "
    f"It started {words['verb ending in -ing']} all over the kitchen and ate "
    f"{words['number']} plates of {words['food']}! "
    f"I yelled \"{words['exclamation']}!\" and it ran all the way to {words['place']}. "
    f"Nobody believed me at school."
)

print("\n=== Your Story ===")
print(story)
