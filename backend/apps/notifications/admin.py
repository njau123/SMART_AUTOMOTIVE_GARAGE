from django.contrib import admin
from .models import Notification, NotificationTemplate, NotificationDevice, NotificationLog

@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ['title', 'recipient', 'notification_type', 'is_read', 'is_sent', 'created_at']
    list_filter = ['notification_type', 'priority', 'is_read', 'is_sent']
    search_fields = ['title', 'message', 'recipient__email']
    readonly_fields = ['created_at', 'updated_at']

@admin.register(NotificationTemplate)
class NotificationTemplateAdmin(admin.ModelAdmin):
    list_display = ['name', 'slug', 'notification_type', 'is_active']
    list_filter = ['notification_type', 'is_active']
    search_fields = ['name', 'slug']

@admin.register(NotificationDevice)
class NotificationDeviceAdmin(admin.ModelAdmin):
    list_display = ['user', 'device_type', 'device_name', 'is_active', 'last_used']
    list_filter = ['device_type', 'is_active']
    search_fields = ['device_token', 'device_name', 'user__email']

@admin.register(NotificationLog)
class NotificationLogAdmin(admin.ModelAdmin):
    list_display = ['notification', 'recipient', 'delivery_method', 'is_successful', 'sent_at']
    list_filter = ['delivery_method', 'is_successful']
    search_fields = ['notification__title', 'recipient__email']
