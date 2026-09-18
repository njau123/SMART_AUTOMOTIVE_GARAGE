class VehicleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Vehicle
        fields = ['id', 'make', 'model', 'year', 'registration_number', 'vin',
                  'engine_type', 'engine_capacity_cc', 'fuel_type', 'transmission',
                  'color', 'mileage_km', 'vehicle_image', 'is_primary', 'is_active',
                  'notes', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']
