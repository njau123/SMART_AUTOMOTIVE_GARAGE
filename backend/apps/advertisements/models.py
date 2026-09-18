import uuid

from django.conf import settings
from django.db import models
from django.utils import timezone


class AdvertisementType(models.TextChoices):
    BANNER = "BANNER", "Banner"
    CARD = "CARD", "Card"
    POPUP = "POPUP", "Popup"
    VIDEO = "VIDEO", "Video"


class AdvertisementStatus(models.TextChoices):
    DRAFT = "DRAFT", "Draft"
    ACTIVE = "ACTIVE", "Active"
    PAUSED = "PAUSED", "Paused"
    EXPIRED = "EXPIRED", "Expired"


class Advertisement(models.Model):
    reference = models.CharField(
        max_length=50,
        unique=True,
        editable=False,
        db_index=True,
    )

    title = models.CharField(
        max_length=255,
    )

    description = models.TextField(
        blank=True,
    )

    advertisement_type = models.CharField(
        max_length=20,
        choices=AdvertisementType.choices,
        default=AdvertisementType.BANNER,
    )

    image = models.ImageField(
        upload_to="advertisements/%Y/%m/%d/",
        null=True,
        blank=True,
    )

    video = models.FileField(
        upload_to="advertisements/videos/%Y/%m/%d/",
        null=True,
        blank=True,
    )

    target_url = models.URLField(
        blank=True,
    )

    target_screen = models.CharField(
        max_length=100,
        blank=True,
    )

    status = models.CharField(
        max_length=20,
        choices=AdvertisementStatus.choices,
        default=AdvertisementStatus.DRAFT,
        db_index=True,
    )

    start_at = models.DateTimeField()

    end_at = models.DateTimeField()

    priority = models.PositiveIntegerField(
        default=0,
    )

    impressions = models.PositiveIntegerField(
        default=0,
    )

    clicks = models.PositiveIntegerField(
        default=0,
    )

    is_active = models.BooleanField(
        default=True,
    )

    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="created_advertisements",
    )

    created_at = models.DateTimeField(
        auto_now_add=True,
    )

    updated_at = models.DateTimeField(
        auto_now=True,
    )

    class Meta:
        db_table = "advertisements"
        ordering = [
            "-priority",
            "-created_at",
        ]

        indexes = [
            models.Index(
                fields=[
                    "status",
                    "start_at",
                    "end_at",
                ]
            ),
            models.Index(
                fields=[
                    "advertisement_type",
                    "status",
                ]
            ),
        ]

    def save(self, *args, **kwargs):
        if not self.reference:
            self.reference = (
                f"AD-{uuid.uuid4().hex[:14].upper()}"
            )

        super().save(*args, **kwargs)

    def is_currently_active(self):
        now = timezone.now()

        return (
            self.is_active
            and self.status
            == AdvertisementStatus.ACTIVE
            and self.start_at <= now
            <= self.end_at
        )

    def __str__(self):
        return self.title


class AdvertisementImpression(models.Model):
    advertisement = models.ForeignKey(
        Advertisement,
        on_delete=models.CASCADE,
        related_name="impression_records",
    )

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="advertisement_impressions",
    )

    ip_address = models.GenericIPAddressField(
        null=True,
        blank=True,
    )

    created_at = models.DateTimeField(
        auto_now_add=True,
    )

    class Meta:
        db_table = "advertisement_impressions"
        indexes = [
            models.Index(
                fields=[
                    "advertisement",
                    "created_at",
                ]
            ),
        ]


class AdvertisementClick(models.Model):
    advertisement = models.ForeignKey(
        Advertisement,
        on_delete=models.CASCADE,
        related_name="click_records",
    )

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="advertisement_clicks",
    )

    ip_address = models.GenericIPAddressField(
        null=True,
        blank=True,
    )

    created_at = models.DateTimeField(
        auto_now_add=True,
    )

    class Meta:
        db_table = "advertisement_clicks"
        indexes = [
            models.Index(
                fields=[
                    "advertisement",
                    "created_at",
                ]
            ),
        ]