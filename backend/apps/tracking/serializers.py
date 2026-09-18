from rest_framework import serializers

from .models import (
    Geofence,
    GeofenceEvent,
    MechanicLocation,
    TrackingSession,
    VehicleLocation,
)


class TrackingSessionSerializer(
    serializers.ModelSerializer
):
    class Meta:
        model = TrackingSession

        fields = [
            "id",
            "reference",
            "vehicle",
            "tracking_type",
            "status",
            "started_at",
            "ended_at",
            "last_location_at",
            "total_distance_km",
            "metadata",
            "created_at",
            "updated_at",
        ]

        read_only_fields = [
            "id",
            "reference",
            "started_at",
            "ended_at",
            "last_location_at",
            "total_distance_km",
            "created_at",
            "updated_at",
        ]


class VehicleLocationSerializer(
    serializers.ModelSerializer
):
    class Meta:
        model = VehicleLocation

        fields = [
            "id",
            "session",
            "vehicle",
            "latitude",
            "longitude",
            "altitude",
            "accuracy",
            "speed_kmh",
            "heading",
            "battery_level",
            "source",
            "recorded_at",
            "created_at",
        ]

        read_only_fields = [
            "id",
            "created_at",
        ]

    def validate_latitude(self, value):
        if not -90 <= value <= 90:
            raise serializers.ValidationError(
                "Latitude must be between -90 and 90."
            )

        return value

    def validate_longitude(self, value):
        if not -180 <= value <= 180:
            raise serializers.ValidationError(
                "Longitude must be between -180 and 180."
            )

        return value


class MechanicLocationSerializer(
    serializers.ModelSerializer
):
    class Meta:
        model = MechanicLocation

        fields = [
            "id",
            "mechanic",
            "latitude",
            "longitude",
            "altitude",
            "accuracy",
            "speed_kmh",
            "heading",
            "is_online",
            "recorded_at",
            "created_at",
        ]

        read_only_fields = [
            "id",
            "mechanic",
            "created_at",
        ]


class GeofenceSerializer(
    serializers.ModelSerializer
):
    class Meta:
        model = Geofence

        fields = [
            "id",
            "reference",
            "vehicle",
            "name",
            "geofence_type",
            "latitude",
            "longitude",
            "radius_meters",
            "is_active",
            "notify_on_enter",
            "notify_on_exit",
            "created_at",
            "updated_at",
        ]

        read_only_fields = [
            "id",
            "reference",
            "created_at",
            "updated_at",
        ]


class GeofenceEventSerializer(
    serializers.ModelSerializer
):
    class Meta:
        model = GeofenceEvent

        fields = [
            "id",
            "geofence",
            "vehicle",
            "event_type",
            "latitude",
            "longitude",
            "occurred_at",
            "created_at",
        ]

        read_only_fields = [
            "id",
            "created_at",
        ]