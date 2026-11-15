// @title RFID Card Reader (RC522)
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; install "MFRC522"; RC522 SDA to 10, SCK to 13, MOSI to 11, MISO to 12, RST to 9, 3.3V to 3.3V (not 5V!), GND; open Serial Monitor at 9600.
// @keywords rfid reader, rc522, mfrc522, read rfid card uid, arduino rfid tag
// @about Prints the ID number of any RFID card or key tag you hold near the reader.

#include <SPI.h>
#include <MFRC522.h>

const int SS_PIN = 10;
const int RST_PIN = 9;
MFRC522 rfid(SS_PIN, RST_PIN);

void setup() {
  Serial.begin(9600);
  SPI.begin();
  rfid.PCD_Init();
  Serial.println("Hold a card near the reader...");
}

void loop() {
  // Wait for a new card and read its ID.
  if (!rfid.PICC_IsNewCardPresent()) return;
  if (!rfid.PICC_ReadCardSerial()) return;

  Serial.print("Card ID:");
  for (byte i = 0; i < rfid.uid.size; i++) {
    Serial.print(rfid.uid.uidByte[i] < 0x10 ? " 0" : " ");  // add a leading 0
    Serial.print(rfid.uid.uidByte[i], HEX);
  }
  Serial.println();

  rfid.PICC_HaltA();  // tell the card we are done
  rfid.PCD_StopCrypto1();
}
