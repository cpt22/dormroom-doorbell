from django.views import generic
from django import forms
from django.contrib.auth.mixins import LoginRequiredMixin
from django.views.generic.edit import FormMixin
from django.views.decorators.csrf import csrf_exempt
from django.http import HttpResponseForbidden, HttpResponse
from django.shortcuts import get_object_or_404
from rest_framework.views import APIView
from rest_framework.decorators import api_view
from rest_framework.parsers import FileUploadParser
from rest_framework.response import Response
from rest_framework import status
from .models import Lampi, Doorbell, DoorbellEvent, LampiDoorbellLink
from .serializers import DoorbellEventSerializer
from lampi.forms import *
import json


def user_has_device(user):
    if Lampi.objects.filter(user=user) or Doorbell.objects.filter(user=user):
        return True
    return False


class IndexView(LoginRequiredMixin, generic.ListView):
    template_name = 'lampi/index.html'
    context_object_name = 'devices'

    def get_queryset(self):
        results = {'lampis': Lampi.objects.filter(user=self.request.user),
                   'doorbells': Doorbell.objects.filter(user=self.request.user)}
        return results


class LampiDetailView(LoginRequiredMixin, generic.TemplateView):
    template_name = 'lampi/lampidetail.html'

    def get_context_data(self, **kwargs):
        context = super(LampiDetailView, self).get_context_data(**kwargs)
        context['device'] = get_object_or_404(
            Lampi, pk=kwargs['device_id'], user=self.request.user)
        print("CONTEXT: {}".format(context))
        return context


class DoorbellDetailView(LoginRequiredMixin, FormMixin, generic.ListView):
    template_name = 'lampi/doorbelldetail.html'
    context_object_name = 'data'
    form_class = DoorbellNameForm
    base_url = '/lampi/device/doorbell/'
    success_url = '/lampi/device/doorbell'

    def get_queryset(self):
        doorbell = get_object_or_404(Doorbell, pk=self.kwargs['device_id'], user=self.request.user)
        results = {'doorbell': doorbell,
                   'events': DoorbellEvent.objects.filter(device_id=doorbell.device_id)
                   .order_by('-time')}
        return results

    def post(self, request, *args, **kwargs):
        if not (request.user.is_authenticated and user_has_device(request.user)):
            return HttpResponseForbidden()
        form = self.get_form()
        self.success_url = self.base_url + kwargs['device_id']
        if form.is_valid():
            return self.form_valid(form, **kwargs)
        else:
            return self.form_invalid(form)

    def form_valid(self, form, **kwargs):
        name = form.cleaned_data['name']
        doorbell = Doorbell.objects.get(pk=kwargs['device_id'], user=self.request.user)
        doorbell.name = name
        doorbell.save()
        return super().form_valid(form)


class LinkView(LoginRequiredMixin, generic.ListView):
    template_name = 'lampi/links.html'
    context_object_name = 'data'

    def get_queryset(self):
        doorbells = Doorbell.objects.filter(user=self.request.user)
        results = {'links': [],
                   'doorbells': Doorbell.objects.filter(user=self.request.user),
                   'lampis': Lampi.objects.filter(user=self.request.user)
                   }
        for doorbell in doorbells:
            links = LampiDoorbellLink.objects.filter(doorbell=doorbell)
            print(links)
            for link in links:
                print(link)
                results['links'].append(link)
        print(results)
        return results


class AddDeviceView(LoginRequiredMixin, generic.FormView):
    template_name = 'lampi/adddevice.html'
    form_class = AddDeviceForm
    success_url = '/lampi'

    def form_valid(self, form):
        device = form.cleaned_data['device']
        device.associate_and_publish_associated_msg(self.request.user)
        return super(AddDeviceView, self).form_valid(form)


class DoorbellEventView(APIView):
    parser_class = (FileUploadParser,)

    def post(self, request, *args, **kwargs):
        event_serializer = DoorbellEventSerializer(data=request.data)

        if event_serializer.is_valid():
            event_serializer.save()
            filename = event_serializer.data['recording'].replace('/recordings/', '')
            print(filename)
            event = DoorbellEvent.objects.filter(recording__endswith=filename)
            if event:
                event[0].transcribe_and_push_notification()
            else:
                print("Unknown doorbell -- error")

            return Response(event_serializer.data, status=status.HTTP_201_CREATED)
        else:
            return Response(event_serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
def update_link_data(request):
    response = {
        "outcome": "",
    }
    if not request.user.is_authenticated:
        print('non authenticated user')
        return HttpResponseForbidden()
    if not request.method == 'POST':
        print('method not post')
        return HttpResponse("{}", status=status.HTTP_405_METHOD_NOT_ALLOWED)

    data = request.POST
    if not ('doorbell' in data and 'lampi' in data):
        return HttpResponse("{}", status=status.HTTP_400_BAD_REQUEST)

    lampi = None
    doorbell = None
    try:
        doorbell = Doorbell.objects.get(pk=data['doorbell'])
        lampi = Lampi.objects.get(pk=data['lampi'])
    except Lampi.DoesNotExist:
        return HttpResponse('{"error":"Lampi does not exist"', status=status.HTTP_400_BAD_REQUEST)
    except Doorbell.DoesNotExist:
        return HttpResponse('{"error":"Doorbell does not exist"', status=status.HTTP_400_BAD_REQUEST)

    link = None
    try:
        link = LampiDoorbellLink.objects.get(doorbell=doorbell, lampi=lampi)
        response['outcome'] = "updated"
    except LampiDoorbellLink.DoesNotExist:
        response['outcome'] = "created"
        link = LampiDoorbellLink(doorbell=doorbell, lampi=doorbell)

    if 'hue' in data:
        link.hue = data['hue']
    if 'saturation' in data:
        link.saturation = data['saturation']
    if 'brightness' in data:
        link.brightness = data['brightness']
    if 'number_flashes' in data:
        link.number_flashes = data['number_flashes']

    link.save()
    return HttpResponse(json.dumps(response), status=status.HTTP_200_OK)


#{"lampi":"b827eb9b7d67", "doorbell":"b827ebffed0f"}