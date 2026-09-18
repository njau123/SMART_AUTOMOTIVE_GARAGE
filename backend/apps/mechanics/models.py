from django.db import models
from apps.accounts.models import User


class MechanicProfile(models.Model):
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='mechanic_profile'
    )
    business_name = models.CharField(max_length=200)
    professional_title = models.CharField(max_length=100, blank=True, null=True)
    bio = models.TextField(blank=True, null=True)
    expertise = models.CharField(max_length=200)
    specialties = models.JSONField(default=list)
    region = models.CharField(max_length=50)
    district = models.CharField(max_length=50)
    ward = models.CharField(max_length=50, blank=True, null=True)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    service_radius = models.PositiveIntegerField(default=50)
    is_available = models.BooleanField(default=True)  # ← HII IKO
    experience = models.PositiveIntegerField(default=0)
    profile_image = models.ImageField(upload_to='mechanics/', blank=True, null=True)
    is_verified = models.BooleanField(default=False)
    verification_documents = models.JSONField(default=list, blank=True)
    rating = models.DecimalField(max_digits=3, decimal_places=2, default=0)
    review_count = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)  # ← ONGEZA HII
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.business_name} - {self.user.get_full_name()}"
