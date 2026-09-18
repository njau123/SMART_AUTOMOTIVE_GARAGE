from django.conf import settings
from django.db import models


class OBDScan(models.Model):
    class Status(models.TextChoices):
        PENDING = "PENDING", "Pending"
        CONNECTING = "CONNECTING", "Connecting"
        SCANNING = "SCANNING", "Scanning"
        COMPLETED = "COMPLETED", "Completed"
        FAILED = "FAILED", "Failed"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="obd_scans",
    )
    vehicle = models.ForeignKey(
        "vehicles.Vehicle",
        on_delete=models.CASCADE,
        related_name="obd_scans",
    )
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.PENDING,
        db_index=True,
    )
    adapter_name = models.CharField(max_length=150, blank=True)
    protocol = models.CharField(max_length=100, blank=True)
    dtc_codes = models.JSONField(default=list, blank=True)
    live_data = models.JSONField(default=dict, blank=True)
    summary = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "obd_scans"
        ordering = ["-created_at"]

    def __str__(self):
        return f"OBD Scan #{self.pk}"
