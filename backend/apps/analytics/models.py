from django.conf import settings
from django.db import models


class AnalyticsEventType(models.TextChoices):
    APP_OPEN = "APP_OPEN", "App Open"
    LOGIN = "LOGIN", "Login"
    LOGOUT = "LOGOUT", "Logout"

    VEHICLE_CREATED = (
        "VEHICLE_CREATED",
        "Vehicle Created",
    )

    BOOKING_CREATED = (
        "BOOKING_CREATED",
        "Booking Created",
    )

    BOOKING_COMPLETED = (
        "BOOKING_COMPLETED",
        "Booking Completed",
    )

    ORDER_CREATED = (
        "ORDER_CREATED",
        "Order Created",
    )

    PAYMENT_COMPLETED = (
        "PAYMENT_COMPLETED",
        "Payment Completed",
    )

    PRODUCT_VIEWED = (
        "PRODUCT_VIEWED",
        "Product Viewed",
    )

    NEWS_VIEWED = (
        "NEWS_VIEWED",
        "News Viewed",
    )

    AD_CLICKED = (
        "AD_CLICKED",
        "Advertisement Clicked",
    )

    SERVICE_VIEWED = (
        "SERVICE_VIEWED",
        "Service Viewed",
    )


class AnalyticsEvent(models.Model):
    event_type = models.CharField(
        max_length=50,
        choices=AnalyticsEventType.choices,
        db_index=True,
    )

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="analytics_events",
    )

    session_id = models.CharField(
        max_length=255,
        blank=True,
        db_index=True,
    )

    ip_address = models.GenericIPAddressField(
        null=True,
        blank=True,
    )

    platform = models.CharField(
        max_length=30,
        blank=True,
    )

    app_version = models.CharField(
        max_length=50,
        blank=True,
    )

    device = models.CharField(
        max_length=100,
        blank=True,
    )

    metadata = models.JSONField(
        default=dict,
        blank=True,
    )

    created_at = models.DateTimeField(
        auto_now_add=True,
        db_index=True,
    )

    class Meta:
        db_table = "analytics_events"
        ordering = ["-created_at"]
        indexes = [
            models.Index(
                fields=[
                    "event_type",
                    "created_at",
                ]
            ),
            models.Index(
                fields=[
                    "user",
                    "created_at",
                ]
            ),
        ]

    def __str__(self):
        return (
            f"{self.event_type} - "
            f"{self.created_at}"
        )