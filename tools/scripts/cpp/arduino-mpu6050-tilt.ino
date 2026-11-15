// @title MPU6050 Tilt Angles (No Library)
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; MPU6050 VCC to 5V, GND to GND, SDA to A4, SCL to A5; open Serial Monitor at 9600.
// @keywords mpu6050, accelerometer arduino, gy-521, tilt angle pitch roll, gyroscope sensor
// @about Talks to an MPU6050 over I2C and works out how much it is tilted forward and sideways.

#include <Wire.h>

const int MPU_ADDRESS = 0x68;

void setup() {
  Serial.begin(9600);
  Wire.begin();
  // Wake the chip up: write 0 to the power register (0x6B).
  Wire.beginTransmission(MPU_ADDRESS);
  Wire.write(0x6B);
  Wire.write(0);
  Wire.endTransmission();
}

// Reads two bytes and joins them into one signed number.
int16_t read16() {
  uint16_t high = Wire.read();  // unsigned, so shifting it left is safe
  uint16_t low = Wire.read();
  return (int16_t)((high << 8) | low);
}

void loop() {
  // Start reading at the accelerometer register (0x3B): 6 bytes for X, Y, Z.
  Wire.beginTransmission(MPU_ADDRESS);
  Wire.write(0x3B);
  Wire.endTransmission(false);
  Wire.requestFrom(MPU_ADDRESS, 6);
  if (Wire.available() < 6) {
    Serial.println("MPU6050 not found, check wires");
    delay(500);
    return;
  }

  float ax = read16() / 16384.0;  // 16384 = 1 g on the default setting
  float ay = read16() / 16384.0;
  float az = read16() / 16384.0;

  // Gravity always points down, so its direction tells us the tilt.
  float pitch = atan2(ax, sqrt(ay * ay + az * az)) * RAD_TO_DEG;
  float roll = atan2(ay, az) * RAD_TO_DEG;

  Serial.print("Pitch: ");
  Serial.print(pitch, 1);
  Serial.print("  Roll: ");
  Serial.println(roll, 1);
  delay(100);
}
