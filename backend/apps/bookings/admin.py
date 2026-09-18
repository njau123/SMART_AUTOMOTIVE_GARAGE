from django.contrib import admin

from .models import (
    Booking,
    BookingAttachment,
    BookingStatusHistory,
)


class BookingStatusHistoryInline(
    admin.TabularInline
):
    model = BookingStatusHistory
    extra = 0
    readonly_fields = [
        "old_status",
        "new_status",
        "changed_by",
        "note",
        "created_at",
    ]


class BookingAttachmentInline(
    admin.TabularInline
):
    model = BookingAttachment
    extra = 0
    readonly_fields = [
        "uploaded_by",
        "created_at",
    ]


@admin.register(Booking)
class BookingAdmin(admin.ModelAdmin):
    list_display = [
        "booking_number",
        "customer",
        "mechanic",
        "vehicle",
        "service",
        "status",
        "payment_status",
        "scheduled_date",
        "scheduled_time",
        "total_price",
        "created_at",
    ]

    list_filter = [
        "status",
        "payment_status",
        "booking_type",
        "scheduled_date",
        "created_at",
    ]

    search_fields = [
        "booking_number",
        "customer__email",
        "customer__first_name",
        "customer__last_name",
        "mechanic__user__email",
        "vehicle__registration_number",
        "vehicle__vin",
        "service__name",
    ]

    list_select_related = [
        "customer",
        "mechanic",
        "vehicle",
        "service",
    ]

    readonly_fields = [
        "booking_number",
        "total_price",
        "customer_confirmed_at",
        "mechanic_accepted_at",
        "started_at",
        "completed_at",
        "cancelled_at",
        "created_at",
        "updated_at",
    ]

    inlines = [
        BookingStatusHistoryInline,
        BookingAttachmentInline,
    ]


@admin.register(BookingStatusHistory)
class BookingStatusHistoryAdmin(admin.ModelAdmin):
    list_display = [
        "booking",
        "old_status",
        "new_status",
        "changed_by",
        "created_at",
    ]

    list_filter = [
        "new_status",
        "created_at",
    ]

    search_fields = [
        "booking__booking_number",
        "changed_by__email",
        "note",
    ]

    readonly_fields = [
        "created_at",
    ]


@admin.register(BookingAttachment)
class BookingAttachmentAdmin(admin.ModelAdmin):
    list_display = [
        "booking",
        "description",
        "uploaded_by",
        "created_at",
    ]

    search_fields = [
        "booking__booking_number",
        "description",
    ]

    readonly_fields = [
        "created_at",
    ]