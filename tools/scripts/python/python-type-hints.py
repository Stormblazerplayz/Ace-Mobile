# @title Type Hints
# @category Basics
# @kind Console program
# @where Save as type_hints.py and run: python3 type_hints.py
# @keywords python type hints, python annotations, python optional type, python function types
# @about Shows how to label what type each variable and function expects, which makes code easier to read.

from typing import Optional

# Type hints are labels. Python doesn't force them, but editors use them to warn you.
name: str = "Storm"
level: int = 12
speed: float = 3.5
friends: list[str] = ["Doodle", "Nova"]
scores: dict[str, int] = {"Storm": 90, "Doodle": 85}


def average(numbers: list[float]) -> float:
    """Takes a list of numbers and gives back a float."""
    return sum(numbers) / len(numbers) if numbers else 0.0


def find_score(player: str) -> Optional[int]:
    """Gives back an int, or None if the player is missing."""
    return scores.get(player)


def greet(person: str, times: int = 1) -> None:
    for _ in range(times):
        print(f"Hi {person}!")


print("Average:", average([90, 85, 77.5]))
print("Storm's score:", find_score("Storm"))
print("Ghost's score:", find_score("Ghost"))
greet(name, times=2)
print(f"{name} is level {level} with speed {speed} and friends {', '.join(friends)}")
