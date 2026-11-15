# @title If, Elif and Else
# @category Basics
# @kind Console program
# @where Save as decisions.py and run: python3 decisions.py
# @keywords python if statement, python elif, python else, python decisions, python conditions
# @about Asks for a test score and uses if, elif and else to give a letter grade and a message.

text = input("What did you get on your test (0 to 100)? ")

# isdigit() checks that the text is only numbers, so int() won't crash.
if not text.isdigit():
    print("Please type a whole number like 85.")
else:
    score = int(text)

    # Python checks each condition from top to bottom and runs the FIRST one that is True.
    if score > 100:
        print("Hmm, that's more than 100. Nice try!")
    elif score >= 90:
        print("A! Amazing work!")
    elif score >= 80:
        print("B! Really good.")
    elif score >= 70:
        print("C. Not bad, keep practicing.")
    elif score >= 60:
        print("D. You can do better next time.")
    else:
        print("F. Let's study together and try again!")

    # "and" means both must be true. "or" means at least one.
    if score >= 90 and score <= 100:
        print("You made the honor roll!")
    if score == 0 or score == 100:
        print("Wow, that's an extreme score!")
