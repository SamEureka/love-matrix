# For my wife, Andrea!
# 2023 (c) Sam Dennon

import RPi.GPIO as GPIO
import time
import sys
import os

def is_shorted(pin):
    # Read the state of the pin multiple times and check if consistently LOW
    for _ in range(20):  # Check 10 times
        if GPIO.input(pin) != GPIO.LOW:
            return False
        time.sleep(0.1)  # Wait for a short duration between checks
    return True

# Set up GPIO mode
GPIO.setmode(GPIO.BCM)

# Set up GPIO pin 25 as an input
pin = 25
GPIO.setup(pin, GPIO.IN)

try:
    while True:
        if is_shorted(pin):
            print(f"GPIO{pin} is shorted to ground!")
            time.sleep(1) 
        else:
            print(f"GPIO{pin} Toggle has been switched to off. Executing shutdown")
            os.system("sudo shutdown -h now")
            break

except KeyboardInterrupt: # User escape
    print("\nScript interrupted by user.")
    sys.exit(42)

finally:
    # Clean up GPIO
    GPIO.cleanup()
    sys.exit(0)
