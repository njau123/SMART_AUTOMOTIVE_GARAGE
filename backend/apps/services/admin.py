from django.contrib import admin

from .models import Service, ServiceCategory


@admin.register(ServiceCategory)
class ServiceCategoryAdmin(admin.ModelAdmin):
    list_display = [
        "name",
        "is_active",
        "created_at",
    ]

    list_filter = [
        "is_active",
    ]

    search_fields = [
        "name",
        "description",
    ]


@admin.register(Service)
class ServiceAdmin(admin.ModelAdmin):
    list_display = [
        "name",
        "category",
        "base_price",
        "estimated_duration_minutes",
        "is_active",
        "created_at",
    ]

    list_filter = [
        "category",
        "is_active",
    ]

    search_fields = [
        "name",
        "description",
        "category__name",
    ]

    list_select_related = [
        "category",
    ]