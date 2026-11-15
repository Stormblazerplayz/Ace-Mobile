// @title Classes and Inheritance
// @category Swift basics
// @kind Swift program
// @where On a Mac, save as Classes.swift and run in Terminal: swiftc -parse-as-library Classes.swift -o classes && ./classes
// @keywords swift class, swift inheritance, swift override, swift reference type, swift init
// @about Builds an Animal class with Dog and Bird subclasses, and shows how classes are shared, not copied.

import Foundation

class ZooAnimal {
    let name: String
    var energy = 10

    init(name: String) {
        self.name = name
    }

    func speak() -> String {
        "..."
    }

    func describe() -> String {
        "\(name) says \(speak()) and has \(energy) energy"
    }
}

// Dog inherits everything from ZooAnimal and changes speak()
class ZooDog: ZooAnimal {
    override func speak() -> String {
        "Woof!"
    }

    func fetch() {
        energy -= 3
        print("\(name) fetches the ball!")
    }
}

class ZooBird: ZooAnimal {
    let canFly: Bool

    init(name: String, canFly: Bool) {
        self.canFly = canFly
        super.init(name: name)  // let the parent class set up its part
    }

    override func speak() -> String {
        canFly ? "Tweet!" : "Squawk!"
    }
}

@main
struct ClassesProgram {
    static func main() {
        let rex = ZooDog(name: "Rex")
        rex.fetch()
        let animals: [ZooAnimal] = [rex, ZooBird(name: "Tweety", canFly: true), ZooBird(name: "Pingu", canFly: false)]
        for animal in animals {
            print(animal.describe())  // each one uses its own speak()
        }

        // Classes are SHARED: two names can point to the same object
        let sameDog = rex
        sameDog.energy = 99
        print("Rex's energy is now \(rex.energy) because sameDog IS rex")

        // Check what kind of object something is with "is" and "as?"
        for animal in animals {
            if let dog = animal as? ZooDog {
                print("\(dog.name) is a dog")
            } else if animal is ZooBird {
                print("\(animal.name) is a bird")
            }
        }
    }
}
