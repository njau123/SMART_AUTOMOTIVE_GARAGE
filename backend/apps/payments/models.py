import uuid
from decimal import Decimal

from django.conf import settings
from django.core.validators import MinValueValidator
from django.db import models


class PaymentMethodType(models.TextChoices):
    WALLET = "WALLET", "Wallet"
    MOBILE_MONEY = "MOBILE_MONEY", "Mobile Money"
    CARD = "CARD", "Card"
    BANK = "BANK", "Bank Transfer"
    CASH = "CASH", "Cash"


class PaymentProvider(models.TextChoices):
    INTERNAL = "INTERNAL", "Internal Wallet"
    SANDBOX = "SANDBOX", "Sandbox"
    MPESA = "MPESA", "M-Pesa"
    TIGOPESA = "TIGOPESA", "Tigo Pesa"
    AIRTEL_MONEY = "AIRTEL_MONEY", "Airtel Money"
    HALOPESA = "HALOPESA", "HaloPesa"
    CRDB = "CRDB", "CRDB"
    NMB = "NMB", "NMB"


class PaymentStatus(models.TextChoices):
    CREATED = "CREATED", "Created"
    PENDING = "PENDING", "Pending"
    PROCESSING = "PROCESSING", "Processing"
    SUCCESS = "SUCCESS", "Success"
    FAILED = "FAILED", "Failed"
    CANCELLED = "CANCELLED", "Cancelled"
    EXPIRED = "EXPIRED", "Expired"
    REFUNDED = "REFUNDED", "Refunded"
    PARTIALLY_REFUNDED = "PARTIALLY_REFUNDED", "Partially Refunded"


class PaymentPurpose(models.TextChoices):
    WALLET_TOPUP = "WALLET_TOPUP", "Wallet Top Up"
    BOOKING = "BOOKING", "Booking"
    SERVICE = "SERVICE", "Service"
    SPARE_PART = "SPARE_PART", "Spare Part"
    ORDER = "ORDER", "Order"
    OTHER = "OTHER", "Other"


class Payment(models.Model):
    reference = models.CharField(
        max_length=50,
        unique=True,
        editable=False,
        db_index=True,
    )

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name="payments",
    )

    amount = models.DecimalField(
        max_digits=18,
        decimal_places=2,
        validators=[
            MinValueValidator(Decimal("0.01")),
        ],
    )

    currency = models.CharField(
        max_length=3,
        default="TZS",
    )

    method = models.CharField(
        max_length=30,
        choices=PaymentMethodType.choices,
    )

    provider = models.CharField(
        max_length=30,
        choices=PaymentProvider.choices,
    )

    purpose = models.CharField(
        max_length=30,
        choices=PaymentPurpose.choices,
        default=PaymentPurpose.OTHER,
    )

    status = models.CharField(
        max_length=30,
        choices=PaymentStatus.choices,
        default=PaymentStatus.CREATED,
        db_index=True,
    )

    description = models.CharField(
        max_length=500,
        blank=True,
    )

    external_reference = models.CharField(
        max_length=255,
        blank=True,
        db_index=True,
    )

    gateway_reference = models.CharField(
        max_length=255,
        blank=True,
        db_index=True,
    )

    callback_reference = models.CharField(
        max_length=255,
        blank=True,
    )

    phone_number = models.CharField(
        max_length=30,
        blank=True,
    )

    metadata = models.JSONField(
        default=dict,
        blank=True,
    )

    failure_reason = models.TextField(
        blank=True,
    )

    expires_at = models.DateTimeField(
        null=True,
        blank=True,
    )

    completed_at = models.DateTimeField(
        null=True,
        blank=True,
    )

    created_at = models.DateTimeField(
        auto_now_add=True,
        db_index=True,
    )

    updated_at = models.DateTimeField(
        auto_now=True,
    )

    class Meta:
        db_table = "payments"
        ordering = ["-created_at"]
        indexes = [
            models.Index(
                fields=["user", "status"],
            ),
            models.Index(
                fields=["user", "created_at"],
            ),
            models.Index(
                fields=["provider", "status"],
            ),
            models.Index(
                fields=["external_reference"],
            ),
        ]

    def save(self, *args, **kwargs):
        if not self.reference:
            self.reference = (
                f"PAY-{uuid.uuid4().hex[:14].upper()}"
            )

        super().save(*args, **kwargs)

    def check_expiry(self):
        """Angalia kama payment ime-expire. Kama ndiyo, ibadilishe status."""
        from django.utils import timezone as tz
        if (
            self.status in (PaymentStatus.PENDING, PaymentStatus.CREATED, PaymentStatus.PROCESSING)
            and self.expires_at
            and self.expires_at < tz.now()
        ):
            self.status = PaymentStatus.EXPIRED
            self.failure_reason = "Payment expired (45 minutes passed)"
            self.save(update_fields=["status", "failure_reason", "updated_at"])
            return True
        return False

    def __str__(self):
        return self.reference


class PaymentAttempt(models.Model):
    payment = models.ForeignKey(
        Payment,
        on_delete=models.CASCADE,
        related_name="attempts",
    )

    attempt_number = models.PositiveIntegerField()

    status = models.CharField(
        max_length=30,
        choices=PaymentStatus.choices,
    )

    request_payload = models.JSONField(
        default=dict,
        blank=True,
    )

    response_payload = models.JSONField(
        default=dict,
        blank=True,
    )

    gateway_reference = models.CharField(
        max_length=255,
        blank=True,
    )

    error_message = models.TextField(
        blank=True,
    )

    created_at = models.DateTimeField(
        auto_now_add=True,
    )

    class Meta:
        db_table = "payment_attempts"
        ordering = ["-created_at"]
        constraints = [
            models.UniqueConstraint(
                fields=[
                    "payment",
                    "attempt_number",
                ],
                name="unique_payment_attempt_number",
            )
        ]

    def __str__(self):
        return (
            f"{self.payment.reference} "
            f"Attempt {self.attempt_number}"
        )


class PaymentWebhookEvent(models.Model):
    event_id = models.CharField(
        max_length=255,
        unique=True,
        db_index=True,
    )

    provider = models.CharField(
        max_length=30,
        choices=PaymentProvider.choices,
    )

    event_type = models.CharField(
        max_length=100,
    )

    payment = models.ForeignKey(
        Payment,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="webhook_events",
    )

    payload = models.JSONField(
        default=dict,
        blank=True,
    )

    signature = models.TextField(
        blank=True,
    )

    processed = models.BooleanField(
        default=False,
    )

    processing_error = models.TextField(
        blank=True,
    )

    processed_at = models.DateTimeField(
        null=True,
        blank=True,
    )

    created_at = models.DateTimeField(
        auto_now_add=True,
        db_index=True,
    )

    class Meta:
        db_table = "payment_webhook_events"
        ordering = ["-created_at"]

    def __str__(self):
        return self.event_id


class PaymentRefund(models.Model):
    reference = models.CharField(
        max_length=50,
        unique=True,
        editable=False,
        db_index=True,
    )

    payment = models.ForeignKey(
        Payment,
        on_delete=models.PROTECT,
        related_name="refunds",
    )

    amount = models.DecimalField(
        max_digits=18,
        decimal_places=2,
        validators=[
            MinValueValidator(Decimal("0.01")),
        ],
    )

    reason = models.TextField()

    status = models.CharField(
        max_length=30,
        choices=PaymentStatus.choices,
        default=PaymentStatus.CREATED,
    )

    gateway_reference = models.CharField(
        max_length=255,
        blank=True,
    )

    metadata = models.JSONField(
        default=dict,
        blank=True,
    )

    completed_at = models.DateTimeField(
        null=True,
        blank=True,
    )

    created_at = models.DateTimeField(
        auto_now_add=True,
    )

    class Meta:
        db_table = "payment_refunds"
        ordering = ["-created_at"]

    def save(self, *args, **kwargs):
        if not self.reference:
            self.reference = (
                f"REF-{uuid.uuid4().hex[:14].upper()}"
            )

        super().save(*args, **kwargs)

    def __str__(self):
        return self.reference