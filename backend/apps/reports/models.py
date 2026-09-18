from django.db import models
from apps.accounts.models import User


class Report(models.Model):
    """Report Model"""
    
    title = models.CharField(max_length=200)
    report_type = models.CharField(max_length=50)
    
    # Report Data
    data = models.JSONField(default=dict)
    
    # User who created
    created_by = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='created_reports'
    )
    
    # Status
    STATUS_CHOICES = [
        ('draft', 'Draft'),
        ('generated', 'Generated'),
        ('sent', 'Sent'),
        ('archived', 'Archived'),
    ]
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft')
    
    # File
    file = models.FileField(upload_to='reports/', blank=True, null=True)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return self.title
