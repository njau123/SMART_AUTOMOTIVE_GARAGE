from rest_framework import serializers
from .models import Payment, PaymentRefund


class PaymentSerializer(serializers.ModelSerializer):
    user_email = serializers.CharField(source="user.email", read_only=True)
    user_full_name = serializers.SerializerMethodField()
    user_phone = serializers.CharField(source="user.phone_number", read_only=True)

    class Meta:
        model = Payment
        fields = [
            "id", "reference", "user", "user_email", "user_full_name", "user_phone",
            "amount", "currency", "method", "provider", "purpose",
            "status", "description", "phone_number",
            "external_reference", "gateway_reference",
            "metadata", "failure_reason",
            "created_at", "updated_at", "completed_at",
        ]
        read_only_fields = [
            "id", "reference", "created_at", "updated_at", "completed_at",
        ]

    def get_user_full_name(self, obj):
        if obj.user:
            return f"{obj.user.first_name} {obj.user.last_name}".strip() or obj.user.email
        return ""


class PaymentInitiateSerializer(serializers.Serializer):
    amount = serializers.DecimalField(max_digits=18, decimal_places=2)
    purpose = serializers.ChoiceField(
        choices=["BOOKING", "SERVICE", "SPARE_PART", "WALLET_TOPUP", "OTHER"]
    )
    phone_number = serializers.CharField(max_length=30)
    description = serializers.CharField(max_length=500, required=False, allow_blank=True)
    reference_id = serializers.CharField(required=False, allow_blank=True)


class PaymentSubmitReferenceSerializer(serializers.Serializer):
    """User anaweka reference ya M-Pesa / Tigo Pesa / Airtel baada ya kulipa."""
    user_reference = serializers.CharField(max_length=100)
    note = serializers.CharField(max_length=500, required=False, allow_blank=True)


class PaymentRefundSerializer(serializers.ModelSerializer):
    class Meta:
        model = PaymentRefund
        fields = "__all__"
