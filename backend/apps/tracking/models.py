import uuid

from django.conf import settings
from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models


class TrackingSessionStatus(models.TextChoices):
    ACTIVE = "ACTIVE", "Active"
    PAUSED = "PAUSED", "Paused"
    COMPLETED = "COMPLETED", "Completed"
    CANCELLED = "CANCELLED", "Cancelled"


class TrackingType(models.TextChoices):
    VEHICLE = "VEHICLE", "Vehicle"
    MECHANIC = "MECHANIC", "Mechanic"
    BOOKING = "BOOKING", "Booking"
    DELIVERY = "DELIVERY", "Delivery"


class LocationSource(models.TextChoices):
    GPS = "GPS", "GPS"
    NETWORK = "NETWORK", "Network"
    MANUAL = "MANUAL", "Manual"
    BLUETOOTH = "BLUETOOTH", "Bluetooth"
    OBD = "OBD", "OBD"


class GeofenceType(models.TextChoices):
    CIRCLE = "CIRCLE", "Circle"


class GeofenceEventType(models.TextChoices):
    ENTER = "ENTER", "Enter"
    EXIT = "EXIT", "Exit"


class TrackingSession(models.Model):
    reference = models.CharField(
        max_length=50,
        unique=True,
        editable=False,
        db_index=True,
    )

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="tracking_sessions",
    )

    vehicle = models.ForeignKey(
        "vehicles.Vehicle",
        on_delete=models.CASCADE,
        related_name="tracking_sessions",
        null=True,
        blank=True,
    )

    tracking_type = models.CharField(
        max_length=20,
        choices=TrackingType.choices,
        default=TrackingType.VEHICLE,
        db_index=True,
    )

    status = models.CharField(
        max_length=20,
        choices=TrackingSessionStatus.choices,
        default=TrackingSessionStatus.ACTIVE,
        db_index=True,
    )

    started_at = models.DateTimeField(
        auto_now_add=True,
        db_index=True,
    )

    ended_at = models.DateTimeField(
        null=True,
        blank=True,
    )

    last_location_at = models.DateTimeField(
        null=True,
        blank=True,
        db_index=True,
    )

    total_distance_km = models.DecimalField(
        max_digits=12,
        decimal_places=3,
        default=0,
    )

    metadata = models.JSONField(
        default=dict,
        blank=True,
    )

    created_at = models.DateTimeField(
        auto_now_add=True,
    )

    updated_at = models.DateTimeField(
        auto_now=True,
    )

    class Meta:
        db_table = "tracking_sessions"
        ordering = ["-started_at"]
        indexes = [
            models.Index(
                fields=["user", "status"],
            ),
            models.Index(
                fields=["vehicle", "status"],
            ),
            models.Index(
                fields=["tracking_type", "status"],
            ),
            models.Index(
                fields=["last_location_at"],
            ),
        ]

    def save(self, *args, **kwargs):
        if not self.reference:
            self.reference = (
                f"TRK-{uuid.uuid4().hex[:14].upper()}"
            )

        super().save(*args, **kwargs)

    def __str__(self):
        return self.reference


class VehicleLocation(models.Model):
    session = models.ForeignKey(
        TrackingSession,
        on_delete=models.CASCADE,
        related_name="locations",
    )

    vehicle = models.ForeignKey(
        "vehicles.Vehicle",
        on_delete=models.CASCADE,
        related_name="location_history",
    )

    latitude = models.DecimalField(
        max_digits=10,
        decimal_places=7,
        validators=[
            MinValueValidator(-90),
            MaxValueValidator(90),
        ],
    )

    longitude = models.DecimalField(
        max_digits=10,
        decimal_places=7,
        validators=[
            MinValueValidator(-180),
            MaxValueValidator(180),
        ],
    )

    altitude = models.FloatField(
        null=True,
        blank=True,
    )

    accuracy = models.FloatField(
        null=True,
        blank=True,
        validators=[
            MinValueValidator(0),
        ],
    )

    speed_kmh = models.FloatField(
        null=True,
        blank=True,
        validators=[
            MinValueValidator(0),
        ],
    )

    heading = models.FloatField(
        null=True,
        blank=True,
        validators=[
            MinValueValidator(0),
            MaxValueValidator(360),
        ],
    )

    battery_level = models.PositiveSmallIntegerField(
        null=True,
        blank=True,
        validators=[
            MinValueValidator(0),
            MaxValueValidator(100),
        ],
    )

    source = models.CharField(
        max_length=20,
        choices=LocationSource.choices,
        default=LocationSource.GPS,
    )

    recorded_at = models.DateTimeField(
        db_index=True,
    )

    created_at = models.DateTimeField(
        auto_now_add=True,
    )

    class Meta:
        db_table = "vehicle_locations"
        ordering = ["-recorded_at"]
        indexes = [
            models.Index(
                fields=["vehicle", "recorded_at"],
            ),
            models.Index(
                fields=["session", "recorded_at"],
            ),
            models.Index(
                fields=["latitude", "longitude"],
            ),
        ]

    def __str__(self):
        return (
            f"{self.vehicle_id} - "
            f"{self.latitude}, {self.longitude}"
        )


class MechanicLocation(models.Model):
    mechanic = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="mechanic_location_history",
    )

    latitude = models.DecimalField(
        max_digits=10,
        decimal_places=7,
        validators=[
            MinValueValidator(-90),
            MaxValueValidator(90),
        ],
    )

    longitude = models.DecimalField(
        max_digits=10,
        decimal_places=7,
        validators=[
            MinValueValidator(-180),
            MaxValueValidator(180),
        ],
    )

    altitude = models.FloatField(
        null=True,
        blank=True,
    )

    accuracy = models.FloatField(
        null=True,
        blank=True,
        validators=[
            MinValueValidator(0),
        ],
    )

    speed_kmh = models.FloatField(
        null=True,
        blank=True,
        validators=[
            MinValueValidator(0),
        ],
    )

    heading = models.FloatField(
        null=True,
        blank=True,
        validators=[
            MinValueValidator(0),
            MaxValueValidator(360),
        ],
    )

    is_online = models.BooleanField(
        default=True,
        db_index=True,
    )

    recorded_at = models.DateTimeField(
        db_index=True,
    )

    created_at = models.DateTimeField(
        auto_now_add=True,
    )

    class Meta:
        db_table = "mechanic_locations"
        ordering = ["-recorded_at"]
        indexes = [
            models.Index(
                fields=["mechanic", "recorded_at"],
            ),
            models.Index(
                fields=["mechanic", "is_online"],
            ),
        ]

    def __str__(self):
        return f"Mechanic {self.mechanic_id}"


class Geofence(models.Model):
    reference = models.CharField(
        max_length=50,
        unique=True,
        editable=False,
    )

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="geofences",
    )

    vehicle = models.ForeignKey(
        "vehicles.Vehicle",
        on_delete=models.CASCADE,
        related_name="geofences",
        null=True,
        blank=True,
    )

    name = models.CharField(
        max_length=255,
    )

    geofence_type = models.CharField(
        max_length=20,
        choices=GeofenceType.choices,
        default=GeofenceType.CIRCLE,
    )

    latitude = models.DecimalField(
        max_digits=10,
        decimal_places=7,
        validators=[
            MinValueValidator(-90),
            MaxValueValidator(90),
        ],
    )

    longitude = models.DecimalField(
        max_digits=10,
        decimal_places=7,
        validators=[
            MinValueValidator(-180),
            MaxValueValidator(180),
        ],
    )

    radius_meters = models.PositiveIntegerField(
        validators=[
            MinValueValidator(10),
        ],
    )

    is_active = models.BooleanField(
        default=True,
        db_index=True,
    )

    notify_on_enter = models.BooleanField(
        default=True,
    )

    notify_on_exit = models.BooleanField(
        default=True,
    )

    created_at = models.DateTimeField(
        auto_now_add=True,
    )

    updated_at = models.DateTimeField(
        auto_now=True,
    )

    class Meta:
        db_table = "geofences"
        ordering = ["-created_at"]
        indexes = [
            models.Index(
                fields=["user", "is_active"],
            ),
            models.Index(
                fields=["vehicle", "is_active"],
            ),
        ]

    def save(self, *args, **kwargs):
        if not self.reference:
            self.reference = (
                f"GEO-{uuid.uuid4().hex[:14].upper()}"
            )

        super().save(*args, **kwargs)

    def __str__(self):
        return self.name


class GeofenceEvent(models.Model):
    geofence = models.ForeignKey(
        Geofence,
        on_delete=models.CASCADE,
        related_name="events",
    )

    vehicle = models.ForeignKey(
        "vehicles.Vehicle",
        on_delete=models.CASCADE,
        related_name="geofence_events",
        null=True,
        blank=True,
    )

    event_type = models.CharField(
        max_length=10,
        choices=GeofenceEventType.choices,
    )

    latitude = models.DecimalField(
        max_digits=10,
        decimal_places=7,
    )

    longitude = models.DecimalField(
        max_digits=10,
        decimal_places=7,
    )

    occurred_at = models.DateTimeField(
        db_index=True,
    )

    created_at = models.DateTimeField(
        auto_now_add=True,
    )

    class Meta:
        db_table = "geofence_events"
        ordering = ["-occurred_at"]
        indexes = [
            models.Index(
                fields=["geofence", "occurred_at"],
            ),
            models.Index(
                fields=["vehicle", "occurred_at"],
            ),
        ]

    def __str__(self):
        return (
            f"{self.geofence.name} - "
            f"{self.event_type}"
        )