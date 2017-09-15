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
    - The **GPIO number** (not the pin number) should be specify in the configuration using `pin`
- Connect the negative wire (the black one) to the GND pin
    - Example in figure: pin 34 (GND)
- Add following line to your Tamashii Agent configuration file: 
```ruby
add_component :buzzer, 'Buzzer', device: 'PwmBuzzer', pin: 19
```
- Restart Tamashii Agent

## Card Readers

### MFRC522 via SPI

![MFRC522 SPI](https://tamashii.io/images/devices/mfrc522_spi.jpg)
- Make sure your MFRC522 is configured to use SPI interface
- Connect corresponding pins from reader module to Raspberry PI
    - reader NSS to pin 24 (SPI0 CS0)
    - reader SCK to pin 23 (SPI0 SCLK)
    - reader MOSI to pin 19 (MOSI)
    - reader MISO to pin 21 (MISO)
    - reader GND to any GND pin (pin 20 for example)
    - reader RST522 to pin 18 (GPIO 24)
        - The RESET pin
        - Could be changed in configuration using `reset_pin`
    - reader VIN to any 5V PWR pin (pin 4 for example)
- Add following line to your Tamashii Agent configuration file: 
```ruby
add_component :card_reader_mfrc, 'CardReader', device: 'Mfrc522Spi', reset_pin: 24
```
- Restart Tamashii Agent

### PN532 via UART

![PN532 UART](https://tamashii.io/images/devices/pn532_uart.jpg)
- Make sure your PN532 is configured to use UART (or HSU, High Speed UART) interface
- Connect corresponding pins from reader module to Raspberry PI
    - reader GND to any GND pin (pin 6 for example)
    - reader VIN to any 3.3V PWR pin (pin 1 for example)
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
    - Check whether your PN532 works by using `nfc-list`
- Add following line to your Tamashii Agent configuration file: 
```ruby
add_component :card_reader_felica_uart, 'CardReader', device: 'Pn532Uart', path: "/dev/ttyAMA0"
```
- Restart Tamashii Agent

    
#### PN532 via UART to USB adapter

![UART to USB](https://tamashii.io/images/devices/uart_to_usb_adapter.jpg)


If you have the UART to USB adapter in this case, the setup is much simpler. You don't need to disable Bluetooth described in the previous section. Instead, after setup serial via `rasp-config` and install `libnfc`, you have to do the following step: 

- Attach yout PN532 to the UART-to-USB adapter
    - reader GND to USB GND
    - reader VCC to USB 5V
    - reader **TX** to USB **RXD**
    - reader **RX** to USB **TXD**
- Plug it into the USB port on your Raspberry PI. 
- Find out the USB device name of your PN532. If it is the only USB device on your Raspberry PI, it should be `/dev/ttyUSB0`. You can find more information by executing command `dmesg`
- Create or modify `libnfc` configuration file. Modify or create one of the following files (assume your device is at `/dev/ttyUSB0`. Modify it to match your need):
    - `/etc/nfc/libnfc.conf`
        ```
        device.name = "PN532 board via USB"
        device.connstring = "pn532_uart:/dev/ttyUSB0"
        ``` 

    - or `/etc/nfc/devices.d/pn53x_usb.conf`
        ```
        name = "PN532 board via USB
        connstring = pn532_uart:/dev/ttyUSB0
        ```
- Reboot
- Check whether your PN532 works by using `nfc-list`
- Add following line to your Tamashii Agent configuration file: 
```ruby
add_component :card_reader_felica_usb, 'CardReader', device: 'Pn532Uart', path: "/dev/ttyUSB0"
```
- Restart Tamashii Agent


## Keyboards

### 8/16-Way TTP229 Capacitive Touch Sensor via GPIO

![TTP 229](https://tamashii.io/images/devices/ttp229_gpio.jpg)

> Note: the 16-key functionality in 16-way TTP229 is disabled by default. You need to attach a jumper wire between P1/3 and P1/6 like following figure:
![TTP229 connection](https://raw.githubusercontent.com/tamashii-io/tamashii-io.github.io/master/images/devices/TTP229_connection.png)

- Connect corresponding pins from TTP229 module to Raspberry PI:
    - TTP229 VCC to any 3.3V PWR pin (pin 1 for example)
    - TTP229 GND to any GND pin (pin 14 for example)
    - TTP229 SCL to pin 11 (GPIO 17)
    - TTP229 SDO to pin 7 (GPIO 4)
- Add following line to your Tamashii Agent configuration file. Change the `number_of_keys` to match your need.
```ruby
add_component :kb_touch, 'KeyboardLogger', device: 'TTP229Serial', number_of_keys: 16
```
- Restart Tamashii Agent



### 4x4 Button Matrix via GPIO (8 pins)

![Button Matrix 4x4](https://tamashii.io/images/devices/button_matrix_4x4.jpg)

- The button matrix requires 8 arbitrary GPIO pins on your device. 4 pins for generating **row output** from PI to button matrix and 4 pins for receiving **column input** from button matrix. 
- Choose 4 GPIO pins for row output (assume GPIO 21, 20, 16, 12 for row 0 to row 3). Connect these pins from PI to button matrix **in order**. 
    - GPIO 21 (pin 40) to the 1st pin on matrix
    - GPIO 20 (pin 38) to the 2nd pin on matrix
    - GPIO 16 (pin 36) to the 3rd pin on matrix
    - GPIO 12 (pin 42) to the 4th pin on matrix
- Choose 4 GPIO pins for column input (assume GPIO 26, 19, 13, 6 for column 0 to column 3). Connect these pins from PI to button matrix **in order**. 
    - GPIO 26 (pin 37) to the 5th pin on matrix
    - GPIO 19 (pin 35) to the 6th pin on matrix
    - GPIO 13 (pin 33) to the 7th pin on matrix
    - GPIO 6 (pin 31) to the 8th pin on matrix
- Add following line to your Tamashii Agent configuration file: 
```ruby
add_component :kb_button, 'KeyboardLogger', device: 'ButtonMatrix4x4', row_pins: [21, 20, 16, 12], col_pins: [26, 19, 13, 6]
```
- Restart Tamashii Agent


## LCDs

### LCM 1602 via I2C

![LCM602 I2C](https://tamashii.io/images/devices/lcm1602_i2c.jpg)

- Make sure your LCM 1602 has bundled with the I2C adapter
- Connect corresponding pins from lcd module to Raspberry PI
    - lcd GND to any GND pin (pin 9 for example)
    - lcd VCC to any 5V PWR pin (pin 2 for example)
    - lcd SDA to pin 3 (SDA)
    - lcd SCL to pin 5 (SCL)
- Enable I2C interface on your Raspberry PI
    - Using `rasp-config` => `Interfacing Options` => `I2C`, then reboot
    - If successful, you should able to see `/dev/i2c-1` under `/dev` on Raspberry PI.
- Add following line to your Tamashii Agent configuration file: 
```ruby
add_component :lcd, 'Lcd', device: 'Lcm1602I2c'
```
- Restart Tamashii Agent
