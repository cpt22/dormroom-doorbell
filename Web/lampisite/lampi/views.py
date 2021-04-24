from django.views import generic
from django.contrib.auth.mixins import LoginRequiredMixin
from django.shortcuts import get_object_or_404
from rest_framework.views import APIView
from rest_framework.parsers import FileUploadParser
from rest_framework.response import Response
from rest_framework import status
from .models import Lampi, Doorbell, DoorbellEvent
from .serializers import DoorbellEventSerializer
from lampi.forms import AddDeviceForm


class IndexView(LoginRequiredMixin, generic.ListView):
    template_name = 'lampi/index.html'

    def get_queryset(self):
        results = Lampi.objects.filter(user=self.request.user)
        print("RESULTS: {}".format(results))
        return results


class DetailView(LoginRequiredMixin, generic.TemplateView):
    template_name = 'lampi/detail.html'

    def get_context_data(self, **kwargs):
        context = super(DetailView, self).get_context_data(**kwargs)
        context['device'] = get_object_or_404(
            Lampi, pk=kwargs['device_id'], user=self.request.user)
        print("CONTEXT: {}".format(context))
        return context


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
            return Response(event_serializer.data, status=status.HTTP_201_CREATED)
        else:
            return Response(event_serializer.errors, status=status.HTTP_400_BAD_REQUEST)


#class DoorbellEventView(viewsets.ModelViewSet):
#    serializer_class = DoorbellEventSerializer
#    queryset = To