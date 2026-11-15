# @title Raspberry Pi Buzzer Melody
# @category Raspberry Pi
# @kind Console program
# @where On a Raspberry Pi: passive piezo buzzer between GPIO17 and GND. Run: python3 melody.py
# @keywords raspberry pi melody, gpiozero tonalbuzzer, pi play notes, raspberry pi music buzzer
# @about Plays a tune on a passive buzzer using TonalBuzzer and named musical notes.

from time import sleep

from gpiozero import TonalBuzzer
from gpiozero.tones import Tone

buzzer = TonalBuzzer(17, octaves=2)  # 2 octaves lets us play from A3 up to A5

# (note, beats). None means a rest (silence).
SONG = [("C4", 1), ("C4", 1), ("G4", 1), ("G4", 1), ("A4", 1), ("A4", 1), ("G4", 2),
        ("F4", 1), ("F4", 1), ("E4", 1), ("E4", 1), ("D4", 1), ("D4", 1), ("C4", 2), (None, 1)]
BEAT = 0.35  # seconds per beat

print("Playing Twinkle Twinkle Little Star...")
for note, beats in SONG:
    if note is None:
        buzzer.stop()
    else:
        print(note, end=" ", flush=True)
        buzzer.play(Tone(note))
    sleep(BEAT * beats * 0.9)
    buzzer.stop()          # a tiny gap so repeated notes sound separate
    sleep(BEAT * beats * 0.1)
print("\nDone!")
