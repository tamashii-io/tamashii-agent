Device Setup
===

This page describes the connection of hardware supported by Tamashii Agent.
Following figure shows a typical Raspberry PI and pins on it. 

![Raspberry Pins](https://tamashii.io/images/devices/rpi_pins.png)

## Buzzers

### SFM-27-W buzzer via PWM

![PWM Buzzer](https://tamashii.io/images/devices/pwm_buzzer.jpg)

- Connect positive wire (the red one) to the PWM GPIO pin
    - Example in figure: pin 35 (GPIO 19)
    - The **GPIO number** (not the pin number) should be specify in the configuration
    ```ruby
    add_component :buzzer, 'Buzzer', device: 'PwmBuzzer', pin: 19
    ```
- Connect the negative wire (the black one) to the GND pin
    - Example in figure: pin 34 (GND)

## Card Readers

### MFRC522 via SPI

![MFRC522 SPI](https://tamashii.io/images/devices/mfrc522_spi.jpg)
- Connect corresponding pins from reader module to Raspberry PI
    - reader NSS to pin 24 (SPI0 CS0)
    - reader SCK to pin 23 (SPI0 SCLK)
    - reader MOSI to pin 19 (MOSI)
    - reader MISO to pin 21 (MISO)
    - reader GND to pin 20 (GND)
    - reader RST522 to pin 18 (GPIO 24)
        - The RESET pin
        - Could be changed in configuration
        ```ruby
        add_component :card_reader_mfrc, 'CardReader', device: 'Mfrc522Spi', reset_pin: 24
        ```
    - reader VIN to pin 4(5V PWR)

### PN532 via UART

![PN532 UART](https://tamashii.io/images/devices/pn532_uart.jpg)
- Connect corresponding pins from reader module to Raspberry PI
    - reader GND to pin 6 (GND)
    - reader VIN to pin 1 (3.3V PWR)
    - reader **TX** to pin 10 (UART0 **RX**)
    - reader **RX** to pin 8 (UART0 **TX**)
- On Raspberry 3 (Jessie), the Bluetooth module occupied the UART interface `/dev/ttyAMA0`. Before you using PN532 via UART, you need to disable Bluetooth first.
    - Disable serial console and enable serial hardware using `rasp-config`
        - `rasp-config` => `Interfacing Options` => `Serial`
        - Disable serial login shell
        - Enable serial port hardware
    - Disable Bluetooth
        - Add following line at the end of `/boot/config.txt`
            - This will also make `/dev/serial0` points to `/dev/ttyAMA0`
            ```
            dtoverlay=pi3-disable-bt
            ```
        - Disable Bluetooth services
            ```
            sudo systemctl stop hciuart
            sudo systemctl disable hciuart
            ```
    - Install `libnfc`, refer to [this page](https://www.raspberrypi.org/forums/viewtopic.php?t=78966)
        - We do not need the extra steps after `sudo make install`
    - Create or modify `libnfc` configuration file. Modify or create one of the following files:
        - `/etc/nfc/libnfc.conf`
            ```
            device.name = "PN532 board via UART"
            device.connstring = "pn532_uart:/dev/ttyAMA0"
            ``` 
        
        - or `/etc/nfc/devices.d/pn53x_uart.conf`
            ```
            name = "PN532 board via UART"
            connstring = pn532_uart:/dev/ttyAMA0
            ```


        
    - Remove `console=serial0` from `/boot/cmdline.txt`, if any.
    - Reboot
 

## LCDs

## LCM 1602 via I2C

![LCM602 I2C](https://tamashii.io/images/devices/lcm1602_i2c.jpg)

- Connect corresponding pins from lcd module to Raspberry PI
    - lcd GND to pin 9 (GND)
    - lcd VCC to pin 2 (5V PWR)
    - lcd SDA to pin 3 (SDA)
    - lcd SCL to pin 5 (SCL)
- Enable I2C interface on your Raspberry PI
    - Using `rasp-config` => `Interfacing Options` => `I2C`
    - If successful, you should able to see `/dev/i2c-1` under `/dev` on Raspberry PI 
