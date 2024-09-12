#### A minimal ESP32 camera server with OTA (over the air) updates.

#### todo

- clean up test code, especially psram
x enable OTA 
  - arduino cli export compiled binary instead of -e which exports all build artifacts.
    like arduino ide sketch > export compiled binary
- if we use OTA, is the programmer shield necessary? (aside from supplying 5V via USB)
- can we add some html with status to the output stream, as both multipart stream and HTML?
  (Perhaps yes, using multiple http handlers like:
  ~/src/arduino-esp32/libraries/ESP32/examples/Camera/CameraWebServer/
- any point in websockets?
- (no) change to the esp32 being a wifi access point (AP)
- (not practical) advertise the esp32 via ZeroConf/bonjour or something? (if connected to the wifi LAN)
- are there any advantages to running freeRTOS? Like being able to run the camera on one core, and ota on the second core? 

#### command line OTA (over the air) wifi update?

Note that I'm using the arduino-cli. Text is more obvious, easier to document (I think), and easier to automate. All the arduino-cli commands have some equivalent in the Arduino IDE. My suggestion: learn to use Emacs, learn to use the command line, learn/use a good Linux/unix/BSD shell like zsh or bash. These examples are from a Mac, running zsh, but bash is close enough.

#### The OTA crash and solution

Adding OTA to CameraWebServer crashes when the OTA tries to update the ESP32. Here is the diagnosis and fix.

tldr;

Remove the file `partitions.csv` from the local folder, then compile with `--clean` and min_spiffs partitions.

```bash
arduino-cli compile --clean -v -e --no-color --fqbn esp32:esp32:esp32cam --build-property build.partitions=min_spiffs --build-property upload.maximum_size=3145728 .
```

#### Detailed explanation

The CameraWebServer example has a local file `partitions.csv` for unknown reasons. Perhaps to make room to save images or videos, or to emulate the `huge_app` partition. In any case, a local `partitions.csv` overrides build-property __and__ the compiler defaults to caching build artifacts (intermediate files created during compile and link).

- compile with `--clean` if you change --build-properties because some files are cached. This is true of partitions.csv

This copy of partitions.csv was cached, even after removing the local copy:

`/private/var/folders/2m/m49tydvj599cf1yv8nk7f82m0000gn/T/arduino/sketches/17A8CF01606570ED251909C235DA3B34/partitions.csv`

The BasicOTA sketch performed OTA when compiling with:

`--build-property build.partitions=min_spiffs --build-property upload.maximum_size=3145728`

```bash
arduino-cli compile -v -e --no-color --fqbn esp32:esp32:esp32cam --build-property build.partitions=min_spiffs --build-property upload.maximum_size=3145728 .
```

Interestingly, my camweb1 sketch was able to do OTA after successfully uploading BasicOTA to the ESP32. This suggested that the problem was in the build/configuration, not the code. OTA only change the .ino.bin, and not the entire filesystem on the ESP32.

The error below was caused by wrong partitions, then by cached partitions. Fix: use min_spiffs and compile with `--clean`

```bash
> ./ota-upload.sh
Uploading to specified board using network protocol requires the following info:
Password:
python3 "/Users/zeus/Library/Arduino15/packages/esp32/hardware/esp32/3.0.4/tools/espota.py" -r -i 192.168.1.238 -p 3232 --auth= -f "build/esp32.esp32.esp32cam/BasicOTA.ino.bin"
Sending invitation to 192.168.1.238
Uploading: [                                                            ] 0%
11:41:49 [ERROR]: Error Uploading: [Errno 54] Connection reset by peer
Failed uploading: uploading error: exit status 1
```

Suggest additional param for the compile command:
`--build-property build.custom_partitions=min_spiffs`

Might also need:
`--build-property upload.maximum_size=3145728`

where upload.maximum.size is from boards.txt
--

Note that the system min_spiffs.csv matches the partitions.csv in the arduino build artifacts folder. If your partitions.csv doesn't match min_spiffs.csv, then you aren't using min_spiffs partitioning, and OTA will probably crash.

```bash
> cat /Users/zeus/Library/Arduino15/packages/esp32/hardware/esp32/3.0.4/tools/partitions/min_spiffs.csv
# Name,   Type, SubType, Offset,  Size, Flags
nvs,      data, nvs,     0x9000,  0x5000,
otadata,  data, ota,     0xe000,  0x2000,
app0,     app,  ota_0,   0x10000, 0x1E0000,
app1,     app,  ota_1,   0x1F0000,0x1E0000,
spiffs,   data, spiffs,  0x3D0000,0x20000,
coredump, data, coredump,0x3F0000,0x10000,
```


```bash
> less /private/var/folders/2m/m49tydvj599cf1yv8nk7f82m0000gn/T/arduino/sketches/17A8CF01606570ED251909C235DA3B34/partitions.csv
# Name,   Type, SubType, Offset,  Size, Flags
nvs,      data, nvs,     0x9000,  0x5000,
otadata,  data, ota,     0xe000,  0x2000,
app0,     app,  ota_0,   0x10000, 0x1E0000,
app1,     app,  ota_1,   0x1F0000,0x1E0000,
spiffs,   data, spiffs,  0x3D0000,0x20000,
coredump, data, coredump,0x3F0000,0x10000,
```


https://github.com/sigmdel/ESP32-CAM_OTA

https://github.com/espressif/arduino-esp32/blob/master/boards.txt#L28071

The file platforms.txt in root (or local?) directory controls build config.


Local file partitions.csv probably overrides boards.txt.
~/src/arduino-esp32/libraries/ESP32/examples/Camera/CameraWebServer

```
> cat partitions.csv
# Name,   Type,  SubType, Offset,   Size,    Flags
nvs,      data,  nvs,     0x9000,   0x5000,
otadata,  data,  ota,     0xe000,   0x2000,
app0,     app,   ota_0,   0x10000,  0x3d0000,
fr,       data,        ,  0x3e0000, 0x20000,
```

After adding partitions.csv to sketch directory, `upload -v` is the same as always, so I think partitions.csv is being ignored. 

"/Users/zeus/Library/Arduino15/packages/esp32/tools/esptool_py/4.6/esptool" --chip esp32 --port "/dev/cu.usbserial-210" --baud 460800  --before default_reset --after hard_reset write_flash  -z --flash_mode keep --flash_freq keep --flash_size keep 0x1000 "build/esp32.esp32.esp32cam/camweb1.ino.bootloader.bin" 0x8000 "build/esp32.esp32.esp32cam/camweb1.ino.partitions.bin" 0xe000 "/Users/zeus/Library/Arduino15/packages/esp32/hardware/esp32/3.0.4/tools/partitions/boot_app0.bin" 0x10000 "build/esp32.esp32.esp32cam/camweb1.ino.bin"

starting ota update crashed:

Still crashing after using an esp32 example vs an esp8266 example 
2024-09-10 abort() was called at PC 0x40081c61 on core 1

2024-09-10 abort() was called at PC 0x40081c61 on core 1

Maybe. The ArduinoOTA function is listening on port 8266 (or any port you chose, just not port 80 if your sketch is running a web server). Your sketch and future sketches __must__ contain OTA boilerplate code, or the OTA will stop working.

Your sketch must call `ArduinoOTA.handle();` every interation. This won't usually impact performance (much?).

https://randomnerdtutorials.com/esp8266-ota-updates-with-arduino-ide-over-the-air/

~/src/arduino-esp32/libraries/ArduinoOTA/examples/BasicOTA/BasicOTA.ino
~/src/arduino-esp32/libraries/ArduinoOTA/src/ArduinoOTA.cpp

Possible arduino-cli examples:
arduino-cli upload --fqbn "esp8266:esp8266:nodemcuv2" --board-options "ip=lm6f" --protocol network --port "192.168.1.113" "OTA_Test"

arduino-cli upload mySketch.ino -b esp8266:esp8266:d1_mini -p IP_ADDRESS

Diagnose mdns issues:
~/.arduino15/packages/builtin/tools/mdns-discovery/1.0.9/mdns-discovery

This might be a command line OTA update app:
~/src/arduino-esp32/tools/espota.exe
~/src/arduino-esp32/tools/espota.py

Example:

https://steve.fi/hardware/ota-upload/

This is a working example of the OTA above, and requires that `ArduinoOTA.handle();` is called in the `loop()`.

Nice example of `espota.py`:

`python espota.py -d  -i 10.0.0.106 -f d1-helsinki-tram-times.ino.d1_mini.bin`

`python espota.py -d  -i <esp-ip-address> -f <.bin file generated by arduino-cli or IDE>`

https://github.com/skx/esp8266/blob/master/d1-helsinki-tram-times/d1-helsinki-tram-times.ino#L581

#### web ota via web browser not command line

Over the air updates, OTAWebUpdate, requires a web browser on the host computer. (As opposed to command line or python script as BasicOTA above.)

Compile and upload a web ota update the usual way (Arduino IDE, or arduino-cli) , add some web ota code to any sketch you want to upload, compile sketch and export binary, use a web browser to upload the binary. Web browser based, not command line (although maybe `curl` or `wget` could make it command line?).

A fairly clear explanation:

https://randomnerdtutorials.com/esp32-over-the-air-ota-programming/

A poor explanation:

~/src/arduino-esp32/docs/en/ota_web_update.rst

~/src/arduino-esp32/libraries/Update/examples/OTAWebUpdater/OTAWebUpdater.ino
~/src/arduino-esp32/libraries/Update/src/HttpsOTAUpdate.cpp


#### wifi soft access point

It might be as easy as the code snippet below. However, the desktop client won't be able to connect to this AP and to another wifi router at the same time. Since my use case is a unmanned ground vehicle (UGV) controlled via wifi from a computer, the whole UGV system would have to share the same access point. My first generation UGV is controlled via ssh to a RPi running arduino-cli monitor, and the UGV send video from multiple camera streaming through wifi. A soft AP makes no sense. 

What may make more sense is for the UGV to carry its own wifi router, and some micro controllers/micro computers make fine wifi routers.

~/src/arduino-esp32/libraries/WiFi/examples/WiFiAccessPoint

```C
#include <WiFi.h>
#include <WiFiAP.h>

const char *ssid = "yourAP";
const char *password = "yourPassword";

  if (!WiFi.softAP(ssid, password)) {
    log_e("Soft AP creation failed.");
    while (1);
  }
  IPAddress myIP = WiFi.softAPIP();
```

#### camera notes

Is it interesting that no matter how the camera is rotated, the image remains the same orientation?

The CAMERA_MODEL_AI_THINKER has psram:
Found psram, using UXGA framesize

arduino-cli compile -e --no-color --fqbn esp32:esp32:esp32cam .

arduino-cli compile -e --show-properties --no-color --fqbn esp32:esp32:esp32cam .

arduino-cli upload -v -p /dev/cu.usbserial-210 --fqbn esp32:esp32:esp32cam --input-dir build/esp32.esp32.esp32cam

add -v for verbose
Error during Upload: Unknown FQBN: getting build properties for board esp32:esp32:esp32cam: invalid option 'UploadSpeed'
--fqbn esp32:esp32:esp32cam:UploadSpeed=460800
esptool_py defaults to chaning the baud to 460800, so no point in trying to change the fqbn options

arduino-cli upload -v -p /dev/cu.usbserial-210 --fqbn esp32:esp32:esp32cam:UploadSpeed=460800 --input-dir build/esp32.esp32.esp32cam

does 460800 work for monitor?
arduino-cli monitor -p /dev/cu.usbserial-210 --config 460800 -b esp32:esp32:esp32cam

# random cli notes

Change baud rate to 460800 which is supported by the esp32.

https://github.com/arduino/arduino-cli/issues/824
So the correct FQBN is esp32:esp32:esp32:UploadSpeed=115200.

menu.EraseFlash.all=Enabled
menu.EraseFlash.all.upload.erase_cmd=-e
menu.EraseFlash.none=Disabled
menu.EraseFlash.none.upload.erase_cmd=

tools.esptool_py.program.pattern_args=--chip esp32 --port "{serial.port}" --baud 460800  --before default_reset --after hard_reset write_flash -z --flash_mode keep --flash_freq keep --flash_size keep 0x10000 "/private/var/folders/2m/m49tydvj599cf1yv8nk7f82m0000gn/T/arduino/sketches/17A8CF01606570ED251909C235DA3B34/camweb1.ino.bin"

tools.esptool_py.upload.network_pattern={network_cmd} -i "{serial.port}" -p "{network.port}" "--auth={network.password}" -f "/private/var/folders/2m/m49tydvj599cf1yv8nk7f82m0000gn/T/arduino/sketches/17A8CF01606570ED251909C235DA3B34/camweb1.ino.bin"


"/Users/zeus/Library/Arduino15/packages/esp32/tools/esptool_py/4.6/esptool" --chip esp32 --port "/dev/cu.usbserial-210" --baud 460800  --before default_reset --after hard_reset write_flash  -z --flash_mode keep --flash_freq keep --flash_size keep 0x1000 "build/esp32.esp32.esp32cam/camweb1.ino.bootloader.bin" 0x8000 "build/esp32.esp32.esp32cam/camweb1.ino.partitions.bin" 0xe000 "/Users/zeus/Library/Arduino15/packages/esp32/hardware/esp32/3.0.4/tools/partitions/boot_app0.bin" 0x10000 "build/esp32.esp32.esp32cam/camweb1.ino.bin"

It might be possible to only write fewer files to flask, like only camweb1.ino.bin, but I never tried it. 
Besides, the .ino.bin is the largest and slowest write:
"/Users/zeus/Library/Arduino15/packages/esp32/tools/esptool_py/4.6/esptool" --chip esp32 --port "/dev/cu.usbserial-210" --baud 460800  --before default_reset --after hard_reset write_flash  -z --flash_mode keep --flash_freq keep --flash_size keep 0x10000 "build/esp32.esp32.esp32cam/camweb1.ino.bin"

--no-stub             Disable launching the flasher stub, only talk to ROM bootloader. Some features will not be available.

https://stackoverflow.com/questions/65749587/what-does-stub-mean-in-the-context-of-esp32-and-esptool-option-no-stub

Using --no-stub you will be using the original ESP32 bootloader, which is known to be slower at flashing the program and at some other operations. There are some commands which can only be used in the esptool bootloader, but if you are not using any optional commands to boot your code, it is safe to use --no-stub


usage: esptool [-h]
               [--chip {auto,esp8266,esp32,esp32s2,esp32s3beta2,esp32s3,esp32c3,esp32c6beta,esp32h2beta1,esp32h2beta2,esp32c2,esp32c6,esp32h2}]
               [--port PORT] [--baud BAUD] [--before {default_reset,usb_reset,no_reset,no_reset_no_sync}]
               [--after {hard_reset,soft_reset,no_reset,no_reset_stub}] [--no-stub] [--trace] [--override-vddsdio [{1.8V,1.9V,OFF}]]
               [--connect-attempts CONNECT_ATTEMPTS]
               {load_ram,dump_mem,read_mem,write_mem,write_flash,run,image_info,make_image,elf2image,read_mac,chip_id,flash_id,read_flash_status,write_flash_status,read_flash,verify_flash,erase_flash,erase_region,merge_bin,get_security_info,version}


# camera settings from the camerawebserver app

framesize_t frame_size;         /*!< Size of the output image: FRAMESIZE_ + QVGA|CIF|VGA|SVGA|XGA|SXGA|UXGA  */
int jpeg_quality;               /*!< Quality of JPEG output. 0-63 lower means higher quality  */
size_t fb_count;                /*!< Number of frame buffers to be allocated. If more than one, then each frame will be acquired (double speed)  */

resolution vga 640x480
quality 4
brightness 0 or +1
contrast 0
saturation 0
awb off
awb gain off
exposure 600 (0 to 1200)
ae level 0
agc off
gain 5x
wpc on
raw gma on
lens correction on
led intensity 0

window
sensor resolution uxga 1600x1200
    x y 
offset 400 300
window size 800 600
output size 320 240


-- 

Eventually run as AP, maybe websockets over AP:

https://github.com/Links2004/arduinoWebSockets/blob/master/examples/esp32/WebSocketServer/WebSocketServer.ino

https://techtutorialsx.com/2017/11/03/esp32-arduino-websocket-server-over-soft-ap/

--

#### more than you wanted to know about esp32 wifi

https://randomnerdtutorials.com/esp32-useful-wi-fi-functions-arduino/

WIFI_STA station mode, the ESP32 connects to access point aka wifi router
WIFI_AP	access point mode, other stations can connect to the ESP32
WIFI_AP_STA access point and a station can connect to a second access point

I'd guess that WIFI_STA is the default.

```C
WiFi.mode(WIFI_STA);
```
