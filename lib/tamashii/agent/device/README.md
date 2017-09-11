Device Setup
===

This page describes the connection of hardware supported by Tamashii Agent.
Following figure shows a typical Raspberry PI and pins on it. 

![Raspberry Pins](https://tamashii.io/images/devices/rpi_pins.png)

## Buzzers

### PWM buzzer

![PWM Buzzer](https://tamashii.io/images/devices/pwm_buzzer.jpg)

- connect one wire to the PWM GPIO pin
    - Example in figure: pin 35(GPIO 19)
    - The **GPIO number** (not the pin number) should be specify in the configuration
    ```ruby
    add_component :buzzer, 'Buzzer', device: 'PwmBuzzer', pin: 19
    ```
- connect the other wire to the GND pin
    - Example in figure: pin 34(GND)

## Card Readers

### MFRC522 via SPI

![MFRC522 SPI](https://tamashii.io/images/devices/mfrc522_spi.jpg)
- connect corresponding pins from reader module to Raspberry PI
    - reader NSS to pin 24(SPI0 CS0)
    - reader SCK to pin 23(SPI0 SCLK)
    - reader MOSI to pin 19(MOSI)
    - reader MISO to pin 21(MISO)
    - reader GND to pin 20(GND)
    - reader RST522 to pin 18(GPIO 24)
        - This pin is used to reset the reader
        - Could be changed in configuration
        ```ruby
        add_component :card_reader_mfrc, 'CardReader', device: 'Mfrc522Spi', reset_pin: 24
        ```
    - reader VIN to pin 4(5V PWR)

### PN532 via UART

![PN532 UART](https://tamashii.io/images/devices/pn532_uart.jpg)
- connect corresponding pins from reader module to Raspberry PI
    - reader GND to pin 6(GND)
    - reader VIN to pin 1(3.3V PWR)
    - reader **TX** to pin 10(UART0 **RX**)
    - reader **RX** to pin 8(UART0 **TX**)

## LCDs

## LCM 1602 via I2C
