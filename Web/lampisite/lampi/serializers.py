from rest_framework import serializers
from .models import DoorbellEvent


class DoorbellEventSerializer(serializers.ModelSerializer):
    class Meta:
        model = DoorbellEvent
        fields = ('device_id', 'recording')
