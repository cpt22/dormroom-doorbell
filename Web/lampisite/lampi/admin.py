from django.contrib import admin
from .models import Lampi, Doorbell, LampiDoorbellLink, DoorbellEvent

# Register your models here.
admin.site.register(Doorbell)
admin.site.register(Lampi)
admin.site.register(LampiDoorbellLink)
admin.site.register(DoorbellEvent)