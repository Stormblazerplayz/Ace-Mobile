// @title Save Settings with a Struct in EEPROM
// @category Arduino
// @kind Arduino sketch
// @where Any Arduino Uno or Nano; open Serial Monitor at 9600 with "Newline"; type commands like volume 7, name Bolt, show, reset.
// @keywords eeprom struct, save settings arduino, eeprom put get struct, settings menu serial
// @about Keeps a group of settings (volume, brightness and a robot name) in one struct and saves them all to EEPROM at once.

#include <EEPROM.h>

// The "magic" number tells us the EEPROM really holds our settings and not junk.
const uint16_t MAGIC = 0xBEEF;

struct Settings {
  uint16_t magic;
  byte volume;
  byte brightness;
  char robotName[12];
};

Settings settings;

void resetSettings() {
  settings.magic = MAGIC;
  settings.volume = 5;
  settings.brightness = 128;
  strcpy(settings.robotName, "Robo");
  EEPROM.put(0, settings);
}

void show() {
  Serial.print("Name: ");
  Serial.print(settings.robotName);
  Serial.print("  Volume: ");
  Serial.print(settings.volume);
  Serial.print("  Brightness: ");
  Serial.println(settings.brightness);
}

void setup() {
  Serial.begin(9600);
  EEPROM.get(0, settings);  // load the whole struct in one go
  if (settings.magic != MAGIC) resetSettings();
  show();
  Serial.println("Commands: volume N, brightness N, name X, show, reset");
}

void loop() {
  if (!Serial.available()) return;
  String line = Serial.readStringUntil('\n');
  line.trim();

  if (line.startsWith("volume ")) {
    settings.volume = constrain(line.substring(7).toInt(), 0, 10);
  } else if (line.startsWith("brightness ")) {
    settings.brightness = constrain(line.substring(11).toInt(), 0, 255);
  } else if (line.startsWith("name ")) {
    // Copy at most 11 letters, leaving room for the end marker.
    strncpy(settings.robotName, line.substring(5).c_str(), sizeof(settings.robotName) - 1);
    settings.robotName[sizeof(settings.robotName) - 1] = '\0';
  } else if (line == "reset") {
    resetSettings();
  } else if (line != "show") {
    Serial.println("Unknown command");
    return;
  }
  EEPROM.put(0, settings);  // save after every change
  show();
}
