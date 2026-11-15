# @title Guess the Animal (Learning AI)
# @category Games
# @kind Console program
# @where Save as animals_ai.py and run: python3 animals_ai.py
# @keywords python guess the animal, python twenty questions, python learning game, python decision tree
# @about Think of an animal and the computer asks yes or no questions to guess it, learning new animals when it's wrong.

# The "brain" is a tree. A question has a yes branch and a no branch. A leaf is an animal.
brain = {"question": "Does it live in water?",
         "yes": {"animal": "fish"},
         "no": {"animal": "dog"}}


def ask_yes(question):
    return input(question + " (y/n) ").strip().lower().startswith("y")


def play(node):
    # Walk down the tree asking questions until we reach an animal
    while "question" in node:
        node = node["yes"] if ask_yes(node["question"]) else node["no"]
    guess = node["animal"]
    if ask_yes(f"Is it a {guess}?"):
        print("I got it! I'm so smart.")
        return
    # Learn the new animal by turning this leaf into a question
    new_animal = input("I give up. What was your animal? ").strip().lower() or "mystery animal"
    question = input(f"Type a yes/no question that tells a {new_animal} apart from a {guess}: ").strip()
    if not question.endswith("?"):
        question += "?"
    answer_for_new = ask_yes(f"For a {new_animal}, what is the answer?")
    node.clear()
    node["question"] = question
    node["yes" if answer_for_new else "no"] = {"animal": new_animal}
    node["no" if answer_for_new else "yes"] = {"animal": guess}
    print("Thanks! I learned something new.")


print("Think of an animal and I'll try to guess it!")
while True:
    play(brain)
    if not ask_yes("Play again?"):
        break
