from django.db import models


class DashboardSnapshot(models.Model):
    """
    Optional cached dashboard snapshot.

    This model is intentionally lightweight.
    It can later be populated by scheduled background
    jobs for high-traffic production environments.
    """

    snapshot_type = models.CharField(
        max_length=50,
        db_index=True,
    )

    total_users = models.PositiveBigIntegerField(
        default=0,
    )

    total_mechanics = models.PositiveBigIntegerField(
        default=0,
    )

    total_vehicles = models.PositiveBigIntegerField(
        default=0,
    )

    total_bookings = models.PositiveBigIntegerField(
        default=0,
    )

    total_orders = models.PositiveBigIntegerField(
        default=0,
    )

    total_revenue = models.DecimalField(
        max_digits=18,
        decimal_places=2,
        default=0,
    )

    metadata = models.JSONField(
        default=dict,
        blank=True,
    )

    generated_at = models.DateTimeField(
        auto_now_add=True,
    )

    class Meta:
        db_table = "dashboard_snapshots"
        ordering = ["-generated_at"]
        indexes = [
            models.Index(
                fields=[
                    "snapshot_type",
                    "generated_at",
                ]
            ),
        ]

    def __str__(self):
        return (
            f"{self.snapshot_type} - "
            f"{self.generated_at}"
        )