from rest_framework import serializers
from .models import MechanicProfile


class MechanicProfileSerializer(serializers.ModelSerializer):
    """Mechanic Profile Serializer"""
    full_name = serializers.CharField(source='user.full_name', read_only=True)
    email = serializers.CharField(source='user.email', read_only=True)
    phone = serializers.CharField(source='user.phone_number', read_only=True)
    location_display = serializers.ReadOnlyField()
    display_name = serializers.ReadOnlyField()
    
    class Meta:
        model = MechanicProfile
        fields = [
            'id', 'user', 'full_name', 'email', 'phone',
            'business_name', 'professional_title', 'bio',
            'expertise', 'specialties', 'region', 'district',
            'ward', 'latitude', 'longitude', 'service_radius',
            'is_available', 'experience', 'profile_image',
            'is_verified', 'verification_documents',
            'rating', 'review_count', 'availability',
            'location_display', 'display_name',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'rating', 'review_count', 'created_at', 'updated_at']


class MechanicProfileCreateSerializer(serializers.ModelSerializer):
    """Mechanic Profile Create Serializer"""
    
    class Meta:
        model = MechanicProfile
        fields = [
            'business_name', 'professional_title', 'bio',
            'expertise', 'specialties', 'region', 'district',
            'ward', 'latitude', 'longitude', 'service_radius',
            'experience', 'profile_image', 'availability'
        ]
