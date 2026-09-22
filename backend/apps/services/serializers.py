from rest_framework import serializers
from .models import ServiceCategory, Service


class ServiceCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = ServiceCategory
        fields = ['id', 'name', 'description', 'image', 'is_active', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']


class ServiceSerializer(serializers.ModelSerializer):
    category_name = serializers.CharField(source='category.name', read_only=True)
    available_days = serializers.JSONField(required=False)
    category = serializers.PrimaryKeyRelatedField(
        queryset=ServiceCategory.objects.all(),
        required=False,
        allow_null=True,
    )

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
            'fixed_price', 'video',
            'is_active',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def to_internal_value(self, data):
        """Handle multipart: available_days inaweza kuwa string 'MON,TUE' au JSON string."""
        data = data.copy() if hasattr(data, 'copy') else dict(data)

        # available_days — multipart inatuma kama string "MON,TUE,WED"
        if 'available_days' in data and isinstance(data['available_days'], str):
            raw = data['available_days'].strip()
            if raw.startswith('['):
                import json
                try:
                    data['available_days'] = json.loads(raw)
                except Exception:
                    data['available_days'] = []
            elif raw:
                data['available_days'] = [d.strip() for d in raw.split(',') if d.strip()]
            else:
                data['available_days'] = []

        # symptoms / supported_vehicle_types
        for field in ('symptoms', 'supported_vehicle_types'):
            if field in data and isinstance(data[field], str):
                raw = data[field].strip()
                if raw.startswith('['):
                    import json
                    try:
                        data[field] = json.loads(raw)
                    except Exception:
                        data[field] = []
                elif raw:
                    data[field] = [s.strip() for s in raw.split(',') if s.strip()]
                else:
                    data[field] = []

        # fixed_price / is_active kutoka multipart ni string "true"/"false"
        for field in ('fixed_price', 'is_active'):
            if field in data and isinstance(data[field], str):
                data[field] = data[field].lower() in ('true', '1', 'yes', 'on')

        return super().to_internal_value(data)


class ServiceCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Service
        fields = [
            'category', 'name', 'description',
            'symptoms', 'supported_vehicle_types',
            'estimated_duration_minutes',
            'base_price', 'image',
            'available_days', 'start_time', 'end_time',
            'fixed_price', 'video', 'is_active',
        ]
