from rest_framework import serializers
from .models import ServiceCategory, Service


class ServiceCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = ServiceCategory
        fields = ['id', 'name', 'slug', 'description', 'icon', 'is_active']


class ServiceSerializer(serializers.ModelSerializer):
    category_name = serializers.CharField(source='category.name', read_only=True)
    final_price = serializers.ReadOnlyField()
    
    class Meta:
        model = Service
        fields = [
            'id', 'name', 'slug', 'description', 'short_description',
            'category', 'category_name', 'base_price', 'discount_price',
            'final_price', 'estimated_duration', 'vehicle_types',
            'symptoms', 'image', 'additional_images',
            'is_active', 'is_featured', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class ServiceCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Service
        fields = [
            'name', 'slug', 'description', 'short_description',
            'category', 'base_price', 'discount_price',
            'estimated_duration', 'vehicle_types', 'symptoms',
            'image', 'additional_images', 'is_active', 'is_featured'
        ]
