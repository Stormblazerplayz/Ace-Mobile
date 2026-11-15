// @title Control an LED from Your Phone (Bluetooth)
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; HC-05/HC-06 TXD to pin 10, RXD to pin 11 through a 1k/2k voltage divider, VCC 5V, GND; LED with 220 ohm resistor on pin 9. Use a Bluetooth terminal app on an Android phone.
// @keywords bluetooth led, hc-06 led control, phone turns on led, bluetooth terminal arduino
// @about Type 1 to turn the LED on, 0 to turn it off, or a letter a to j to set its brightness from your phone.

#include <SoftwareSerial.h>

SoftwareSerial bluetooth(10, 11);  // RX, TX
const int LED_PIN = 9;

void setup() {
  pinMode(LED_PIN, OUTPUT);
  bluetooth.begin(9600);
  bluetooth.println("Hi! Send 1 (on), 0 (off) or a to j (brightness).");
}

void loop() {
  if (!bluetooth.available()) return;
  char c = bluetooth.read();

  if (c == '1') {
    digitalWrite(LED_PIN, HIGH);
    bluetooth.println("LED on");
  } else if (c == '0') {
    digitalWrite(LED_PIN, LOW);
    bluetooth.println("LED off");
  } else if (c >= 'a' && c <= 'j') {
    int level = (c - 'a' + 1) * 25;  // a = 25 ... j = 250
    analogWrite(LED_PIN, level);
    bluetooth.print("Brightness ");
    bluetooth.println(level);
  }
  // Anything else (like the Enter key) is ignored.
}
