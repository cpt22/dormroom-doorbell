from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone
from uuid import uuid4
import json
import paho.mqtt.publish

# Create your models here.
DEFAULT_USER = 'parked_device_user'


def get_parked_user():
    return get_user_model().objects.get_or_create(username=DEFAULT_USER)[0]


def generate_association_code():
    return uuid4().hex

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
    doorbell = models.ForeignKey('Doorbell', related_name='link', on_delete=models.CASCADE)
    lampi = models.ForeignKey('Lampi', related_name='link', on_delete=models.CASCADE)
    hue = models.DecimalField(decimal_places=2, max_digits=3, default=1.0)
    saturation = models.DecimalField(decimal_places=2, max_digits=3, default=1.0)
    brightness = models.DecimalField(decimal_places=2, max_digits=3, default=1.0)
    number_flashes = models.PositiveSmallIntegerField(default=5)


class DoorbellEvent(models.Model):
    device_id = models.ForeignKey('Doorbell', related_name='doorbell_id', on_delete=models.SET("ffffffffffff"))
    time = models.DateTimeField(default=timezone.now)
    recording = models.FileField(blank=False, null=False)
    transcription = models.TextField()


#    user = models.ForeignKey(User, on_delete=models.CASCADE)
#    lampi_id = models.ForeignKey(Lampi, on_delete=models.CASCADE, primary_key=True)
#    doorbell_id = models.ForeignKey(Doorbell, on_delete=models.CASCADE, primary_key=True)

#    def __str__(self):
#        return "{}: {} -> {}".format(self.user, self.doorbell_id, self.lampi_id)
