from django.contrib import admin
from .models import Category, Brand, SparePart


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ['name', 'slug', 'parent', 'is_active', 'created_at']
    search_fields = ['name', 'description']
    prepopulated_fields = {'slug': ('name',)}
    list_filter = ['is_active', 'parent']


@admin.register(Brand)
class BrandAdmin(admin.ModelAdmin):
    list_display = ['name', 'slug', 'is_verified', 'is_active', 'created_at']
    search_fields = ['name', 'description']
    prepopulated_fields = {'slug': ('name',)}
    list_filter = ['is_verified', 'is_active']


@admin.register(SparePart)
class SparePartAdmin(admin.ModelAdmin):
    list_display = ['name', 'part_number', 'category', 'brand', 'price', 'stock_quantity', 'status']
    search_fields = ['name', 'part_number', 'oem_number']
    list_filter = ['category', 'brand', 'condition', 'status', 'is_active']
    readonly_fields = ['views_count', 'orders_count', 'created_at', 'updated_at']
