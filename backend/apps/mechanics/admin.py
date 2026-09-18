from django.contrib import admin

from .models import MechanicProfile


@admin.register(MechanicProfile)
class MechanicProfileAdmin(admin.ModelAdmin):
    list_display = [
        "user",
        "professional_title",
        "region",
        
        "is_verified",
        "is_active",
        
        
    ]

    list_filter = [
        
        "region",
        "is_verified",
        "is_active",
    ]

    search_fields = [
        "user__email",
        "user__first_name",
        "user__last_name",
        "user__phone_number",
        "business_name",
        "professional_title",
        "region",
        "district",
    ]

    readonly_fields = [
        
        
        "created_at",
        "updated_at",
    ]

    list_select_related = [
        "user",
    ]