"""
Unified Payment — inatumika kwa kila aina ya malipo.
"""
import uuid
from decimal import Decimal

from django.utils import timezone
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Payment, PaymentStatus, PaymentProvider, PaymentPurpose
from .payment_config import PAYMENT_TIMEOUT_MINUTES
from .detection import get_instructions, detect_network, detect_bank


class PaymentInitiateUnifiedView(APIView):
    """
    Unified payment initiate — inatumika kwa:

    - OBD_DIAGNOSIS
    - BOOKING
    - SERVICE
    - SPARE_PART
    - WALLET_TOPUP
    - OTHER

    Request body:
        amount: float/decimal (required)
        purpose: str (required) — OBD_DIAGNOSIS, BOOKING, SERVICE, SPARE_PART, WALLET_TOPUP, OTHER
        method_type: str (required) — 'MOBILE_MONEY' au 'BANK'
        identifier: str (required) — phone number (mobile) au account/card (bank)
        network_override: str (optional) — user anaweza kubadilisha network
        bank_override: str (optional) — user anaweza kubadilisha bank
        description: str (optional)
        reference_id: str (optional) — kwa booking/service/spare_part id
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        data = request.data

        # ============ VALIDATE ============
        amount = data.get('amount')
        purpose = data.get('purpose', '').upper()
        method_type = data.get('method_type', '').upper()
        identifier = (data.get('identifier') or '').strip()

        if not amount:
            return self._error('amount ni lazima')
        try:
            amount = Decimal(str(amount))
            if amount <= 0:
                return self._error('amount lazima iwe zaidi ya 0')
        except Exception:
            return self._error('amount si sahihi')

        if not purpose:
            return self._error('purpose ni lazima')

        if method_type not in ('MOBILE_MONEY', 'BANK'):
            return self._error('method_type lazima iwe MOBILE_MONEY au BANK')

        if not identifier:
            return self._error('identifier (namba ya simu/account) ni lazima')

        # ============ DETECT NETWORK/BANK ============
        network_override = data.get('network_override', '').strip()
        bank_override = data.get('bank_override', '').strip()

        if method_type == 'MOBILE_MONEY':
            if network_override:
                detected = network_override
            else:
                detected = detect_network(identifier)
            provider = detected if detected != 'Unknown' else 'MOBILE_MONEY'
        else:  # BANK
            if bank_override:
                detected = bank_override
            else:
                detected = detect_bank(identifier)
            provider = detected if detected != 'Unknown' else 'BANK'

        # ============ GET INSTRUCTIONS ============
        inst = get_instructions(method_type, identifier, amount, '')

        # ============ CREATE PAYMENT ============
        reference = f"PAY-{uuid.uuid4().hex[:10].upper()}"

        # Sasisha reference kwenye instructions
        inst = get_instructions(method_type, identifier, amount, reference)

        try:
            provider_enum = PaymentProvider(detected).value if detected in [p.value for p in PaymentProvider] else PaymentProvider.SANDBOX.value
        except Exception:
            provider_enum = PaymentProvider.SANDBOX.value

        try:
            purpose_enum = PaymentPurpose(purpose).value if purpose in [p.value for p in PaymentPurpose] else PaymentPurpose.OTHER.value
        except Exception:
            purpose_enum = PaymentPurpose.OTHER.value

        payment = Payment.objects.create(
            user=request.user,
            amount=amount,
            currency='TZS',
            method=method_type,
            provider=provider_enum,
            purpose=purpose_enum,
            reference=reference,
            phone_number=identifier if method_type == 'MOBILE_MONEY' else '',
            status=PaymentStatus.PENDING,
            description=data.get('description', '') or f'{purpose} payment',
            expires_at=timezone.now() + timezone.timedelta(minutes=PAYMENT_TIMEOUT_MINUTES),
            metadata={
                'identifier': identifier,
                'detected_network_or_bank': detected,
                'method_type': method_type,
                'reference_id': data.get('reference_id', ''),
                'instructions_text': inst['instructions'],
            },
        )

        # ============ NOTIFY ADMIN ============
        self._notify_admin(payment, detected, method_type)

        # ============ RESPONSE ============
        return Response({
            'success': True,
            'message': 'Malipo yameanzishwa. Tafadhali lipa kwa maelekezo hapo chini.',
            'data': {
                'id': payment.id,
                'reference': payment.reference,
                'amount': str(payment.amount),
                'currency': payment.currency,
                'method_type': method_type,
                'detected_network_or_bank': detected,
                'is_detected': detected != 'Unknown',
                'identifier': identifier,
                'status': payment.status,
                'expires_at': payment.expires_at.isoformat() if payment.expires_at else None,
                'timeout_minutes': PAYMENT_TIMEOUT_MINUTES,
            },
            'instructions': inst['instructions'],
            'company_account': inst.get('network_or_bank', ''),
        }, status=status.HTTP_201_CREATED)

    # ============ HELPERS ============
    def _error(self, message):
        return Response(
            {'success': False, 'message': message, 'data': None},
            status=status.HTTP_400_BAD_REQUEST,
        )

    def _notify_admin(self, payment, detected, method_type):
        """Tuma notification kwa admin kila malipo yanapyoanzishwa."""
        try:
            from apps.notifications.models import Notification
            from django.contrib.auth import get_user_model

            User = get_user_model()
            admins = User.objects.filter(is_staff=True, is_active=True)

            title = f"💰 Malipo Mapya — {payment.reference}"
            message = (
                f"User: {payment.user.email}\n"
                f"Kiasi: TSh {payment.amount:,.0f}\n"
                f"Aina: {payment.purpose}\n"
                f"{'Mtandao' if method_type == 'MOBILE_MONEY' else 'Benki'}: {detected}\n"
                f"Namba: {payment.phone_number or payment.metadata.get('identifier', '')}\n"
                f"Reference: {payment.reference}"
            )

            for admin in admins:
                try:
                    Notification.objects.create(
                        recipient=admin,
                        notification_type='payment',
                        title=title,
                        message=message,
                        is_sent=True,
                        sent_at=timezone.now(),
                        metadata={
                            'payment_id': payment.id,
                            'payment_reference': payment.reference,
                            'amount': str(payment.amount),
                        },
                    )
                except Exception:
                    pass

            # Pia notify user mwenyewe
            try:
                Notification.objects.create(
                    recipient=payment.user,
                    notification_type='payment',
                    title="Malipo Yameanzishwa",
                    message=(
                        f"Malipo ya TSh {payment.amount:,.0f} yameanzishwa.\n"
                        f"Tafadhali lipa kwa maelekezo yaliyotolewa.\n"
                        f"Reference: {payment.reference}"
                    ),
                    is_sent=True,
                    sent_at=timezone.now(),
                    metadata={'payment_id': payment.id},
                )
            except Exception:
                pass

        except Exception:
            pass
