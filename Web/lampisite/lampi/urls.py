from django.urls import path, re_path


from . import views

app_name = 'lampi'

urlpatterns = [
    path('', views.IndexView.as_view(), name='index'),
    path('add/', views.AddDeviceView.as_view(), name='add'),
    path('api/doorbellevent/', views.DoorbellEventView.as_view(), name='addevent'),
    path('links/', views.LinkView.as_view(), name='links'),
    path('links/update/', views.update_link_data),
    re_path(r'^device/lampi/(?P<device_id>[0-9a-fA-F]+)$',
            views.LampiDetailView.as_view(), name='lampidetail'),
    re_path(r'^device/doorbell/(?P<device_id>[0-9a-fA-F]+)$',
            views.DoorbellDetailView.as_view(), name='doorbelldetail'),
]
