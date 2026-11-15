# @title Rock Paper Scissors
# @category Games
# @kind Console program
# @where Save as rps.py and run: python3 rps.py
# @keywords python rock paper scissors, python rps game, python game against computer, python best of five
# @about Play rock paper scissors against the computer, first to 3 wins.

import random

CHOICES = ["rock", "paper", "scissors"]
BEATS = {"rock": "scissors", "paper": "rock", "scissors": "paper"}  # key beats value

player_score = 0
computer_score = 0
print("First to 3 wins! Type rock, paper or scissors (or r, p, s).")

while player_score < 3 and computer_score < 3:
    text = input("\nYour move: ").strip().lower()
    # Let them type just the first letter
    move = next((c for c in CHOICES if c.startswith(text)), None) if text else None
    if move is None:
        print("That's not a move!")
        continue
    computer = random.choice(CHOICES)
    print(f"You: {move}   Computer: {computer}")
    if move == computer:
        print("Tie!")
    elif BEATS[move] == computer:
        player_score += 1
        print(f"{move.capitalize()} beats {computer}. You win this round!")
    else:
        computer_score += 1
        print(f"{computer.capitalize()} beats {move}. Computer wins this round.")
    print(f"Score: you {player_score} - {computer_score} computer")

print("\nYOU WIN THE MATCH!" if player_score == 3 else "\nThe computer wins the match. Rematch?")
