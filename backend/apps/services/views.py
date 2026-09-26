from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.response import Response
from django.utils import timezone

from api.permissions import IsAdminOrReadOnly
from .models import ServiceCategory, Service
from .serializers import ServiceCategorySerializer, ServiceSerializer
from rest_framework.views import APIView
from rest_framework import status
from rest_framework.permissions import IsAuthenticated


class ServiceCategoryViewSet(viewsets.ModelViewSet):
    queryset = ServiceCategory.objects.all()
    serializer_class = ServiceCategorySerializer
    permission_classes = [IsAdminOrReadOnly]
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    pagination_class = None  # Rudisha zote bila pagination


def _notify_all_users(service, action="created"):
    """Tuma notification kwa users wote kuhusu service mpya/iliyobadilishwa."""
    try:
        from apps.notifications.models import Notification
        from django.contrib.auth import get_user_model
        User = get_user_model()

        if action == "created":
            title = f"Service Mpya: {service.name}"
            message = (
                f"Huduma mpya imeongezwa: {service.name}\n"
                f"Bei: TSh {service.base_price:,.0f}\n"
            )
        elif action == "updated":
            title = f"Service Imebadilishwa: {service.name}"
            message = f"Huduma imebadilishwa: {service.name}\nBei: TSh {service.base_price:,.0f}\n"
        elif action == "deleted":
            title = f"Service Imefutwa: {service.name}"
            message = f"Huduma imefutwa: {service.name}\n"
        else:
            return

        # Ongeza siku + muda kama zipo
        if service.available_days:
            days_map = {
                "MON": "Jumatatu", "TUE": "Jumanne", "WED": "Jumatano",
                "THU": "Alhamisi", "FRI": "Ijumaa", "SAT": "Jumamosi", "SUN": "Jumapili"
            }
            days_str = ", ".join([days_map.get(d, d) for d in service.available_days])
            message += f"Siku: {days_str}\n"
        if service.start_time and service.end_time:
            message += f"Muda: {service.start_time.strftime('%H:%M')} - {service.end_time.strftime('%H:%M')}\n"

        # Tuma kwa users wote (isipokuwa admins)
        users = User.objects.filter(is_active=True).exclude(is_staff=True)
        count = 0
        errors = []
        for user in users:
            try:
                Notification.objects.create(
                    recipient=user,
                    notification_type="service",
                    title=title,
                    message=message,
                    is_sent=True,
                    sent_at=timezone.now(),
                    metadata={"service_id": service.id, "action": action},
                )
                count += 1
            except Exception as e:
                errors.append(f"{user.email}: {e}")

        print(f"[NOTIFY SERVICE] Sent to {count} users. Errors: {errors}")
        return count
    except Exception as e:
        print(f"[NOTIFY SERVICE ERROR] {e}")
        return 0


class ServiceViewSet(viewsets.ModelViewSet):
    queryset = Service.objects.all().select_related('category')
    serializer_class = ServiceSerializer
    permission_classes = [IsAdminOrReadOnly]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def perform_create(self, serializer):
        service = serializer.save()
        # Notify users wote
        _notify_all_users(service, action="created")

    def perform_update(self, serializer):
        service = serializer.save()
        _notify_all_users(service, action="updated")

    def perform_destroy(self, instance):
        # Notify kabla ya kufuta
        _notify_all_users(instance, action="deleted")
        instance.delete()


    @action(detail=True, methods=['post'], url_path='notify-all')
    def notify_all(self, request, pk=None):
        """Admin - tuma notification kwa users wote kuhusu service hii."""
        service = self.get_object()
        count = _notify_all_users(service, action="updated")
        return Response({
            "success": True,
            "message": f"Notification imetumwa kwa users {count}",
            "data": {"sent_count": count},
        })

# ==================== SERVICE BOOKING (GROUP 3) ====================
from .serializers import ServiceBookingSerializer, ServiceBookingCreateSerializer


class ServiceBookingCreateView(APIView):
    """User anaunda service booking."""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        from .models import ServiceBooking, Service
        serializer = ServiceBookingCreateSerializer(data=request.data)
        if not serializer.is_valid():
            return Response({
                "success": False,
                "message": "Taarifa hazijakamilika",
                "errors": serializer.errors,
            }, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        try:
            service = Service.objects.get(pk=data["service_id"], is_active=True)
        except Service.DoesNotExist:
            return Response({
                "success": False,
                "message": "Service haipo",
            }, status=status.HTTP_404_NOT_FOUND)

        booking = ServiceBooking.objects.create(
            user=request.user,
            service=service,
            vehicle_make=data["vehicle_make"],
            vehicle_model=data["vehicle_model"],
            vehicle_year=data.get("vehicle_year", ""),
            vehicle_registration=data.get("vehicle_registration", ""),
            vehicle_notes=data.get("vehicle_notes", ""),
            total_price=service.base_price,
        )

        return Response({
            "success": True,
            "message": "Booking imeundwa. Lipa deposit (50%) kuendelea.",
            "data": ServiceBookingSerializer(booking, context={"request": request}).data,
        }, status=status.HTTP_201_CREATED)


class ServiceBookingListView(APIView):
    """User anaona bookings zake."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        from .models import ServiceBooking
        bookings = ServiceBooking.objects.filter(
            user=request.user
        ).select_related("service").order_by("-created_at")
        return Response({
            "success": True,
            "count": bookings.count(),
            "data": ServiceBookingSerializer(bookings, many=True, context={"request": request}).data,
        })


class ServiceBookingDetailView(APIView):
    """Booking detail."""
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        from .models import ServiceBooking
        try:
            b = ServiceBooking.objects.get(pk=pk, user=request.user)
        except ServiceBooking.DoesNotExist:
            return Response({"success": False, "message": "Booking haipo"}, status=404)
        return Response({
            "success": True,
            "data": ServiceBookingSerializer(b, context={"request": request}).data,
        })


class ServiceBookingPayDepositView(APIView):
    """User analipa 50% deposit — initiate payment."""
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        from .models import ServiceBooking
        from apps.payments.payment_unified import PaymentInitiateUnifiedView
        import re as _re

        try:
            booking = ServiceBooking.objects.get(pk=pk, user=request.user)
        except ServiceBooking.DoesNotExist:
            return Response({"success": False, "message": "Booking haipo"}, status=404)

        if booking.status not in ("PENDING_PAYMENT",):
            return Response({
                "success": False,
                "message": "Booking hii imeshalipiwa au imefutwa",
            }, status=400)

        phone = (request.data.get("phone_number") or "").strip()
        method = (request.data.get("payment_method") or "MOBILE_MONEY").upper()
        bank = (request.data.get("bank_name") or "").strip()

        if method == "MOBILE_MONEY":
            clean = _re.sub(r"[^0-9]", "", phone)
            if clean.startswith("255"):
                clean = "0" + clean[3:]
            elif not clean.startswith("0"):
                clean = "0" + clean
            if len(clean) != 10 or not (clean.startswith("07") or clean.startswith("06")):
                return Response({
                    "success": False,
                    "message": "Namba si sahihi. Tumia 07XXXXXXXX au 06XXXXXXXX",
                }, status=400)
            phone = clean

        # Unda payment kwa kutumia unified
        from apps.payments.models import Payment
        from apps.payments.detection import get_instructions, detect_network
        from apps.payments.payment_config import PAYMENT_TIMEOUT_MINUTES
        from decimal import Decimal
        import uuid as _uuid

        detected = detect_network(phone) if method == "MOBILE_MONEY" else "Unknown"
        reference = f"SB-{_uuid.uuid4().hex[:8].upper()}"

        payment = Payment.objects.create(
            user=request.user,
            amount=booking.deposit_amount,
            currency="TZS",
            provider=method,
            method=method,
            purpose="SERVICE",
            reference=reference,
            phone_number=phone,
            status="PENDING",
            description=f"Deposit 50% — {booking.service.name}",
            expires_at=timezone.now() + timezone.timedelta(minutes=PAYMENT_TIMEOUT_MINUTES),
            metadata={
                "service_booking_id": booking.id,
                "booking_number": booking.booking_number,
                "type": "SERVICE_DEPOSIT",
                "bank_name": bank,
            },
        )

        # Update booking
        booking.payment_reference = reference
        booking.payment_phone = phone
        booking.payment_method = method
        booking.detected_network = detected
        booking.payment_countdown_ends_at = payment.expires_at
        booking.save()

        inst = get_instructions(method, phone, booking.deposit_amount, reference) if method == "MOBILE_MONEY" else None

        return Response({
            "success": True,
            "message": "Malipo yameanzishwa",
            "data": {
                "payment_id": payment.id,
                "reference": reference,
                "amount": float(booking.deposit_amount),
                "total_price": float(booking.total_price),
                "balance_amount": float(booking.balance_amount),
                "detected_network": detected,
                "payment_method": method,
                "admin_number": "0759212300",
                "bank_name": bank or "NMB",
                "bank_account": "23210042232",
                "countdown_seconds": PAYMENT_TIMEOUT_MINUTES * 60,
                "expires_at": payment.expires_at.isoformat(),
                "instructions_mobile": inst["instructions"] if inst else None,
                "instructions_bank": (
                    f"BENKI: {bank or 'NMB'}\n"
                    f"Account: 23210042232\n"
                    f"Jina: Automotive Smart Garage\n"
                    f"Kiasi: TSh {float(booking.deposit_amount):,.0f}\n"
                    f"Reference: {reference}\n\n"
                    f"1. Nenda app ya benki yako\n"
                    f"2. Chagua Transfer/Send Money\n"
                    f"3. Weka account 23210042232\n"
                    f"4. Weka kiasi TSh {float(booking.deposit_amount):,.0f}\n"
                    f"5. Weka reference {reference}"
                ) if method == "BANK" else None,
            },
        }, status=201)


class ServiceBookingStatusView(APIView):
    """Status + countdown ya booking."""
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        from .models import ServiceBooking
        try:
            b = ServiceBooking.objects.get(pk=pk, user=request.user)
        except ServiceBooking.DoesNotExist:
            return Response({"success": False, "message": "Booking haipo"}, status=404)

        now = timezone.now()
        payment_remaining = 0
        if b.payment_countdown_ends_at and b.status == "PENDING_PAYMENT":
            diff = b.payment_countdown_ends_at - now
            payment_remaining = max(0, int(diff.total_seconds()))

        eta_remaining = 0
        if b.eta_countdown_ends_at and b.status in ("CONFIRMED", "IN_PROGRESS"):
            diff = b.eta_countdown_ends_at - now
            eta_remaining = max(0, int(diff.total_seconds()))

        return Response({
            "success": True,
            "data": {
                "booking_id": b.id,
                "booking_number": b.booking_number,
                "status": b.status,
                "payment_status": b.payment_status,
                "total_price": float(b.total_price),
                "deposit_amount": float(b.deposit_amount),
                "balance_amount": float(b.balance_amount),
                "payment_countdown_seconds": payment_remaining,
                "eta_countdown_seconds": eta_remaining,
                "eta_minutes": b.eta_minutes,
                "appointment_date": b.appointment_date.isoformat() if b.appointment_date else None,
                "appointment_time": b.appointment_time,
                "service_location": b.service_location,
                "distance_km": float(b.distance_km) if b.distance_km else None,
                "receipt_confirmed": b.receipt_confirmed_at is not None,
                "extended_count": b.extended_count,
                "is_eta_due": (
                    b.eta_countdown_ends_at
                    and now > b.eta_countdown_ends_at
                    and not b.receipt_confirmed_at
                ),
            },
        })


class ServiceBookingConfirmReceiptView(APIView):
    """User anathibitisha: YES = amepokea, NO = extend."""
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        from .models import ServiceBooking
        try:
            b = ServiceBooking.objects.get(pk=pk, user=request.user)
        except ServiceBooking.DoesNotExist:
            return Response({"success": False, "message": "Booking haipo"}, status=404)

        answer = (request.data.get("answer") or "").lower()

        if answer == "yes":
            b.receipt_confirmed_at = timezone.now()
            b.status = "COMPLETED"
            b.completed_at = timezone.now()
            b.save()

            # Notify admin
            try:
                from apps.notifications.models import Notification
                from django.contrib.auth import get_user_model
                User = get_user_model()
                for admin in User.objects.filter(is_staff=True, is_active=True):
                    Notification.objects.create(
                        recipient=admin,
                        notification_type="service",
                        title=f"✅ Service Completed — {b.booking_number}",
                        message=f"{b.user.email} amethibitisha huduma ya {b.service.name}.",
                        is_sent=True,
                        metadata={"booking_id": b.id},
                    )
            except Exception:
                pass

            return Response({
                "success": True,
                "message": "Asante! Tafadhali toa maoni yako.",
                "data": {"status": "COMPLETED", "feedback_pending": True},
            })
        elif answer == "no":
            return Response({
                "success": True,
                "message": "Sorry. Can you allow some extra time for our mechanic in case of an emergency?",
                "data": {"status": "waiting_extension", "extension_minutes": 15},
            })

        return Response({"success": False, "message": "Jibu YES au NO"}, status=400)


class ServiceBookingExtendView(APIView):
    """User anaongeza +15 min."""
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        from .models import ServiceBooking
        try:
            b = ServiceBooking.objects.get(pk=pk, user=request.user)
        except ServiceBooking.DoesNotExist:
            return Response({"success": False, "message": "Booking haipo"}, status=404)

        minutes = int(request.data.get("minutes", 15))
        base = b.eta_countdown_ends_at or timezone.now()
        b.eta_countdown_ends_at = base + timezone.timedelta(minutes=minutes)
        b.extended_count += 1
        b.save()

        # Notify admin
        try:
            from apps.notifications.models import Notification
            from django.contrib.auth import get_user_model
            User = get_user_model()
            for admin in User.objects.filter(is_staff=True, is_active=True):
                Notification.objects.create(
                    recipient=admin,
                    notification_type="alert",
                    title=f"⚠️ Emergency Extension — {b.booking_number}",
                    message=f"{b.user.email} ameongeza dakika {minutes}.",
                    is_sent=True,
                    metadata={"booking_id": b.id},
                )
        except Exception:
            pass

        return Response({
            "success": True,
            "message": f"Dakika {minutes} zimeongezwa",
            "data": {"eta_countdown_ends_at": b.eta_countdown_ends_at.isoformat()},
        })


class ServiceBookingFeedbackView(APIView):
    """User anaacha feedback."""
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        from .models import ServiceBooking
        try:
            b = ServiceBooking.objects.get(pk=pk, user=request.user)
        except ServiceBooking.DoesNotExist:
            return Response({"success": False, "message": "Booking haipo"}, status=404)

        b.user_feedback = (request.data.get("feedback") or "").strip()
        try:
            b.user_rating = int(request.data.get("rating", 0))
        except (ValueError, TypeError):
            b.user_rating = 0
        b.save()

        # Notify admin
        try:
            from apps.notifications.models import Notification
            from django.contrib.auth import get_user_model
            User = get_user_model()
            for admin in User.objects.filter(is_staff=True, is_active=True):
                Notification.objects.create(
                    recipient=admin,
                    notification_type="system",
                    title=f"📩 Feedback — {b.booking_number}",
                    message=f"{b.user.email}: {b.user_feedback[:80]}",
                    is_sent=True,
                    metadata={"booking_id": b.id},
                )
        except Exception:
            pass

        return Response({"success": True, "message": "Asante kwa maoni yako!"})


class ServiceBookingCancelView(APIView):
    """User ana-cancel booking."""
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        from .models import ServiceBooking
        try:
            b = ServiceBooking.objects.get(pk=pk, user=request.user)
        except ServiceBooking.DoesNotExist:
            return Response({"success": False, "message": "Booking haipo"}, status=404)

        if b.status in ("IN_PROGRESS", "COMPLETED"):
            return Response({
                "success": False,
                "message": "Booking imeshaanza — hauwezi kufuta",
            }, status=400)

        b.status = "CANCELLED"
        b.save()
        return Response({"success": True, "message": "Booking imefutwa"})


# ==================== ADMIN ====================
class AdminServiceBookingListView(APIView):
    """Admin — bookings zote."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        from .models import ServiceBooking
        if not (request.user.is_staff or request.user.role in ("ADMIN", "SUPER_ADMIN")):
            return Response({"success": False, "message": "Hauna ruhusa"}, status=403)
        bookings = ServiceBooking.objects.all().select_related("service", "user").order_by("-created_at")[:100]
        return Response({
            "success": True,
            "count": len(bookings),
            "data": ServiceBookingSerializer(bookings, many=True, context={"request": request}).data,
        })


class AdminServiceBookingVerifyPaymentView(APIView):
    """Admin ana-verify malipo ya booking."""
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        from .models import ServiceBooking
        if not (request.user.is_staff or request.user.role in ("ADMIN", "SUPER_ADMIN")):
            return Response({"success": False, "message": "Hauna ruhusa"}, status=403)

        try:
            b = ServiceBooking.objects.get(pk=pk)
        except ServiceBooking.DoesNotExist:
            return Response({"success": False, "message": "Booking haipo"}, status=404)

        b.payment_status = "DEPOSIT_PAID"
        b.status = "DEPOSIT_PAID"
        b.save()

        # Notify user
        try:
            from apps.notifications.services import send_notification_to_user
            send_notification_to_user(
                user=b.user,
                title="✅ Malipo yamethibitishwa",
                message=f"Deposit yako ya {b.booking_number} imethibitishwa. Admin atakupanga tarehe.",
                notification_type="service",
                data={"booking_id": b.id, "type": "service_deposit_verified"},
            )
        except Exception as e:
            print(f"[Notif] {e}")

        return Response({
            "success": True,
            "message": "Malipo yamethibitishwa",
            "data": ServiceBookingSerializer(b, context={"request": request}).data,
        })


class AdminServiceBookingSetAppointmentView(APIView):
    """Admin ana-set tarehe + muda wa appointment."""
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        from .models import ServiceBooking
        if not (request.user.is_staff or request.user.role in ("ADMIN", "SUPER_ADMIN")):
            return Response({"success": False, "message": "Hauna ruhusa"}, status=403)

        try:
            b = ServiceBooking.objects.get(pk=pk)
        except ServiceBooking.DoesNotExist:
            return Response({"success": False, "message": "Booking haipo"}, status=404)

        from datetime import datetime
        date_str = request.data.get("appointment_date")
        time_str = request.data.get("appointment_time", "")

        if date_str:
            try:
                b.appointment_date = datetime.strptime(date_str, "%Y-%m-%d").date()
            except Exception:
                return Response({"success": False, "message": "Tarehe si sahihi"}, status=400)

        b.appointment_time = time_str
        b.status = "CONFIRMED"

        # ETA kama imewekwa
        try:
            hours = int(request.data.get("eta_hours", 0))
            minutes = int(request.data.get("eta_minutes", 0))
            total = hours * 60 + minutes
            if total > 0:
                b.eta_minutes = total
                b.eta_countdown_ends_at = timezone.now() + timezone.timedelta(minutes=total)
        except (ValueError, TypeError):
            pass

        b.admin_notes = request.data.get("admin_notes", b.admin_notes)
        b.save()

        # Notify user
        try:
            from apps.notifications.services import send_notification_to_user
            send_notification_to_user(
                user=b.user,
                title="📅 Booking imethibitishwa",
                message=f"{b.service.name} yako imepangwa. Tarehe: {b.appointment_date} saa {b.appointment_time}",
                notification_type="service",
                data={"booking_id": b.id, "type": "service_appointment_set"},
            )
        except Exception as e:
            print(f"[Notif] {e}")

        return Response({
            "success": True,
            "message": "Appointment imewekwa",
            "data": ServiceBookingSerializer(b, context={"request": request}).data,
        })
