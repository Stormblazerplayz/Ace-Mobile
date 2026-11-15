# @title Raspberry Pi Morse Code Flasher
# @category Raspberry Pi
# @kind Console program
# @where On a Raspberry Pi: LED on GPIO17 (with a resistor to GND), and an optional buzzer on GPIO27. Run: python3 morse_led.py
# @keywords raspberry pi morse code, pi flash message, gpiozero led morse, raspberry pi sos
# @about Flashes any message you type in Morse code on an LED, with matching beeps on a buzzer.

from time import sleep

from gpiozero import LED, Buzzer

led = LED(17)
buzzer = Buzzer(27)
UNIT = 0.15  # length of one dot in seconds
MORSE = {"A": ".-", "B": "-...", "C": "-.-.", "D": "-..", "E": ".", "F": "..-.", "G": "--.", "H": "....",
         "I": "..", "J": ".---", "K": "-.-", "L": ".-..", "M": "--", "N": "-.", "O": "---", "P": ".--.",
         "Q": "--.-", "R": ".-.", "S": "...", "T": "-", "U": "..-", "V": "...-", "W": ".--", "X": "-..-",
         "Y": "-.--", "Z": "--..", "1": ".----", "2": "..---", "3": "...--", "4": "....-", "5": ".....",
         "6": "-....", "7": "--...", "8": "---..", "9": "----.", "0": "-----"}


def signal(length):
    led.on()
    buzzer.on()
    sleep(length)
    led.off()
    buzzer.off()
    sleep(UNIT)  # gap between dots and dashes


while True:
    message = input("Message to flash (Enter to quit): ").strip().upper()
    if not message:
        break
    for word in message.split():
        for letter in word:
            code = MORSE.get(letter, "")
            print(letter, code)
            for symbol in code:
                signal(UNIT if symbol == "." else UNIT * 3)  # a dash is 3 dots long
            sleep(UNIT * 2)  # gap between letters (3 units in total)
        sleep(UNIT * 4)      # gap between words (7 units in total)
