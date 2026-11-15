# @title Settings File with ConfigParser
# @category Files and data
# @kind Console program
# @where Save as settings_demo.py and run: python3 settings_demo.py. It makes settings.ini that you can edit in any text editor.
# @keywords python configparser, python ini file, python settings file, python save preferences
# @about Saves and loads program settings in an easy-to-edit .ini file with sections.

import configparser
from pathlib import Path

PATH = Path(__file__).with_name("settings.ini")
config = configparser.ConfigParser()

if PATH.exists():
    config.read(PATH)
else:
    # First run: write some defaults
    config["player"] = {"name": "Storm", "color": "blue"}
    config["game"] = {"difficulty": "normal", "volume": "70", "music": "yes"}
    with open(PATH, "w") as f:
        config.write(f)
    print("Made a new settings.ini with default values.")

# Read values. getint and getboolean turn text into the right type.
name = config.get("player", "name", fallback="Player")
volume = config.getint("game", "volume", fallback=50)
music = config.getboolean("game", "music", fallback=True)
print(f"Hello {name}! Volume is {volume}%, music is {'on' if music else 'off'}.")

new_volume = input("New volume 0-100 (Enter to keep): ").strip()
if new_volume.isdigit() and 0 <= int(new_volume) <= 100:
    config["game"]["volume"] = new_volume
    with open(PATH, "w") as f:
        config.write(f)
    print("Saved!")

print("\nsettings.ini now looks like this:")
print(PATH.read_text())
