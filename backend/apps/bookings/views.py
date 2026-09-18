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
    """User - kulipa deposit 50%."""
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
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
        payment = Payment.objects.create(
            user=request.user,
            amount=booking.deposit_amount,
            currency="TZS",
            method=PaymentMethodType.MOBILE_MONEY,
            provider=PaymentProvider.SANDBOX,
            purpose=PaymentPurpose.BOOKING,
            status=PaymentStatus.PENDING,
            reference=f"DEP-{booking.booking_number}",
            phone_number=phone,
            description=f"Deposit 50% for {booking.booking_number}",
            metadata={"booking_id": booking.id, "kind": "deposit"},
            expires_at=timezone.now() + timezone.timedelta(hours=24),
        )
        booking.payment_status = Booking.PaymentStatus.PENDING
        booking.save(update_fields=["payment_status"])
        return Response({
            "success": True,
            "message": f"Deposit TSh {booking.deposit_amount} imeanzishwa. Admin atathibitisha.",
            "data": {
                "booking": BookingSerializer(booking).data,
                "payment": {
                    "id": payment.id,
                    "reference": payment.reference,
                    "amount": str(payment.amount),
                    "status": payment.status,
                },
                "instructions": (
                    f"Tuma TSh {booking.deposit_amount} kwenda "
                    f"Automotive Smart Garage. Reference: {payment.reference}"
                ),
            },
        }, status=status.HTTP_201_CREATED)


class FinalPaymentView(APIView):
    """User - kulipa baada ya kazi."""
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
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
        payment = Payment.objects.create(
            user=request.user,
            amount=booking.final_amount,
            currency="TZS",
            method=PaymentMethodType.MOBILE_MONEY,
            provider=PaymentProvider.SANDBOX,
            purpose=PaymentPurpose.BOOKING,
            status=PaymentStatus.PENDING,
            reference=f"FIN-{booking.booking_number}",
            phone_number=phone,
            description=f"Final 50% for {booking.booking_number}",
            metadata={"booking_id": booking.id, "kind": "final"},
            expires_at=timezone.now() + timezone.timedelta(hours=24),
        )
        return Response({
            "success": True,
            "message": f"Final TSh {booking.final_amount} imeanzishwa",
            "data": {
                "payment_id": payment.id,
                "reference": payment.reference,
                "amount": str(payment.amount),
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
class MechanicAcceptBookingView(APIView):
    """Mechanic anakubali booking. Ina-assign yeye, inaunda chat, inatuma notification kwa user."""
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
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

        # Hakikisha booking ni ya mechanic huyu (kama ilipangwa)
        if booking.mechanic and booking.mechanic.id != mech.id:
            return Response(
                {"success": False, "message": "Booking hii si yako"},
                status=status.HTTP_403_FORBIDDEN,
            )

        if booking.status != Booking.Status.PENDING:
            return Response(
                {"success": False, "message": f"Booking ipo kwenye status {booking.status}"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        with transaction.atomic():
            old_status = booking.status
            booking.mechanic = mech
            booking.status = Booking.Status.ACCEPTED
            booking.mechanic_accepted_at = timezone.now()
            booking.save()

            _log_status(
                booking, old_status, booking.status, request.user,
                f"Mechanic {mech.user.get_full_name()} amekubali kazi"
            )

            # Tengeneza Chat Room
            chat_room, _ = ChatRoom.objects.get_or_create(
                booking=booking,
                room_type="booking",
                defaults={"name": f"Kazi ya {booking.booking_number}"},
            )
            chat_room.participants.add(booking.customer, mech.user)

        # Notify user
        try:
            send_notification_to_user(
                user=booking.customer,
                title="Fundi Amekubali Ombi Lako",
                message=f"{mech.user.get_full_name() or 'Fundi'} amekubali kazi yako. Unaweza kuanza kuchat naye.",
                notification_type="booking",
                data={
                    "type": "job_accepted",
                    "booking_id": str(booking.id),
                    "chat_room_id": str(chat_room.id),
                    "mechanic_name": mech.user.get_full_name() or "Fundi",
                },
            )
        except Exception as e:
            print(f"[NOTIFY ERROR] {e}")

        return Response({
            "success": True,
            "message": "Umekubali kazi. Unaweza kuanza kuchat na mteja.",
            "data": {
                "booking_id": booking.id,
                "chat_room_id": chat_room.id,
                "status": booking.status,
                "mechanic_name": mech.user.get_full_name(),
                "customer_name": booking.customer.get_full_name(),
            },
        })


class MechanicRejectBookingView(APIView):
    """
    Mechanic anakataa booking.
    Booking inarudi PENDING (mechanic haipangiwi).
    User anapata ujumbe wa 'network issue' (sio 'amekataa').
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
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

        if booking.status != Booking.Status.PENDING:
            return Response(
                {"success": False, "message": "Booking haiwezi kukataliwa"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        with transaction.atomic():
            # Ondoa mechanic assignment (kama alikuwa amepewa)
            old_status = booking.status
            booking.mechanic = None
            booking.status = Booking.Status.PENDING
            booking.save()

            _log_status(
                booking, old_status, booking.status, request.user,
                f"Mechanic {mech.user.get_full_name()} hakuweza kuchukua kazi"
            )

        # Notify user kwa ujumbe wa "network issue" (SI "amekataa")
        try:
            send_notification_to_user(
                user=booking.customer,
                title="Ombi Lako Linaendelea",
                message="Tunaendelea kutafuta fundi mwingine wa karibu. Tafadhali subiri.",
                notification_type="booking",
                data={
                    "type": "job_searching",
                    "booking_id": str(booking.id),
                },
            )
        except Exception as e:
            print(f"[NOTIFY ERROR] {e}")

        return Response({
            "success": True,
            "message": "Umepitisha kazi hii.",
            "data": {"booking_id": booking.id, "status": booking.status},
        })


# ==================== ADMIN ====================
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
