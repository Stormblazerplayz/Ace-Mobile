// @title LED Blinker Class (Many LEDs, No delay)
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; LEDs with 220 ohm resistors on pins 3, 4, 5 and 6.
// @keywords arduino class, millis class led, object oriented arduino, flasher class, many timers
// @about Makes a small Blinker class so each LED keeps its own on and off times, then runs four of them together.

class Blinker {
public:
  Blinker(int pin, unsigned long onMs, unsigned long offMs)
      : pin_(pin), onMs_(onMs), offMs_(offMs) {}

  void begin() {
    pinMode(pin_, OUTPUT);
  }

  // Call this as often as possible. It decides by itself if it is time to switch.
  void update() {
    unsigned long now = millis();
    unsigned long wait = on_ ? onMs_ : offMs_;
    if (now - lastChange_ >= wait) {
      on_ = !on_;
      digitalWrite(pin_, on_ ? HIGH : LOW);
      lastChange_ = now;
    }
  }

private:
  int pin_;
  unsigned long onMs_, offMs_;
  bool on_ = false;
  unsigned long lastChange_ = 0;
};

// Four objects from one class, each with its own timing.
Blinker leds[] = {
  Blinker(3, 100, 900),  // quick flash once a second
  Blinker(4, 500, 500),  // steady blink
  Blinker(5, 50, 150),   // fast flicker
  Blinker(6, 2000, 1000) // long on, short off
};

void setup() {
  for (Blinker &b : leds) b.begin();
}

void loop() {
  for (Blinker &b : leds) b.update();
}
