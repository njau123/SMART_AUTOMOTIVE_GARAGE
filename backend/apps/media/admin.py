from django.contrib import admin
from .models import Media


@admin.register(Media)
class MediaAdmin(admin.ModelAdmin):
    list_display = ['title', 'category', 'file_type', 'file_size', 'uploaded_by', 'is_active', 'created_at']
    list_filter = ['category', 'file_type', 'is_active']
    search_fields = ['title', 'description']
    readonly_fields = ['created_at', 'updated_at']
    
    fieldsets = (
        ('Media Info', {
            'fields': ('title', 'file', 'file_type', 'file_size', 'category')
        }),
        ('Description', {
            'fields': ('description',)
        }),
        ('User', {
            'fields': ('uploaded_by',)
        }),
        ('Metadata', {
            'fields': ('metadata',)
        }),
        ('Status', {
            'fields': ('is_active',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at')
        }),
    )
