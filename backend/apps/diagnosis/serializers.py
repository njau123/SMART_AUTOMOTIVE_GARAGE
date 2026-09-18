from rest_framework import serializers

from .models import (
    DiagnosisSession,
    DTCCode,
    DiagnosisDTC,
    OBDPID,
    OBDReading,
    OBDScanEvent,
)


class DiagnosisSessionSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(
        source="user.get_full_name",
        read_only=True,
    )
    vehicle_display = serializers.CharField(
        source="vehicle.full_name",
        read_only=True,
        allow_null=True,
    )
    dtc_count = serializers.SerializerMethodField()
    reading_count = serializers.SerializerMethodField()
    event_count = serializers.SerializerMethodField()

    class Meta:
        model = DiagnosisSession
        fields = [
            "id",
            "session_id",
            "user",
            "user_name",
            "vehicle",
            "vehicle_display",
            "mechanic",
            "source",
            "status",
            "started_at",
            "completed_at",
            "mileage",
            "battery_voltage",
            "protocol",
            "device_name",
            "device_mac_address",
            "raw_data",
            "summary",
            "notes",
            "error_message",
            "dtc_count",
            "reading_count",
            "event_count",
            "created_at",
            "updated_at",
        ]
        read_only_fields = [
            "id",
            "user",
            "created_at",
            "updated_at",
            "dtc_count",
            "reading_count",
            "event_count",
        ]

    def get_dtc_count(self, obj):
        return obj.dtcs.count()

    def get_reading_count(self, obj):
        return obj.readings.count()

    def get_event_count(self, obj):
        return obj.events.count()


class DiagnosisSessionCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = DiagnosisSession
        fields = [
            "vehicle",
            "source",
            "mileage",
            "protocol",
            "device_name",
            "device_mac_address",
        ]


class DiagnosisSessionUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = DiagnosisSession
        fields = [
            "status",
            "summary",
            "notes",
            "error_message",
        ]


class DTCCodeSerializer(serializers.ModelSerializer):
    class Meta:
        model = DTCCode
        fields = [
            "id",
            "code",
            "system",
            "category",
            "title",
            "description",
            "detailed_description",
            "severity",
            "symptoms",
            "possible_symptoms",
            "possible_causes",
            "diagnostic_steps",
            "recommended_actions",
            "recommended_repair",
            "recommended_repairs",
            "is_common",
            "is_active",
            "is_emission_related",
            "created_at",
            "updated_at",
        ]
        read_only_fields = [
            "id",
            "created_at",
            "updated_at",
        ]


class DiagnosisDTCSerializer(serializers.ModelSerializer):
    dtc_details = DTCCodeSerializer(
        source="dtc_code",
        read_only=True,
    )

    class Meta:
        model = DiagnosisDTC
        fields = [
            "id",
            "session",
            "dtc_code",
            "dtc_details",
            "raw_code",
            "status",
            "detected_at",
        ]
        read_only_fields = [
            "id",
            "detected_at",
        ]


class OBDPIDSerializer(serializers.ModelSerializer):
    class Meta:
        model = OBDPID
        fields = [
            "id",
            "pid",
            "name",
            "description",
            "unit",
            "created_at",
        ]
        read_only_fields = [
            "id",
            "created_at",
        ]


class OBDReadingSerializer(serializers.ModelSerializer):
    pid_details = OBDPIDSerializer(
        source="pid",
        read_only=True,
    )

    class Meta:
        model = OBDReading
        fields = [
            "id",
            "session",
            "pid",
            "pid_details",
            "value",
            "unit",
            "timestamp",
        ]
        read_only_fields = [
            "id",
            "timestamp",
        ]


class OBDScanEventSerializer(serializers.ModelSerializer):
    class Meta:
        model = OBDScanEvent
        fields = [
            "id",
            "session",
            "event_type",
            "description",
            "data",
            "created_at",
        ]
        read_only_fields = [
            "id",
            "created_at",
        ]
