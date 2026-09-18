from django.urls import path
from .views import register_device, send_admin_notification

urlpatterns = [
    path('devices/register/', register_device, name='register-device'),
    path('admin-send/', send_admin_notification, name='admin-send-notification'),
]
