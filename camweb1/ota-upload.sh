#!/bin/bash
# 192.168.1.238
# esp32-6C725C.home
# Can't change the ip port with the arduino-cli command.
arduino-cli upload -v --protocol network -p 192.168.1.238  --fqbn esp32:esp32:esp32cam --input-dir build/esp32.esp32.esp32cam

# Can change the ip port with espota.py
# python3 "/Users/zeus/Library/Arduino15/packages/esp32/hardware/esp32/3.0.4/tools/espota.py" -r -i 192.168.1.238 -p 8266 --auth= -f "build/esp32.esp32.esp32cam/camweb1.ino.bin"

# python3 "/Users/zeus/Library/Arduino15/packages/esp32/hardware/esp32/3.0.4/tools/espota.py" -r -i 192.168.1.238 -p 3232 --auth= -f "build/esp32.esp32.esp32cam/camweb1.ino.bin"
