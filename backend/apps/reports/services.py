from datetime import datetime, time, timedelta
from decimal import Decimal

from django.apps import apps
from django.db.models import Count, Sum
from django.utils import timezone


def get_model(app_label, model_name):
    try:
        return apps.get_model(
            app_label,
            model_name,
        )
    except LookupError:
        return None


def safe_count(model, **filters):
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


class ReportService:

    @staticmethod
    def period(
        date_from=None,
        date_to=None,
    ):
        now = timezone.now()

        if date_to is None:
            date_to = now

        if date_from is None:
            date_from = now - timedelta(
                days=30
            )

        return date_from, date_to

    @staticmethod
    def booking_report(
        date_from=None,
        date_to=None,
    ):
        Booking = get_model(
            "bookings",
            "Booking",
        )

        date_from, date_to = (
            ReportService.period(
                date_from,
                date_to,
            )
        )

        if Booking is None:
            return {
                "period": {
                    "from": date_from,
                    "to": date_to,
                },
                "total": 0,
                "statuses": [],
            }

        queryset = Booking.objects.filter(
            created_at__gte=date_from,
            created_at__lte=date_to,
        )

        statuses = list(
            queryset.values(
                "status"
            )
            .annotate(
                total=Count("id")
            )
            .order_by("-total")
        )

        return {
            "period": {
                "from": date_from,
                "to": date_to,
            },
            "total": queryset.count(),
            "statuses": statuses,
        }

    @staticmethod
    def payment_report(
        date_from=None,
        date_to=None,
    ):
        Payment = get_model(
            "payments",
            "Payment",
        )

        date_from, date_to = (
            ReportService.period(
                date_from,
                date_to,
            )
        )

        if Payment is None:
            return {
                "period": {
                    "from": date_from,
                    "to": date_to,
                },
                "total_transactions": 0,
                "total_amount": "0.00",
                "statuses": [],
            }

        queryset = Payment.objects.filter(
            created_at__gte=date_from,
            created_at__lte=date_to,
        )

        amount = safe_sum(
            Payment,
            "amount",
            created_at__gte=date_from,
            created_at__lte=date_to,
        )

        statuses = list(
            queryset.values(
                "status"
            )
            .annotate(
                total=Count("id"),
                amount=Sum("amount"),
            )
            .order_by("-total")
        )

        for item in statuses:
            if item["amount"] is not None:
                item["amount"] = str(
                    item["amount"]
                )

        return {
            "period": {
                "from": date_from,
                "to": date_to,
            },
            "total_transactions": queryset.count(),
            "total_amount": str(amount),
            "statuses": statuses,
        }

    @staticmethod
    def order_report(
        date_from=None,
        date_to=None,
    ):
        Order = get_model(
            "spare_parts",
            "SparePartOrder",
        )

        date_from, date_to = (
            ReportService.period(
                date_from,
                date_to,
            )
        )

        if Order is None:
            return {
                "period": {
                    "from": date_from,
                    "to": date_to,
                },
                "total_orders": 0,
                "statuses": [],
            }

        queryset = Order.objects.filter(
            created_at__gte=date_from,
            created_at__lte=date_to,
        )

        statuses = list(
            queryset.values(
                "status"
            )
            .annotate(
                total=Count("id")
            )
            .order_by("-total")
        )

        return {
            "period": {
                "from": date_from,
                "to": date_to,
            },
            "total_orders": queryset.count(),
            "statuses": statuses,
        }

    @staticmethod
    def user_report(
        date_from=None,
        date_to=None,
    ):
        User = get_model(
            "accounts",
            "User",
        )

        date_from, date_to = (
            ReportService.period(
                date_from,
                date_to,
            )
        )

        if User is None:
            return {
                "period": {
                    "from": date_from,
                    "to": date_to,
                },
                "total_users": 0,
            }

        queryset = User.objects.filter(
            date_joined__gte=date_from,
            date_joined__lte=date_to,
        )

        roles = list(
            queryset.values(
                "role"
            )
            .annotate(
                total=Count("id")
            )
            .order_by("-total")
        )

        return {
            "period": {
                "from": date_from,
                "to": date_to,
            },
            "total_users": queryset.count(),
            "roles": roles,
        }

    @staticmethod
    def mechanic_report(
        date_from=None,
        date_to=None,
    ):
        MechanicProfile = get_model(
            "mechanics",
            "MechanicProfile",
        )

        date_from, date_to = (
            ReportService.period(
                date_from,
                date_to,
            )
        )

        if MechanicProfile is None:
            return {
                "period": {
                    "from": date_from,
                    "to": date_to,
                },
                "total_mechanics": 0,
            }

        queryset = MechanicProfile.objects.all()

        return {
            "period": {
                "from": date_from,
                "to": date_to,
            },
            "total_mechanics": queryset.count(),
            "verified": queryset.filter(
                is_verified=True
            ).count(),
            "unverified": queryset.filter(
                is_verified=False
            ).count(),
        }

    @staticmethod
    def revenue_report(
        date_from=None,
        date_to=None,
    ):
        Payment = get_model(
            "payments",
            "Payment",
        )

        date_from, date_to = (
            ReportService.period(
                date_from,
                date_to,
            )
        )

        if Payment is None:
            return {
                "period": {
                    "from": date_from,
                    "to": date_to,
                },
                "revenue": "0.00",
            }

        queryset = Payment.objects.filter(
            created_at__gte=date_from,
            created_at__lte=date_to,
        )

        try:
            successful = queryset.filter(
                status="SUCCESS"
            )
        except Exception:
            successful = queryset

        revenue = successful.aggregate(
            total=Sum("amount")
        )["total"] or Decimal("0.00")

        return {
            "period": {
                "from": date_from,
                "to": date_to,
            },
            "revenue": str(revenue),
            "transactions": successful.count(),
        }