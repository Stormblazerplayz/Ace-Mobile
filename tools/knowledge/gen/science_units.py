#!/usr/bin/env python3
"""Writes data/science/gen_units.txt: SI units, what they measure, and who they're named after.

Data source: the SI Brochure (BIPM, 9th edition, 2019) for unit names, symbols and what
they measure. Who each unit is named after is standard history, hand-checked.

Run from the repo root:  python3 tools/knowledge/gen/science_units.py
"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, "..", "data", "science", "gen_units.txt"))

# unit, symbol, quantity, person it honors (or None), short note about the person or the unit
UNITS = [
    ("meter", "m", "length", None, "It's one of the seven SI base units."),
    ("kilogram", "kg", "mass", None, "It's the only SI base unit with a prefix in its name."),
    ("second", "s", "time", None, "It's one of the seven SI base units, defined using cesium atomic clocks."),
    ("ampere", "A", "electric current", "André-Marie Ampère, a French physicist who studied electromagnetism", None),
    ("kelvin", "K", "temperature", "Lord Kelvin (William Thomson), a Scottish-Irish physicist", "Zero kelvin is absolute zero, the coldest possible temperature."),
    ("mole", "mol", "amount of substance", None, "One mole is about 6.022 × 10^23 particles."),
    ("candela", "cd", "how bright a light source is in a given direction", None, "One candela is roughly the brightness of one candle."),
    ("newton", "N", "force", "Isaac Newton", "One newton is about the weight of a small apple."),
    ("joule", "J", "energy and work", "James Prescott Joule, an English physicist who studied heat", "Lifting a small apple 1 meter takes about 1 joule."),
    ("watt", "W", "power, how fast energy is used or transferred", "James Watt, the Scottish engineer who improved the steam engine", "One watt is one joule per second."),
    ("pascal", "Pa", "pressure", "Blaise Pascal, a French mathematician and physicist", "Air pressure at sea level is about 101,325 pascals."),
    ("volt", "V", "voltage, the push that drives electric current", "Alessandro Volta, the Italian who invented the battery", None),
    ("ohm", "Ω", "electrical resistance", "Georg Ohm, the German physicist behind Ohm's law", None),
    ("coulomb", "C", "electric charge", "Charles-Augustin de Coulomb, a French physicist", "One coulomb is the charge of about 6.24 × 10^18 electrons."),
    ("hertz", "Hz", "frequency, how many times something happens per second", "Heinrich Hertz, who first proved radio waves exist", "Concert A is 440 hertz."),
    ("farad", "F", "capacitance, how much charge a capacitor stores", "Michael Faraday", None),
    ("tesla", "T", "magnetic field strength", "Nikola Tesla", "A fridge magnet is about 0.005 tesla, and an MRI scanner about 1.5 to 3 tesla."),
    ("weber", "Wb", "magnetic flux", "Wilhelm Weber, a German physicist", None),
    ("henry", "H", "inductance", "Joseph Henry, an American scientist who studied electromagnets", None),
    ("becquerel", "Bq", "radioactivity, one atom decaying per second", "Henri Becquerel, who discovered radioactivity", None),
    ("gray", "Gy", "absorbed radiation dose", "Louis Harold Gray, a British physicist", None),
    ("sievert", "Sv", "the health effect of a radiation dose", "Rolf Sievert, a Swedish medical physicist", None),
    ("lumen", "lm", "the total amount of visible light from a source", None, "Light bulbs are labeled in lumens to show how bright they are."),
    ("lux", "lx", "how much light falls on a surface", None, "Bright sunlight is about 100,000 lux, and a well-lit office about 500 lux."),
    ("siemens", "S", "electrical conductance", "Werner von Siemens, a German inventor and industrialist", None),
    ("katal", "kat", "catalytic activity, how fast a catalyst speeds up a reaction", None, None),
    ("radian", "rad", "angle", None, "A full circle is 2π radians, about 6.28."),
]

SHORT = {'meter': 'length', 'kilogram': 'mass', 'second': 'time', 'ampere': 'electric current', 'kelvin': 'temperature', 'mole': 'amount of substance', 'candela': 'luminous intensity', 'newton': 'force', 'joule': 'energy', 'watt': 'power', 'pascal': 'pressure', 'volt': 'voltage', 'ohm': 'resistance', 'coulomb': 'electric charge', 'hertz': 'frequency', 'farad': 'capacitance', 'tesla': 'magnetic field strength', 'weber': 'magnetic flux', 'henry': 'inductance', 'becquerel': 'radioactivity', 'gray': 'absorbed radiation dose', 'sievert': 'radiation dose equivalent', 'lumen': 'luminous flux', 'lux': 'illuminance', 'siemens': 'electrical conductance', 'katal': 'catalytic activity', 'radian': 'angle'}
PLURAL = {'hertz': 'hertz', 'lux': 'lux', 'siemens': 'siemens', 'henry': 'henries', 'candela': 'candelas'}

# Common non-SI units people meet in science.
OTHER = [
    ("what is a degree celsius | celsius vs kelvin | how do you convert celsius to kelvin",
     "A degree Celsius is the same size as a kelvin, but the scales start in different places. Add 273.15 to a Celsius temperature to get kelvin, so 0 °C is 273.15 K."),
    ("how do you convert celsius to fahrenheit | celsius to fahrenheit formula | c to f",
     "Multiply by 9, divide by 5, then add 32. So 20 °C is 68 °F, and 100 °C is 212 °F."),
    ("how do you convert fahrenheit to celsius | fahrenheit to celsius formula | f to c",
     "Subtract 32, multiply by 5, then divide by 9. So 98.6 °F is 37 °C."),
    ("when are celsius and fahrenheit the same | what temperature is the same in c and f | minus 40 degrees",
     "Minus 40 is the same in both: minus 40 °C equals minus 40 °F."),
    ("what is a liter | how big is a liter | liters to cubic centimeters",
     "A liter is a unit of volume equal to 1,000 cubic centimeters, a cube 10 cm on each side. One liter of water has a mass of about 1 kilogram."),
    ("what is a milliliter | ml vs cm3 | is a milliliter the same as a cubic centimeter",
     "A milliliter is a thousandth of a liter, exactly the same as one cubic centimeter. A teaspoon holds about 5 mL."),
    ("what is a tonne | metric ton | how much is a tonne",
     "A tonne, or metric ton, is 1,000 kilograms. A small car has a mass of roughly one tonne."),
    ("what is an atmosphere unit | atm pressure unit | how many pascals in an atmosphere",
     "One standard atmosphere (atm) is 101,325 pascals, about the air pressure at sea level."),
    ("what is a bar pressure unit | millibar | hectopascal",
     "A bar is 100,000 pascals, close to air pressure at sea level. Weather maps use millibars or hectopascals, which are the same size: 1,013 mb is typical."),
    ("what is psi | pounds per square inch | tire pressure units",
     "PSI means pounds per square inch, a pressure unit used in the US for tires and air tanks. Air pressure at sea level is about 14.7 psi."),
    ("what is a newton meter | what is torque measured in | unit of torque",
     "Torque, a turning force, is measured in newton meters (N m): a force of one newton acting one meter from the pivot."),
    ("what is a kilowatt | how much is a megawatt | kilowatt vs megawatt",
     "A kilowatt is 1,000 watts and a megawatt is a million watts. A microwave uses about 1 kilowatt, and a big wind turbine can produce a few megawatts."),
    ("what is a gigawatt | how much power is a gigawatt | 1.21 gigawatts",
     "A gigawatt is a billion watts, about the output of a large nuclear power station."),
    ("what is a nanosecond | how long is a millisecond | microsecond meaning",
     "A millisecond is a thousandth of a second, a microsecond a millionth, and a nanosecond a billionth. Light travels about 30 cm in a nanosecond."),
    ("what is a micrometer unit | how small is a micron | micron meaning",
     "A micrometer, or micron, is a millionth of a meter. A human hair is about 50 to 100 micrometers thick."),
    ("what is an angstrom | angstrom unit | how small is an angstrom",
     "An ångström is a ten-billionth of a meter (0.1 nanometers). Atoms are about 1 to 3 ångströms across, so it's handy in chemistry."),
    ("what is a decibel scale | how loud is 100 decibels | decibel examples",
     "Decibels measure loudness on a scale where every 10 dB is 10 times more intense. Whispers are about 30 dB, talking 60 dB, a rock concert 110 dB. Long exposure above about 85 dB can damage hearing."),
    ("what is a calorie vs a kilocalorie | food calories vs calories | what is a kcal",
     "A food Calorie is actually a kilocalorie, 1,000 small calories, which is about 4,184 joules. It's enough energy to warm 1 kg of water by 1 °C."),
    ("what is a knot speed | how fast is a knot | why do ships use knots",
     "A knot is one nautical mile per hour, about 1.85 km/h. Ships and planes use it because a nautical mile is tied to Earth's latitude, which helps navigation."),
    ("what is a nautical mile | nautical mile vs mile | how long is a nautical mile",
     "A nautical mile is exactly 1,852 meters, a bit longer than a regular mile (1,609 meters)."),
    ("what is a hectare | how big is a hectare | hectare vs acre",
     "A hectare is 10,000 square meters, a square 100 m on each side, about 2.5 acres. A soccer field is roughly 0.7 hectares."),
    ("what is a dalton | atomic mass unit | what is amu",
     "A dalton, or atomic mass unit, is one twelfth the mass of a carbon-12 atom, about the mass of a proton or neutron. Atomic masses on the periodic table are in daltons."),
]


def main():
    lines = ["# Generated by tools/knowledge/gen/science_units.py. Do not edit by hand.",
             "# Source: SI Brochure (BIPM, 9th edition), hand-checked history.",
             "# tag: science.units"]
    for unit, sym, qty, person, note in UNITS:
        a = f"The {unit} ({sym}) is the SI unit of {qty}."
        if person:
            a += f" It's named after {person}."
        if note:
            a += " " + note
        lines.append(f"what is a {unit} | what does a {unit} measure | what is the {unit} unit => {a}")
        q = SHORT[unit]
        pl = PLURAL.get(unit, unit + "s")
        lines.append(f"what is the si unit of {q} | what unit is {q} measured in | unit for {q} => "
                     f"{q[0].upper() + q[1:]} is measured in {pl} ({sym}) in the SI system.")
        if person:
            lines.append(f"who is the {unit} named after | why is it called a {unit} | {unit} unit named after => "
                         f"The {unit} is named after {person}.")
    for qs, a in OTHER:
        lines.append(qs + " => " + a)
    with open(OUT, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print(f"wrote {len(lines) - 3} entries to {OUT}")


if __name__ == "__main__":
    main()
