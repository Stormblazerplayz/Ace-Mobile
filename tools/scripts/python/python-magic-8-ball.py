# @title Magic 8 Ball
# @category Games
# @kind Console program
# @where Save as magic8.py and run: python3 magic8.py
# @keywords python magic 8 ball, python fortune teller, python random answers, python yes no question
# @about Ask the Magic 8 Ball any yes or no question and it shakes up a random answer.

import random
import time

ANSWERS = [
    "It is certain.", "Without a doubt.", "Yes, definitely!", "You may rely on it.",
    "Most likely.", "Outlook good.", "Signs point to yes.",
    "Reply hazy, try again.", "Ask again later.", "Cannot predict now.",
    "Don't count on it.", "My reply is no.", "Very doubtful.", "Outlook not so good.",
]

print("I am the Magic 8 Ball. Ask me a yes or no question (or press Enter to quit).")
while True:
    question = input("\nYour question: ").strip()
    if not question:
        print("The 8 Ball goes back to sleep...")
        break
    if not question.endswith("?"):
        print("(Hmm, that doesn't sound like a question, but I'll answer anyway.)")
    print("Shaking", end="", flush=True)
    for _ in range(3):
        time.sleep(0.4)
        print(".", end="", flush=True)
    print()
    print(random.choice(ANSWERS))
