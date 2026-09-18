from django.contrib import admin

from .models import Vehicle


@admin.register(Vehicle)
class VehicleAdmin(admin.ModelAdmin):
    list_display = [
        "registration_number",
        "make",
        "model",
        "year",
        "user",
        "fuel_type",
        "transmission",
        "is_primary",
        "is_active",
        "created_at",
    ]

    list_filter = [
        "fuel_type",
        "transmission",
        "is_primary",
        "is_active",
        "year",
    ]

    search_fields = [
        "registration_number",
        "vin",
        "make",
        "model",
        "user__email",
        "user__first_name",
        "user__last_name",
    ]

    readonly_fields = [
        "created_at",
        "updated_at",
    ]

    list_select_related = [
        "user",
    ]