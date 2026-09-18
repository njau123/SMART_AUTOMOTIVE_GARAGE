from django.db import models
from apps.accounts.models import User


class Media(models.Model):
    """Media Model"""
    
    title = models.CharField(max_length=200)
    file = models.FileField(upload_to='media/%Y/%m/%d/')
    file_type = models.CharField(max_length=50)
    file_size = models.PositiveIntegerField(help_text="File size in bytes", default=0)
    
    CATEGORY_CHOICES = [
        ('image', 'Image'),
        ('video', 'Video'),
        ('audio', 'Audio'),
        ('document', 'Document'),
        ('other', 'Other'),
    ]
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES, default='other')
    
    description = models.TextField(blank=True, null=True)
    
    uploaded_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name='uploaded_media'
    )
    
    metadata = models.JSONField(default=dict, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name_plural = 'Media'

    def __str__(self):
        return self.title

    @property
    def file_url(self):
        if self.file:
            return self.file.url
        return None

    @property
    def file_name(self):
        if self.file:
            return self.file.name.split('/')[-1]
        return None
