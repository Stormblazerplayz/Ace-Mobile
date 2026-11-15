// Stub IRremote.hpp (Armin Joachimsmeyer's IRremote library, version 4) for syntax checks.
#pragma once
#include "Arduino.h"

#define ENABLE_LED_FEEDBACK true
#define DISABLE_LED_FEEDBACK false
#define USE_DEFAULT_FEEDBACK_LED_PIN 0
#define IRDATA_FLAGS_IS_REPEAT 0x01

typedef enum {
  UNKNOWN = 0, PULSE_WIDTH, PULSE_DISTANCE, APPLE, DENON, JVC, LG, LG2, NEC, NEC2, ONKYO,
  PANASONIC, KASEIKYO, KASEIKYO_DENON, KASEIKYO_SHARP, KASEIKYO_JVC, KASEIKYO_MITSUBISHI,
  RC5, RC6, SAMSUNG, SAMSUNG48, SAMSUNG_LG, SHARP, SONY
} decode_type_t;

typedef uint32_t IRRawDataType;

struct IRData {
  decode_type_t protocol;
  uint16_t address;
  uint16_t command;
  uint16_t extra;
  IRRawDataType decodedRawData;
  uint8_t flags;
};

class IRrecv {
public:
  void begin(uint_fast8_t aReceivePin, bool aEnableLEDFeedback = false,
             uint_fast8_t aFeedbackLEDPin = USE_DEFAULT_FEEDBACK_LED_PIN);
  bool decode();
  void resume();
  void printIRResultShort(Print *aSerial, bool aCheckForRecordGapsMicros = true);
  IRData decodedIRData;
};
extern IRrecv IrReceiver;
