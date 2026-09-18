import hashlib
import hmac
import json
import requests
from datetime import datetime
from django.conf import settings
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from apps.payments.models import Payment, PaymentAttempt, PaymentWebhookEvent

class SelcomPaymentGateway:
    BASE_URL = "https://api.selcom.co.tz/v1"  # Sandbox URL

    @staticmethod
    def initiate_payment(amount, phone_number, reference, description="Payment"):
        """
        Simulate Selcom payment initiation
        In production, use real Selcom API
        """
        # Simulate payment initiation
        return {
            "reference": reference,
            "amount": amount,
            "phone_number": phone_number,
            "status": "PENDING",
            "instructions": f"Dial *150*01# and enter code 123456",
            "code": "123456"  # Simulated USSD code
        }

    @staticmethod
    def verify_payment(reference):
        """
        Simulate payment verification
        In production, use real Selcom API
        """
        # Simulate verification
        return {"status": "COMPLETED", "reference": reference}

class InitiatePaymentView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        amount = request.data.get('amount')
        phone_number = request.data.get('phone_number')
        purpose = request.data.get('purpose', 'SERVICE')

        if not amount or not phone_number:
            return Response({"success": False, "message": "amount and phone_number required"}, status=400)

        try:
            amount = float(amount)
            if amount <= 0:
                raise ValueError("Amount must be positive")
        except ValueError:
            return Response({"success": False, "message": "Invalid amount"}, status=400)

        # Create payment record
        reference = f"PAY-{uuid.uuid4().hex[:8].upper()}"
        payment = Payment.objects.create(
            user=request.user,
            amount=amount,
            currency="TZS",
            provider="SELCOM",
            purpose=purpose,
            phone_number=phone_number,
            status="PENDING",
            external_reference=reference
        )

        # Call payment gateway
        result = SelcomPaymentGateway.initiate_payment(
            amount=amount,
            phone_number=phone_number,
            reference=reference,
            description=f"Payment for {purpose}"
        )

        # Create payment attempt
        PaymentAttempt.objects.create(
            payment=payment,
            provider="SELCOM",
            reference=reference,
            status="PENDING",
            response_data=result
        )

        return Response({
            "success": True,
            "message": "Payment initiated",
            "data": {
                "payment_id": payment.id,
                "reference": reference,
                "amount": amount,
                "status": "PENDING",
                "instructions": result.get("instructions", "Check your phone for USSD"),
                "code": result.get("code", "123456")  # For testing
            }
        })

class VerifyPaymentView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        reference = request.data.get('reference')

        if not reference:
            return Response({"success": False, "message": "reference required"}, status=400)

        try:
            payment = Payment.objects.get(external_reference=reference, user=request.user)
        except Payment.DoesNotExist:
            return Response({"success": False, "message": "Payment not found"}, status=404)

        # Verify with gateway
        result = SelcomPaymentGateway.verify_payment(reference)

        if result.get("status") == "COMPLETED":
            payment.status = "COMPLETED"
            payment.completed_at = now()
            payment.save()

            # Create webhook event for audit
            PaymentWebhookEvent.objects.create(
                payment=payment,
                provider="SELCOM",
                event_type="payment.verified",
                payload=result
            )

            return Response({
                "success": True,
                "message": "Payment verified successfully",
                "data": {"status": "COMPLETED", "reference": reference}
            })
        else:
            return Response({
                "success": False,
                "message": "Payment not completed",
                "data": {"status": result.get("status"), "reference": reference}
            })
