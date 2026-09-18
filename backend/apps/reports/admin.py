from django.contrib import admin
from .models import Report


@admin.register(Report)
class ReportAdmin(admin.ModelAdmin):
    list_display = ['id', 'report_type', 'status', 'created_by', 'created_at']
    list_filter = ['report_type', 'status']
    search_fields = ['title', 'report_type']
    readonly_fields = ['created_at', 'updated_at']
    
    fieldsets = (
        ('Report Info', {
            'fields': ('title', 'report_type', 'status')
        }),
        ('Data', {
            'fields': ('data', 'file')
        }),
        ('User', {
            'fields': ('created_by',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at')
        }),
    )
