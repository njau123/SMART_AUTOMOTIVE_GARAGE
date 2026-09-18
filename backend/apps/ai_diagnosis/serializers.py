from rest_framework import serializers
from .models import DiagnosisSession


class DiagnosisSessionSerializer(serializers.ModelSerializer):
    vehicle_name = serializers.SerializerMethodField()

    class Meta:
        model = DiagnosisSession
        fields = [
            "id",
            "user",
            "vehicle",
            "vehicle_name",
            "source",
            "status",
            "symptoms",
            "user_description",
            "ai_summary",
            "possible_causes",
            "recommended_actions",
            "severity",
            "raw_response",
            "created_at",
            "updated_at",
        ]
        read_only_fields = [
            "id",
            "user",
            "source",
            "status",
            "ai_summary",
            "possible_causes",
            "recommended_actions",
            "severity",
            "raw_response",
            "created_at",
            "updated_at",
        ]

    def get_vehicle_name(self, obj):
        return f"{obj.vehicle.make} {obj.vehicle.model} ({obj.vehicle.registration_number})"


class CreateDiagnosisSerializer(serializers.ModelSerializer):
    class Meta:
        model = DiagnosisSession
        fields = [
            "vehicle",
            "symptoms",
            "user_description",
        ]

    def validate_vehicle(self, value):
        request = self.context["request"]
        if value.user_id != request.user.id:
            raise serializers.ValidationError(
                "You can only diagnose your own vehicle."
            )
        return value

    def validate_symptoms(self, value):
        if not isinstance(value, list):
            raise serializers.ValidationError(
                "Symptoms must be a list."
            )
        return value
