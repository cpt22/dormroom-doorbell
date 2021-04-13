from django.contrib import admin
from .models import Lampi, Doorbell

# Register your models here.
admin.site.register(Doorbell)
admin.site.register(Lampi)
