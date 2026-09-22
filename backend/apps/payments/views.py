from decimal import Decimal

from django.db.models import Sum
from django.utils import timezone
from rest_framework import status
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Payment, PaymentStatus, PaymentProvider
from .serializers import (
    PaymentSerializer,
    PaymentInitiateSerializer,
    PaymentSubmitReferenceSerializer,
)

# Namba ya kampuni (imefichwa kwa UI)
COMPANY_ACCOUNT_NAME = "Automotive Smart Garage"
COMPANY_PHONE = "Automotive Smart Garage Account"  # ← itafichwa


def _create_user_notification(user, title, message, notification_type="payment", payment_id=None):
    """Tuma notification kwa user (in-app)."""
    try:
        from apps.notifications.models import Notification
        Notification.objects.create(
            recipient=user,
            notification_type=notification_type,
            title=title,
            message=message,
            is_sent=True,
            sent_at=timezone.now(),
            metadata={"payment_id": payment_id} if payment_id else {},
        )
        return True
    except Exception:
        return False


# ==================== USER ====================
class PaymentInitiateView(APIView):
    """User - kuanzisha malipo. Payment iko PENDING hadi admin athibitishe."""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = PaymentInitiateSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(
                {"success": False, "errors": serializer.errors},
                status=status.HTTP_400_BAD_REQUEST,
            )
        data = serializer.validated_data

        payment = Payment.objects.create(
            user=request.user,
            amount=data["amount"],
            currency="TZS",
            method="MOBILE_MONEY",
            provider=PaymentProvider.SANDBOX,
            purpose=data["purpose"],
            status=PaymentStatus.PENDING,
            phone_number=data["phone_number"],
            description=data.get("description", ""),
            metadata={
                "reference_id": data.get("reference_id", ""),
                "user_reference": "",
                "note": "",
            },
            expires_at=timezone.now() + timezone.timedelta(hours=24),
        )

        instructions = (
            f"1. Tuma TSh {payment.amount} kwenda {COMPANY_ACCOUNT_NAME}\n"
            f"2. Tumia M-Pesa / Tigo Pesa / Airtel Money / Halopesa\n"
            f"3. Weka namba yako ya Siri kuthibitisha\n"
            f"4. Baada ya kutuma, nakili transaction ID (M-Pesa/Tigo)\n"
            f"5. Rudi hapa na uweke transaction ID kuthibitisha\n\n"
            f"Kumbukumbu: {payment.reference}"
        )

        return Response({
            "success": True,
            "message": (
                "Malipo yameanzishwa. Tuma kiasi kwenda Automotive Smart Garage, "
                "kisha weka transaction ID yako."
            ),
            "data": PaymentSerializer(payment).data,
            "instructions": instructions,
            "company_account": COMPANY_ACCOUNT_NAME,
        }, status=status.HTTP_201_CREATED)


class PaymentSubmitReferenceView(APIView):
    """User - kuweka reference ya M-Pesa baada ya kulipa."""
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            payment = Payment.objects.get(pk=pk, user=request.user)
        except Payment.DoesNotExist:
            return Response(
                {"success": False, "message": "Payment haipo"},
                status=status.HTTP_404_NOT_FOUND,
            )

        if payment.status not in (PaymentStatus.PENDING, PaymentStatus.CREATED):
            return Response(
                {"success": False, "message": f"Payment ipo {payment.status}, haiwezi kubadilishwa"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        serializer = PaymentSubmitReferenceSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(
                {"success": False, "errors": serializer.errors},
                status=status.HTTP_400_BAD_REQUEST,
            )

        ref = serializer.validated_data["user_reference"].strip()
        if len(ref) < 4:
            return Response(
                {"success": False, "message": "Reference ni fupi sana"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        meta = dict(payment.metadata or {})
        meta["user_reference"] = ref
        meta["note"] = serializer.validated_data.get("note", "")
        meta["submitted_at"] = timezone.now().isoformat()
        payment.metadata = meta
        payment.external_reference = ref
        payment.status = PaymentStatus.PROCESSING
        payment.save()

        # Notification kwa admin (kwa sasa, tutaongeza Notification model ya admin baadaye)
        return Response({
            "success": True,
            "message": "Reference imepokelewa. Admin atathibitisha malipo yako hivi karibuni.",
            "data": PaymentSerializer(payment).data,
        })


class PaymentListView(APIView):
    """User - kuona malipo yake."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        qs = Payment.objects.filter(user=request.user).order_by("-created_at")
        # Auto-expire yoyote yaliyopitwa na muda
        for p in qs[:100]:
            p.check_expiry()
        return Response({
            "success": True,
            "count": qs.count(),
            "data": PaymentSerializer(qs[:100], many=True).data,
        })


class PaymentDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        try:
            payment = Payment.objects.get(pk=pk, user=request.user)
        except Payment.DoesNotExist:
            return Response(
                {"success": False, "message": "Payment haipo"},
                status=status.HTTP_404_NOT_FOUND,
            )
        payment.check_expiry()
        return Response({
            "success": True,
            "data": PaymentSerializer(payment).data,
        })


class EarningsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        payments = Payment.objects.filter(
            user=request.user,
            status__in=[PaymentStatus.SUCCESS, "COMPLETED"],
        )
        total = payments.aggregate(total=Sum("amount"))["total"] or 0
        history = []
        for p in payments.order_by("-created_at")[:10]:
            history.append({
                "id": p.id,
                "amount": str(p.amount),
                "type": p.purpose or p.method or "payment",
                "reference": p.reference or "",
                "created_at": p.created_at.isoformat() if p.created_at else "",
            })
        return Response({"total_earnings": str(total), "history": history})


# ==================== ADMIN ====================
class AdminPaymentListView(APIView):
    permission_classes = [IsAdminUser]

    def get(self, request):
        qs = Payment.objects.select_related("user").all().order_by("-created_at")
        status_filter = request.query_params.get("status")
        if status_filter and status_filter.upper() != "ALL":
            qs = qs.filter(status=status_filter.upper())
        return Response({
            "success": True,
            "count": qs.count(),
            "data": PaymentSerializer(qs[:200], many=True).data,
        })


class AdminPaymentVerifyView(APIView):
    """Admin - kuthibitisha au kukataa malipo."""
    permission_classes = [IsAdminUser]

    def post(self, request, pk):
        try:
            payment = Payment.objects.select_related("user").get(pk=pk)
        except Payment.DoesNotExist:
            return Response(
                {"success": False, "message": "Payment haipo"},
                status=status.HTTP_404_NOT_FOUND,
            )

        action = (request.data.get("action") or "verify").lower()

        if action == "verify":
            payment.status = PaymentStatus.SUCCESS
            payment.completed_at = timezone.now()
            payment.save()
            _create_user_notification(
                payment.user,
                title="Malipo Yamethibitishwa ✅",
                message=(
                    f"Malipo yako ya TSh {payment.amount} "
                    f"(Ref: {payment.reference}) yamethibitishwa. "
                    f"Asante kwa kutumia Automotive Smart Garage."
                ),
                payment_id=payment.id,
            )
            msg = "Malipo yamethibitishwa"

        elif action == "reject":
            payment.status = PaymentStatus.FAILED
            payment.failure_reason = request.data.get("reason", "Rejected by admin")
            payment.save()
            _create_user_notification(
                payment.user,
                title="Malipo Yamekataliwa ❌",
                message=(
                    f"Malipo yako ya TSh {payment.amount} "
                    f"(Ref: {payment.reference}) hayakuthibitishwa. "
                    f"Sababu: {payment.failure_reason}"
                ),
                payment_id=payment.id,
            )
            msg = "Malipo yamekataliwa"

        elif action == "processing":
            payment.status = PaymentStatus.PROCESSING
            payment.save()
            _create_user_notification(
                payment.user,
                title="Malipo Yanachakatwa ⏳",
                message=(
                    f"Malipo yako ya TSh {payment.amount} "
                    f"(Ref: {payment.reference}) yanachakatwa."
                ),
                payment_id=payment.id,
            )
            msg = "Malipo yamewekwa kama processing"
        else:
            return Response(
                {"success": False, "message": "Action si sahihi"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        return Response({
            "success": True,
            "message": msg,
            "data": PaymentSerializer(payment).data,
        })


# ==================== MANUAL PAYMENT CONFIRMATION ====================
class PaymentConfirmManualView(APIView):
    """
    User ana-confirm kuwa amelipa. Admin atathibitisha.
    Inatuma notification kwa admin.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        from apps.notifications.models import Notification
        from django.contrib.auth import get_user_model

        phone_number = request.data.get('phone_number', '').strip()
        network = request.data.get('network', '').strip()

        if not phone_number:
            return Response(
                {'success': False, 'message': 'phone_number ni lazima'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Tafuta payment ya mwisho ya user (PENDING)
        payment = Payment.objects.filter(
            user=request.user,
            status__in=['PENDING', 'CREATED'],
        ).order_by('-created_at').first()

        if not payment:
            return Response(
                {'success': False, 'message': 'Hakuna malipo yanayosubiri'},
                status=status.HTTP_404_NOT_FOUND,
            )

        # Update payment na taarifa za user
        payment.phone_number = phone_number
        payment.status = PaymentStatus.PENDING  # Bado pending, admin atathibitisha
        payment.metadata = {
            **(payment.metadata or {}),
            'user_confirmed': True,
            'user_network': network,
            'user_confirmed_at': timezone.now().isoformat(),
        }
        payment.save()

        # Tuma notification kwa admin
        User = get_user_model()
        admins = User.objects.filter(role__in=['ADMIN', 'SUPER_ADMIN'], is_active=True)
        user_name = request.user.get_full_name() or request.user.email

        for admin in admins:
            try:
                Notification.objects.create(
                    recipient=admin,
                    notification_type='payment',
                    title='Malipo Mapya Yanahitaji Uthibitisho',
                    message=(
                        f'User {user_name} '
                        f'({phone_number}) amelipa TSh {payment.amount} '
                        f'via {network}. Reference: {payment.reference}'
                    ),
                    action_data={
                        'type': 'payment_confirmation',
                        'payment_id': payment.id,
                        'reference': payment.reference,
                        'amount': str(payment.amount),
                        'user_name': user_name,
                        'user_phone': phone_number,
                        'network': network,
                    },
                )
            except Exception as e:
                print(f"[Notification Error] {e}")

        return Response({
            'success': True,
            'message': 'Taarifa yako imepokelewa. Admin atathibitisha malipo hivi karibuni.',
            'data': {
                'reference': payment.reference,
                'amount': str(payment.amount),
                'status': payment.status,
            },
        })


# ==================== COUNTDOWN ====================
class PaymentCountdownView(APIView):
    """User - kuangalia muda uliobaki wa malipo (countdown 45 min)."""
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        try:
            payment = Payment.objects.get(pk=pk, user=request.user)
        except Payment.DoesNotExist:
            return Response(
                {"success": False, "message": "Payment haipo"},
                status=status.HTTP_404_NOT_FOUND,
            )

        # Auto-expire kama imepitwa na muda
        just_expired = payment.check_expiry()

        now = timezone.now()
        remaining_seconds = 0
        is_expired = payment.status == PaymentStatus.EXPIRED

        if not is_expired and payment.expires_at:
            diff = payment.expires_at - now
            remaining_seconds = max(0, int(diff.total_seconds()))
            if remaining_seconds == 0 and not is_expired:
                payment.check_expiry()
                is_expired = True

        return Response({
            "success": True,
            "data": {
                "payment_id": payment.id,
                "reference": payment.reference,
                "status": payment.status,
                "amount": str(payment.amount),
                "expires_at": payment.expires_at.isoformat() if payment.expires_at else None,
                "remaining_seconds": remaining_seconds,
                "remaining_minutes": remaining_seconds // 60,
                "remaining_seconds_display": remaining_seconds % 60,
                "is_expired": is_expired,
                "timeout_minutes": 45,
            },
        })


class PaymentCancelView(APIView):
    """User - kucancel malipo kwa hiari yake."""
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            payment = Payment.objects.get(pk=pk, user=request.user)
        except Payment.DoesNotExist:
            return Response(
                {"success": False, "message": "Payment haipo"},
                status=status.HTTP_404_NOT_FOUND,
            )

        if payment.status not in (PaymentStatus.PENDING, PaymentStatus.CREATED, PaymentStatus.PROCESSING):
            return Response(
                {"success": False, "message": f"Payment ipo {payment.status}, haiwezi kucancel"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        payment.status = PaymentStatus.CANCELLED
        payment.failure_reason = request.data.get("reason", "Cancelled by user")
        payment.save()

        # Notify admin
        try:
            from apps.notifications.models import Notification
            from django.contrib.auth import get_user_model
            User = get_user_model()
            for admin in User.objects.filter(is_staff=True, is_active=True):
                try:
                    Notification.objects.create(
                        recipient=admin,
                        notification_type="payment",
                        title=f"❌ Malipo Yamecancel — {payment.reference}",
                        message=(
                            f"User: {request.user.email}\n"
                            f"Kiasi: TSh {payment.amount:,.0f}\n"
                            f"Sababu: {payment.failure_reason}"
                        ),
                        is_sent=True,
                    )
                except Exception:
                    pass
        except Exception:
            pass

        return Response({
            "success": True,
            "message": "Malipo yamecancel",
            "data": PaymentSerializer(payment).data,
        })
