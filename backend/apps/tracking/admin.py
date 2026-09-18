from django.contrib import admin

from .models import (
    Geofence,
    GeofenceEvent,
    MechanicLocation,
    TrackingSession,
    VehicleLocation,
)


@admin.register(TrackingSession)
class TrackingSessionAdmin(admin.ModelAdmin):
    list_display = [
        "reference",
        "user",
        "vehicle",
        "tracking_type",
        "status",
        "started_at",
        "last_location_at",
    ]

    list_filter = [
        "tracking_type",
        "status",
        "started_at",
    ]

    search_fields = [
        "reference",
        "user__email",
        "vehicle__registration_number",
    ]

    readonly_fields = [
        "reference",
        "started_at",
        "created_at",
        "updated_at",
    ]

    autocomplete_fields = [
        "user",
        "vehicle",
    ]


@admin.register(VehicleLocation)
class VehicleLocationAdmin(admin.ModelAdmin):
    list_display = [
        "vehicle",
        "latitude",
        "longitude",
        "speed_kmh",
        "heading",
        "accuracy",
        "recorded_at",
    ]

    list_filter = [
        "source",
        "recorded_at",
    ]

    search_fields = [
        "vehicle__registration_number",
        "vehicle__vin",
    ]

    autocomplete_fields = [
        "vehicle",
        "session",
    ]


@admin.register(MechanicLocation)
class MechanicLocationAdmin(admin.ModelAdmin):
    list_display = [
        "mechanic",
        "latitude",
        "longitude",
        "speed_kmh",
        "is_online",
        "recorded_at",
    ]

    list_filter = [
        "is_online",
        "recorded_at",
    ]

    search_fields = [
        "mechanic__email",
        "mechanic__first_name",
        "mechanic__last_name",
    ]

    autocomplete_fields = [
        "mechanic",
    ]


@admin.register(Geofence)
class GeofenceAdmin(admin.ModelAdmin):
    list_display = [
        "reference",
        "name",
        "user",
        "vehicle",
        "radius_meters",
        "is_active",
    ]

    list_filter = [
        "geofence_type",
        "is_active",
        "notify_on_enter",
        "notify_on_exit",
    ]

    search_fields = [
        "reference",
        "name",
        "user__email",
        "vehicle__registration_number",
    ]

    readonly_fields = [
        "reference",
        "created_at",
        "updated_at",
    ]

    autocomplete_fields = [
        "user",
        "vehicle",
    ]


@admin.register(GeofenceEvent)
class GeofenceEventAdmin(admin.ModelAdmin):
    list_display = [
        "geofence",
        "vehicle",
        "event_type",
        "latitude",
        "longitude",
        "occurred_at",
    ]

    list_filter = [
        "event_type",
        "occurred_at",
    ]

    search_fields = [
        "geofence__name",
        "vehicle__registration_number",
    ]

    autocomplete_fields = [
        "geofence",
        "vehicle",
    ]