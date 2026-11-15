// Stub Arduino.h for syntax-checking sketches on a normal computer.
// It only declares things so g++ can check the code. It does not run anything.
#pragma once
#include <stdint.h>
#include <stddef.h>
#include <math.h>
#include <string.h>

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
#define BIN 2

static const uint8_t A0 = 14;
static const uint8_t A1 = 15;
static const uint8_t A2 = 16;
static const uint8_t A3 = 17;
static const uint8_t A4 = 18;
static const uint8_t A5 = 19;

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
void tone(uint8_t pin, unsigned int frequency, unsigned long duration = 0);
void noTone(uint8_t pin);
long map(long value, long fromLow, long fromHigh, long toLow, long toHigh);
long random(long howBig);
long random(long howSmall, long howBig);
void randomSeed(unsigned long seed);

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

class String {
public:
  String(const char *s = "") { (void)s; }
  String(int v) { (void)v; }
  String(long v) { (void)v; }
  String(unsigned long v) { (void)v; }
  String(float v, unsigned int decimals = 2) { (void)v; (void)decimals; }
  const char *c_str() const { return ""; }
  unsigned int length() const { return 0; }
};

class SerialClass {
public:
  void begin(unsigned long baud);
  void end();
  int available();
  int read();
  void flush();
  explicit operator bool() const { return true; }
  size_t print(const char *s);
  size_t print(const String &s);
  size_t print(char c);
  size_t print(int n, int base = DEC);
  size_t print(unsigned int n, int base = DEC);
  size_t print(long n, int base = DEC);
  size_t print(unsigned long n, int base = DEC);
  size_t print(double n, int digits = 2);
  size_t println();
  size_t println(const char *s);
  size_t println(const String &s);
  size_t println(char c);
  size_t println(int n, int base = DEC);
  size_t println(unsigned int n, int base = DEC);
  size_t println(long n, int base = DEC);
  size_t println(unsigned long n, int base = DEC);
  size_t println(double n, int digits = 2);
};
extern SerialClass Serial;

// The real Arduino calls these for you.
void setup();
void loop();
