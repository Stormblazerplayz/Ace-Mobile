// @title Keypad Password Lock
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "Keypad"; keypad rows to pins 9, 8, 7, 6 and columns to 5, 4, 3, 2; servo on pin 10; buzzer on A0; open Serial Monitor at 9600.
// @keywords keypad password, keypad door lock, secret code lock, pin code arduino, servo lock keypad
// @about Opens a servo lock when you type the secret code and press #, and buzzes for a wrong code.

#include <Keypad.h>
#include <Servo.h>

const byte ROWS = 4;
const byte COLS = 4;
char keys[ROWS][COLS] = {
  {'1', '2', '3', 'A'}, {'4', '5', '6', 'B'}, {'7', '8', '9', 'C'}, {'*', '0', '#', 'D'}
};
byte rowPins[ROWS] = {9, 8, 7, 6};
byte colPins[COLS] = {5, 4, 3, 2};
Keypad keypad = Keypad(makeKeymap(keys), rowPins, colPins, ROWS, COLS);

Servo lock;
const int BUZZER_PIN = A0;
const char SECRET[] = "1234";  // change me!
char typed[9];                 // up to 8 keys plus the end marker
byte typedCount = 0;

void setup() {
  lock.attach(10);
  lock.write(0);
  pinMode(BUZZER_PIN, OUTPUT);
  Serial.begin(9600);
  Serial.println("Type the code, then press #. Press * to clear.");
}

void loop() {
  char key = keypad.getKey();
  if (key == NO_KEY) return;
  tone(BUZZER_PIN, 1500, 40);  // little click for every key

  if (key == '*') {
    typedCount = 0;
    Serial.println("Cleared");
  } else if (key == '#') {
    typed[typedCount] = '\0';  // finish the text
    if (strcmp(typed, SECRET) == 0) {
      Serial.println("Correct! Unlocked for 5 seconds.");
      lock.write(90);
      delay(5000);
      lock.write(0);
    } else {
      Serial.println("Wrong code!");
      tone(BUZZER_PIN, 200, 800);
    }
    typedCount = 0;
  } else if (typedCount < 8) {
    typed[typedCount++] = key;
    Serial.print('*');  // show stars, not the real keys
  }
}
