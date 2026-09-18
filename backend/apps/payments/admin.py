from django.contrib import admin

from .models import (
    Payment,
    PaymentAttempt,
    PaymentRefund,
    PaymentWebhookEvent,
)


@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = [
        "reference",
        "user",
        "amount",
        "currency",
        "method",
        "provider",
        "purpose",
        "status",
        "created_at",
    ]

    list_filter = [
        "method",
        "provider",
        "purpose",
        "status",
        "currency",
        "created_at",
    ]

    search_fields = [
        "reference",
        "external_reference",
        "gateway_reference",
        "phone_number",
        "user__email",
    ]

    readonly_fields = [
        "reference",
        "created_at",
        "updated_at",
    ]

    autocomplete_fields = [
        "user",
    ]


@admin.register(PaymentAttempt)
class PaymentAttemptAdmin(admin.ModelAdmin):
    list_display = [
        "payment",
        "attempt_number",
        "status",
        "gateway_reference",
        "created_at",
    ]

    list_filter = [
        "status",
        "created_at",
    ]

    search_fields = [
        "payment__reference",
        "gateway_reference",
        "error_message",
    ]

    readonly_fields = [
        "created_at",
    ]

    autocomplete_fields = [
        "payment",
    ]


@admin.register(PaymentWebhookEvent)
class PaymentWebhookEventAdmin(admin.ModelAdmin):
    list_display = [
        "event_id",
        "provider",
        "event_type",
        "payment",
        "processed",
        "created_at",
    ]

    list_filter = [
        "provider",
        "processed",
        "event_type",
        "created_at",
    ]

    search_fields = [
        "event_id",
        "event_type",
        "payment__reference",
    ]

    readonly_fields = [
        "created_at",
        "processed_at",
    ]

    autocomplete_fields = [
        "payment",
    ]


@admin.register(PaymentRefund)
class PaymentRefundAdmin(admin.ModelAdmin):
    list_display = [
        "reference",
        "payment",
        "amount",
        "status",
        "gateway_reference",
        "created_at",
    ]

    list_filter = [
        "status",
        "created_at",
    ]

    search_fields = [
        "reference",
        "payment__reference",
        "gateway_reference",
        "reason",
    ]

    readonly_fields = [
        "reference",
        "created_at",
    ]

    autocomplete_fields = [
        "payment",
    ]