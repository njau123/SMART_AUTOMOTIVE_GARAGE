from rest_framework import serializers
from .models import ServiceCategory, Service


class ServiceCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = ServiceCategory
        fields = ['id', 'name', 'description', 'image', 'is_active', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']


class ServiceSerializer(serializers.ModelSerializer):
    category_name = serializers.CharField(source='category.name', read_only=True)

    # CharField inapokea string yoyote — tunaconvert kwenye create/update
    available_days = serializers.CharField(required=False, allow_blank=True)
    symptoms = serializers.CharField(required=False, allow_blank=True)
    supported_vehicle_types = serializers.CharField(required=False, allow_blank=True)

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
        """Handle multipart: convert list/JSON kuwa comma-separated string."""
        data = data.copy() if hasattr(data, 'copy') else dict(data)

        for field in ('available_days', 'symptoms', 'supported_vehicle_types'):
            if field in data:
                val = data[field]
                if isinstance(val, list):
                    # JSON: ['MON', 'TUE'] → "MON,TUE"
                    data[field] = ','.join(str(v) for v in val)
                elif isinstance(val, str):
                    raw = val.strip()
                    if raw.startswith('['):
                        # JSON string: '["MON","TUE"]' → "MON,TUE"
                        import json
                        try:
                            lst = json.loads(raw)
                            data[field] = ','.join(str(v) for v in lst) if lst else ''
                        except Exception:
                            data[field] = ''
                    # else: tayari ni "MON,TUE" (multipart)

        for field in ('fixed_price', 'is_active'):
            if field in data and isinstance(data[field], str):
                data[field] = data[field].lower() in ('true', '1', 'yes', 'on')

        return super().to_internal_value(data)

    def to_representation(self, instance):
        """Convert JSONField list kuwa list kwenye response (sio string)."""
        data = super().to_representation(instance)
        # JSONField inarudi string kama "['MON', 'TUE']" — convert kuwa list
        for field in ('available_days', 'symptoms', 'supported_vehicle_types'):
            val = getattr(instance, field, None)
            if isinstance(val, list):
                data[field] = val
            elif isinstance(val, str):
                try:
                    import ast
                    data[field] = ast.literal_eval(val) if val.startswith('[') else []
                except Exception:
                    data[field] = []
            else:
                data[field] = []
        return data

    def _convert_days(self, validated_data):
        """Convert comma-separated string kuwa list kwa JSONField."""
        for field in ('available_days', 'symptoms', 'supported_vehicle_types'):
            val = validated_data.get(field)
            if isinstance(val, str):
                validated_data[field] = [s.strip() for s in val.split(',') if s.strip()]
            elif val is None:
                validated_data[field] = []
        return validated_data

    def create(self, validated_data):
        validated_data = self._convert_days(validated_data)
        return super().create(validated_data)

    def update(self, instance, validated_data):
        validated_data = self._convert_days(validated_data)
        return super().update(instance, validated_data)


class ServiceCreateSerializer(serializers.ModelSerializer):
    available_days = serializers.CharField(required=False, allow_blank=True)

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

# ==================== SERVICE BOOKING SERIALIZERS ====================
from rest_framework import serializers as drf_serializers


class ServiceBookingCreateSerializer(drf_serializers.Serializer):
    service_id = drf_serializers.IntegerField()
    vehicle_make = drf_serializers.CharField(max_length=100)
    vehicle_model = drf_serializers.CharField(max_length=100)
    vehicle_year = drf_serializers.CharField(max_length=20, required=False, allow_blank=True)
    vehicle_registration = drf_serializers.CharField(max_length=50, required=False, allow_blank=True)
    vehicle_notes = drf_serializers.CharField(required=False, allow_blank=True)


class ServiceBookingSerializer(drf_serializers.ModelSerializer):
    service_name = drf_serializers.CharField(source="service.name", read_only=True)
    service_category = drf_serializers.CharField(source="service.category.name", read_only=True)
    user_email = drf_serializers.CharField(source="user.email", read_only=True)
    user_name = drf_serializers.CharField(source="user.get_full_name", read_only=True)

    class Meta:
        from .models import ServiceBooking
        model = ServiceBooking
        fields = [
            "id", "booking_number",
            "user_email", "user_name",
            "service", "service_name", "service_category",
            "vehicle_make", "vehicle_model", "vehicle_year",
            "vehicle_registration", "vehicle_notes",
            "total_price", "deposit_amount", "balance_amount",
            "payment_status", "payment_reference", "payment_phone",
            "payment_method", "detected_network",
            "payment_countdown_ends_at",
            "status",
            "appointment_date", "appointment_time",
            "service_location", "distance_km", "eta_minutes",
            "eta_countdown_ends_at",
            "receipt_confirmed_at", "extended_count", "completed_at",
            "user_feedback", "user_rating",
            "admin_notes",
            "created_at", "updated_at",
        ]
        read_only_fields = fields

