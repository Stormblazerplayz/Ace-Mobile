# @title Classes: Virtual Pet
# @category Basics
# @kind Console program
# @where Save as pet.py and run: python3 pet.py
# @keywords python class, python object oriented, python pet class, python __init__, python methods
# @about Builds a Pet class with hunger and happiness, then makes two pets and plays with them.

class Pet:
    """A blueprint for pets. Each pet made from it is an object."""

    def __init__(self, name, species):
        # __init__ runs when a new pet is made. self means "this pet".
        self.name = name
        self.species = species
        self.hunger = 50
        self.happiness = 50

    def feed(self):
        self.hunger = max(0, self.hunger - 30)
        print(f"{self.name} munches some food. Yum!")

    def play(self):
        self.happiness = min(100, self.happiness + 25)
        self.hunger = min(100, self.hunger + 10)
        print(f"{self.name} plays fetch and looks so happy!")

    def mood(self):
        if self.hunger > 70:
            return "hungry"
        if self.happiness > 70:
            return "super happy"
        return "okay"

    def __str__(self):
        # __str__ decides what print(pet) shows.
        return f"{self.name} the {self.species}: hunger {self.hunger}, happiness {self.happiness}, feels {self.mood()}"


rex = Pet("Rex", "dog")
whiskers = Pet("Whiskers", "cat")

rex.play()
rex.play()
whiskers.feed()

print(rex)
print(whiskers)
