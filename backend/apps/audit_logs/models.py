from django.db import models
from apps.accounts.models import User


class AuditLog(models.Model):
    """Audit Log Model"""
    
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='audit_logs'
    )

    ACTION_CHOICES = [
        ('create', 'Create'),
        ('update', 'Update'),
        ('delete', 'Delete'),
        ('view', 'View'),
        ('login', 'Login'),
        ('logout', 'Logout'),
        ('export', 'Export'),
        ('import', 'Import'),
    ]
    action = models.CharField(max_length=20, choices=ACTION_CHOICES)

    model = models.CharField(max_length=100)
    object_id = models.CharField(max_length=100)
    changes = models.JSONField(default=dict)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.user.get_full_name()} - {self.action} - {self.model}"
