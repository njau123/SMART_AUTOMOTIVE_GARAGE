from django.db import models
from django.utils import timezone
from django.contrib.auth import get_user_model

User = get_user_model()

class NewsCategory(models.Model):
    name = models.CharField(max_length=100)
    slug = models.SlugField(unique=True)
    description = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name

    class Meta:
        verbose_name_plural = "News Categories"

class News(models.Model):
    STATUS_CHOICES = (
        ('draft', 'Draft'),
        ('published', 'Published'),
        ('archived', 'Archived'),
    )

    title = models.CharField(max_length=200)
    slug = models.SlugField(unique=True, max_length=200)
    summary = models.TextField(blank=True)
    content = models.TextField()
    category = models.ForeignKey(NewsCategory, on_delete=models.SET_NULL, null=True, blank=True, related_name='news')
    author = models.ForeignKey("accounts.User", on_delete=models.CASCADE, null=True, blank=True)

    featured_image = models.ImageField(upload_to='news/', blank=True, null=True)
    images = models.JSONField(default=list, blank=True)
    videos = models.JSONField(default=list, blank=True)

    # Video fields (added for video uploads)
    video_url = models.URLField(max_length=500, blank=True, null=True)
    video_file = models.FileField(upload_to='videos/', blank=True, null=True)

    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft')
    scheduled_publish_at = models.DateTimeField(null=True, blank=True)
    published_at = models.DateTimeField(null=True, blank=True)
    archived_at = models.DateTimeField(null=True, blank=True)

    visibility = models.CharField(max_length=20, default='public')
    views_count = models.PositiveIntegerField(default=0)
    likes_count = models.PositiveIntegerField(default=0)
    shares_count = models.PositiveIntegerField(default=0)
    comments_count = models.PositiveIntegerField(default=0)

    is_featured = models.BooleanField(default=False)
    is_breaking = models.BooleanField(default=False)
    is_urgent = models.BooleanField(default=False)

    tags = models.JSONField(default=list, blank=True)

    meta_title = models.CharField(max_length=200, blank=True)
    meta_description = models.TextField(blank=True)
    meta_keywords = models.TextField(blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.title

    class Meta:
        verbose_name_plural = "News"
        ordering = ['-created_at']
