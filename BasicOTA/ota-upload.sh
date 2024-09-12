#!/bin/bash
# 192.168.1.238
# esp32-6C725C.home
# Can't change the ip port with the arduino-cli command.
# The sketch correctly defaults to ip port 3232.
arduino-cli upload -v --protocol network -p 192.168.1.238  --fqbn esp32:esp32:esp32cam --input-dir build/esp32.esp32.esp32cam

