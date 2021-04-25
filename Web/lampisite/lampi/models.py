from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone
from uuid import uuid4
import speech_recognition as sr
import json
import paho.mqtt.publish

# Create your models here.
DEFAULT_USER = 'parked_device_user'


def get_parked_user():
    return get_user_model().objects.get_or_create(username=DEFAULT_USER)[0]


def generate_association_code():
    return uuid4().hex

def generate_lamp_notification_topic(device_id, type):
    return 'devices/{}/{}/notification'.format(device_id, type)

def generate_device_association_topic(type, device_id):
    return 'devices/{}/{}/associated'.format(device_id, type)

def send_association_message(type, device_id, message):
    paho.mqtt.publish.single(
        generate_device_association_topic(type, device_id),
        json.dumps(message),
        qos=2,
        retain=True,
        hostname="localhost",
        port=50001,
    )


class Lampi(models.Model):
    name = models.CharField(max_length=50, default="My LAMPI")
    device_id = models.CharField(max_length=12, primary_key=True)
    user = models.ForeignKey(User,
                             on_delete=models.SET(get_parked_user))
    association_code = models.CharField(max_length=32, unique=True,
                                        default=generate_association_code)
    created_at = models.DateTimeField(auto_now_add=True)

    type = "lamp"

    def __str__(self):
        return "{}: {}".format(self.device_id, self.name)

    #def _generate_device_association_topic(self):
    #    return 'devices/{}/lamp/associated'.format(self.device_id)

    def publish_unassociated_msg(self):
        # send association MQTT message
        assoc_msg = {}
        assoc_msg['associated'] = False
        assoc_msg['code'] = self.association_code
        send_association_message(self.type, self.device_id, assoc_msg)


    def associate_and_publish_associated_msg(self,  user):
        # update Lampi instance with new user
        self.user = user
        self.save()
        # publish associated message
        assoc_msg = {}
        assoc_msg['associated'] = True
        send_association_message(self.type, self.device_id, assoc_msg)


class Doorbell(models.Model):
    name = models.CharField(max_length=50, default="My Doorbell")
    device_id = models.CharField(max_length=12, primary_key=True)
    user = models.ForeignKey(User,
                             on_delete=models.SET(get_parked_user))
    association_code = models.CharField(max_length=32, unique=True,
                                        default=generate_association_code)
    created_at = models.DateTimeField(auto_now_add=True)
    lampis = models.ManyToManyField('Lampi', through='LampiDoorbellLink', related_name='doorbells')

    type = "doorbell"

    def __str__(self):
        return "{}: {}".format(self.device_id, self.name)

    def publish_unassociated_msg(self):
        # send association MQTT message
        assoc_msg = {}
        assoc_msg['associated'] = False
        assoc_msg['code'] = self.association_code
        send_association_message(self.type, self.device_id, assoc_msg)

    def associate_and_publish_associated_msg(self,  user):
        # update Doorbell instance with new user
        self.user = user
        self.save()
        # publish associated message
        assoc_msg = {}
        assoc_msg['associated'] = True
        send_association_message(self.type, self.device_id, assoc_msg)


class LampiDoorbellLink(models.Model):
    doorbell = models.ForeignKey('Doorbell', related_name='links', on_delete=models.CASCADE)
    lampi = models.ForeignKey('Lampi', related_name='links', on_delete=models.CASCADE)
    hue = models.DecimalField(decimal_places=2, max_digits=3, default=1.0)
    saturation = models.DecimalField(decimal_places=2, max_digits=3, default=1.0)
    brightness = models.DecimalField(decimal_places=2, max_digits=3, default=1.0)
    number_flashes = models.PositiveSmallIntegerField(default=5)

    class Meta:
        unique_together = ('doorbell', 'lampi',)


class DoorbellEvent(models.Model):
    device_id = models.ForeignKey('Doorbell', related_name='doorbell', on_delete=models.CASCADE)#on_delete=models.SET("ffffffffffff"))
    time = models.DateTimeField(default=timezone.now)
    recording = models.FileField(blank=False, null=False)
    transcription = models.TextField()

    def transcribe_and_push_notification(self):
        print("Transcribing")
        r = sr.Recognizer()
        path = self.recording.path
        file = sr.AudioFile(path)
        with file as source:
            audio = r.record(source)

        text = r.recognize_google(audio)
        print(text)
        self.transcription = text
        self.save()
        self.send_notification_to_associated_lampis()

    def send_notification_to_associated_lampis(self):
        try:
            doorbell = self.device_id
            lampis = doorbell.lampis.all()
            if lampis:
                for lampi in lampis:
                    try:
                        link = LampiDoorbellLink.objects.get(doorbell=doorbell)

                        notification_message = {
                            'type': 'doorbell_event',
                            'title': doorbell.name,
                            'message': self.transcription,
                            'hue': float(link.hue),
                            'saturation': float(link.saturation),
                            'brightness': float(link.brightness),
                            'num_flashes': link.number_flashes,
                        }
                        paho.mqtt.publish.single(
                            generate_lamp_notification_topic(lampi.device_id, 'lamp'),
                            json.dumps(notification_message),
                            qos=2,
                            retain=False,
                            hostname="localhost",
                            port=50001,
                        )
                    except LampiDoorbellLink.DoesNotExist:
                        print("missing lampi or something")
            else:
                print("No associated lampis")
        except Doorbell.DoesNotExist:
            print("Error finding doorbell")
