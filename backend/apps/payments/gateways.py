from abc import ABC, abstractmethod
from dataclasses import dataclass
from decimal import Decimal
from typing import Any


@dataclass
class PaymentRequest:
    amount: Decimal
    currency: str
    phone_number: str = ""
    reference: str = ""
    description: str = ""
    metadata: dict[str, Any] | None = None


@dataclass
class PaymentGatewayResult:
    success: bool
    status: str
    gateway_reference: str = ""
    message: str = ""
    raw_response: dict[str, Any] | None = None


class PaymentGateway(ABC):
    """
    Base interface for all payment providers.
    """

    @abstractmethod
    def initiate_payment(
        self,
        request: PaymentRequest,
    ) -> PaymentGatewayResult:
        raise NotImplementedError

    @abstractmethod
    def check_payment_status(
        self,
        gateway_reference: str,
    ) -> PaymentGatewayResult:
        raise NotImplementedError

    @abstractmethod
    def refund_payment(
        self,
        gateway_reference: str,
        amount: Decimal,
    ) -> PaymentGatewayResult:
        raise NotImplementedError


class SandboxPaymentGateway(PaymentGateway):
    """
    Development gateway.

    This gateway must never be treated as a real
    money provider in production.
    """

    def initiate_payment(
        self,
        request: PaymentRequest,
    ) -> PaymentGatewayResult:

        gateway_reference = (
            f"SANDBOX-{request.reference}"
        )

        return PaymentGatewayResult(
            success=True,
            status="SUCCESS",
            gateway_reference=gateway_reference,
            message="Sandbox payment completed.",
            raw_response={
                "provider": "SANDBOX",
                "reference": request.reference,
                "amount": str(request.amount),
                "currency": request.currency,
            },
        )

    def check_payment_status(
        self,
        gateway_reference: str,
    ) -> PaymentGatewayResult:

        return PaymentGatewayResult(
            success=True,
            status="SUCCESS",
            gateway_reference=gateway_reference,
            message="Sandbox payment is successful.",
            raw_response={
                "provider": "SANDBOX",
                "gateway_reference": gateway_reference,
            },
        )

    def refund_payment(
        self,
        gateway_reference: str,
        amount: Decimal,
    ) -> PaymentGatewayResult:

        return PaymentGatewayResult(
            success=True,
            status="SUCCESS",
            gateway_reference=gateway_reference,
            message="Sandbox refund completed.",
            raw_response={
                "provider": "SANDBOX",
                "refund_amount": str(amount),
            },
        )


def get_payment_gateway(provider: str) -> PaymentGateway:
    providers = {
        "SANDBOX": SandboxPaymentGateway,
    }

    gateway_class = providers.get(provider)

    if not gateway_class:
        raise ValueError(
            f"Payment provider '{provider}' is not configured."
        )

    return gateway_class()