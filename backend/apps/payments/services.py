from decimal import Decimal

from django.db import transaction
from django.utils import timezone

from .gateways import (
    PaymentRequest,
    get_payment_gateway,
)
from .models import (
    Payment,
    PaymentAttempt,
    PaymentStatus,
)


class PaymentService:

    @staticmethod
    @transaction.atomic
    def initiate_payment(payment: Payment) -> Payment:
        gateway = get_payment_gateway(
            payment.provider
        )

        attempt_count = payment.attempts.count()

        attempt = PaymentAttempt.objects.create(
            payment=payment,
            attempt_number=attempt_count + 1,
            status=PaymentStatus.PROCESSING,
            request_payload={
                "amount": str(payment.amount),
                "currency": payment.currency,
                "phone_number": payment.phone_number,
                "reference": payment.reference,
            },
        )

        payment.status = PaymentStatus.PROCESSING
        payment.save(
            update_fields=[
                "status",
                "updated_at",
            ]
        )

        try:
            result = gateway.initiate_payment(
                PaymentRequest(
                    amount=payment.amount,
                    currency=payment.currency,
                    phone_number=payment.phone_number,
                    reference=payment.reference,
                    description=payment.description,
                    metadata=payment.metadata,
                )
            )

            attempt.response_payload = (
                result.raw_response or {}
            )

            attempt.gateway_reference = (
                result.gateway_reference
            )

            attempt.status = (
                PaymentStatus.SUCCESS
                if result.success
                else PaymentStatus.FAILED
            )

            attempt.error_message = (
                ""
                if result.success
                else result.message
            )

            attempt.save()

            if result.success:
                payment.status = PaymentStatus.SUCCESS
                payment.gateway_reference = (
                    result.gateway_reference
                )
                payment.completed_at = timezone.now()
                payment.failure_reason = ""
            else:
                payment.status = PaymentStatus.FAILED
                payment.failure_reason = result.message

            payment.save(
                update_fields=[
                    "status",
                    "gateway_reference",
                    "completed_at",
                    "failure_reason",
                    "updated_at",
                ]
            )

            return payment

        except Exception as exc:
            attempt.status = PaymentStatus.FAILED
            attempt.error_message = str(exc)
            attempt.save()

            payment.status = PaymentStatus.FAILED
            payment.failure_reason = str(exc)

            payment.save(
                update_fields=[
                    "status",
                    "failure_reason",
                    "updated_at",
                ]
            )

            return payment

    @staticmethod
    def check_payment_status(payment: Payment) -> Payment:
        if not payment.gateway_reference:
            return payment

        gateway = get_payment_gateway(
            payment.provider
        )

        result = gateway.check_payment_status(
            payment.gateway_reference
        )

        if result.success:
            payment.status = PaymentStatus.SUCCESS
            payment.completed_at = timezone.now()
            payment.failure_reason = ""
        else:
            payment.status = PaymentStatus.FAILED
            payment.failure_reason = result.message

        payment.save(
            update_fields=[
                "status",
                "completed_at",
                "failure_reason",
                "updated_at",
            ]
        )

        return payment

    @staticmethod
    @transaction.atomic
    def refund_payment(
        payment: Payment,
        amount: Decimal,
        reason: str,
    ):
        if payment.status != PaymentStatus.SUCCESS:
            raise ValueError(
                "Only successful payments can be refunded."
            )

        if amount <= Decimal("0.00"):
            raise ValueError(
                "Refund amount must be greater than zero."
            )

        refunded = sum(
            refund.amount
            for refund in payment.refunds.all()
            if refund.status == PaymentStatus.SUCCESS
        )

        if refunded + amount > payment.amount:
            raise ValueError(
                "Refund amount exceeds payment amount."
            )

        gateway = get_payment_gateway(
            payment.provider
        )

        result = gateway.refund_payment(
            payment.gateway_reference,
            amount,
        )

        from .models import PaymentRefund

        refund = PaymentRefund.objects.create(
            payment=payment,
            amount=amount,
            reason=reason,
            status=(
                PaymentStatus.SUCCESS
                if result.success
                else PaymentStatus.FAILED
            ),
            gateway_reference=(
                result.gateway_reference
            ),
            metadata=result.raw_response or {},
            completed_at=(
                timezone.now()
                if result.success
                else None
            ),
        )

        return refund