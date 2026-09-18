from rest_framework import serializers
from .models import OBDScan


class OBDScanSerializer(serializers.ModelSerializer):
    vehicle_name = serializers.SerializerMethodField()

    class Meta:
        model = OBDScan
        fields = [
            "id",
            "user",
            "vehicle",
            "vehicle_name",
            "status",
            "adapter_name",
            "protocol",
            "dtc_codes",
            "live_data",
            "summary",
            "created_at",
            "completed_at",
            "updated_at",
        ]
        read_only_fields = [
            "id",
            "user",
            "status",
            "dtc_codes",
            "live_data",
            "summary",
            "created_at",
            "completed_at",
            "updated_at",
        ]

    def get_vehicle_name(self, obj):
        return f"{obj.vehicle.make} {obj.vehicle.model} ({obj.vehicle.registration_number})"


class CreateOBDScanSerializer(serializers.ModelSerializer):
    class Meta:
        model = OBDScan
        fields = [
            "vehicle",
            "adapter_name",
            "protocol",
        ]

    def validate_vehicle(self, value):
        request = self.context["request"]
        if value.user_id != request.user.id:
            raise serializers.ValidationError(
                "You can only scan your own vehicle."
            )
        return value
