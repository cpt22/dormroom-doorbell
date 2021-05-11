from django.db import models
from django.contrib.auth.models import User
from django.contrib.auth import get_user_model
from django.utils import timezone
from django.conf import settings
from uuid import uuid4
from django.db.models.signals import post_save
from django.dispatch import receiver
from twilio.rest import Client as TwilioClient
from mixpanel import Mixpanel
import speech_recognition as sr
import json
import paho.mqtt.publish
import colorsys

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


@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    if created:
        Profile.objects.create(user=instance)


@receiver(post_save, sender=User)
def save_user_profile(sender, instance, **kwargs):
    instance.profile.save()


class Profile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    phone = models.CharField(max_length=12, blank=True)


class Lampi(models.Model):
    name = models.CharField(max_length=50, default="My LAMPI")
    device_id = models.CharField(max_length=12, primary_key=True)
    user = models.ForeignKey(User,
                             on_delete=models.SET(get_parked_user))
    association_code = models.CharField(max_length=32, unique=True,
                                        default=generate_association_code)
    created_at = models.DateTimeField(auto_now_add=True)

    type = "lamp"

    mp = Mixpanel(settings.MIXPANEL_TOKEN)

    def __str__(self):
        return "{}: {}".format(self.device_id, self.name)

    def to_dict(self):
        dct = {
            'name': self.name,
            'device_id': self.device_id
        }
        return dct

    def dissociate(self):
        self.user = get_parked_user()
        self.association_code = generate_association_code()
        self.doorbells.clear()
        self.save()
        self.publish_unassociated_msg()
        print(self.doorbells.all())

    def publish_unassociated_msg(self):
        # send association MQTT message
        assoc_msg = {}
        assoc_msg['associated'] = False
        assoc_msg['code'] = self.association_code
        send_association_message(self.type, self.device_id, assoc_msg)
        self.mp.track(self.user.username, "LAMPI Dissociation",
                      {'event_type': 'dissociation', 'device_id': self.device_id,
                       'associated': False})

    def associate_and_publish_associated_msg(self, user):
        # update Lampi instance with new user
        self.user = user
        self.save()
        # publish associated message
        assoc_msg = {}
        assoc_msg['associated'] = True
        send_association_message(self.type, self.device_id, assoc_msg)
        self.mp.track(self.user.username, "LAMPI Association",
                      {'event_type': 'association', 'device_id': self.device_id,
                       'associated': True})


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

    mp = Mixpanel(settings.MIXPANEL_TOKEN)

    def __str__(self):
        return "{}: {}".format(self.device_id, self.name)

    def to_dict(self):
        dct = {
            'name': self.name,
            'device_id': self.device_id
        }
        return dct

    def dissociate(self):
        self.user = get_parked_user()
        self.association_code = generate_association_code()
        self.save()
        self.publish_unassociated_msg()
        self.events.all().delete()

    def publish_unassociated_msg(self):
        # send association MQTT message
        assoc_msg = {}
        assoc_msg['associated'] = False
        assoc_msg['code'] = self.association_code
        send_association_message(self.type, self.device_id, assoc_msg)
        self.mp.track(self.user.username, "Doorbell Dissociation",
                      {'event_type': 'dissociation', 'device_id': self.device_id,
                       'associated': False})

    def associate_and_publish_associated_msg(self, user):
        # update Doorbell instance with new user
        self.user = user
        self.save()
        # publish associated message
        assoc_msg = {}
        assoc_msg['associated'] = True
        send_association_message(self.type, self.device_id, assoc_msg)
        self.mp.track(self.user.username, "Doorbell Association",
                      {'event_type': 'association', 'device_id': self.device_id,
                       'associated': True})


class LampiDoorbellLink(models.Model):
    doorbell = models.ForeignKey('Doorbell', related_name='links', on_delete=models.CASCADE)
    lampi = models.ForeignKey('Lampi', related_name='links', on_delete=models.CASCADE)
    hue = models.DecimalField(decimal_places=2, max_digits=3, default=1.0)
    saturation = models.DecimalField(decimal_places=2, max_digits=3, default=1.0)
    brightness = models.DecimalField(decimal_places=2, max_digits=3, default=1.0)
    number_flashes = models.PositiveSmallIntegerField(default=5)

    class Meta:
        unique_together = ('doorbell', 'lampi',)

    @property
    def hex_color(self):
        rgb = colorsys.hsv_to_rgb(float(self.hue), float(self.saturation), float(self.brightness))
        r = int(rgb[0] * 255)
        g = int(rgb[1] * 255)
        b = int(rgb[2] * 255)
        return '#%02x%02x%02x' % (r, g, b)

    def set_hex_color(self, hex_color):
        rgb_color = self.hex_to_rgb(hex_color)
        scaled = (rgb_color[0] / 255.0, rgb_color[1] / 255.0, rgb_color[2] / 255.0)
        hsv_color = colorsys.rgb_to_hsv(scaled[0], scaled[1], scaled[2])
        self.hue = hsv_color[0]
        self.saturation = hsv_color[1]
        self.brightness = hsv_color[2]
        print(hsv_color)

    def to_dict(self):
        print("here")
        print(self.doorbell.to_dict())
        dct = {'doorbell': self.doorbell.to_dict(),
               'lampi': self.lampi.to_dict(),
               'hue': float(self.hue),
               'saturation': float(self.saturation),
               'brightness': float(self.brightness),
               'hex_color': self.hex_color,
               'number_flashes': self.number_flashes}
        return dct

    def hex_to_rgb(self, value):
        value = value.lstrip('#')
        lv = len(value)
        return tuple(int(value[i:i + lv // 3], 16) for i in range(0, lv, lv // 3))


class DoorbellEvent(models.Model):
    doorbell = models.ForeignKey(Doorbell, related_name='events', on_delete=models.CASCADE)
    time = models.DateTimeField(default=timezone.now)
    recording = models.FileField(blank=False, null=False)
    transcription = models.TextField()

    def transcribe_and_push_notification(self):
        text = "No Message"
        try:
            r = sr.Recognizer()
            path = self.recording.path
            file = sr.AudioFile(path)
            with file as source:
                audio = r.record(source)

            text = r.recognize_google(audio)
            print(text)
        except sr.UnknownValueError:
            print("Unknown Value")

        self.transcription = text
        self.save()
        self.send_notification_to_associated_lampis()

        user = self.doorbell.user
        if user is not get_parked_user() and user.profile.phone:
            print(settings.TWILIO_AUTH_TOKEN)
            twiliotext = self.doorbell.name + ": " + self.transcription
            print("Running twilio messenger")
            client = TwilioClient(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
            print("Sending message to: " + user.profile.phone)
            message = client.messages.create(
                to=user.profile.phone,
                from_="+16175534108",
                body=twiliotext
            )
            print(message.sid)
            print(message)

    def send_notification_to_associated_lampis(self):
        try:
            doorbell = self.doorbell
            links = LampiDoorbellLink.objects.filter(doorbell=doorbell)

            Mixpanel(settings.MIXPANEL_TOKEN).track('mqttbridge', "Doorbell Event",
                                                    {'event_type': 'doorbellevent', 'device_id': doorbell.doorbell,
                                                     'time': self.time, 'number_devices_notified': links.count()})
            if links:
                for link in links:
                    try:
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
                            generate_lamp_notification_topic(link.lampi.doorbell, 'lamp'),
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
