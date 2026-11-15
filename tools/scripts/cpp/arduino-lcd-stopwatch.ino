// @title LCD Stopwatch with Lap Times
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "LiquidCrystal I2C"; LCD SDA A4, SCL A5; start/stop button pin 2 to GND; lap/reset button pin 3 to GND.
// @keywords lcd stopwatch, stopwatch with laps, arduino stopwatch buttons, race timer
// @about A stopwatch showing minutes, seconds and hundredths, with a lap time on the second line.

#include <Wire.h>
#include <LiquidCrystal_I2C.h>

LiquidCrystal_I2C lcd(0x27, 16, 2);
const int START_STOP = 2, LAP_RESET = 3;

bool running = false;
unsigned long startTime = 0;  // when we pressed start
unsigned long saved = 0;      // time counted before the last stop
bool lastStart = HIGH, lastLap = HIGH;

unsigned long elapsed() {
  return running ? saved + (millis() - startTime) : saved;
}

void printTime(unsigned long ms) {
  unsigned long minutes = ms / 60000;
  unsigned long seconds = (ms / 1000) % 60;
  unsigned long hundredths = (ms / 10) % 100;
  if (minutes < 10) lcd.print('0');
  lcd.print(minutes);
  lcd.print(':');
  if (seconds < 10) lcd.print('0');
  lcd.print(seconds);
  lcd.print('.');
  if (hundredths < 10) lcd.print('0');
  lcd.print(hundredths);
}

void setup() {
  pinMode(START_STOP, INPUT_PULLUP);
  pinMode(LAP_RESET, INPUT_PULLUP);
  lcd.init();
  lcd.backlight();
}

void loop() {
  bool start = digitalRead(START_STOP), lap = digitalRead(LAP_RESET);

  if (start == LOW && lastStart == HIGH) {
    if (running) saved = elapsed();  // stopping: remember the time
    else startTime = millis();       // starting: note the start moment
    running = !running;
    delay(20);
  }
  if (lap == LOW && lastLap == HIGH) {
    if (running) {  // while running: show a lap time
      lcd.setCursor(0, 1);
      lcd.print("Lap ");
      printTime(elapsed());
    } else {        // while stopped: reset everything
      saved = 0;
      lcd.clear();
    }
    delay(20);
  }
  lastStart = start;
  lastLap = lap;

  lcd.setCursor(0, 0);
  lcd.print(running ? "RUN  " : "STOP ");
  printTime(elapsed());
  delay(30);
}
