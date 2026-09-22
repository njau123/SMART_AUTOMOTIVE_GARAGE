from rest_framework import serializers
from .models import ServiceCategory, Service


class ServiceCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = ServiceCategory
        fields = ['id', 'name', 'description', 'image', 'is_active', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']


class ServiceSerializer(serializers.ModelSerializer):
    category_name = serializers.CharField(source='category.name', read_only=True)

    class Meta:
        model = Service
        fields = [
            'id',
            'category', 'category_name',
            'name', 'description',
            'symptoms', 'supported_vehicle_types',
            'estimated_duration_minutes',
            'base_price',
            'image',
            'available_days', 'start_time', 'end_time',
            'fixed_price',
            'is_active',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class ServiceCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Service
        fields = [
            'category', 'name', 'description',
            'symptoms', 'supported_vehicle_types',
            'estimated_duration_minutes',
            'base_price', 'image',
            'available_days', 'start_time', 'end_time',
            'fixed_price', 'is_active',
        ]
