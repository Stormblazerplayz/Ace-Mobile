// @title RFID Door Lock with a Servo
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; RC522 wired as SDA 10, SCK 13, MOSI 11, MISO 12, RST 9, 3.3V, GND; servo on pin 6; green LED pin 4, red LED pin 5. Put your card's ID (from the reader sketch) in MY_CARD.
// @keywords rfid door lock, rfid servo lock, access control arduino, key card lock
// @about Unlocks a servo latch for 3 seconds when the right RFID card is scanned and flashes red for wrong ones.

#include <SPI.h>
#include <MFRC522.h>
#include <Servo.h>

MFRC522 rfid(10, 9);
Servo lock;
const int GREEN_LED = 4;
const int RED_LED = 5;

// Change these 4 numbers to your card's ID.
const byte MY_CARD[4] = {0xDE, 0xAD, 0xBE, 0xEF};

bool isMyCard() {
  if (rfid.uid.size != 4) return false;
  for (byte i = 0; i < 4; i++) {
    if (rfid.uid.uidByte[i] != MY_CARD[i]) return false;
  }
  return true;
}

void setup() {
  SPI.begin();
  rfid.PCD_Init();
  lock.attach(6);
  lock.write(0);  // 0 = locked
  pinMode(GREEN_LED, OUTPUT);
  pinMode(RED_LED, OUTPUT);
}

void loop() {
  if (!rfid.PICC_IsNewCardPresent() || !rfid.PICC_ReadCardSerial()) return;

  if (isMyCard()) {
    digitalWrite(GREEN_LED, HIGH);
    lock.write(90);  // unlock
    delay(3000);
    lock.write(0);   // lock again
    digitalWrite(GREEN_LED, LOW);
  } else {
    for (int i = 0; i < 3; i++) {
      digitalWrite(RED_LED, HIGH);
      delay(150);
      digitalWrite(RED_LED, LOW);
      delay(150);
    }
  }
  rfid.PICC_HaltA();
  rfid.PCD_StopCrypto1();
}
