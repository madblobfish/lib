#!/usr/bin/python3

# original by: Henryk Plötz
# https://hackaday.io/project/5301-reverse-engineering-a-low-cost-usb-co-monitor/log/17909-all-your-base-are-belong-to-us
#
# udev rules example to detect and gain access to the devices:
#   ACTION=="remove", GOTO="co2mini_end"
#   SUBSYSTEMS=="usb", KERNEL=="hidraw*", ATTRS{idVendor}=="04d9", ATTRS{idProduct}=="a052", GROUP="YOU", MODE="0660", SYMLINK+="co2mini%n", GOTO="co2mini_end"
#   LABEL="co2mini_end"
import sys, fcntl, time

with open(sys.argv[1], mode="rb", buffering=0) as fp:
    fcntl.ioctl(fp, 0xC0094806, b"\x00"*9)
    while True:
        data = fp.read(8)
        value = int.from_bytes(data[1:3])

        match data[0]:
            case 0x42:
                print(f'co2sensor temperature={value / 16.0 - 273.15}')
            case 0x44 | 0x41:
                print(f'co2sensor humidity={value}')
            case 0x50:
                print(f'co2sensor co2={value}')
