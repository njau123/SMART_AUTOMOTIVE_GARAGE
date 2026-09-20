from decimal import Decimal

from django.db import transaction

from django.utils import timezone
from rest_framework import status
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.mechanics.models import MechanicProfile
from apps.payments.models import (
    Payment, PaymentMethodType, PaymentProvider,
    PaymentPurpose, PaymentStatus,
)
from .models import Booking, BookingStatusHistory
from .serializers import BookingSerializer


def _log_status(booking, old_status, new_status, user, note=""):
    BookingStatusHistory.objects.create(
        booking=booking,
        old_status=old_status,
        new_status=new_status,
        changed_by=user,
        note=note,
    )


# ==================== USER ====================
class BookingCreateView(APIView):
    """User - kuunda booking. Auto-calculate deposit 50%."""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        data = request.data
        try:
            vehicle_id = data.get("vehicle")
            service_id = data.get("service")
            if not vehicle_id or not service_id:
                return Response(
                    {"success": False, "message": "vehicle na service ni lazima"},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            from apps.vehicles.models import Vehicle
            from apps.services.models import Service
            vehicle = Vehicle.objects.get(pk=vehicle_id, user=request.user)
            service = Service.objects.get(pk=service_id)

            # Optional: mechanic aliyeombwa
            mechanic_id = data.get("mechanic_id")
            mechanic = None
            if mechanic_id:
                from apps.mechanics.models import MechanicProfile
                mechanic = MechanicProfile.objects.filter(pk=mechanic_id).first()

            booking = Booking.objects.create(
                customer=request.user,
                vehicle=vehicle,
                service=service,
                mechanic=mechanic,
                scheduled_date=data.get("scheduled_date"),
                scheduled_time=data.get("scheduled_time") or "09:00:00",
                booking_type=data.get("booking_type", "GARAGE"),
                customer_notes=data.get("customer_notes", ""),
                service_address=data.get("service_address", ""),
                region=data.get("region", ""),
                district=data.get("district", ""),
                latitude=data.get("latitude"),
                longitude=data.get("longitude"),
            )
            _log_status(booking, "", Booking.Status.PENDING, request.user)

            # Notify mechanic (kama amechaguliwa)
            if mechanic is not None:
                try:
                    send_notification_to_user(
                        user=mechanic.user,
                        title="Ombi Jipya la Kazi",
                        message=f"{request.user.get_full_name() or 'Mteja'} ameomba kazi yako - {service.name}",
                        notification_type="mechanic",
                        data={
                            "type": "new_job_request",
                            "booking_id": str(booking.id),
                            "booking_number": booking.booking_number,
                            "service_name": service.name,
                            "customer_name": request.user.get_full_name() or "Mteja",
                        },
                    )
                    print(f"[NOTIFY] Notification sent to mechanic {mechanic.user.email}")
                except Exception as e:
                    print(f"[NOTIFY ERROR] {e}")

            return Response({
                "success": True,
                "message": "Booking imeundwa. Lipa deposit 50% ili kuthibitisha.",
                "data": BookingSerializer(booking).data,
            }, status=status.HTTP_201_CREATED)
        except Vehicle.DoesNotExist:
            return Response(
                {"success": False, "message": "Gari halipo"},
                status=status.HTTP_404_NOT_FOUND,
            )
        except Service.DoesNotExist:
            return Response(
                {"success": False, "message": "Service haipo"},
                status=status.HTTP_404_NOT_FOUND,
            )
        except Exception as e:
            return Response(
                {"success": False, "message": str(e)},
                status=status.HTTP_400_BAD_REQUEST,
            )


class MyBookingsView(APIView):
    """User - bookings zake zote."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        qs = Booking.objects.filter(customer=request.user).order_by("-created_at")
        return Response({
            "success": True,
            "count": qs.count(),
            "data": BookingSerializer(qs[:50], many=True).data,
        })


class BookingDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        try:
            b = Booking.objects.get(pk=pk, customer=request.user)
        except Booking.DoesNotExist:
            return Response(
                {"success": False, "message": "Booking haipo"},
                status=status.HTTP_404_NOT_FOUND,
            )
        return Response({"success": True, "data": BookingSerializer(b).data})


class PayDepositView(APIView):
    """User - kulipa deposit 50% (unified network detection)."""
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        from apps.payments.detection import get_instructions, detect_network
        from apps.payments.payment_config import PAYMENT_TIMEOUT_MINUTES

        try:
            booking = Booking.objects.get(pk=pk, customer=request.user)
        except Booking.DoesNotExist:
            return Response(
                {"success": False, "message": "Booking haipo"},
                status=status.HTTP_404_NOT_FOUND,
            )
        if booking.deposit_paid:
            return Response({
                "success": True,
                "message": "Deposit imelipwa tayari",
                "data": BookingSerializer(booking).data,
            })
        phone = request.data.get("phone_number", "")
        if not phone:
            return Response(
                {"success": False, "message": "phone_number ni lazima"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        detected_network = detect_network(phone)
        reference = f"DEP-{booking.booking_number}"
        inst = get_instructions("MOBILE_MONEY", phone, booking.deposit_amount, reference)

        try:
            provider_value = detected_network if detected_network in [p.value for p in PaymentProvider] else PaymentProvider.SANDBOX.value
        except Exception:
            provider_value = PaymentProvider.SANDBOX.value

        payment = Payment.objects.create(
            user=request.user,
            amount=booking.deposit_amount,
            currency="TZS",
            method=PaymentMethodType.MOBILE_MONEY,
            provider=provider_value,
            purpose=PaymentPurpose.BOOKING,
            status=PaymentStatus.PENDING,
            reference=reference,
            phone_number=phone,
            description=f"Deposit 50% for {booking.booking_number}",
            metadata={"booking_id": booking.id, "kind": "deposit", "detected_network": detected_network},
            expires_at=timezone.now() + timezone.timedelta(minutes=PAYMENT_TIMEOUT_MINUTES),
        )
        booking.payment_status = Booking.PaymentStatus.PENDING
        booking.save(update_fields=["payment_status"])

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
                        title=f"💰 Deposit — {booking.booking_number}",
                        message=(
                            f"User: {request.user.email}\n"
                            f"Kiasi: TSh {booking.deposit_amount:,.0f}\n"
                            f"Mtandao: {detected_network}\n"
                            f"Namba: {phone}\n"
                            f"Reference: {reference}"
                        ),
                        is_sent=True,
                        metadata={"payment_id": payment.id, "booking_id": booking.id, "kind": "deposit"},
                    )
                except Exception:
                    pass
        except Exception:
            pass

        return Response({
            "success": True,
            "message": f"Deposit TSh {booking.deposit_amount} imeanzishwa. Fuata maelekezo.",
            "data": {
                "booking": BookingSerializer(booking).data,
                "payment": {
                    "id": payment.id,
                    "reference": payment.reference,
                    "amount": str(payment.amount),
                    "status": payment.status,
                    "detected_network": detected_network,
                    "is_detected": detected_network != "Unknown",
                    "expires_at": payment.expires_at.isoformat() if payment.expires_at else None,
                    "timeout_minutes": PAYMENT_TIMEOUT_MINUTES,
                },
                "instructions": inst["instructions"],
            },
        }, status=status.HTTP_201_CREATED)


class FinalPaymentView(APIView):
    """User - kulipa baada ya kazi (unified network detection)."""
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        from apps.payments.detection import get_instructions, detect_network
        from apps.payments.payment_config import PAYMENT_TIMEOUT_MINUTES

        try:
            booking = Booking.objects.get(pk=pk, customer=request.user)
        except Booking.DoesNotExist:
            return Response(
                {"success": False, "message": "Booking haipo"},
                status=status.HTTP_404_NOT_FOUND,
            )
        if booking.final_paid:
            return Response({"success": True, "message": "Final imelipwa tayari"})
        phone = request.data.get("phone_number", "")
        if not phone:
            return Response(
                {"success": False, "message": "phone_number ni lazima"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        detected_network = detect_network(phone)
        reference = f"FIN-{booking.booking_number}"
        inst = get_instructions("MOBILE_MONEY", phone, booking.final_amount, reference)

        try:
            provider_value = detected_network if detected_network in [p.value for p in PaymentProvider] else PaymentProvider.SANDBOX.value
        except Exception:
            provider_value = PaymentProvider.SANDBOX.value

        payment = Payment.objects.create(
            user=request.user,
            amount=booking.final_amount,
            currency="TZS",
            method=PaymentMethodType.MOBILE_MONEY,
            provider=provider_value,
            purpose=PaymentPurpose.BOOKING,
            status=PaymentStatus.PENDING,
            reference=reference,
            phone_number=phone,
            description=f"Final 50% for {booking.booking_number}",
            metadata={"booking_id": booking.id, "kind": "final", "detected_network": detected_network},
            expires_at=timezone.now() + timezone.timedelta(minutes=PAYMENT_TIMEOUT_MINUTES),
        )

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
                        title=f"💰 Final — {booking.booking_number}",
                        message=(
                            f"User: {request.user.email}\n"
                            f"Kiasi: TSh {booking.final_amount:,.0f}\n"
                            f"Mtandao: {detected_network}\n"
                            f"Namba: {phone}\n"
                            f"Reference: {reference}"
                        ),
                        is_sent=True,
                        metadata={"payment_id": payment.id, "booking_id": booking.id, "kind": "final"},
                    )
                except Exception:
                    pass
        except Exception:
            pass

        return Response({
            "success": True,
            "message": f"Final TSh {booking.final_amount} imeanzishwa. Fuata maelekezo.",
            "data": {
                "payment_id": payment.id,
                "reference": payment.reference,
                "amount": str(payment.amount),
                "detected_network": detected_network,
                "is_detected": detected_network != "Unknown",
                "expires_at": payment.expires_at.isoformat() if payment.expires_at else None,
                "timeout_minutes": PAYMENT_TIMEOUT_MINUTES,
                "instructions": inst["instructions"],
            },
        }, status=status.HTTP_201_CREATED)


class CancelBookingView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            booking = Booking.objects.get(pk=pk, customer=request.user)
        except Booking.DoesNotExist:
            return Response(
                {"success": False, "message": "Booking haipo"},
                status=status.HTTP_404_NOT_FOUND,
            )
        if booking.status in [Booking.Status.COMPLETED, Booking.Status.CANCELLED]:
            return Response(
                {"success": False, "message": "Booking haiwezi kufutwa"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        old = booking.status
        booking.status = Booking.Status.CANCELLED
        booking.cancellation_reason = request.data.get("reason", "")
        booking.cancelled_at = timezone.now()
        booking.save()
        _log_status(booking, old, booking.status, request.user, request.data.get("reason", ""))
        return Response({"success": True, "message": "Booking imefutwa"})


class AvailableJobsView(APIView):
    """Mechanic - kuona kazi zilizopo karibu."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        # Onyesha bookings PENDING ambazo HAZIJAPANGIWA mechanic
        qs = Booking.objects.filter(
            status=Booking.Status.PENDING,
            mechanic__isnull=True,
        ).order_by("-created_at")[:50]
        return Response({
            "success": True,
            "count": qs.count(),
            "data": BookingSerializer(qs, many=True).data,
        })


class RequestJobView(APIView):
    """Mechanic - kuomba kazi. Ina-assign mechanic + inatengeneza chat room."""
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        from apps.chat.models import ChatRoom
        from apps.notifications.models import Notification

        try:
            booking = Booking.objects.get(pk=pk)
        except Booking.DoesNotExist:
            return Response(
                {"success": False, "message": "Booking haipo"},
                status=status.HTTP_404_NOT_FOUND,
            )

        try:
            mech = MechanicProfile.objects.get(user=request.user)
        except MechanicProfile.DoesNotExist:
            return Response(
                {"success": False, "message": "Wewe si mechanic"},
                status=status.HTTP_403_FORBIDDEN,
            )

        # Hakikisha booking haijapangiwa mechanic mwingine
        if booking.mechanic and booking.mechanic.id != mech.id:
            return Response(
                {"success": False, "message": "Booking imechukuliwa na mechanic mwingine"},
                status=status.HTTP_409_CONFLICT,
            )

        # Hakikisha status ni PENDING
        if booking.status != Booking.Status.PENDING:
            return Response(
                {"success": False, "message": f"Booking ipo kwenye status {booking.status}"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        with transaction.atomic():
            # Assign mechanic
            old_status = booking.status
            booking.mechanic = mech
            booking.status = Booking.Status.ACCEPTED
            booking.mechanic_accepted_at = timezone.now()
            booking.save()

            _log_status(
                booking, old_status, booking.status, request.user,
                f"Mechanic {mech.user.get_full_name()} amechukua kazi"
            )

            # Tengeneza Chat Room
            chat_room, created = ChatRoom.objects.get_or_create(
                booking=booking,
                room_type="booking",
                defaults={
                    "name": f"Kazi ya {booking.booking_number}",
                },
            )
            chat_room.participants.add(booking.customer, mech.user)

        # Notify user (customer)
        try:
            Notification.objects.create(
                recipient=booking.customer,
                notification_type="mechanic",
                title="Fundi amechukua kazi yako",
                message=(
                    f"Fundi {mech.user.get_full_name()} "
                    f"({mech.experience or 'Mechanic'}) amechukua kazi yako. "
                    f"Unaweza kuanza kuchat naye sasa."
                ),
                action_data={"booking_id": booking.id, "chat_room_id": chat_room.id},
            )
        except Exception as e:
            print(f"Notification error: {e}")

        return Response({
            "success": True,
            "message": "Umefanikiwa kuchukua kazi. Unaweza kuanza kuchat na mteja.",
            "data": {
                "booking_id": booking.id,
                "chat_room_id": chat_room.id,
                "status": booking.status,
                "mechanic_name": mech.user.get_full_name(),
                "customer_name": booking.customer.get_full_name(),
            },
        })




# ==================== MECHANIC ACCEPT/REJECT ====================
class AdminBookingListView(APIView):
    permission_classes = [IsAdminUser]

    def get(self, request):
        qs = Booking.objects.all().order_by("-created_at")
        status_filter = request.query_params.get("status")
        if status_filter:
            qs = qs.filter(status=status_filter.upper())
        return Response({
            "success": True,
            "count": qs.count(),
            "data": BookingSerializer(qs[:200], many=True).data,
        })


class AdminBookingAssignMechanicView(APIView):
    permission_classes = [IsAdminUser]

    def post(self, request, pk):
        try:
            booking = Booking.objects.get(pk=pk)
            mech = MechanicProfile.objects.get(pk=request.data.get("mechanic_id"))
        except (Booking.DoesNotExist, MechanicProfile.DoesNotExist):
            return Response(
                {"success": False, "message": "Booking au mechanic haipo"},
                status=status.HTTP_404_NOT_FOUND,
            )
        old = booking.status
        booking.mechanic = mech
        booking.status = Booking.Status.ACCEPTED
        booking.mechanic_accepted_at = timezone.now()
        booking.save()
        _log_status(booking, old, booking.status, request.user, f"Assigned to {mech.user.email}")
        return Response({
            "success": True,
            "message": "Mechanic amepangiwa",
            "data": BookingSerializer(booking).data,
        })


class AdminBookingStatusView(APIView):
    permission_classes = [IsAdminUser]

    def post(self, request, pk):
        try:
            booking = Booking.objects.get(pk=pk)
        except Booking.DoesNotExist:
            return Response(
                {"success": False, "message": "Booking haipo"},
                status=status.HTTP_404_NOT_FOUND,
            )
        new_status = request.data.get("status", "").upper()
        valid = [s[0] for s in Booking.Status.choices]
        if new_status not in valid:
            return Response(
                {"success": False, "message": f"Status si sahihi. Tumia: {valid}"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        old = booking.status
        booking.status = new_status
        if new_status == Booking.Status.IN_PROGRESS:
            booking.started_at = timezone.now()
        elif new_status == Booking.Status.COMPLETED:
            booking.completed_at = timezone.now()
        booking.save()
        _log_status(booking, old, new_status, request.user)
        return Response({
            "success": True,
            "message": f"Status imebadilishwa kuwa {new_status}",
            "data": BookingSerializer(booking).data,
        })


# ==================== MECHANIC ACTIONS ====================
class MechanicPendingBookingsView(APIView):
    """Mechanic — bookings zote zilizo PENDING (kwa requests)."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        # Tafuta MechanicProfile ya user
        try:
            profile = MechanicProfile.objects.get(user=request.user)
        except MechanicProfile.DoesNotExist:
            return Response(
                {"success": False, "message": "Wewe si mechanic"},
                status=status.HTTP_403_FORBIDDEN,
            )

        # Bookings zilizo PENDING au zilizoassign kwa mechanic huyu
        from django.db.models import Q
        qs = Booking.objects.filter(
            Q(status="PENDING") | Q(mechanic=profile, status__in=["ACCEPTED", "ARRIVING", "IN_PROGRESS"]),
        ).order_by("-created_at")

        return Response({
            "success": True,
            "count": qs.count(),
            "data": BookingSerializer(qs, many=True, context={"request": request}).data,
        })


class MechanicAcceptBookingView(APIView):
    """Mechanic — anakubali booking + ana-set ETA."""
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            profile = MechanicProfile.objects.get(user=request.user)
        except MechanicProfile.DoesNotExist:
            return Response(
                {"success": False, "message": "Wewe si mechanic"},
                status=status.HTTP_403_FORBIDDEN,
            )

        try:
            booking = Booking.objects.get(pk=pk)
        except Booking.DoesNotExist:
            return Response(
                {"success": False, "message": "Booking haipo"},
                status=status.HTTP_404_NOT_FOUND,
            )

        if booking.status not in ["PENDING"]:
            return Response(
                {"success": False, "message": "Booking haiwezi kukubaliwa sasa"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # ETA input
        travel_hours = int(request.data.get("travel_hours", 1))
        travel_minutes = int(request.data.get("travel_minutes", 0))

        if travel_hours < 1 or travel_hours > 24:
            return Response(
                {"success": False, "message": "Masaa yanapaswa kuwa 1-24"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        now = timezone.now()
        eta_delta = timezone.timedelta(hours=travel_hours, minutes=travel_minutes)
        countdown_ends = now + eta_delta

        old_status = booking.status
        booking.mechanic = profile
        booking.status = "ACCEPTED"
        booking.accepted_at = now
        booking.travel_hours = travel_hours
        booking.travel_minutes = travel_minutes
        booking.countdown_started_at = now
        booking.countdown_ends_at = countdown_ends
        booking.save()

        # Log
        _log_status(booking, old_status, "ACCEPTED", request.user,
                    f"ETA: {travel_hours}h {travel_minutes}m")

        # Notify user
        try:
            from apps.notifications.models import Notification
            Notification.objects.create(
                recipient=booking.customer,
                notification_type="BOOKING",
                title=f"🔧 Mechanic Amekubali — {booking.booking_number}",
                message=(
                    f"{request.user.get_full_name() or 'Mechanic'} amekubali booking yako.\n"
                    f"Atakufikia baada ya masaa {travel_hours}"
                    + (f" na dakika {travel_minutes}." if travel_minutes else ".")
                ),
                is_sent=True,
                metadata={"booking_id": booking.id},
            )
        except Exception:
            pass

        return Response({
            "success": True,
            "message": f"Booking imekubaliwa. ETA: {travel_hours}h {travel_minutes}m",
            "data": {
                "booking_id": booking.id,
                "countdown_ends_at": booking.countdown_ends_at.isoformat(),
                "travel_hours": travel_hours,
                "travel_minutes": travel_minutes,
            },
        })


class MechanicRejectBookingView(APIView):
    """Mechanic — anakataa booking."""
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            profile = MechanicProfile.objects.get(user=request.user)
        except MechanicProfile.DoesNotExist:
            return Response(
                {"success": False, "message": "Wewe si mechanic"},
                status=status.HTTP_403_FORBIDDEN,
            )

        try:
            booking = Booking.objects.get(pk=pk)
        except Booking.DoesNotExist:
            return Response(
                {"success": False, "message": "Booking haipo"},
                status=status.HTTP_404_NOT_FOUND,
            )

        reason = request.data.get("reason", "")
        old_status = booking.status
        booking.status = "REJECTED"
        booking.save()

        _log_status(booking, old_status, "REJECTED", request.user, reason)

        return Response({
            "success": True,
            "message": "Booking imekataliwa",
        })


class BookingCountdownView(APIView):
    """User — kuangalia countdown ya booking."""
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        try:
            booking = Booking.objects.get(pk=pk)
        except Booking.DoesNotExist:
            return Response(
                {"success": False, "message": "Booking haipo"},
                status=status.HTTP_404_NOT_FOUND,
            )

        # User pekee au mechanic au admin
        is_customer = booking.customer_id == request.user.id
        is_mechanic = booking.mechanic and booking.mechanic.user_id == request.user.id
        is_admin = request.user.is_staff or request.user.role in ["ADMIN", "SUPER_ADMIN"]

        if not (is_customer or is_mechanic or is_admin):
            return Response(
                {"success": False, "message": "Huna ruhusa"},
                status=status.HTTP_403_FORBIDDEN,
            )

        now = timezone.now()
        remaining_seconds = 0
        is_expired = False

        if booking.countdown_ends_at:
            diff = booking.countdown_ends_at - now
            remaining_seconds = max(0, int(diff.total_seconds()))
            is_expired = remaining_seconds == 0

        return Response({
            "success": True,
            "data": {
                "booking_id": booking.id,
                "booking_number": booking.booking_number,
                "status": booking.status,
                "travel_hours": booking.travel_hours,
                "travel_minutes": booking.travel_minutes,
                "countdown_started_at": booking.countdown_started_at.isoformat() if booking.countdown_started_at else None,
                "countdown_ends_at": booking.countdown_ends_at.isoformat() if booking.countdown_ends_at else None,
                "remaining_seconds": remaining_seconds,
                "remaining_hours": remaining_seconds // 3600,
                "remaining_minutes": (remaining_seconds % 3600) // 60,
                "is_expired": is_expired,
            },
        })
