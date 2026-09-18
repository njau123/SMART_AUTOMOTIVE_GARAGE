from django.contrib import admin
from .models import OBDScan


@admin.register(OBDScan)
class OBDScanAdmin(admin.ModelAdmin):
    list_display = [
        "id",
        "user",
        "vehicle",
        "status",
        "adapter_name",
        "protocol",
        "created_at",
        "completed_at",
    ]
    list_filter = [
        "status",
        "protocol",
        "created_at",
    ]
    search_fields = [
        "user__email",
        "vehicle__registration_number",
        "vehicle__make",
        "vehicle__model",
        "adapter_name",
    ]
    readonly_fields = [
        "created_at",
        "completed_at",
        "updated_at",
    ]
