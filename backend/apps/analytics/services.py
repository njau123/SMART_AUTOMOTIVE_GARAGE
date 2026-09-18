from datetime import timedelta

from django.apps import apps
from django.db.models import Count
from django.utils import timezone

from .models import AnalyticsEvent


class AnalyticsService:

    @staticmethod
    def record_event(
        *,
        event_type,
        user=None,
        session_id="",
        ip_address=None,
        platform="",
        app_version="",
        device="",
        metadata=None,
    ):
        return AnalyticsEvent.objects.create(
            event_type=event_type,
            user=user,
            session_id=session_id,
            ip_address=ip_address,
            platform=platform,
            app_version=app_version,
            device=device,
            metadata=metadata or {},
        )

    @staticmethod
    def overview(
        days=30,
    ):
        now = timezone.now()

        start_date = now - timedelta(
            days=days
        )

        events = AnalyticsEvent.objects.filter(
            created_at__gte=start_date
        )

        total_events = events.count()

        unique_users = (
            events
            .exclude(user=None)
            .values("user")
            .distinct()
            .count()
        )

        event_breakdown = list(
            events.values(
                "event_type"
            )
            .annotate(
                total=Count("id")
            )
            .order_by("-total")
        )

        platform_breakdown = list(
            events.values(
                "platform"
            )
            .annotate(
                total=Count("id")
            )
            .order_by("-total")
        )

        daily_events = list(
            events.extra(
                select={
                    "day": (
                        "DATE(created_at)"
                    )
                }
            )
            .values("day")
            .annotate(
                total=Count("id")
            )
            .order_by("day")
        )

        return {
            "period": {
                "days": days,
                "start": start_date,
                "end": now,
            },
            "total_events": total_events,
            "unique_users": unique_users,
            "event_breakdown": (
                event_breakdown
            ),
            "platform_breakdown": (
                platform_breakdown
            ),
            "daily_events": daily_events,
        }

    @staticmethod
    def user_activity(
        user,
        days=30,
    ):
        now = timezone.now()

        start_date = now - timedelta(
            days=days
        )

        events = AnalyticsEvent.objects.filter(
            user=user,
            created_at__gte=start_date,
        )

        breakdown = list(
            events.values(
                "event_type"
            )
            .annotate(
                total=Count("id")
            )
            .order_by("-total")
        )

        return {
            "user_id": user.id,
            "period_days": days,
            "total_events": events.count(),
            "events": breakdown,
        }