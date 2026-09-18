from django.conf import settings
from django.core.validators import MinValueValidator, MaxValueValidator
from django.db import models


class Vehicle(models.Model):
    class FuelType(models.TextChoices):
        PETROL = "PETROL", "Petrol"
        DIESEL = "DIESEL", "Diesel"
        HYBRID = "HYBRID", "Hybrid"
        ELECTRIC = "ELECTRIC", "Electric"
        LPG = "LPG", "LPG"
        CNG = "CNG", "CNG"
        OTHER = "OTHER", "Other"

    class TransmissionType(models.TextChoices):
        MANUAL = "MANUAL", "Manual"
        AUTOMATIC = "AUTOMATIC", "Automatic"
        AMT = "AMT", "AMT"
        CVT = "CVT", "CVT"
        DCT = "DCT", "DCT"
        OTHER = "OTHER", "Other"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="vehicles",
    )

    make = models.CharField(max_length=100)
    model = models.CharField(max_length=100)
    year = models.PositiveIntegerField(
        validators=[
            MinValueValidator(1950),
            MaxValueValidator(2100),
        ]
    )

    registration_number = models.CharField(
        max_length=30,
        unique=True,
        db_index=True,
    )

    vin = models.CharField(
        max_length=17,
        unique=True,
        null=True,
        blank=True,
        db_index=True,
    )

    engine_type = models.CharField(
        max_length=100,
        blank=True,
    )

    engine_capacity_cc = models.PositiveIntegerField(
        null=True,
        blank=True,
    )

    fuel_type = models.CharField(
        max_length=20,
        choices=FuelType.choices,
        default=FuelType.PETROL,
    )

    transmission = models.CharField(
        max_length=20,
        choices=TransmissionType.choices,
        default=TransmissionType.MANUAL,
    )

    color = models.CharField(
        max_length=50,
        blank=True,
    )

    mileage_km = models.PositiveBigIntegerField(
        null=True,
        blank=True,
    )

    vehicle_image = models.ImageField(
        upload_to="vehicles/%Y/%m/",
        null=True,
        blank=True,
    )

    is_primary = models.BooleanField(
        default=False,
    )

    is_active = models.BooleanField(
        default=True,
    )

    notes = models.TextField(
        blank=True,
    )

    created_at = models.DateTimeField(
        auto_now_add=True,
    )

    updated_at = models.DateTimeField(
        auto_now=True,
    )

    class Meta:
        db_table = "vehicles"
        ordering = ["-is_primary", "-created_at"]
        indexes = [
            models.Index(
                fields=["user", "is_active"]
            ),
            models.Index(
                fields=["make", "model", "year"]
            ),
            models.Index(
                fields=["registration_number"]
            ),
            models.Index(
                fields=["vin"]
            ),
        ]

    def __str__(self):
        return (
            f"{self.make} {self.model} "
            f"({self.registration_number})"
        )

    def save(self, *args, **kwargs):
        self.make = self.make.strip()
        self.model = self.model.strip()

        self.registration_number = (
            self.registration_number
            .strip()
            .upper()
        )

        if self.vin:
            self.vin = self.vin.strip().upper()

        super().save(*args, **kwargs)