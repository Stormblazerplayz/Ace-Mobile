# @title Pomodoro Study Timer
# @category Tools
# @kind Console program
# @where Save as pomodoro.py and run: python3 pomodoro.py
# @keywords python pomodoro, python study timer, python focus timer, python work break cycle
# @about A study timer that switches between 25 minutes of focus and 5 minute breaks, with a long break every 4 rounds.

import time

FOCUS, SHORT_BREAK, LONG_BREAK = 25, 5, 15  # minutes (change these if you like)


def countdown(minutes, label):
    end = time.time() + minutes * 60
    while True:
        left = int(end - time.time())
        if left <= 0:
            break
        m, s = divmod(left, 60)
        print(f"\r{label}: {m:02d}:{s:02d} ", end="", flush=True)
        time.sleep(1)
    print(f"\r{label}: done!       \a")


text = input("How many focus rounds? (Enter for 4): ").strip()
rounds = int(text) if text.isdigit() and int(text) > 0 else 4
try:
    for number in range(1, rounds + 1):
        input(f"\nRound {number}: press Enter to start focusing...")
        countdown(FOCUS, f"Focus {number}")
        if number == rounds:
            break
        rest = LONG_BREAK if number % 4 == 0 else SHORT_BREAK
        print("Great work! Stand up, stretch and drink some water.")
        countdown(rest, "Break")
    print("\nAll rounds finished. Awesome job!")
except KeyboardInterrupt:
    print("\nStopped early. You still did great.")
