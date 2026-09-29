from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import unregister_device, clear_all_user_devices, (
    NotificationViewSet, register_device, send_admin_notification,
)

router = DefaultRouter()
router.register(r'', NotificationViewSet, basename='notification')

urlpatterns = [
    path('devices/register/', register_device, name='register-device'),
    path('devices/unregister/', unregister_device, name='unregister-device'),
    path('devices/clear-all/', clear_all_user_devices, name='clear-all-devices'),
    path('admin-send/', send_admin_notification, name='admin-send-notification'),
    path('', include(router.urls)),
]
