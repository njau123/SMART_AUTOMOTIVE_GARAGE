from django.db import models
from django.utils import timezone
from apps.accounts.models import User
from apps.bookings.models import Booking


class ChatRoom(models.Model):
    """Chat Room Model"""
    
    ROOM_TYPES = [
        ('direct', 'Direct Message'),
        ('booking', 'Booking Chat'),
        ('group', 'Group Chat'),
        ('support', 'Support Chat'),
    ]
    room_type = models.CharField(max_length=20, choices=ROOM_TYPES)
    name = models.CharField(max_length=100, blank=True, null=True)
    participants = models.ManyToManyField(User, related_name='chat_rooms')
    booking = models.ForeignKey(Booking, on_delete=models.SET_NULL, null=True, blank=True, related_name='chat_rooms')
    last_message = models.TextField(blank=True, null=True)
    last_message_at = models.DateTimeField(null=True, blank=True)
    last_message_sender = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='last_messages')
    
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('archived', 'Archived'),
        ('closed', 'Closed'),
    ]
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-last_message_at']

    def __str__(self):
        return f"{self.room_type} - {self.id}"

    @property
    def participant_count(self):
        return self.participants.count()

    def unread_count_for_user(self, user):
        return self.messages.filter(is_read=False).exclude(sender=user).count()

    def update_last_message(self, message):
        self.last_message = message.content[:200]
        self.last_message_at = message.created_at
        self.last_message_sender = message.sender
        self.save()


class Message(models.Model):
    """Message Model"""
    
    room = models.ForeignKey(ChatRoom, on_delete=models.CASCADE, related_name='messages')
    sender = models.ForeignKey(User, on_delete=models.CASCADE, related_name='sent_messages')
    content = models.TextField()
    
    MESSAGE_TYPES = [
        ('text', 'Text'),
        ('image', 'Image'),
        ('video', 'Video'),
        ('audio', 'Audio'),
        ('file', 'File'),
        ('location', 'Location'),
        ('booking', 'Booking Update'),
        ('system', 'System Message'),
    ]
    message_type = models.CharField(max_length=20, choices=MESSAGE_TYPES, default='text')
    media_urls = models.JSONField(default=list, blank=True)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    reply_to = models.ForeignKey('self', on_delete=models.SET_NULL, null=True, blank=True, related_name='replies')
    is_read = models.BooleanField(default=False)
    read_by = models.ManyToManyField(User, related_name='read_messages', blank=True)
    read_at = models.DateTimeField(null=True, blank=True)
    delivery_status = models.CharField(
        max_length=20,
        choices=[
            ('sent', 'Sent'),
            ('delivered', 'Delivered'),
            ('read', 'Read'),
            ('failed', 'Failed'),
        ],
        default='sent'
    )
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        return f"{self.sender.get_full_name()}: {self.content[:50]}"

    def mark_as_read(self, user):
        if user != self.sender:
            self.is_read = True
            self.read_by.add(user)
            self.read_at = timezone.now()
            self.delivery_status = 'read'
            self.save()


class MessageAttachment(models.Model):
    """Message Attachment Model"""
    
    message = models.ForeignKey(Message, on_delete=models.CASCADE, related_name='attachments')
    file = models.FileField(upload_to='chat/attachments/')
    file_name = models.CharField(max_length=255)
    file_size = models.PositiveIntegerField(help_text="File size in bytes")
    file_type = models.CharField(max_length=100)
    thumbnail = models.ImageField(upload_to='chat/thumbnails/', blank=True, null=True)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.file_name


class UserChatStatus(models.Model):
    """User's chat status"""
    
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='chat_status')
    
    STATUS_CHOICES = [
        ('online', 'Online'),
        ('offline', 'Offline'),
        ('away', 'Away'),
        ('busy', 'Busy'),
    ]
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='offline')
    last_seen = models.DateTimeField(auto_now=True)
    is_typing = models.BooleanField(default=False)
    typing_in_room = models.ForeignKey(ChatRoom, on_delete=models.SET_NULL, null=True, blank=True, related_name='typing_users')
    typing_updated_at = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"{self.user.get_full_name()} - {self.status}"

    def set_online(self):
        self.status = 'online'
        self.last_seen = timezone.now()
        self.save()

    def set_offline(self):
        self.status = 'offline'
        self.last_seen = timezone.now()
        self.save()

    def set_typing(self, room, is_typing=True):
        self.is_typing = is_typing
        self.typing_in_room = room if is_typing else None
        self.typing_updated_at = timezone.now()
        self.save()


class ChatNotification(models.Model):
    """Chat Notification Model"""
    
    recipient = models.ForeignKey(User, on_delete=models.CASCADE, related_name='chat_notifications')
    message = models.ForeignKey(Message, on_delete=models.CASCADE, related_name='notifications')
    room = models.ForeignKey(ChatRoom, on_delete=models.CASCADE, related_name='notifications')
    
    NOTIFICATION_TYPES = [
        ('new_message', 'New Message'),
        ('mention', 'Mention'),
        ('booking_update', 'Booking Update'),
        ('system', 'System'),
    ]
    notification_type = models.CharField(max_length=20, choices=NOTIFICATION_TYPES)
    is_read = models.BooleanField(default=False)
    read_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.recipient.get_full_name()} - {self.notification_type}"

    def mark_as_read(self):
        self.is_read = True
        self.read_at = timezone.now()
        self.save()


class ChatBlock(models.Model):
    """Block users from chatting"""
    
    blocker = models.ForeignKey(User, on_delete=models.CASCADE, related_name='blocked_users')
    blocked = models.ForeignKey(User, on_delete=models.CASCADE, related_name='blocked_by')
    reason = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = [['blocker', 'blocked']]

    def __str__(self):
        return f"{self.blocker.get_full_name()} blocked {self.blocked.get_full_name()}"
