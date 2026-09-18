from rest_framework import serializers
from .models import ContactMessage


class ContactMessageCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = ContactMessage
        fields = ["id", "full_name", "email", "phone", "subject", "message"]

    def validate_email(self, value):
        if not value or "@" not in value:
            raise serializers.ValidationError("Email si sahihi")
        return value.lower()

    def validate_message(self, value):
        if not value or len(value.strip()) < 5:
            raise serializers.ValidationError("Ujumbe ni mfupi sana")
        return value.strip()


class ContactMessageSerializer(serializers.ModelSerializer):
    replied_by_email = serializers.CharField(
        source="replied_by.email", read_only=True, default=""
    )

    class Meta:
        model = ContactMessage
        fields = [
            "id", "user", "full_name", "email", "phone",
            "subject", "message", "status", "admin_reply",
            "replied_at", "replied_by", "replied_by_email",
            "created_at", "updated_at",
        ]
        read_only_fields = ["id", "user", "created_at", "updated_at"]
