from django.contrib import admin

from .models import (
    BluetoothConnectionSession,
    BluetoothDevice,
    OBDCommandLog,
    OBDTelemetry,
)


@admin.register(BluetoothDevice)
class BluetoothDeviceAdmin(admin.ModelAdmin):
    list_display = [
        "name",
        "device_id",
        "user",
        "device_type",
        "connection_type",
        "status",
        "is_paired",
        "is_trusted",
        "is_active",
    ]

    list_filter = [
        "device_type",
        "connection_type",
        "status",
        "is_paired",
        "is_trusted",
        "is_active",
    ]

    search_fields = [
        "name",
        "device_id",
        "mac_address",
        "manufacturer",
        "model_name",
        "user__email",
    ]

    autocomplete_fields = [
        "user",
    ]


@admin.register(BluetoothConnectionSession)
class BluetoothConnectionSessionAdmin(admin.ModelAdmin):
    list_display = [
        "reference",
        "user",
        "device",
        "status",
        "connection_type",
        "connected_at",
        "disconnected_at",
    ]

    list_filter = [
        "status",
        "connection_type",
        "created_at",
    ]

    search_fields = [
        "reference",
        "device__name",
        "device__device_id",
        "user__email",
    ]

    readonly_fields = [
        "reference",
        "created_at",
        "updated_at",
    ]

    autocomplete_fields = ["user", "device"]


@admin.register(OBDCommandLog)
class OBDCommandLogAdmin(admin.ModelAdmin):
    list_display = [
        "connection",
        "command",
        "direction",
        "successful",
        "response_time_ms",
        "created_at",
    ]

    list_filter = [
        "direction",
        "successful",
        "created_at",
    ]

    search_fields = [
        "command",
        "raw_data",
        "connection__reference",
    ]

    autocomplete_fields = ["connection"]


@admin.register(OBDTelemetry)
class OBDTelemetryAdmin(admin.ModelAdmin):
    list_display = [
        "connection",
        "pid",
        "name",
        "value",
        "unit",
        "recorded_at",
    ]

    list_filter = [
        "pid",
        "unit",
        "recorded_at",
    ]

    search_fields = [
        "pid",
        "name",
        "connection__reference",
    ]

    autocomplete_fields = ["connection"]