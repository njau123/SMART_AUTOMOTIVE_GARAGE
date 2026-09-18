from django.contrib import admin
from .models import ChatRoom, Message, MessageAttachment, UserChatStatus, ChatNotification, ChatBlock


@admin.register(ChatRoom)
class ChatRoomAdmin(admin.ModelAdmin):
    list_display = ['id', 'room_type', 'name', 'participant_count', 'status', 'created_at']
    list_filter = ['room_type', 'status']
    search_fields = ['name', 'booking__booking_number']
    filter_horizontal = ['participants']

    def participant_count(self, obj):
        return obj.participants.count()
    participant_count.short_description = 'Participants'


@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    list_display = ['room', 'sender', 'content_preview', 'message_type', 'is_read', 'created_at']
    list_filter = ['message_type', 'is_read', 'delivery_status']
    search_fields = ['content', 'sender__email']
    readonly_fields = ['created_at', 'updated_at']

    def content_preview(self, obj):
        return obj.content[:50] + '...' if len(obj.content) > 50 else obj.content
    content_preview.short_description = 'Content'


@admin.register(MessageAttachment)
class MessageAttachmentAdmin(admin.ModelAdmin):
    list_display = ['message', 'file_name', 'file_size', 'file_type', 'created_at']
    search_fields = ['file_name']


@admin.register(UserChatStatus)
class UserChatStatusAdmin(admin.ModelAdmin):
    list_display = ['user', 'status', 'is_typing', 'last_seen']
    list_filter = ['status', 'is_typing']
    search_fields = ['user__email']


@admin.register(ChatNotification)
class ChatNotificationAdmin(admin.ModelAdmin):
    list_display = ['recipient', 'notification_type', 'is_read', 'created_at']
    list_filter = ['notification_type', 'is_read']
    search_fields = ['recipient__email']


@admin.register(ChatBlock)
class ChatBlockAdmin(admin.ModelAdmin):
    list_display = ['blocker', 'blocked', 'created_at']
    search_fields = ['blocker__email', 'blocked__email']
