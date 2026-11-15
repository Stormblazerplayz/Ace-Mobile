# @title Inheritance: Animals
# @category Basics
# @kind Console program
# @where Save as animals.py and run: python3 animals.py
# @keywords python inheritance, python subclass, python super, python override method, python polymorphism
# @about Shows how a Dog and a Bird class can inherit from an Animal class and change its behavior.

class Animal:
    def __init__(self, name):
        self.name = name

    def speak(self):
        return "makes a sound"

    def move(self):
        return "moves around"

    def describe(self):
        return f"{self.name} {self.speak()} and {self.move()}."


# Dog "inherits" from Animal, so it gets all of Animal's methods for free.
class Dog(Animal):
    def speak(self):  # override: replace the parent's version
        return "barks"


class Bird(Animal):
    def __init__(self, name, can_fly=True):
        super().__init__(name)  # run Animal's __init__ first
        self.can_fly = can_fly

    def speak(self):
        return "tweets"

    def move(self):
        return "flies" if self.can_fly else "waddles"


animals = [Dog("Buddy"), Bird("Tweety"), Bird("Pingu", can_fly=False), Animal("Mystery")]

# Same method call, different results. That's called polymorphism.
for animal in animals:
    print(animal.describe())

print("Is Buddy an Animal?", isinstance(animals[0], Animal))
print("Is Buddy a Bird?", isinstance(animals[0], Bird))
