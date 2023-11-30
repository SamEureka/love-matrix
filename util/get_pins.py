# run as sudo to get those GPIO permissions
# 2023//Sam Dennon

import RPi.GPIO as GPIO

def print_gpio_status():
    mode = GPIO.getmode()
    print(f"GPIO mode: {mode}")

    print("GPIO Pin Status:")
    for pin in range(2, 28):  # GPIO pins 2 to 27 are available on most Raspberry Pi models
        func = GPIO.gpio_function(pin)
        print(f"GPIO-{pin}: {func}")

if __name__ == "__main__":
    GPIO.setmode(GPIO.BCM)

    try:
        print_gpio_status()

    finally:
       print(f"done")
