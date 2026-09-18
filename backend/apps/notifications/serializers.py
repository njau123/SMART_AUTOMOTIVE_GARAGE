from rest_framework import serializers
from .models import Notification, NotificationTemplate, NotificationDevice, NotificationLog


class NotificationSerializer(serializers.ModelSerializer):
    recipient_name = serializers.CharField(source='recipient.get_full_name', read_only=True)
    is_expired = serializers.SerializerMethodField()
    formatted_created = serializers.SerializerMethodField()

    class Meta:
        model = Notification
        fields = [
            'id', 'recipient', 'recipient_name', 'notification_type',
            'priority', 'title', 'message', 'subtitle',
            'action_url', 'action_label', 'action_data',
            'image', 'icon', 'is_read', 'is_clicked',
            'is_dismissed', 'is_sent', 'is_expired',
            'send_method', 'read_at', 'clicked_at',
            'dismissed_at', 'sent_at', 'expires_at',
            'metadata', 'formatted_created', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def get_is_expired(self, obj):
        return obj.check_expiry()

    def get_formatted_created(self, obj):
        return obj.created_at.strftime('%Y-%m-%d %H:%M')


class NotificationCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = [
            'recipient', 'notification_type', 'priority',
            'title', 'message', 'subtitle', 'action_url',
            'action_label', 'action_data', 'image', 'icon',
            'send_method', 'expires_at', 'metadata'
        ]


class NotificationTemplateSerializer(serializers.ModelSerializer):
    class Meta:
        model = NotificationTemplate
        fields = [
            'id', 'name', 'slug', 'notification_type',
            'title_template', 'message_template', 'subtitle_template',
            'action_url_template', 'action_label_template',
            'priority', 'send_method', 'icon',
            'is_active', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class NotificationDeviceSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source='user.get_full_name', read_only=True)

    class Meta:
        model = NotificationDevice
        fields = [
            'id', 'user', 'user_name', 'device_token',
            'device_type', 'device_name', 'device_model',
            'os_version', 'app_version', 'is_active',
            'last_used', 'metadata', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class NotificationLogSerializer(serializers.ModelSerializer):
    recipient_name = serializers.CharField(source='recipient.get_full_name', read_only=True)

    class Meta:
        model = NotificationLog
        fields = [
            'id', 'notification', 'recipient', 'recipient_name',
            'delivery_method', 'is_successful', 'error_message',
            'response_data', 'sent_at'
        ]
        read_only_fields = ['id', 'sent_at']
