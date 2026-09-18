from django.contrib import admin

from .models import (
    Advertisement,
    AdvertisementClick,
    AdvertisementImpression,
)


@admin.register(Advertisement)
class AdvertisementAdmin(admin.ModelAdmin):
    list_display = [
        "reference",
        "title",
        "advertisement_type",
        "status",
        "priority",
        "start_at",
        "end_at",
        "impressions",
        "clicks",
    ]

    list_filter = [
        "advertisement_type",
        "status",
        "is_active",
    ]

    search_fields = [
        "reference",
        "title",
        "description",
    ]

    readonly_fields = [
        "reference",
        "impressions",
        "clicks",
        "created_at",
        "updated_at",
    ]

    autocomplete_fields = [
        "created_by",
    ]


@admin.register(AdvertisementImpression)
class AdvertisementImpressionAdmin(
    admin.ModelAdmin
):
    list_display = [
        "advertisement",
        "user",
        "ip_address",
        "created_at",
    ]

    list_filter = [
        "created_at",
    ]

    search_fields = [
        "advertisement__reference",
        "user__email",
        "ip_address",
    ]

    autocomplete_fields = [
        "advertisement",
        "user",
    ]


@admin.register(AdvertisementClick)
class AdvertisementClickAdmin(
    admin.ModelAdmin
):
    list_display = [
        "advertisement",
        "user",
        "ip_address",
        "created_at",
    ]

    list_filter = [
        "created_at",
    ]

    search_fields = [
        "advertisement__reference",
        "user__email",
        "ip_address",
    ]

    autocomplete_fields = [
        "advertisement",
        "user",
    ]