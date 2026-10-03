// Do Not Disturb desk traffic light: Seeed XIAO ESP32-C3 + 5 LEDs of WS2812B strip (60 LEDs/m), DIN on D1.
// The board makes no decisions. It only listens for single letters on USB serial,
// so you can change the rules on the computer side without reflashing.
//
//   R red   Y yellow   B blinking yellow   G green   O off   ? replies "traffic-light"
//
// Send the current letter about once a second as a heartbeat. If nothing arrives for 15 seconds,
// the light turns itself off, so it never gets stuck on an old color when the laptop sleeps,
// the sender crashes or the cable comes out.
//
// The strip runs up from the bottom: LEDs 0 / 2 / 4 sit behind green / yellow / red, 1 and 3 stay off.
// Build: arduino-cli compile --fqbn esp32:esp32:XIAO_ESP32C3 (USB CDC is on by default on this board.
// Don't add CDCOnBoot=cdc: on the XIAO that value turns it off.)
// Library: Adafruit NeoPixel. WiFi is never included, so it never starts.
#include <Adafruit_NeoPixel.h>

const int PIN = D1;   // not D0: D0 is GPIO2, a boot strapping pin, and a strip on it can stop the board from booting
const int N = 5;
const int GREEN = 0, YELLOW = 2, RED = 4;
const uint8_t BRIGHT = 60;              // 0-255
const unsigned long TIMEOUT_MS = 15000;

Adafruit_NeoPixel strip(N, PIN, NEO_GRB + NEO_KHZ800);
char mode = 'O';
unsigned long lastRx = 0;

void show(int idx, uint32_t color) {
  strip.clear();
  if (idx >= 0) strip.setPixelColor(idx, color);
  strip.show();
}

void render() {
  bool blinkOn = (millis() / 500) % 2 == 0;
  switch (mode) {
    case 'R': show(RED, strip.Color(255, 0, 0)); break;
    case 'Y': show(YELLOW, strip.Color(255, 140, 0)); break;
    case 'B': show(blinkOn ? YELLOW : -1, strip.Color(255, 140, 0)); break;
    case 'G': show(GREEN, strip.Color(0, 255, 40)); break;
    default:  show(-1, 0);
  }
}

void setup() {
  setCpuFrequencyMhz(80);
  Serial.begin(115200);
  strip.begin();
  strip.setBrightness(BRIGHT);
  // Power-on self test: green, yellow, red for half a second each, so you know right away the LEDs line up
  int order[3] = {GREEN, YELLOW, RED};
  uint32_t colors[3] = {strip.Color(0, 255, 40), strip.Color(255, 140, 0), strip.Color(255, 0, 0)};
  for (int i = 0; i < 3; i++) { show(order[i], colors[i]); delay(500); }
  show(-1, 0);
}

void loop() {
  while (Serial.available()) {
    char c = Serial.read();
    if (c == 'R' || c == 'Y' || c == 'B' || c == 'G' || c == 'O') { mode = c; lastRx = millis(); }
    else if (c == '?') Serial.println("traffic-light");   // handshake, to find which serial port is the light
  }
  if (mode != 'O' && millis() - lastRx > TIMEOUT_MS) mode = 'O';
  render();
  delay(20);
}
