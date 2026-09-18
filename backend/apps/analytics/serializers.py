from rest_framework import serializers

from .models import AnalyticsEvent


class AnalyticsEventSerializer(
    serializers.ModelSerializer
):
    class Meta:
        model = AnalyticsEvent

        fields = [
            "id",
            "event_type",
            "user",
            "session_id",
            "ip_address",
            "platform",
            "app_version",
            "device",
            "metadata",
            "created_at",
        ]

        read_only_fields = [
            "id",
            "user",
            "ip_address",
            "created_at",
        ]