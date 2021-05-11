#!/usr/bin/env python3
import subprocess
import os
import time
import threading
import requests
import RPi.GPIO as GPIO
import doorbell_util as util
import schedule
import urllib.request

#OUTPUT_PATH = "/home/pi/recordings/"
OUTPUT_PATH = "/tmp/"
OUTPUT_FILETYPE = "wav"
RECORDING_TIME = 5

UPLOAD_URL = "http://ec2-18-232-7-159.compute-1.amazonaws.com/lampi/api/doorbellevent/"

BUTTON_PIN = 7
RED_PIN = 22
GREEN_PIN = 23

is_internet_connected = False


class recorder(threading.Thread):
    def __init__(self):
        threading.Thread.__init__(self)

    def run(self):
        filename = util.get_device_id() + time.strftime("-%d-%m-%Y--%H:%M:%S") + "." + OUTPUT_FILETYPE
        filepath = OUTPUT_PATH + filename

        proc_args = ['arecord', '-D', 'plughw:0', '-d', str(RECORDING_TIME), '-c1', '-r', '44100', '-f', 'S32_LE', '-t',
                     OUTPUT_FILETYPE, filepath]
        subprocess.Popen(proc_args, shell=False, preexec_fn=os.setsid)

        GPIO.output(GREEN_PIN, GPIO.HIGH)
        time.sleep(RECORDING_TIME)
        GPIO.output(GREEN_PIN, GPIO.LOW)
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


class ConnectionChecker(threading.Thread):
    is_connected = False

    def __init__(self, check_time):
        threading.Thread.__init__(self)
        self.check_time = check_time / 1000.0
        self.job()

    def run(self):
        schedule.every(self.check_time).seconds.do(self.job)
        while True:
            schedule.run_pending()
            time.sleep(1)

    def job(self):
        print("Checking Connection")
        try:
            urllib.request.urlopen('http://google.com')  # Python 3.x
            self.is_connected = True
        except:
            self.is_connected = False
        print(self.is_connected)


def main():
    # Setup GPIO
    GPIO.setmode(GPIO.BOARD)
    GPIO.setwarnings(False)
    GPIO.setup(BUTTON_PIN, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)
    GPIO.add_event_detect(BUTTON_PIN, GPIO.RISING, bouncetime=1000)

    GPIO.setup(RED_PIN, GPIO.OUT, initial=GPIO.LOW)
    GPIO.setup(GREEN_PIN, GPIO.OUT, initial=GPIO.LOW)

    thread = None

    conn_checker = ConnectionChecker(500)
    conn_checker.start()

    while True:
        while conn_checker.is_connected:
            GPIO.output(RED_PIN, GPIO.LOW)
            if GPIO.event_detected(BUTTON_PIN):
                print("Button pressed")
                play_chime()
                if thread is None or not thread.is_alive():
                    thread = create_recording()

        GPIO.output(RED_PIN, GPIO.HIGH)
        time.sleep(0.1)

    GPIO.cleanup()


def create_recording():
    thread = recorder()
    thread.start()
    return thread


def play_chime():
    pass


if __name__ == "__main__":
    main()
