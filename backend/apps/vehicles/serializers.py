from rest_framework import serializers
from .models import Vehicle


class VehicleSerializer(serializers.ModelSerializer):
    """Vehicle Serializer"""
    full_name = serializers.ReadOnlyField()
    display_name = serializers.ReadOnlyField()
    
    class Meta:
        model = Vehicle
        fields = [
            'id', 'user', 'make', 'model', 'year',
            'registration_number', 'vin', 'engine_type',
            'engine_capacity', 'fuel_type', 'transmission',
            'color', 'mileage', 'image', 'is_primary',
            'is_active', 'full_name', 'display_name',
            'notes', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class VehicleCreateSerializer(serializers.ModelSerializer):
    """Vehicle Create Serializer"""
    
    class Meta:
        model = Vehicle
        fields = [
            'make', 'model', 'year', 'registration_number',
            'vin', 'engine_type', 'engine_capacity',
            'fuel_type', 'transmission', 'color',
            'mileage', 'image', 'notes'
        ]

    def validate_registration_number(self, value):
        """Validate registration number"""
        value = value.upper()
        if Vehicle.objects.filter(registration_number=value).exists():
            raise serializers.ValidationError(
                "A vehicle with this registration number already exists"
            )
        return value
