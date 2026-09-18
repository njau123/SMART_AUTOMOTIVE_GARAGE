from django.contrib.auth import get_user_model

from rest_framework import serializers

from .models import (
    Review,
    ReviewHelpful,
    ReviewImage,
    ReviewReport,
)

User = get_user_model()


class ReviewImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ReviewImage
        fields = [
            "id",
            "image",
            "caption",
            "created_at",
        ]
        read_only_fields = [
            "id",
            "created_at",
        ]


class ReviewSerializer(serializers.ModelSerializer):
    images = ReviewImageSerializer(
        many=True,
        read_only=True,
    )

    customer_name = serializers.SerializerMethodField()
    mechanic_name = serializers.SerializerMethodField()

    class Meta:
        model = Review
        fields = [
            "id",
            "reference",
            "customer",
            "customer_name",
            "mechanic",
            "mechanic_name",
            "booking",
            "service",
            "overall_rating",
            "service_rating",
            "mechanic_rating",
            "communication_rating",
            "value_rating",
            "comment",
            "status",
            "is_verified",
            "is_anonymous",
            "helpful_count",
            "report_count",
            "images",
            "created_at",
            "updated_at",
        ]

        read_only_fields = [
            "id",
            "reference",
            "customer",
            "customer_name",
            "mechanic_name",
            "status",
            "is_verified",
            "helpful_count",
            "report_count",
            "created_at",
            "updated_at",
        ]

    def get_customer_name(self, obj):
        if obj.is_anonymous:
            return "Anonymous"

        full_name = obj.customer.get_full_name()

        return full_name or obj.customer.email

    def get_mechanic_name(self, obj):
        if not obj.mechanic:
            return None

        full_name = obj.mechanic.get_full_name()

        return full_name or obj.mechanic.email

    def validate_overall_rating(self, value):
        if value < 1 or value > 5:
            raise serializers.ValidationError(
                "Rating must be between 1 and 5."
            )

        return value


class ReviewCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Review
        fields = [
            "booking",
            "mechanic",
            "service",
            "overall_rating",
            "service_rating",
            "mechanic_rating",
            "communication_rating",
            "value_rating",
            "comment",
            "is_anonymous",
        ]

    def validate(self, attrs):
        customer = self.context[
            "request"
        ].user

        booking = attrs.get("booking")

        if Review.objects.filter(
            customer=customer,
            booking=booking,
        ).exists():
            raise serializers.ValidationError(
                {
                    "booking": (
                        "You have already reviewed "
                        "this booking."
                    )
                }
            )

        return attrs


class ReviewHelpfulSerializer(serializers.ModelSerializer):
    class Meta:
        model = ReviewHelpful
        fields = [
            "id",
            "review",
            "user",
            "created_at",
        ]
        read_only_fields = [
            "id",
            "user",
            "created_at",
        ]


class ReviewReportSerializer(serializers.ModelSerializer):
    class Meta:
        model = ReviewReport
        fields = [
            "id",
            "review",
            "reason",
            "description",
            "created_at",
        ]
        read_only_fields = [
            "id",
            "created_at",
        ]


class ReviewSummarySerializer(
    serializers.Serializer
):
    average_rating = serializers.FloatField()
    total_reviews = serializers.IntegerField()
    five_star = serializers.IntegerField()
    four_star = serializers.IntegerField()
    three_star = serializers.IntegerField()
    two_star = serializers.IntegerField()
    one_star = serializers.IntegerField()