import uuid

from django.conf import settings
from django.db import models


class BluetoothDeviceType(models.TextChoices):
    OBD_ADAPTER = "OBD_ADAPTER", "OBD-II Adapter"
    ELM327 = "ELM327", "ELM327"
    OBDLINK = "OBDLINK", "OBDLink"
    GENERIC = "GENERIC", "Generic Bluetooth Device"


class BluetoothConnectionType(models.TextChoices):
    CLASSIC = "CLASSIC", "Bluetooth Classic"
    BLE = "BLE", "Bluetooth Low Energy"


class BluetoothDeviceStatus(models.TextChoices):
    UNKNOWN = "UNKNOWN", "Unknown"
    AVAILABLE = "AVAILABLE", "Available"
    PAIRED = "PAIRED", "Paired"
    CONNECTING = "CONNECTING", "Connecting"
    CONNECTED = "CONNECTED", "Connected"
    DISCONNECTED = "DISCONNECTED", "Disconnected"
    ERROR = "ERROR", "Error"


class BluetoothConnectionStatus(models.TextChoices):
    CREATED = "CREATED", "Created"
    CONNECTING = "CONNECTING", "Connecting"
    CONNECTED = "CONNECTED", "Connected"
    DISCONNECTED = "DISCONNECTED", "Disconnected"
    FAILED = "FAILED", "Failed"


class OBDCommandDirection(models.TextChoices):
    REQUEST = "REQUEST", "Request"
    RESPONSE = "RESPONSE", "Response"


class BluetoothDevice(models.Model):
    """
    Stores an OBD/Bluetooth device known by a user.

    Actual Bluetooth communication is performed by Flutter.
    Django stores device metadata and connection history.
    """

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="bluetooth_devices",
    )

    device_id = models.CharField(
        max_length=255,
        db_index=True,
        help_text="Platform-specific Bluetooth identifier.",
    )

    name = models.CharField(
        max_length=255,
    )

    device_type = models.CharField(
        max_length=30,
        choices=BluetoothDeviceType.choices,
        default=BluetoothDeviceType.GENERIC,
    )

    connection_type = models.CharField(
        max_length=20,
        choices=BluetoothConnectionType.choices,
        default=BluetoothConnectionType.CLASSIC,
    )

    mac_address = models.CharField(
        max_length=50,
        blank=True,
    )

    manufacturer = models.CharField(
        max_length=255,
        blank=True,
    )

    model_name = models.CharField(
        max_length=255,
        blank=True,
    )

    firmware_version = models.CharField(
        max_length=100,
        blank=True,
    )

    hardware_version = models.CharField(
        max_length=100,
        blank=True,
    )

    protocol = models.CharField(
        max_length=50,
        blank=True,
    )

    status = models.CharField(
        max_length=20,
        choices=BluetoothDeviceStatus.choices,
        default=BluetoothDeviceStatus.UNKNOWN,
        db_index=True,
    )

    is_paired = models.BooleanField(
        default=False,
    )

    is_trusted = models.BooleanField(
        default=False,
    )

    is_active = models.BooleanField(
        default=True,
    )

    last_connected_at = models.DateTimeField(
        null=True,
        blank=True,
    )

    last_disconnected_at = models.DateTimeField(
        null=True,
        blank=True,
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
        db_table = "bluetooth_devices"
        ordering = ["-updated_at"]
        constraints = [
            models.UniqueConstraint(
                fields=["user", "device_id"],
                name="unique_bluetooth_device_per_user",
            )
        ]
        indexes = [
            models.Index(
                fields=["user", "status"],
            ),
            models.Index(
                fields=["device_id"],
            ),
        ]

    def __str__(self):
        return f"{self.name} ({self.device_id})"


class BluetoothConnectionSession(models.Model):
    """
    Represents one connection lifecycle between Flutter
    and a Bluetooth/OBD device.
    """

    reference = models.CharField(
        max_length=40,
        unique=True,
        editable=False,
        db_index=True,
    )

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="bluetooth_connection_sessions",
    )

    device = models.ForeignKey(
        BluetoothDevice,
        on_delete=models.CASCADE,
        related_name="connection_sessions"
    )


    status = models.CharField(
        max_length=20,
        choices=BluetoothConnectionStatus.choices,
        default=BluetoothConnectionStatus.CREATED,
        db_index=True,
    )

    connection_type = models.CharField(
        max_length=20,
        choices=BluetoothConnectionType.choices,
    )

    transport_identifier = models.CharField(
        max_length=255,
        blank=True,
    )

    error_message = models.TextField(
        blank=True,
    )

    connected_at = models.DateTimeField(
        null=True,
        blank=True,
    )

    disconnected_at = models.DateTimeField(
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
        db_table = "bluetooth_connection_sessions"
        ordering = ["-created_at"]
        indexes = [
            models.Index(
                fields=["user", "status"],
            ),
            models.Index(
                fields=["device", "created_at"],
            ),
        ]

    def save(self, *args, **kwargs):
        if not self.reference:
            self.reference = (
                f"BT-{uuid.uuid4().hex[:10].upper()}"
            )

        super().save(*args, **kwargs)

    def __str__(self):
        return self.reference


class OBDCommandLog(models.Model):
    """
    Stores OBD requests/responses exchanged through Flutter.

    Example request:
        010C

    Example response:
        41 0C 1A F8
    """

    connection = models.ForeignKey(
        BluetoothConnectionSession,
        on_delete=models.CASCADE,
        related_name="command_logs",
    )

    command = models.CharField(
        max_length=255,
    )

    direction = models.CharField(
        max_length=20,
        choices=OBDCommandDirection.choices,
    )

    raw_data = models.TextField(
        blank=True,
    )

    decoded_data = models.JSONField(
        default=dict,
        blank=True,
    )

    successful = models.BooleanField(
        default=True,
    )

    error_message = models.TextField(
        blank=True,
    )

    response_time_ms = models.PositiveIntegerField(
        null=True,
        blank=True,
    )

    created_at = models.DateTimeField(
        auto_now_add=True,
        db_index=True,
    )

    class Meta:
        db_table = "obd_command_logs"
        ordering = ["-created_at"]
        indexes = [
            models.Index(
                fields=["connection", "created_at"],
            ),
            models.Index(
                fields=["command"],
            ),
        ]

    def __str__(self):
        return f"{self.command} - {self.direction}"


class OBDTelemetry(models.Model):
    """
    Stores decoded telemetry received from the vehicle.

    Flutter reads OBD values from the adapter and submits
    normalized values here.
    """

    connection = models.ForeignKey(
        BluetoothConnectionSession,
        on_delete=models.CASCADE,
        related_name="telemetry",
    )


    pid = models.CharField(
        max_length=20,
        db_index=True,
    )

    name = models.CharField(
        max_length=100,
    )

    value = models.DecimalField(
        max_digits=14,
        decimal_places=4,
        null=True,
        blank=True,
    )

    unit = models.CharField(
        max_length=30,
        blank=True,
    )

    raw_value = models.CharField(
        max_length=255,
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

    recorded_at = models.DateTimeField(
        db_index=True,
    )

    created_at = models.DateTimeField(
        auto_now_add=True,
    )

    class Meta:
        db_table = "obd_telemetry"
        ordering = ["-recorded_at"]
        indexes = [
            models.Index(
                fields=["connection", "recorded_at"],
            ),
            models.Index(
                fields=["pid", "recorded_at"],
            ),
        ]

    def __str__(self):
        return f"{self.pid} - {self.value} {self.unit}"