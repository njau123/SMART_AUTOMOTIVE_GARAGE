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