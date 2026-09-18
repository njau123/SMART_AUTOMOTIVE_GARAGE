from django.db import models
from django.utils import timezone
from django.conf import settings
from apps.accounts.models import User


class Notification(models.Model):
    """Main Notification Model"""
    
    recipient = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='notifications'
    )
    
    NOTIFICATION_TYPES = [
        ('booking', 'Booking'),
        ('payment', 'Payment'),
        ('diagnosis', 'Diagnosis'),
        ('spare_part', 'Spare Part'),
        ('service', 'Service'),
        ('mechanic', 'Mechanic'),
        ('system', 'System'),
        ('promotion', 'Promotion'),
        ('news', 'News'),
        ('alert', 'Alert'),
    ]
    notification_type = models.CharField(max_length=20, choices=NOTIFICATION_TYPES)
    
    PRIORITY_CHOICES = [
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('urgent', 'Urgent'),
    ]
    priority = models.CharField(max_length=20, choices=PRIORITY_CHOICES, default='medium')
    
    title = models.CharField(max_length=200)
    message = models.TextField()
    subtitle = models.CharField(max_length=200, blank=True, null=True)
    
    action_url = models.CharField(max_length=500, blank=True, null=True)
    action_label = models.CharField(max_length=100, blank=True, null=True)
    action_data = models.JSONField(default=dict, blank=True)
    
    image = models.URLField(blank=True, null=True)
    icon = models.CharField(max_length=50, blank=True, null=True)
    
    is_read = models.BooleanField(default=False)
    is_clicked = models.BooleanField(default=False)
    is_dismissed = models.BooleanField(default=False)
    is_sent = models.BooleanField(default=False)
    
    SEND_METHODS = [
        ('in_app', 'In App'),
        ('email', 'Email'),
        ('sms', 'SMS'),
        ('push', 'Push Notification'),
        ('all', 'All Methods'),
    ]
    send_method = models.CharField(max_length=20, choices=SEND_METHODS, default='in_app')
    
    read_at = models.DateTimeField(null=True, blank=True)
    clicked_at = models.DateTimeField(null=True, blank=True)
    dismissed_at = models.DateTimeField(null=True, blank=True)
    sent_at = models.DateTimeField(null=True, blank=True)
    
    expires_at = models.DateTimeField(null=True, blank=True)
    is_expired = models.BooleanField(default=False)
    
    metadata = models.JSONField(default=dict, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.recipient.get_full_name()} - {self.title[:50]}"

    def mark_as_read(self):
        self.is_read = True
        self.read_at = timezone.now()
        self.save()

    def mark_as_clicked(self):
        self.is_clicked = True
        self.clicked_at = timezone.now()
        self.save()

    def mark_as_dismissed(self):
        self.is_dismissed = True
        self.dismissed_at = timezone.now()
        self.save()

    def mark_as_sent(self):
        self.is_sent = True
        self.sent_at = timezone.now()
        self.save()

    def check_expiry(self):
        if self.expires_at and timezone.now() > self.expires_at:
            self.is_expired = True
            self.save()
            return True
        return False


class NotificationTemplate(models.Model):
    """Notification Template Model"""
    
    name = models.CharField(max_length=100, unique=True)
    slug = models.SlugField(max_length=100, unique=True)
    notification_type = models.CharField(max_length=20, choices=Notification.NOTIFICATION_TYPES)
    
    title_template = models.CharField(max_length=200)
    message_template = models.TextField()
    subtitle_template = models.CharField(max_length=200, blank=True, null=True)
    
    action_url_template = models.CharField(max_length=500, blank=True, null=True)
    action_label_template = models.CharField(max_length=100, blank=True, null=True)
    
    priority = models.CharField(max_length=20, choices=Notification.PRIORITY_CHOICES, default='medium')
    send_method = models.CharField(max_length=20, choices=Notification.SEND_METHODS, default='in_app')
    
    icon = models.CharField(max_length=50, blank=True, null=True)
    is_active = models.BooleanField(default=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return self.name


class NotificationDevice(models.Model):
    """User's devices for push notifications"""
    
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='notification_devices'
    )
    
    device_token = models.CharField(max_length=500, unique=True, db_index=True)
    device_type = models.CharField(
        max_length=20,
        choices=[
            ('ios', 'iOS'),
            ('android', 'Android'),
            ('web', 'Web'),
        ]
    )
    device_name = models.CharField(max_length=100, blank=True, null=True)
    device_model = models.CharField(max_length=100, blank=True, null=True)
    os_version = models.CharField(max_length=20, blank=True, null=True)
    app_version = models.CharField(max_length=20, blank=True, null=True)
    
    is_active = models.BooleanField(default=True)
    last_used = models.DateTimeField(null=True, blank=True)
    
    metadata = models.JSONField(default=dict, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        unique_together = [['user', 'device_token']]

    def __str__(self):
        return f"{self.user.get_full_name()} - {self.device_type}"


class NotificationLog(models.Model):
    """Log for sent notifications"""
    
    notification = models.ForeignKey(
        Notification,
        on_delete=models.CASCADE,
        related_name='logs'
    )
    
    recipient = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='notification_logs'
    )
    
    delivery_method = models.CharField(max_length=20, choices=Notification.SEND_METHODS)
    is_successful = models.BooleanField(default=False)
    error_message = models.TextField(blank=True, null=True)
    
    response_data = models.JSONField(default=dict, blank=True)
    
    sent_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-sent_at']

    def __str__(self):
        return f"{self.notification} - {self.delivery_method} - {self.sent_at}"


# Alias for backward compatibility
DeviceToken = NotificationDevice
