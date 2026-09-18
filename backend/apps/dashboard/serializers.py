from rest_framework import serializers

from .models import DashboardSnapshot


class DashboardSnapshotSerializer(
    serializers.ModelSerializer
):
    class Meta:
        model = DashboardSnapshot
        fields = [
            "id",
            "snapshot_type",
            "total_users",
            "total_mechanics",
            "total_vehicles",
            "total_bookings",
            "total_orders",
            "total_revenue",
            "metadata",
            "generated_at",
        ]

        read_only_fields = [
            "id",
            "generated_at",
        ]