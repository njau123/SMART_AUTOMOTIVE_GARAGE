from django.contrib import admin
from .models import News, NewsCategory

@admin.register(NewsCategory)
class NewsCategoryAdmin(admin.ModelAdmin):
    list_display = ['name', 'slug', 'created_at']
    search_fields = ['name', 'slug']

@admin.register(News)
class NewsAdmin(admin.ModelAdmin):
    list_display = ['title', 'category', 'status', 'published_at', 'created_at']
    list_filter = ['status', 'category', 'is_featured', 'is_breaking']
    search_fields = ['title', 'slug', 'summary', 'content']
    prepopulated_fields = {'slug': ('title',)}
    readonly_fields = ['created_at', 'updated_at', 'views_count', 'likes_count', 'shares_count', 'comments_count']
