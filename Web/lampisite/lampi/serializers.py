from rest_framework import serializers
from .models import DoorbellEvent, LampiDoorbellLink


class DoorbellEventSerializer(serializers.ModelSerializer):
    class Meta:
        model = DoorbellEvent
        fields = ('device_id', 'recording')
        read_only_fields = ('transcription',)


class LampiDoorbellLinkSerializer(serializers.ModelSerializer):
    class Meta:
        model = LampiDoorbellLink
        fields = ['doorbell', 'lampi', 'hue', 'saturation', 'value', 'brightness', 'number_flashes']
