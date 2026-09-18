import uuid

from django.conf import settings
from django.core.validators import MinValueValidator
from django.db import models


class Booking(models.Model):
    class Status(models.TextChoices):
        PENDING = "PENDING", "Pending"
        ACCEPTED = "ACCEPTED", "Accepted"
        REJECTED = "REJECTED", "Rejected"
        CONFIRMED = "CONFIRMED", "Confirmed"
        ARRIVING = "ARRIVING", "Mechanic Arriving"
        IN_PROGRESS = "IN_PROGRESS", "In Progress"
        COMPLETED = "COMPLETED", "Completed"
        CANCELLED = "CANCELLED", "Cancelled"
        NO_SHOW = "NO_SHOW", "No Show"

    class PaymentStatus(models.TextChoices):
        UNPAID = "UNPAID", "Unpaid"
        PENDING = "PENDING", "Pending"
        PAID = "PAID", "Paid"
        FAILED = "FAILED", "Failed"
        REFUNDED = "REFUNDED", "Refunded"

    class BookingType(models.TextChoices):
        GARAGE = "GARAGE", "Garage Visit"
        MOBILE = "MOBILE", "Mobile Service"
        PICKUP = "PICKUP", "Vehicle Pickup"

    booking_number = models.CharField(
        max_length=50,
        unique=True,
        db_index=True,
    )

    customer = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name="customer_bookings",
    )

    mechanic = models.ForeignKey(
        "mechanics.MechanicProfile",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="bookings",
    )

    vehicle = models.ForeignKey(
        "vehicles.Vehicle",
        on_delete=models.PROTECT,
        related_name="bookings",
    )

    service = models.ForeignKey(
        "services.Service",
        on_delete=models.PROTECT,
        related_name="bookings",
    )

    booking_type = models.CharField(
        max_length=20,
        choices=BookingType.choices,
        default=BookingType.GARAGE,
    )

    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.PENDING,
        db_index=True,
    )

    payment_status = models.CharField(
        max_length=20,
        choices=PaymentStatus.choices,
        default=PaymentStatus.UNPAID,
        db_index=True,
    )

    scheduled_date = models.DateField(
        db_index=True,
    )

    scheduled_time = models.TimeField(
        db_index=True,
    )

    estimated_duration_minutes = models.PositiveIntegerField(
        default=60,
        validators=[MinValueValidator(1)],
    )

    service_price = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=0,
        validators=[MinValueValidator(0)],
    )

    additional_cost = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=0,
        validators=[MinValueValidator(0)],
    )

    total_price = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=0,
        validators=[MinValueValidator(0)],
    )

    # ===== DEPOSIT 50% + FINAL 50% =====
    deposit_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=0,
        validators=[MinValueValidator(0)],
        help_text="Deposit required (50% of total_price)",
    )

    deposit_paid = models.BooleanField(
        default=False,
        db_index=True,
    )

    final_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=0,
        validators=[MinValueValidator(0)],
        help_text="Remaining payment (50% of total_price)",
    )

    final_paid = models.BooleanField(
        default=False,
    )

    customer_notes = models.TextField(
        blank=True,
    )

    mechanic_notes = models.TextField(
        blank=True,
    )

    cancellation_reason = models.TextField(
        blank=True,
    )

    service_address = models.TextField(
        blank=True,
    )

    region = models.CharField(
        max_length=100,
        blank=True,
    )

    district = models.CharField(
        max_length=100,
        blank=True,
    )

    latitude = models.DecimalField(
        max_digits=10,
        decimal_places=7,
        null=True,
        blank=True,
    )

    longitude = models.DecimalField(
        max_digits=10,
        decimal_places=7,
        null=True,
        blank=True,
    )

    customer_confirmed_at = models.DateTimeField(
        null=True,
        blank=True,
    )

    mechanic_accepted_at = models.DateTimeField(
        null=True,
        blank=True,
    )

    started_at = models.DateTimeField(
        null=True,
        blank=True,
    )

    completed_at = models.DateTimeField(
        null=True,
        blank=True,
    )

    cancelled_at = models.DateTimeField(
        null=True,
        blank=True,
    )

    created_at = models.DateTimeField(
        auto_now_add=True,
    )

    updated_at = models.DateTimeField(
        auto_now=True,
    )

    class Meta:
        db_table = "bookings"
        ordering = ["-created_at"]
        indexes = [
            models.Index(
                fields=["customer", "status"]
            ),
            models.Index(
                fields=["mechanic", "status"]
            ),
            models.Index(
                fields=["scheduled_date", "scheduled_time"]
            ),
            models.Index(
                fields=["vehicle"]
            ),
            models.Index(
                fields=["booking_number"]
            ),
        ]

    def save(self, *args, **kwargs):
        from decimal import Decimal

        if not self.booking_number:
            self.booking_number = (
                "SAG-BK-"
                + uuid.uuid4().hex[:10].upper()
            )

        if self.service_price == 0 and self.service_id:
            try:
                self.service_price = self.service.base_price
            except Exception:
                pass

        self.total_price = (
            self.service_price + self.additional_cost
        )

        self.deposit_amount = (
            self.total_price * Decimal("0.5")
        ).quantize(Decimal("0.01"))

        self.final_amount = (
            self.total_price - self.deposit_amount
        ).quantize(Decimal("0.01"))

        super().save(*args, **kwargs)

    def __str__(self):
        return self.booking_number


class BookingStatusHistory(models.Model):
    booking = models.ForeignKey(
        Booking,
        on_delete=models.CASCADE,
        related_name="status_history",
    )

    old_status = models.CharField(
        max_length=20,
        blank=True,
    )

    new_status = models.CharField(
        max_length=20,
    )

    changed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="booking_status_changes",
    )

    note = models.TextField(
        blank=True,
    )

    created_at = models.DateTimeField(
        auto_now_add=True,
    )

    class Meta:
        db_table = "booking_status_history"
        ordering = ["created_at"]

    def __str__(self):
        return (
            f"{self.booking.booking_number}: "
            f"{self.new_status}"
        )


class BookingAttachment(models.Model):
    booking = models.ForeignKey(
        Booking,
        on_delete=models.CASCADE,
        related_name="attachments",
    )

    file = models.FileField(
        upload_to="bookings/%Y/%m/%d/",
    )

    description = models.CharField(
        max_length=255,
        blank=True,
    )

    uploaded_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
    )

    created_at = models.DateTimeField(
        auto_now_add=True,
    )

    class Meta:
        db_table = "booking_attachments"

    def __str__(self):
        return self.booking.booking_number