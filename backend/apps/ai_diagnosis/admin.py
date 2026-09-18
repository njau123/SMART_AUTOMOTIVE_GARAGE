from django.contrib import admin
from .models import DiagnosisSession


@admin.register(DiagnosisSession)
class DiagnosisSessionAdmin(admin.ModelAdmin):
    list_display = [
        "id",
        "user",
        "vehicle",
        "source",
        "status",
        "severity",
        "created_at",
    ]
    list_filter = [
        "source",
        "status",
        "severity",
        "created_at",
    ]
    search_fields = [
        "user__email",
        "vehicle__registration_number",
        "vehicle__make",
        "vehicle__model",
        "user_description",
    ]
    readonly_fields = [
        "created_at",
        "updated_at",
    ]
