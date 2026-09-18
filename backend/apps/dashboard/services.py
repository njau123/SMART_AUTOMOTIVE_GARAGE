from decimal import Decimal

from django.apps import apps
from django.db.models import Avg, Sum


def get_model(
    app_label,
    model_name,
):
    try:
        return apps.get_model(
            app_label,
            model_name,
        )
    except LookupError:
        return None


def safe_count(
    model,
    **filters,
):
    if model is None:
        return 0

    return model.objects.filter(
        **filters
    ).count()


def safe_sum(
    model,
    field_name,
    **filters,
):
    if model is None:
        return Decimal("0.00")

    result = model.objects.filter(
        **filters
    ).aggregate(
        total=Sum(field_name)
    )

    return result["total"] or Decimal("0.00")


def safe_average(
    model,
    field_name,
    **filters,
):
    if model is None:
        return Decimal("0.00")

    result = model.objects.filter(
        **filters
    ).aggregate(
        average=Avg(field_name)
    )

    return result["average"] or Decimal("0.00")


class DashboardService:

    @staticmethod
    def user_dashboard(user):
        Vehicle = get_model(
            "vehicles",
            "Vehicle",
        )

        Booking = get_model(
            "bookings",
            "Booking",
        )

        Order = get_model(
            "spare_parts",
            "SparePartOrder",
        )

        Notification = get_model(
            "notifications",
            "Notification",
        )

        Review = get_model(
            "reviews",
            "Review",
        )

        vehicle_count = safe_count(
            Vehicle,
            owner=user,
        )

        booking_count = safe_count(
            Booking,
            customer=user,
        )

        order_count = safe_count(
            Order,
            customer=user,
        )

        unread_notifications = safe_count(
            Notification,
            user=user,
            is_read=False,
        )

        review_count = safe_count(
            Review,
            customer=user,
        )

        return {
            "user": {
                "id": user.id,
                "email": user.email,
                "name": (
                    user.get_full_name()
                    or user.email
                ),
            },
            "vehicles": {
                "total": vehicle_count,
            },
            "bookings": {
                "total": booking_count,
            },
            "orders": {
                "total": order_count,
            },
            "notifications": {
                "unread": unread_notifications,
            },
            "reviews": {
                "total": review_count,
            },
        }

    @staticmethod
    def mechanic_dashboard(user):
        Booking = get_model(
            "bookings",
            "Booking",
        )

        Review = get_model(
            "reviews",
            "Review",
        )

        MechanicProfile = get_model(
            "mechanics",
            "MechanicProfile",
        )

        booking_count = safe_count(
            Booking,
            mechanic=user,
        )

        completed_bookings = safe_count(
            Booking,
            mechanic=user,
            status="COMPLETED",
        )

        pending_bookings = safe_count(
            Booking,
            mechanic=user,
            status="PENDING",
        )

        cancelled_bookings = safe_count(
            Booking,
            mechanic=user,
            status="CANCELLED",
        )

        review_count = safe_count(
            Review,
            mechanic=user,
        )

        average_rating = safe_average(
            Review,
            "rating",
            mechanic=user,
        )

        profile = None

        if MechanicProfile is not None:
            profile = (
                MechanicProfile.objects.filter(
                    user=user
                ).first()
            )

        rating = average_rating

        if profile is not None:
            rating = getattr(
                profile,
                "rating",
                average_rating,
            )

        return {
            "mechanic": {
                "id": user.id,
                "name": (
                    user.get_full_name()
                    or user.email
                ),
                "rating": rating,
                "verified": (
                    getattr(
                        profile,
                        "is_verified",
                        False,
                    )
                    if profile
                    else False
                ),
            },
            "bookings": {
                "total": booking_count,
                "pending": pending_bookings,
                "completed": completed_bookings,
                "cancelled": cancelled_bookings,
            },
            "reviews": {
                "total": review_count,
                "average_rating": average_rating,
            },
        }

    @staticmethod
    def admin_dashboard():
        User = get_model(
            "accounts",
            "User",
        )

        Vehicle = get_model(
            "vehicles",
            "Vehicle",
        )

        MechanicProfile = get_model(
            "mechanics",
            "MechanicProfile",
        )

        Booking = get_model(
            "bookings",
            "Booking",
        )

        Order = get_model(
            "spare_parts",
            "SparePartOrder",
        )

        Review = get_model(
            "reviews",
            "Review",
        )

        total_users = (
            User.objects.count()
            if User
            else 0
        )

        total_mechanics = (
            MechanicProfile.objects.count()
            if MechanicProfile
            else 0
        )

        total_vehicles = (
            Vehicle.objects.count()
            if Vehicle
            else 0
        )

        total_bookings = (
            Booking.objects.count()
            if Booking
            else 0
        )

        total_orders = (
            Order.objects.count()
            if Order
            else 0
        )

        total_reviews = (
            Review.objects.count()
            if Review
            else 0
        )

        completed_bookings = safe_count(
            Booking,
            status="COMPLETED",
        )

        pending_bookings = safe_count(
            Booking,
            status="PENDING",
        )

        cancelled_bookings = safe_count(
            Booking,
            status="CANCELLED",
        )

        return {
            "users": {
                "total": total_users,
            },
            "mechanics": {
                "total": total_mechanics,
            },
            "vehicles": {
                "total": total_vehicles,
            },
            "bookings": {
                "total": total_bookings,
                "pending": pending_bookings,
                "completed": completed_bookings,
                "cancelled": cancelled_bookings,
            },
            "orders": {
                "total": total_orders,
            },
            "reviews": {
                "total": total_reviews,
            },
        }