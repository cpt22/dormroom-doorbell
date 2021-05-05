#!/usr/bin/env python3
import subprocess
import os
import time
import threading
import requests
import RPi.GPIO as GPIO
import doorbell_util as util

#OUTPUT_PATH = "/home/pi/recordings/"
OUTPUT_PATH = "/tmp/"
OUTPUT_FILETYPE = "wav"
RECORDING_TIME = 5

UPLOAD_URL = "http://ec2-18-232-7-159.compute-1.amazonaws.com/lampi/api/doorbellevent/"

BUTTON_PIN = 7
RGB_PINS = [22, 23, 24]


class recorder(threading.Thread):
    def __init__(self):
        threading.Thread.__init__(self)

    def run(self):
        filename = util.get_device_id() + time.strftime("-%d-%m-%Y--%H:%M:%S") + "." + OUTPUT_FILETYPE
        filepath = OUTPUT_PATH + filename

        proc_args = ['arecord', '-D', 'plughw:0', '-d', str(RECORDING_TIME), '-c1', '-r', '44100', '-f', 'S32_LE', '-t',
                     OUTPUT_FILETYPE, filepath]
        subprocess.Popen(proc_args, shell=False, preexec_fn=os.setsid)

        GPIO.output(RGB_PINS[1], GPIO.HIGH)
        time.sleep(RECORDING_TIME)
        GPIO.output(RGB_PINS[1], GPIO.LOW)
        time.sleep(1)

        wu = webUpload(filename, filepath)
        wu.start()


class webUpload(threading.Thread):
    def __init__(self, filename, filepath):
        threading.Thread.__init__(self)
        self.filename = filename
        self.filepath = filepath

    def run(self):
        try:
            print("Sending file to server")
            data = {'filename': self.filename, 'device_id': util.get_device_id()}
            files = {'recording': (open(self.filepath, 'rb'))}
            response = requests.post(UPLOAD_URL,
                                     data=data,
                                     files=files)
            if response.status_code == 201:
                print("Upload Successful")
            elif response.status_code == 404:
                print("Not Found")
            else:
                print("Other Error")
        except OSError as e:
            print("Could not connect to web server")


def main():
    print("main")
    # Setup GPIO
    GPIO.setmode(GPIO.BOARD)
    GPIO.setwarnings(False)
    GPIO.setup(BUTTON_PIN, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)
    GPIO.add_event_detect(BUTTON_PIN, GPIO.RISING, bouncetime=1000)
    for pin in RGB_PINS:
        GPIO.setup(pin, GPIO.OUT, initial=GPIO.LOW)

    thread = None

    while True:
        if GPIO.event_detected(BUTTON_PIN):
            print("Button pressed")
            play_chime()
            if thread is None or not thread.is_alive():
                thread = create_recording()

    GPIO.cleanup()


def create_recording():
    thread = recorder()
    thread.start()
    return thread


def play_chime():
    pass


if __name__ == "__main__":
    main()
