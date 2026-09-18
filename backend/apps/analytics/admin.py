from django.contrib import admin

from .models import AnalyticsEvent


@admin.register(AnalyticsEvent)
class AnalyticsEventAdmin(admin.ModelAdmin):
    list_display = [
        "event_type",
        "user",
        "platform",
        "app_version",
        "created_at",
    ]

    list_filter = [
        "event_type",
        "platform",
        "created_at",
    ]

    search_fields = [
        "session_id",
        "device",
        "user__email",
    ]

    readonly_fields = [
        "created_at",
    ]

    autocomplete_fields = [
        "user",
    ]