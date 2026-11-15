// Stub MFRC522.h (miguelbalboa's RFID library) for syntax checks. Declarations only.
#pragma once
#include "Arduino.h"

class MFRC522 {
public:
  enum StatusCode : byte { STATUS_OK, STATUS_ERROR, STATUS_COLLISION, STATUS_TIMEOUT };
  typedef struct {
    byte size;
    byte uidByte[10];
    byte sak;
  } Uid;
  Uid uid;
  MFRC522(byte chipSelectPin, byte resetPowerDownPin);
  void PCD_Init();
  void PCD_DumpVersionToSerial();
  bool PICC_IsNewCardPresent();
  bool PICC_ReadCardSerial();
  StatusCode PICC_HaltA();
  void PCD_StopCrypto1();
};
