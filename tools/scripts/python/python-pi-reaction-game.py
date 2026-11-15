# @title Raspberry Pi Reaction Game
# @category Raspberry Pi
# @kind Console program
# @where On a Raspberry Pi: LED on GPIO4, player 1 button on GPIO14, player 2 button on GPIO15 (buttons to GND). Run: python3 reaction_game.py
# @keywords raspberry pi reaction game, pi two player buttons, gpiozero game, raspberry pi quick reflex
# @about A two player game: when the LED lights up, the first person to press their button wins the round.

import random
from time import monotonic, sleep

from gpiozero import LED, Button

led = LED(4)
players = {"Player 1": Button(14), "Player 2": Button(15)}
scores = {name: 0 for name in players}

print("First to 3 points wins! Wait for the light...")
while max(scores.values()) < 3:
    sleep(random.uniform(2, 5))
    # Pressing before the light comes on is a false start
    cheaters = [name for name, b in players.items() if b.is_pressed]
    for name in cheaters:
        scores[name] -= 1
        print(f"{name} pressed too early! -1 point")
    led.on()
    start = monotonic()
    winner = None
    while winner is None:
        for name, button in players.items():
            if button.is_pressed and name not in cheaters:
                winner = name
                break
        if monotonic() - start > 5:
            break
    led.off()
    if winner:
        scores[winner] += 1
        print(f"{winner} wins the round in {monotonic() - start:.3f} s!  Scores: {scores}")
    else:
        print("Nobody pressed in time.")
    sleep(1)

champion = max(scores, key=scores.get)
print(f"\n{champion} is the champion!")
led.blink(on_time=0.1, off_time=0.1, n=10, background=False)
