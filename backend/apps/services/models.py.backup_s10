from django.db import models


class ServiceCategory(models.Model):
    name = models.CharField(
        max_length=150,
        unique=True,
    )

    description = models.TextField(
        blank=True,
    )

    image = models.ImageField(
        upload_to="services/categories/%Y/%m/",
        null=True,
        blank=True,
    )

    is_active = models.BooleanField(
        default=True,
    )

    created_at = models.DateTimeField(
        auto_now_add=True,
    )

    updated_at = models.DateTimeField(
        auto_now=True,
    )

    class Meta:
        db_table = "service_categories"
        ordering = ["name"]

    def __str__(self):
        return self.name


class Service(models.Model):
    category = models.ForeignKey(
        ServiceCategory,
        on_delete=models.PROTECT,
        related_name="services",
    )

    name = models.CharField(
        max_length=200,
    )

    description = models.TextField()

    symptoms = models.JSONField(
        default=list,
        blank=True,
    )

    supported_vehicle_types = models.JSONField(
        default=list,
        blank=True,
    )

    estimated_duration_minutes = models.PositiveIntegerField(
        default=60,
    )

    base_price = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=0,
    )

    image = models.ImageField(
        upload_to="services/%Y/%m/",
        null=True,
        blank=True,
    )

    video = models.FileField(
        upload_to="services/videos/%Y/%m/",
        null=True,
        blank=True,
        help_text="Video ya service (mp4, webm, max 50MB)",
    )

    # ===== RATIBA (Schedule) =====
    available_days = models.JSONField(
        default=list,
        blank=True,
        help_text="Siku zinazopatikana: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']",
    )

    start_time = models.TimeField(
        null=True,
        blank=True,
        help_text="Muda wa kuanza (mfano: 08:00)",
    )

    end_time = models.TimeField(
        null=True,
        blank=True,
        help_text="Muda wa kumaliza (mfano: 18:00)",
    )

    fixed_price = models.BooleanField(
        default=False,
        help_text="Kama True, bei haiwezi kubadilishwa (mfano: AI Diagnosis 30k)",
    )

    is_active = models.BooleanField(
        default=True,
    )

    created_at = models.DateTimeField(
        auto_now_add=True,
    )

    updated_at = models.DateTimeField(
        auto_now=True,
    )

    class Meta:
        db_table = "services"
        ordering = ["name"]
        indexes = [
            models.Index(
                fields=["category", "is_active"]
            ),
            models.Index(
                fields=["is_active"]
            ),
        ]

    def __str__(self):
        return self.name

# ==================== SERVICE BOOKING (GROUP 3) ====================
class ServiceBooking(models.Model):
    """Booking ya service — user anaweka gari + service, analipa 50% deposit."""

    class Status(models.TextChoices):
        PENDING_PAYMENT = "PENDING_PAYMENT", "Inasubiri malipo"
        DEPOSIT_PAID = "DEPOSIT_PAID", "Deposit imelipwa"
        CONFIRMED = "CONFIRMED", "Imethibitishwa na admin"
        IN_PROGRESS = "IN_PROGRESS", "Inafanyika"
        COMPLETED = "COMPLETED", "Imekamilika"
        CANCELLED = "CANCELLED", "Imefutwa"

    class PaymentStatus(models.TextChoices):
        UNPAID = "UNPAID", "Haijalipwa"
        DEPOSIT_PAID = "DEPOSIT_PAID", "Deposit imelipwa"
        FULLY_PAID = "FULLY_PAID", "Imelipwa yote"

    booking_number = models.CharField(max_length=50, unique=True, db_index=True)
    user = models.ForeignKey(
        "accounts.User", on_delete=models.PROTECT,
        related_name="service_bookings",
    )
    service = models.ForeignKey(
        Service, on_delete=models.PROTECT,
        related_name="service_bookings",
    )

    # ===== Vehicle details (user anaweka) =====
    vehicle_make = models.CharField(max_length=100)
    vehicle_model = models.CharField(max_length=100)
    vehicle_year = models.CharField(max_length=20, blank=True)
    vehicle_registration = models.CharField(max_length=50, blank=True)
    vehicle_notes = models.TextField(blank=True)

    # ===== Pricing =====
    total_price = models.DecimalField(max_digits=12, decimal_places=2)
    deposit_amount = models.DecimalField(max_digits=12, decimal_places=2)
    balance_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)

    # ===== Payment =====
    payment_status = models.CharField(
        max_length=20, choices=PaymentStatus.choices,
        default=PaymentStatus.UNPAID, db_index=True,
    )
    payment_reference = models.CharField(max_length=100, blank=True, db_index=True)
    payment_phone = models.CharField(max_length=20, blank=True)
    payment_method = models.CharField(max_length=20, default="MOBILE_MONEY")
    detected_network = models.CharField(max_length=30, blank=True)
    payment_countdown_ends_at = models.DateTimeField(null=True, blank=True)

    # ===== Booking status =====
    status = models.CharField(
        max_length=30, choices=Status.choices,
        default=Status.PENDING_PAYMENT, db_index=True,
    )

    # ===== Appointment (admin ana-set) =====
    appointment_date = models.DateField(null=True, blank=True)
    appointment_time = models.CharField(max_length=20, blank=True)
    mechanic_assigned = models.ForeignKey(
        "mechanics.MechanicProfile", on_delete=models.SET_NULL,
        null=True, blank=True, related_name="service_bookings",
    )

    # ===== Location tracking (kama mobile service) =====
    service_latitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    service_longitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    service_location = models.CharField(max_length=255, blank=True)
    distance_km = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    eta_minutes = models.PositiveIntegerField(default=0)
    eta_countdown_ends_at = models.DateTimeField(null=True, blank=True)

    # ===== Completion =====
    receipt_confirmed_at = models.DateTimeField(null=True, blank=True)
    extended_count = models.PositiveIntegerField(default=0)
    completed_at = models.DateTimeField(null=True, blank=True)

    # ===== Admin =====
    admin_notes = models.TextField(blank=True)

    # ===== Feedback =====
    user_feedback = models.TextField(blank=True)
    user_rating = models.PositiveSmallIntegerField(default=0)

    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "service_bookings"
        ordering = ["-created_at"]

    def save(self, *args, **kwargs):
        import uuid as _u
        if not self.booking_number:
            self.booking_number = f"SB-{_u.uuid4().hex[:10].upper()}"
        if self.service and not self.total_price:
            self.total_price = self.service.base_price
        if self.total_price:
            from decimal import Decimal
            self.deposit_amount = (self.total_price * Decimal("0.5")).quantize(Decimal("0.01"))
            self.balance_amount = self.total_price - self.deposit_amount
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.booking_number} - {self.service.name}"

