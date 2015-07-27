
import time
import RPi.GPIO as GPIO

LED = 17

def setup():
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(LED, GPIO.OUT)
    GPIO.output(LED, GPIO.LOW)

def blink():
    for i in range(3):
        GPIO.output(LED, GPIO.HIGH)
        time.sleep(0.2)
        GPIO.output(LED, GPIO.LOW)
        time.sleep(0.2)

def cleanup():
    GPIO.cleanup()
