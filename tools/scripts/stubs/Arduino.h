// Stub Arduino.h for syntax-checking sketches on a normal computer.
// It only declares things so g++ can check the code. It does not run anything.
#pragma once
#include <stdint.h>
#include <stddef.h>
#include <math.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

typedef uint8_t byte;
typedef bool boolean;
typedef unsigned int word;

#define HIGH 0x1
#define LOW 0x0
#define INPUT 0x0
#define OUTPUT 0x1
#define INPUT_PULLUP 0x2
#define LED_BUILTIN 13
#define DEC 10
#define HEX 16
#define OCT 8
#define BIN 2

#define CHANGE 1
#define FALLING 2
#define RISING 3
#define NOT_AN_INTERRUPT -1
#define digitalPinToInterrupt(p) ((p) == 2 ? 0 : ((p) == 3 ? 1 : NOT_AN_INTERRUPT))

#define LSBFIRST 0
#define MSBFIRST 1

#define PI 3.1415926535897932384626433832795
#define HALF_PI 1.5707963267948966192313216916398
#define TWO_PI 6.283185307179586476925286766559
#define DEG_TO_RAD 0.017453292519943295769236907684886
#define RAD_TO_DEG 57.295779513082320876798154814105

#define PROGMEM
#define pgm_read_byte(addr) (*(const uint8_t *)(addr))
#define pgm_read_word(addr) (*(const uint16_t *)(addr))

static const uint8_t A0 = 14;
static const uint8_t A1 = 15;
static const uint8_t A2 = 16;
static const uint8_t A3 = 17;
static const uint8_t A4 = 18;
static const uint8_t A5 = 19;
static const uint8_t SDA = 18;
static const uint8_t SCL = 19;
static const uint8_t SS = 10;
static const uint8_t MOSI = 11;
static const uint8_t MISO = 12;
static const uint8_t SCK = 13;

void pinMode(uint8_t pin, uint8_t mode);
void digitalWrite(uint8_t pin, uint8_t val);
int digitalRead(uint8_t pin);
int analogRead(uint8_t pin);
void analogWrite(uint8_t pin, int val);
void delay(unsigned long ms);
void delayMicroseconds(unsigned int us);
unsigned long millis();
unsigned long micros();
unsigned long pulseIn(uint8_t pin, uint8_t state, unsigned long timeout = 1000000UL);
unsigned long pulseInLong(uint8_t pin, uint8_t state, unsigned long timeout = 1000000UL);
void tone(uint8_t pin, unsigned int frequency, unsigned long duration = 0);
void noTone(uint8_t pin);
long map(long value, long fromLow, long fromHigh, long toLow, long toHigh);
long random(long howBig);
long random(long howSmall, long howBig);
void randomSeed(unsigned long seed);
void shiftOut(uint8_t dataPin, uint8_t clockPin, uint8_t bitOrder, uint8_t val);
uint8_t shiftIn(uint8_t dataPin, uint8_t clockPin, uint8_t bitOrder);
void attachInterrupt(uint8_t interruptNum, void (*userFunc)(void), int mode);
void detachInterrupt(uint8_t interruptNum);
void interrupts();
void noInterrupts();
void yield();

#ifndef constrain
#define constrain(amt, low, high) ((amt) < (low) ? (low) : ((amt) > (high) ? (high) : (amt)))
#endif
#ifndef min
#define min(a, b) ((a) < (b) ? (a) : (b))
#endif
#ifndef max
#define max(a, b) ((a) > (b) ? (a) : (b))
#endif
#ifndef abs
#define abs(x) ((x) > 0 ? (x) : -(x))
#endif
#define sq(x) ((x) * (x))
#define radians(deg) ((deg) * DEG_TO_RAD)
#define degrees(rad) ((rad) * RAD_TO_DEG)
#define lowByte(w) ((uint8_t)((w) & 0xff))
#define highByte(w) ((uint8_t)((w) >> 8))
#define bitRead(value, bit) (((value) >> (bit)) & 0x01)
#define bitSet(value, bit) ((value) |= (1UL << (bit)))
#define bitClear(value, bit) ((value) &= ~(1UL << (bit)))
#define bitWrite(value, bit, bitvalue) ((bitvalue) ? bitSet(value, bit) : bitClear(value, bit))
#define bit(b) (1UL << (b))

// F("text") keeps text in flash memory on a real board.
class __FlashStringHelper;
#define F(string_literal) (reinterpret_cast<const __FlashStringHelper *>(string_literal))

class String {
public:
  String(const char *s = "") { (void)s; }
  String(int v) { (void)v; }
  String(long v) { (void)v; }
  String(unsigned long v) { (void)v; }
  String(float v, unsigned int decimals = 2) { (void)v; (void)decimals; }
  const char *c_str() const { return ""; }
  unsigned int length() const { return 0; }
  void trim();
  void toLowerCase();
  void toUpperCase();
  long toInt() const;
  float toFloat() const;
  bool equals(const String &s) const;
  bool equalsIgnoreCase(const String &s) const;
  bool startsWith(const String &prefix) const;
  bool endsWith(const String &suffix) const;
  int indexOf(char ch) const;
  int indexOf(const String &s) const;
  String substring(unsigned int beginIndex) const;
  String substring(unsigned int beginIndex, unsigned int endIndex) const;
  char charAt(unsigned int index) const;
  char operator[](unsigned int index) const;
  bool operator==(const String &rhs) const;
  bool operator==(const char *rhs) const;
  bool operator!=(const String &rhs) const;
  bool operator!=(const char *rhs) const;
  String &operator+=(const String &rhs);
  String &operator+=(const char *rhs);
  String &operator+=(char c);
  friend String operator+(const String &lhs, const String &rhs);
  friend String operator+(const String &lhs, const char *rhs);
};

// Print is what Serial, LCDs and OLEDs share so they all have print() and println().
class Print {
public:
  virtual size_t write(uint8_t c) = 0;
  size_t write(const char *str);
  size_t write(const uint8_t *buffer, size_t size);
  size_t print(const __FlashStringHelper *s);
  size_t print(const char *s);
  size_t print(const String &s);
  size_t print(char c);
  size_t print(unsigned char n, int base = DEC);
  size_t print(int n, int base = DEC);
  size_t print(unsigned int n, int base = DEC);
  size_t print(long n, int base = DEC);
  size_t print(unsigned long n, int base = DEC);
  size_t print(double n, int digits = 2);
  size_t println();
  size_t println(const __FlashStringHelper *s);
  size_t println(const char *s);
  size_t println(const String &s);
  size_t println(char c);
  size_t println(unsigned char n, int base = DEC);
  size_t println(int n, int base = DEC);
  size_t println(unsigned int n, int base = DEC);
  size_t println(long n, int base = DEC);
  size_t println(unsigned long n, int base = DEC);
  size_t println(double n, int digits = 2);
};

// Stream adds reading on top of Print.
class Stream : public Print {
public:
  virtual int available() = 0;
  virtual int read() = 0;
  virtual int peek() = 0;
  void setTimeout(unsigned long timeout);
  long parseInt();
  float parseFloat();
  size_t readBytes(char *buffer, size_t length);
  size_t readBytesUntil(char terminator, char *buffer, size_t length);
  String readString();
  String readStringUntil(char terminator);
};

class SerialClass : public Stream {
public:
  void begin(unsigned long baud);
  void end();
  int available() override;
  int read() override;
  int peek() override;
  void flush();
  size_t write(uint8_t c) override;
  size_t write(unsigned long n);
  size_t write(long n);
  size_t write(unsigned int n);
  size_t write(int n);
  using Print::write;
  explicit operator bool() const { return true; }
};
extern SerialClass Serial;

// The real Arduino calls these for you.
void setup();
void loop();
