from rest_framework import serializers

from .models import (
    Booking,
    BookingAttachment,
    BookingStatusHistory,
)


class BookingStatusHistorySerializer(
    serializers.ModelSerializer
):
    changed_by_name = serializers.SerializerMethodField()

    class Meta:
        model = BookingStatusHistory
        fields = [
            "id",
            "old_status",
            "new_status",
            "changed_by",
            "changed_by_name",
            "note",
            "created_at",
        ]

    def get_changed_by_name(self, obj):
        if not obj.changed_by:
            return None

        return obj.changed_by.get_full_name()


class BookingAttachmentSerializer(
    serializers.ModelSerializer
):
    class Meta:
        model = BookingAttachment
        fields = [
            "id",
            "file",
            "description",
            "uploaded_by",
            "created_at",
        ]
        read_only_fields = [
            "id",
            "uploaded_by",
            "created_at",
        ]


class BookingSerializer(
    serializers.ModelSerializer
):
    customer_name = serializers.SerializerMethodField()
    mechanic_name = serializers.SerializerMethodField()
    vehicle_name = serializers.SerializerMethodField()
    service_name = serializers.SerializerMethodField()

    status_history = BookingStatusHistorySerializer(
        many=True,
        read_only=True,
    )

    attachments = BookingAttachmentSerializer(
        many=True,
        read_only=True,
    )

    class Meta:
        model = Booking
        fields = [
            "id",
            "booking_number",
            "customer",
            "customer_name",
            "mechanic",
            "mechanic_name",
            "vehicle",
            "vehicle_name",
            "service",
            "service_name",
            "booking_type",
            "status",
            "payment_status",
            "scheduled_date",
            "scheduled_time",
            "estimated_duration_minutes",
            "service_price",
            "additional_cost",
            "total_price",
            "customer_notes",
            "mechanic_notes",
            "cancellation_reason",
            "service_address",
            "region",
            "district",
            "latitude",
            "longitude",
            "customer_confirmed_at",
            "mechanic_accepted_at",
            "started_at",
            "completed_at",
            "cancelled_at",
            "status_history",
            "attachments",
            "created_at",
            "updated_at",
        ]

        read_only_fields = [
            "id",
            "booking_number",
            "customer",
            "status",
            "payment_status",
            "total_price",
            "customer_confirmed_at",
            "mechanic_accepted_at",
            "started_at",
            "completed_at",
            "cancelled_at",
            "status_history",
            "attachments",
            "created_at",
            "updated_at",
        ]

    def get_customer_name(self, obj):
        return obj.customer.full_name

    def get_mechanic_name(self, obj):
        if not obj.mechanic:
            return None

        user = obj.mechanic.user
        return user.get_full_name()

    def get_vehicle_name(self, obj):
        return (
            f"{obj.vehicle.make} "
            f"{obj.vehicle.model}"
        )

    def get_service_name(self, obj):
        return obj.service.name


class CreateBookingSerializer(
    serializers.ModelSerializer
):
    class Meta:
        model = Booking
        fields = [
            "vehicle",
            "service",
            "booking_type",
            "scheduled_date",
            "scheduled_time",
            "estimated_duration_minutes",
            "service_address",
            "region",
            "district",
            "latitude",
            "longitude",
            "customer_notes",
        ]

    def validate(self, attrs):
        request = self.context["request"]

        vehicle = attrs["vehicle"]

        if vehicle.user_id != request.user.id:
            raise serializers.ValidationError(
                {
                    "vehicle": (
                        "You can only book a service "
                        "for your own vehicle."
                    )
                }
            )

        if attrs["booking_type"] in [
            Booking.BookingType.MOBILE,
            Booking.BookingType.PICKUP,
        ]:
            if not attrs.get("service_address"):
                raise serializers.ValidationError(
                    {
                        "service_address": (
                            "Service address is required "
                            "for mobile or pickup bookings."
                        )
                    }
                )

        return attrs


class AssignMechanicSerializer(
    serializers.Serializer
):
    mechanic = serializers.IntegerField()


class RejectBookingSerializer(
    serializers.Serializer
):
    reason = serializers.CharField(
        required=False,
        allow_blank=True,
    )


class CancelBookingSerializer(
    serializers.Serializer
):
    reason = serializers.CharField(
        required=False,
        allow_blank=True,
    )


class AdditionalCostSerializer(
    serializers.Serializer
):
    amount = serializers.DecimalField(
        max_digits=12,
        decimal_places=2,
        min_value=0,
    )

    note = serializers.CharField(
        required=False,
        allow_blank=True,
    )


class BookingAttachmentCreateSerializer(
    serializers.ModelSerializer
):
    class Meta:
        model = BookingAttachment
        fields = [
            "file",
            "description",
        ]