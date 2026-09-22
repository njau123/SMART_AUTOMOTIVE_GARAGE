from rest_framework import serializers
from .models import ServiceCategory, Service


class ServiceCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = ServiceCategory
        fields = ['id', 'name', 'description', 'image', 'is_active', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']


class ServiceSerializer(serializers.ModelSerializer):
    category_name = serializers.CharField(source='category.name', read_only=True)

    # Tumia ListField badala ya JSONField — inashughulikia multipart "MON,TUE"
    available_days = serializers.ListField(
        child=serializers.CharField(),
        required=False,
        allow_empty=True,
    )
    symptoms = serializers.ListField(
        child=serializers.CharField(),
        required=False,
        allow_empty=True,
    )
    supported_vehicle_types = serializers.ListField(
        child=serializers.CharField(),
        required=False,
        allow_empty=True,
    )

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
            'image', 'video',
            'available_days', 'start_time', 'end_time',
            'fixed_price',
            'is_active',
            'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def to_internal_value(self, data):
        """Handle multipart: available_days inaweza kuwa string 'MON,TUE' au list."""
        data = data.copy() if hasattr(data, 'copy') else dict(data)

        # ListField fields — convert string kuwa list kama multipart
        for field in ('available_days', 'symptoms', 'supported_vehicle_types'):
            if field in data:
                val = data[field]
                if isinstance(val, str):
                    raw = val.strip()
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
                elif isinstance(val, list):
                    # Tayari ni list — DRF ListField ita-handle
                    pass

        # fixed_price / is_active kutoka multipart ni string "true"/"false"
        for field in ('fixed_price', 'is_active'):
            if field in data and isinstance(data[field], str):
                data[field] = data[field].lower() in ('true', '1', 'yes', 'on')

        return super().to_internal_value(data)


class ServiceCreateSerializer(serializers.ModelSerializer):
    available_days = serializers.ListField(
        child=serializers.CharField(),
        required=False,
        allow_empty=True,
    )

    class Meta:
        model = Service
        fields = [
            'category', 'name', 'description',
            'symptoms', 'supported_vehicle_types',
            'estimated_duration_minutes',
            'base_price', 'image', 'video',
            'available_days', 'start_time', 'end_time',
            'fixed_price', 'is_active',
        ]
