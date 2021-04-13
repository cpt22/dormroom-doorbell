from django.contrib import admin
from .models import Lampi, Doorbell, LampiDoorbellLink

# Register your models here.
admin.site.register(Doorbell)
admin.site.register(Lampi)
admin.site.register(LampiDoorbellLink)
