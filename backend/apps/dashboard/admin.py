from django.contrib import admin

from .models import DashboardSnapshot


@admin.register(DashboardSnapshot)
class DashboardSnapshotAdmin(
    admin.ModelAdmin
):
    list_display = [
        "snapshot_type",
        "total_users",
        "total_mechanics",
        "total_vehicles",
        "total_bookings",
        "total_orders",
        "total_revenue",
        "generated_at",
    ]

    list_filter = [
        "snapshot_type",
        "generated_at",
    ]

    search_fields = [
        "snapshot_type",
    ]

    readonly_fields = [
        "generated_at",
    ]