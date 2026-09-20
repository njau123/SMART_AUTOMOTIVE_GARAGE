"""
Expire payments ambazo hazijalipwa baada ya 45 min.
Endesha kwa: python manage.py expire_payments
"""
from django.core.management.base import BaseCommand
from django.utils import timezone
from apps.payments.models import Payment, PaymentStatus


class Command(BaseCommand):
    help = 'Expire payments zilizopitwa na muda (45 min)'

    def handle(self, *args, **options):
        now = timezone.now()

        # Payments zilizo PENDING/PROCESSING na expires_at < now
        expired = Payment.objects.filter(
            status__in=[
                PaymentStatus.PENDING,
                PaymentStatus.PROCESSING,
                PaymentStatus.CREATED,
            ],
            expires_at__lt=now,
        )

        count = expired.count()
        if count == 0:
            self.stdout.write(self.style.SUCCESS('✅ Hakuna payments zilizo-expire'))
            return

        # Notify user + update status
        for payment in expired:
            try:
                from apps.notifications.models import Notification
                Notification.objects.create(
                    recipient=payment.user,
                    notification_type='payment',
                    title=f'⏰ Malipo Yameisha — {payment.reference}',
                    message=(
                        f'Malipo ya TSh {payment.amount:,.0f} hayakulipwa kwa muda uliotakiwa.\n'
                        f'Tafadhali anzisha upya kama unahitaji huduma.'
                    ),
                    is_sent=True,
                    metadata={'payment_id': payment.id},
                )
            except Exception:
                pass

        expired.update(
            status=PaymentStatus.EXPIRED,
            failure_reason='Auto-expired baada ya dakika 45',
        )

        self.stdout.write(
            self.style.SUCCESS(f'✅ {count} payments zime-expire')
        )
