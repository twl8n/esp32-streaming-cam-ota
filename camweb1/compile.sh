#!/bin/bash

# ota still wasn't not working
# try again, maybe sketch was using outdated esp8266 code
arduino-cli compile --clean --dump-profile -v -e --no-color --fqbn esp32:esp32:esp32cam --build-property build.partitions=min_spiffs --build-property upload.maximum_size=3145728 .

# arduino-cli compile -e --no-color --fqbn esp32:esp32:esp32cam .

# does not work
# esp32wrover
# arduino-cli compile -e --no-color --fqbn esp32:esp32:esp32wrover .

# Sketch uses 1074213 bytes (34%) of program storage space. Maximum is 3145728 bytes.
# Global variables use 61632 bytes (18%) of dynamic memory, leaving 266048 bytes for local variables. Maximum is 327680 bytes.


# with custom_partitions only:
# Sketch uses 1074213 bytes (34%) of program storage space. Maximum is 3145728 bytes.
# Global variables use 61632 bytes (18%) of dynamic memory, leaving 266048 bytes for local variables. Maximum is 327680 bytes.

# using the ide
# Sketch uses 1074309 bytes (54%) of program storage space. Maximum is 1966080 bytes.
# Global variables use 61632 bytes (18%) of dynamic memory, leaving 266048 bytes for local variables. Maximum is 327680 bytes.
