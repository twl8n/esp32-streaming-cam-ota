#!/bin/bash
arduino-cli upload -v -p /dev/cu.usbserial-210 --fqbn esp32:esp32:esp32cam --input-dir build/esp32.esp32.esp32cam


# Changing to esp32wrover does not work.
# A fatal error occurred: Unable to verify flash chip connection (Serial data stream stopped: Possible serial noise or corruption.).
# Failed uploading: uploading error: exit status 2

# arduino-cli upload -v -p /dev/cu.usbserial-210 --fqbn esp32:esp32:esp32wrover --input-dir build/esp32.esp32.esp32wrover
