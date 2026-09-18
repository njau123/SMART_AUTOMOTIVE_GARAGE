from django.contrib import admin
from .models import SystemSetting


@admin.register(SystemSetting)
class SystemSettingAdmin(admin.ModelAdmin):
    list_display = ['key', 'value', 'data_type', 'category', 'is_active', 'created_at']
    list_filter = ['category', 'data_type', 'is_active']
    search_fields = ['key', 'description']
    readonly_fields = ['created_at', 'updated_at']
    
    fieldsets = (
        ('Setting Info', {
            'fields': ('key', 'value', 'description')
        }),
        ('Configuration', {
            'fields': ('data_type', 'category')
        }),
        ('Status', {
            'fields': ('is_active', 'is_public')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at')
        }),
    )
