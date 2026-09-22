"""
Management command: Auto-expire payments zilizopitwa na dakika 45.

Tumia kwenye Render Cron Job:
    python manage.py expire_payments

Schedule: */5 * * * * (kila dakika 5)
"""
from django.core.management.base import BaseCommand
from django.utils import timezone
from apps.payments.models import Payment, PaymentStatus


class Command(BaseCommand):
    help = "Expire payments zilizopitwa na 45 minutes"

    def handle(self, *args, **options):
        now = timezone.now()
        expired = Payment.objects.filter(
            status__in=[
                PaymentStatus.PENDING,
                PaymentStatus.CREATED,
                PaymentStatus.PROCESSING,
            ],
            expires_at__lt=now,
        )

        count = expired.count()
        for p in expired:
            p.status = PaymentStatus.EXPIRED
            p.failure_reason = "Payment expired (45 minutes passed)"
            p.save(update_fields=["status", "failure_reason", "updated_at"])

            # Notify user
            try:
                from apps.notifications.models import Notification
                Notification.objects.create(
                    recipient=p.user,
                    notification_type="payment",
                    title="Malipo Yameisha Muda",
                    message=(
                        f"Malipo yako ya TSh {p.amount:,.0f} "
                        f"(Ref: {p.reference}) yameisha muda wa dakika 45. "
                        f"Tafadhali anzisha malipo mapya."
                    ),
                    is_sent=True,
                )
            except Exception:
                pass

        self.stdout.write(
            self.style.SUCCESS(f"OK: Expired {count} payments")
        )
