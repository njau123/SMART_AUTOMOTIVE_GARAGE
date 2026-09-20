from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from django.db import transaction
from rest_framework import generics, viewsets, status
from rest_framework.exceptions import APIException
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.decorators import action
from django.contrib.auth import get_user_model
from django.shortcuts import get_object_or_404
from django.utils.timezone import now
import uuid
import random

from apps.vehicles.models import Vehicle
from apps.mechanics.models import MechanicProfile
from apps.services.models import Service, ServiceCategory
from apps.spare_parts.models import SparePart, Category, Brand
from apps.bookings.models import Booking, BookingStatusHistory
from apps.bookings.serializers import BookingSerializer as BookingSerializerFull
from apps.diagnosis.models import DiagnosisSession, DiagnosisDTC, OBDReading, OBDScanEvent, DTCCode, OBDPID, DiagnosisEntitlement
from apps.wallet.models import Wallet, Transaction
from apps.payments.models import Payment
from apps.news.models import News
from apps.advertisements.models import Advertisement
from apps.reviews.models import Review
from apps.tracking.models import TrackingSession, VehicleLocation, MechanicLocation, Geofence
from apps.chat.models import ChatRoom, Message, MessageAttachment, UserChatStatus
from apps.notifications.models import Notification, NotificationDevice, NotificationLog
from apps.accounts.models import PasswordResetCode


User = get_user_model()

# ============ AUTH ============
from .serializers import (
    UserSerializer, UserProfileSerializer, MechanicProfileSerializer,
    VehicleSerializer, ServiceSerializer, SparePartSerializer,
    DiagnosisSessionSerializer, DiagnosisDTCSerializer,
    OBDReadingSerializer, OBDScanEventSerializer, DTCCodeSerializer,
    ReviewSerializer,
    WalletSerializer, TransactionSerializer, PaymentSerializer,
    NewsSerializer, AdvertisementSerializer,
    NotificationSerializer, NotificationDeviceSerializer,
    ChatRoomSerializer, MessageSerializer,
    TrackingSessionSerializer, VehicleLocationSerializer,
    MechanicLocationSerializer, GeofenceSerializer,
)
from apps.bookings.serializers import BookingSerializer as BookingSerializerFull


class RegisterView(APIView):
    permission_classes = [AllowAny]

    @transaction.atomic
    def post(self, request):
        from django.contrib.auth import get_user_model
        User = get_user_model()

        data = request.data
        email = (data.get('email') or '').strip().lower()
        password = data.get('password') or ''
        first_name = (data.get('first_name') or '').strip()
        middle_name = (data.get('middle_name') or '').strip()
        last_name = (data.get('last_name') or '').strip()
        phone_number = (data.get('phone_number') or '').strip()

        errors = {}
        if not email:
            errors['email'] = 'Email is required'
        if not password or len(password) < 6:
            errors['password'] = 'Password must be at least 6 characters'
        if not first_name:
            errors['first_name'] = 'First name is required'
        if not last_name:
            errors['last_name'] = 'Last name is required'

        # Phone validation: +255XXXXXXXXX au 0XXXXXXXXX
        if not phone_number:
            errors['phone_number'] = 'Phone number is required'
        else:
            import re as _re
            digits = _re.sub(r'[^0-9]', '', phone_number)
            # Aruhusu: +255XXXXXXXXX (12), 255XXXXXXXXX (12), 0XXXXXXXXX (10)
            if digits.startswith('255') and len(digits) == 12:
                phone_number = '+' + digits
            elif digits.startswith('0') and len(digits) == 10:
                phone_number = '+255' + digits[1:]
            elif digits.startswith('255') and len(digits) == 11:
                phone_number = '+' + digits
            else:
                errors['phone_number'] = 'Invalid phone. Use +255XXXXXXXXX or 0XXXXXXXXX'

        if errors:
            return Response(errors, status=400)

        if User.objects.filter(email=email).exists():
            return Response({'email': 'This email is already registered'}, status=400)
        if User.objects.filter(phone_number=phone_number).exists():
            return Response({'phone_number': 'This phone number is already registered'}, status=400)

        user = User.objects.create_user(
            email=email,
            password=password,
            first_name=first_name,
            middle_name=middle_name,
            last_name=last_name,
            phone_number=phone_number,
            is_active=True,
        )

        # Vehicle
        vehicle_data = None
        v_make = (data.get('vehicle_make') or '').strip()
        v_model = (data.get('vehicle_model') or '').strip()
        v_registration = (data.get('vehicle_registration') or '').strip().upper()
        v_year = data.get('vehicle_year')

        if v_make and v_model and v_registration:
            try:
                vehicle = Vehicle.objects.create(
                    user=user,
                    make=v_make,
                    model=v_model,
                    year=int(v_year) if v_year else 2020,
                    registration_number=v_registration,
                    is_primary=True,
                    is_active=True,
                )
                vehicle_data = {
                    'id': vehicle.id,
                    'make': vehicle.make,
                    'model': vehicle.model,
                    'year': vehicle.year,
                    'registration_number': vehicle.registration_number,
                }
            except Exception as e:
                vehicle_data = {'error': str(e)}

        # Wallet
        try:
            Wallet.objects.get_or_create(user=user)
        except Exception:
            pass

        return Response({
            'success': True,
            'message': 'Registration successful! You may continue to login.',
            'user_id': user.id,
            'user': {
                'id': user.id,
                'email': user.email,
                'first_name': user.first_name,
                'middle_name': user.middle_name,
                'last_name': user.last_name,
                'phone_number': user.phone_number,
                'role': getattr(user, 'role', 'USER'),
            },
            'vehicle': vehicle_data,
        }, status=201)

class UserProfileView(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = [
        MultiPartParser,
        FormParser,
        JSONParser,
    ]

    def get(self, request):
        from .serializers import UserProfileSerializer
        serializer = UserProfileSerializer(
            request.user,
            context={'request': request},
        )
        data = dict(serializer.data)

        try:
            v = Vehicle.objects.filter(
                user=request.user, is_primary=True
            ).first() or Vehicle.objects.filter(user=request.user).first()
            if v:
                data['vehicle'] = {
                    'id': v.id,
                    'make': v.make,
                    'model': v.model,
                    'year': v.year,
                    'registration_number': v.registration_number,
                    'color': v.color,
                    'fuel_type': v.fuel_type,
                    'transmission': v.transmission,
                    'mileage_km': v.mileage_km,
                    'vehicle_image': (
                        request.build_absolute_uri(v.vehicle_image.url)
                        if v.vehicle_image else None
                    ),
                }
            data['vehicles'] = [
                {
                    'id': vv.id,
                    'make': vv.make,
                    'model': vv.model,
                    'year': vv.year,
                    'registration_number': vv.registration_number,
                    'vehicle_image': (
                        request.build_absolute_uri(vv.vehicle_image.url)
                        if vv.vehicle_image else None
                    ),
                }
                for vv in Vehicle.objects.filter(user=request.user)
            ]
        except Exception:
            data['vehicle'] = None
            data['vehicles'] = []

        return Response({
            "success": True,
            "message": "Profile retrieved",
            "data": data,
        })

    def patch(self, request):
        user = request.user
        data = request.data

        for field in ['first_name', 'middle_name', 'last_name', 'phone_number']:
            if field in data and data[field] is not None:
                setattr(user, field, str(data[field]).strip())

        if 'profile_image' in request.FILES:
            user.profile_image = request.FILES['profile_image']

        user.save()

        try:
            v = Vehicle.objects.filter(
                user=user, is_primary=True
            ).first() or Vehicle.objects.filter(user=user).first()

            if v:
                for field in ['make', 'model', 'year', 'registration_number',
                              'color', 'fuel_type', 'transmission', 'mileage_km']:
                    if field in data and data[field]:
                        try:
                            if field in ['year', 'mileage_km']:
                                setattr(v, field, int(data[field]))
                            else:
                                setattr(v, field, str(data[field]).strip())
                        except (ValueError, TypeError):
                            pass
                if 'vehicle_image' in request.FILES:
                    v.vehicle_image = request.FILES['vehicle_image']
                v.save()
        except Exception:
            pass

        from .serializers import UserProfileSerializer
        serializer = UserProfileSerializer(user, context={'request': request})
        return Response({
            "success": True,
            "message": "Profile updated successfully",
            "data": serializer.data,
        })


# ============ MECHANIC ============
class MechanicProfileView(APIView):
    permission_classes = [IsAuthenticated]
    def get(self, request):
        try:
            mechanic = MechanicProfile.objects.get(user=request.user)
            serializer = MechanicProfileSerializer(mechanic)
            return Response({
                "success": True,
                "message": "Mechanic profile retrieved",
                "data": serializer.data
            })
        except MechanicProfile.DoesNotExist:
            return Response({
                "success": False,
                "message": "You are not registered as a mechanic."
            }, status=404)

class MechanicListView(generics.ListAPIView):
    serializer_class = MechanicProfileSerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        qs = MechanicProfile.objects.all().order_by('id')
        # Filter by region/location if requested
        region = self.request.query_params.get('region')
        available = self.request.query_params.get('available')
        if available == 'true':
            qs = qs.filter(is_available=True)
        return qs

    def get_serializer_context(self):
        return {'request': self.request}


# ============ VEHICLES ============
class VehicleViewSet(viewsets.ModelViewSet):
    serializer_class = VehicleSerializer
    permission_classes = [IsAuthenticated]
    def get_queryset(self):
        return Vehicle.objects.filter(user=self.request.user)
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

# ============ SERVICES ============
class ServiceViewSet(viewsets.ModelViewSet):
    queryset = Service.objects.all()
    serializer_class = ServiceSerializer

    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            return [AllowAny()]
        return [IsAuthenticated()]
    permission_classes = [IsAuthenticated]

# ============ SPARE PARTS ============
class SparePartViewSet(viewsets.ModelViewSet):
    queryset = SparePart.objects.filter(stock_quantity__gt=0)
    serializer_class = SparePartSerializer

    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            return [AllowAny()]
        return [IsAuthenticated()]
    permission_classes = [IsAuthenticated]

# ============ BOOKINGS ============
class BookingViewSet(viewsets.ModelViewSet):
    serializer_class = BookingSerializerFull
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'MECHANIC':
            return Booking.objects.filter(mechanic__user=user)
        return Booking.objects.filter(customer=user)

    def perform_create(self, serializer):
        serializer.save(customer=self.request.user)

    @action(detail=True, methods=['post'])
    def pay_deposit(self, request, pk=None):
        """User anaomba kulipa deposit 50%."""
        booking = self.get_object()
        if booking.customer != request.user:
            return Response({"success": False, "message": "Not your booking"}, status=403)
        if booking.deposit_paid:
            return Response({
                "success": True,
                "message": "Deposit already paid",
                "data": BookingSerializerFull(booking).data,
            })

        payment = Payment.objects.create(
            user=request.user,
            amount=booking.deposit_amount,
            currency="TZS",
            provider="SANDBOX",
            method="MOBILE_MONEY",
            purpose="BOOKING",
            status="PENDING",
            reference=f"BK-DEP-{booking.booking_number}",
            phone_number=getattr(request.user, 'phone_number', '') or "",
            description=f"Deposit for booking {booking.booking_number}",
        )

        return Response({
            "success": True,
            "message": f"Deposit TSh {booking.deposit_amount} initiated",
            "data": {
                "booking": BookingSerializer(booking).data,
                "payment": {
                    "id": payment.id,
                    "reference": payment.reference,
                    "amount": str(payment.amount),
                    "status": payment.status,
                },
                "instructions": "Lipa kwa M-Pesa/Tigo/Airtel, kisha admin atathibitisha.",
            },
        })

    @action(detail=True, methods=['post'])
    def confirm_deposit(self, request, pk=None):
        """Admin anathibitisha deposit imelipwa."""
        if not (request.user.is_staff or request.user.is_superuser):
            return Response({"success": False, "message": "Admin only"}, status=403)
        booking = self.get_object()
        booking.deposit_paid = True
        booking.payment_status = Booking.PaymentStatus.PAID
        booking.status = Booking.Status.CONFIRMED
        booking.save()

        BookingStatusHistory.objects.create(
            booking=booking,
            new_status=Booking.Status.CONFIRMED,
            changed_by=request.user,
            note="Deposit confirmed by admin",
        )

        return Response({
            "success": True,
            "message": "Deposit confirmed",
            "data": BookingSerializerFull(booking).data,
        })

    @action(detail=True, methods=['post'])
    def accept(self, request, pk=None):
        """Mechanic anakubali booking."""
        booking = self.get_object()
        if request.user.role != 'MECHANIC':
            return Response({"success": False, "message": "Mechanic only"}, status=403)
        try:
            mechanic = MechanicProfile.objects.get(user=request.user)
        except MechanicProfile.DoesNotExist:
            return Response({"success": False, "message": "Mechanic profile not found"}, status=404)
        booking.mechanic = mechanic
        booking.status = Booking.Status.ACCEPTED
        booking.mechanic_accepted_at = now()
        booking.save()

        BookingStatusHistory.objects.create(
            booking=booking,
            new_status=Booking.Status.ACCEPTED,
            changed_by=request.user,
            note="Accepted by mechanic",
        )

        return Response({
            "success": True,
            "message": "Booking accepted",
            "data": BookingSerializerFull(booking).data,
        })

    @action(detail=True, methods=['post'])
    def start(self, request, pk=None):
        """Mechanic anaanza kazi."""
        booking = self.get_object()
        booking.status = Booking.Status.IN_PROGRESS
        booking.started_at = now()
        booking.save()

        BookingStatusHistory.objects.create(
            booking=booking,
            new_status=Booking.Status.IN_PROGRESS,
            changed_by=request.user,
            note="Work started",
        )

        return Response({
            "success": True,
            "message": "Work started",
            "data": BookingSerializerFull(booking).data,
        })

    @action(detail=True, methods=['post'])
    def complete(self, request, pk=None):
        """Mechanic anamaliza kazi."""
        booking = self.get_object()
        booking.status = Booking.Status.COMPLETED
        booking.completed_at = now()
        booking.save()

        BookingStatusHistory.objects.create(
            booking=booking,
            new_status=Booking.Status.COMPLETED,
            changed_by=request.user,
            note="Work completed",
        )

        return Response({
            "success": True,
            "message": "Work completed. User should pay remaining 50%.",
            "data": BookingSerializerFull(booking).data,
        })

    @action(detail=True, methods=['post'])
    def pay_final(self, request, pk=None):
        """User analipa 50% iliyobaki."""
        booking = self.get_object()
        if booking.customer != request.user:
            return Response({"success": False, "message": "Not your booking"}, status=403)
        if booking.final_paid:
            return Response({"success": True, "message": "Already paid"})

        payment = Payment.objects.create(
            user=request.user,
            amount=booking.final_amount,
            currency="TZS",
            provider="SANDBOX",
            method="MOBILE_MONEY",
            purpose="BOOKING",
            status="PENDING",
            reference=f"BK-FIN-{booking.booking_number}",
            phone_number=getattr(request.user, 'phone_number', '') or "",
            description=f"Final payment for booking {booking.booking_number}",
        )

        return Response({
            "success": True,
            "message": f"Final payment TSh {booking.final_amount} initiated",
            "data": {
                "booking": BookingSerializer(booking).data,
                "payment": {
                    "id": payment.id,
                    "reference": payment.reference,
                    "amount": str(payment.amount),
                },
            },
        })

    @action(detail=True, methods=['post'])
    def confirm_final(self, request, pk=None):
        """Admin anathibitisha final payment."""
        if not (request.user.is_staff or request.user.is_superuser):
            return Response({"success": False, "message": "Admin only"}, status=403)
        booking = self.get_object()
        booking.final_paid = True
        booking.payment_status = Booking.PaymentStatus.PAID
        booking.save()

        return Response({
            "success": True,
            "message": "Final payment confirmed",
            "data": BookingSerializerFull(booking).data,
        })

# ============ DIAGNOSIS ============
class DiagnosisSessionViewSet(viewsets.ModelViewSet):
    queryset = DiagnosisSession.objects.all()
    serializer_class = DiagnosisSessionSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return DiagnosisSession.objects.filter(user=self.request.user)

    
    def perform_create(self, serializer):
        from decimal import Decimal

        payment_exists = Payment.objects.filter(
            user=self.request.user,
            purpose="OBD_DIAGNOSIS",
            status="COMPLETED",
            amount=Decimal("30000.00"),
        ).exists()

        if not payment_exists:
            error = APIException("Please pay TSh 30,000 for OBD diagnosis first.")
            error.status_code = 402
            error.default_detail = "Please pay TSh 30,000 for OBD diagnosis first."
            raise error

        serializer.save(
            user=self.request.user,
            source=self.request.data.get("source", "OBD"),
            status="PENDING",
        )

    def connect(self, request, pk=None):
        session = self.get_object()
        vin = request.data.get('vin')
        protocol = request.data.get('protocol')
        adapter_name = request.data.get('adapter_name')
        battery_voltage = request.data.get('battery_voltage')
        connected = request.data.get('connected', False)
        if vin: session.vin = vin
        if protocol: session.protocol = protocol
        if adapter_name: session.adapter_name = adapter_name
        if battery_voltage is not None: session.battery_voltage = battery_voltage
        session.ecu_connected = connected
        session.status = 'CONNECTED' if connected else 'PENDING'
        session.save()
        return Response(DiagnosisSessionSerializer(session).data)

    @action(detail=True, methods=['post'])
    def start(self, request, pk=None):
        session = self.get_object()
        session.status = 'SCANNING'
        session.started_at = now()
        session.save()
        return Response(DiagnosisSessionSerializer(session).data)

    @action(detail=True, methods=['post'])
    def process(self, request, pk=None):
        session = self.get_object()

        responses = request.data.get("responses", {})
        live_data = request.data.get("live_data", {})
        raw_dtc = str(responses.get("raw_dtc_response", "")).strip()

        # ---------------------------------------------------------
        # 1. PROCESSING STARTED EVENT
        # ---------------------------------------------------------
        OBDScanEvent.objects.create(
            session=session,
            event_type="PROCESSING_STARTED",
            description="OBD scan processing started.",
            data={
                "received_dtc_response": bool(raw_dtc),
                "live_data_count": len(live_data),
            },
        )

        dtc_created = False
        detected_dtcs = []

        # ---------------------------------------------------------
        # 2. RAW DATA PRESERVATION
        # ---------------------------------------------------------
        session.raw_data = {
            "responses": responses,
            "live_data": live_data,
        }

        # ---------------------------------------------------------
        # 3. PROCESS DTC
        # ---------------------------------------------------------
        if raw_dtc:
            try:
                # Current test decoder maps this raw response to P0300.
                # Real ELM327/CAN decoding will replace this mapping later.
                dtc, _ = DTCCode.objects.get_or_create(
                    code="P0300",
                    defaults={
                        "title": "Random/Multiple Cylinder Misfire Detected",
                        "description": (
                            "The engine control module has detected "
                            "random or multiple cylinder misfires."
                        ),
                        "possible_causes": [
                            "Worn spark plugs",
                            "Faulty ignition coils",
                            "Fuel injector problem",
                            "Low fuel pressure",
                            "Vacuum leak",
                        ],
                        "symptoms": [
                            "Check engine light",
                            "Rough idle",
                            "Engine misfire",
                        ],
                        "severity": "HIGH",
                        "system": "POWERTRAIN",
                        "category": "ENGINE",
                        "is_common": True,
                        "is_active": True,
                        "is_emission_related": False,
                    },
                )

                diagnosis_dtc, created = DiagnosisDTC.objects.get_or_create(
                    session=session,
                    raw_code=raw_dtc,
                    defaults={
                        "dtc_code": dtc,
                        "status": "ACTIVE",
                    },
                )

                # In case the raw code existed already but points to another
                # DTC, keep it synchronized.
                if diagnosis_dtc.dtc_code_id != dtc.id:
                    diagnosis_dtc.dtc_code = dtc
                    diagnosis_dtc.status = "ACTIVE"
                    diagnosis_dtc.save(update_fields=["dtc_code", "status"])

                dtc_created = True

                detected_dtcs.append({
                    "code": dtc.code,
                    "title": dtc.title,
                    "severity": dtc.severity,
                    "system": dtc.system,
                    "category": dtc.category,
                    "status": diagnosis_dtc.status,
                    "raw_code": raw_dtc,
                })

                # -----------------------------------------------------
                # DTC DETECTED EVENT
                # -----------------------------------------------------
                OBDScanEvent.objects.create(
                    session=session,
                    event_type="DTC_DETECTED",
                    description=f"DTC {dtc.code} detected.",
                    data={
                        "code": dtc.code,
                        "title": dtc.title,
                        "severity": dtc.severity,
                        "system": dtc.system,
                        "category": dtc.category,
                        "raw_code": raw_dtc,
                    },
                )

            except Exception as e:
                session.status = "FAILED"
                session.error_message = str(e)
                session.completed_at = now()
                session.save(
                    update_fields=[
                        "status",
                        "error_message",
                        "completed_at",
                        "raw_data",
                        "updated_at",
                    ]
                )

                OBDScanEvent.objects.create(
                    session=session,
                    event_type="SCAN_FAILED",
                    description="OBD DTC processing failed.",
                    data={"error": str(e)},
                )

                return Response(
                    {
                        "success": False,
                        "message": f"DTC processing error: {str(e)}",
                    },
                    status=500,
                )

        # ---------------------------------------------------------
        # 4. PROCESS LIVE DATA
        # ---------------------------------------------------------
        readings_created = 0

        for pid, value in live_data.items():
            if value is None:
                continue

            try:
                obd_pid, _ = OBDPID.objects.get_or_create(
                    pid=str(pid),
                    defaults={
                        "name": str(pid),
                        "description": f"OBD-II PID {pid}",
                        "unit": "",
                    },
                )

                OBDReading.objects.create(
                    session=session,
                    pid=obd_pid,
                    value=float(value),
                    unit="",
                )

                readings_created += 1

            except Exception as e:
                session.status = "FAILED"
                session.error_message = str(e)
                session.completed_at = now()
                session.save(
                    update_fields=[
                        "status",
                        "error_message",
                        "completed_at",
                        "raw_data",
                        "updated_at",
                    ]
                )

                OBDScanEvent.objects.create(
                    session=session,
                    event_type="SCAN_FAILED",
                    description="OBD live-data processing failed.",
                    data={
                        "pid": pid,
                        "value": value,
                        "error": str(e),
                    },
                )

                return Response(
                    {
                        "success": False,
                        "message": f"OBDReading error: {str(e)}",
                    },
                    status=500,
                )

        # ---------------------------------------------------------
        # 5. LIVE DATA EVENT
        # ---------------------------------------------------------
        if readings_created > 0:
            OBDScanEvent.objects.create(
                session=session,
                event_type="LIVE_DATA_RECEIVED",
                description=f"{readings_created} live OBD parameters received.",
                data={
                    "count": readings_created,
                    "parameters": list(live_data.keys()),
                },
            )

        # ---------------------------------------------------------
        # 6. BUILD DIAGNOSIS RESULT
        # ---------------------------------------------------------
        all_dtcs = list(
            DiagnosisDTC.objects
            .filter(session=session)
            .select_related("dtc_code")
        )

        severity_rank = {
            "LOW": 1,
            "MEDIUM": 2,
            "HIGH": 3,
            "CRITICAL": 4,
        }

        highest_severity = "LOW"

        for item in all_dtcs:
            severity = str(item.dtc_code.severity or "LOW").upper()
            if severity_rank.get(severity, 1) > severity_rank.get(highest_severity, 1):
                highest_severity = severity

        if all_dtcs:
            health_status = "ATTENTION_REQUIRED"
        else:
            health_status = "NO_DTC_DETECTED"

        primary_fault = None
        possible_causes = []
        recommended_actions = []
        mechanic_specialty = "General Mechanic"
        should_call_mechanic = False

        if all_dtcs:
            primary = all_dtcs[0].dtc_code
            primary_fault = primary.title or primary.description

            for item in all_dtcs:
                dtc = item.dtc_code

                if isinstance(dtc.possible_causes, list):
                    possible_causes.extend(dtc.possible_causes)

                if isinstance(dtc.recommended_actions, list):
                    recommended_actions.extend(dtc.recommended_actions)

                if isinstance(dtc.recommended_repairs, list):
                    recommended_actions.extend(dtc.recommended_repairs)

            # Remove duplicates while preserving order
            possible_causes = list(dict.fromkeys(possible_causes))
            recommended_actions = list(dict.fromkeys(recommended_actions))

            if highest_severity in ["HIGH", "CRITICAL"]:
                mechanic_specialty = "Engine Specialist"
                should_call_mechanic = True
            elif highest_severity == "MEDIUM":
                mechanic_specialty = "Engine Specialist"
                should_call_mechanic = True

        # ---------------------------------------------------------
        # 7. SCAN SUMMARY
        # ---------------------------------------------------------
        summary_parts = []

        if all_dtcs:
            summary_parts.append(
                f"{len(all_dtcs)} active DTC detected."
            )
            summary_parts.append(
                f"Primary fault: {primary_fault}."
            )
            summary_parts.append(
                f"Severity: {highest_severity}."
            )
            summary_parts.append(
                f"{readings_created} live data parameters collected."
            )
            summary_parts.append(
                "Vehicle requires further diagnostic inspection."
            )
        else:
            summary_parts.append("No diagnostic trouble codes detected.")
            summary_parts.append(
                f"{readings_created} live data parameters collected."
            )
            summary_parts.append(
                "No active DTC was found during this scan."
            )

        session.summary = " ".join(summary_parts)

        diagnosis_result = {
            "primary_fault": primary_fault,
            "dtc_codes": [
                item.dtc_code.code
                for item in all_dtcs
            ],
            "severity": highest_severity,
            "health_status": health_status,
            "possible_causes": possible_causes[:10],
            "recommended_actions": recommended_actions[:10],
            "mechanic_specialty": mechanic_specialty,
            "should_call_mechanic": should_call_mechanic,
        }

        # Store structured diagnosis result together with original raw input.
        session.raw_data = {
            "responses": responses,
            "live_data": live_data,
            "diagnosis_result": diagnosis_result,
            "scan_statistics": {
                "total_dtcs": len(all_dtcs),
                "active_dtcs": sum(
                    1 for item in all_dtcs
                    if item.status == "ACTIVE"
                ),
                "live_readings": readings_created,
            },
        }

        # ---------------------------------------------------------
        # 8. FINAL STATUS
        # ---------------------------------------------------------
        session.status = (
            "COMPLETED_WITH_DTC"
            if all_dtcs
            else "COMPLETED"
        )
        session.completed_at = now()

        session.save(
            update_fields=[
                "status",
                "completed_at",
                "summary",
                "raw_data",
                "error_message",
                "updated_at",
            ]
        )

        # ---------------------------------------------------------
        # 9. DIAGNOSIS COMPLETED EVENT
        # ---------------------------------------------------------
        OBDScanEvent.objects.create(
            session=session,
            event_type="DIAGNOSIS_COMPLETED",
            description="OBD diagnosis completed successfully.",
            data=diagnosis_result,
        )

        # ---------------------------------------------------------
        # 10. RETURN COMPLETE REPORT
        # ---------------------------------------------------------
        events = OBDScanEvent.objects.filter(
            session=session
        ).order_by("created_at")

        readings = OBDReading.objects.filter(
            session=session
        ).select_related("pid")

        dtcs = DiagnosisDTC.objects.filter(
            session=session
        ).select_related("dtc_code")

        return Response({
            "success": True,
            "message": "OBD diagnosis completed",
            "data": {
                "session": DiagnosisSessionSerializer(session).data,
                "scan_summary": {
                    "total_dtcs": len(all_dtcs),
                    "active_dtcs": sum(
                        1 for item in all_dtcs
                        if item.status == "ACTIVE"
                    ),
                    "total_live_readings": readings_created,
                    "severity": highest_severity,
                    "health_status": health_status,
                },
                "diagnosis_result": diagnosis_result,
                "raw_data": session.raw_data,
                "dtcs": DiagnosisDTCSerializer(
                    dtcs,
                    many=True
                ).data,
                "readings": OBDReadingSerializer(
                    readings,
                    many=True
                ).data,
                "events": OBDScanEventSerializer(
                    events,
                    many=True
                ).data,
            },
        })


    @action(detail=True, methods=['get'])
    def status(self, request, pk=None):
        session = self.get_object()
        return Response(DiagnosisSessionSerializer(session).data)

    @action(detail=True, methods=['get'])
    def report(self, request, pk=None):
        session = self.get_object()

        dtcs = (
            DiagnosisDTC.objects
            .filter(session=session)
            .select_related("dtc_code")
            .order_by("detected_at")
        )

        readings = (
            OBDReading.objects
            .filter(session=session)
            .select_related("pid")
            .order_by("timestamp")
        )

        events = (
            OBDScanEvent.objects
            .filter(session=session)
            .order_by("created_at")
        )

        dtc_list = list(dtcs)

        severity_rank = {
            "LOW": 1,
            "MEDIUM": 2,
            "HIGH": 3,
            "CRITICAL": 4,
        }

        highest_severity = "LOW"

        for item in dtc_list:
            severity = str(
                getattr(item.dtc_code, "severity", "LOW") or "LOW"
            ).upper()

            if severity_rank.get(severity, 1) > severity_rank.get(
                highest_severity, 1
            ):
                highest_severity = severity

        diagnosis_result = session.raw_data.get(
            "diagnosis_result",
            {}
        ) if isinstance(session.raw_data, dict) else {}

        scan_statistics = session.raw_data.get(
            "scan_statistics",
            {}
        ) if isinstance(session.raw_data, dict) else {}

        return Response({
            "success": True,
            "message": "OBD scan report retrieved successfully",
            "data": {
                "session": DiagnosisSessionSerializer(session).data,

                "scan_summary": {
                    "status": session.status,
                    "summary": session.summary,
                    "total_dtcs": len(dtc_list),
                    "active_dtcs": sum(
                        1 for item in dtc_list
                        if item.status == "ACTIVE"
                    ),
                    "total_live_readings": readings.count(),
                    "total_events": events.count(),
                    "severity": highest_severity,
                },

                "diagnosis_result": diagnosis_result,

                "raw_data": session.raw_data,

                "dtcs": DiagnosisDTCSerializer(
                    dtcs,
                    many=True
                ).data,

                "readings": OBDReadingSerializer(
                    readings,
                    many=True
                ).data,

                "events": OBDScanEventSerializer(
                    events,
                    many=True
                ).data,
            }
        })


    @action(detail=True, methods=['post'])
    def cancel(self, request, pk=None):
        session = self.get_object()
        session.status = 'CANCELLED'
        session.save()
        return Response(DiagnosisSessionSerializer(session).data)

    @action(detail=False, methods=['post'])
    def create_with_payment(self, request):
        vehicle_id = request.data.get('vehicle')
        session_id = request.data.get('session_id')
        source = request.data.get('source', 'OBD')
        if not vehicle_id:
            return Response({"success": False, "message": "Vehicle ID required"}, status=400)
        try:
            vehicle = Vehicle.objects.get(id=vehicle_id, user=request.user)
        except Vehicle.DoesNotExist:
            return Response({"success": False, "message": "Vehicle not found"}, status=404)
        session = DiagnosisSession.objects.create(
            user=request.user,
            vehicle=vehicle,
            session_id=session_id or f"OBD-{uuid.uuid4().hex[:8].upper()}",
            source=source,
            status='PENDING'
        )
        return Response({
            "success": True,
            "message": "OBD scan session created",
            "data": DiagnosisSessionSerializer(session).data
        })

class DiagnosisHistoryViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = DiagnosisSessionSerializer
    permission_classes = [IsAuthenticated]
    def get_queryset(self):
        return DiagnosisSession.objects.filter(user=self.request.user).order_by('-created_at')

# ============ REVIEWS ============
class ReviewListCreateView(generics.ListCreateAPIView):
    serializer_class = ReviewSerializer
    permission_classes = [IsAuthenticated]
    def get_queryset(self):
        return Review.objects.filter(customer=self.request.user)
    def perform_create(self, serializer):
        serializer.save(
            customer=self.request.user,
            reference=f"REV-{uuid.uuid4().hex[:8].upper()}",
            status='active',
            is_verified=True
        )

class ReviewDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = ReviewSerializer
    permission_classes = [IsAuthenticated]
    def get_queryset(self):
        return Review.objects.filter(customer=self.request.user)

# ============ WALLET ============
class WalletDetailView(generics.RetrieveAPIView):
    serializer_class = WalletSerializer
    permission_classes = [IsAuthenticated]
    def get_object(self):
        wallet, _ = Wallet.objects.get_or_create(user=self.request.user)
        return wallet

class TransactionListView(generics.ListAPIView):
    serializer_class = TransactionSerializer
    permission_classes = [IsAuthenticated]
    def get_queryset(self):
        return Transaction.objects.filter(wallet__user=self.request.user).order_by('-created_at')

# ============ PAYMENTS ============
class PaymentViewSet(viewsets.ModelViewSet):
    serializer_class = PaymentSerializer
    permission_classes = [IsAuthenticated]
    def get_queryset(self):
        return Payment.objects.filter(user=self.request.user)
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
    @action(detail=True, methods=['post'])
    def verify(self, request, pk=None):
        payment = self.get_object()
        if payment.status == 'PENDING':
            payment.status = 'COMPLETED'
            payment.completed_at = now()
            payment.save()
            return Response({"success": True, "message": "Payment verified", "data": PaymentSerializer(payment).data})
        return Response({"success": False, "message": "Payment already processed"}, status=400)

# ============ NEWS ============
class NewsViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = News.objects.filter(status='published')
    serializer_class = NewsSerializer
    permission_classes = [AllowAny]
    permission_classes = [AllowAny]

# ============ ADVERTISEMENTS ============
class AdvertisementViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Advertisement.objects.filter(status='active')
    serializer_class = AdvertisementSerializer
    permission_classes = [AllowAny]
    permission_classes = [AllowAny]

# ============ NOTIFICATIONS ============
class NotificationViewSet(viewsets.ModelViewSet):
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]
    def get_queryset(self):
        return Notification.objects.filter(recipient=self.request.user)

class NotificationDeviceViewSet(viewsets.ModelViewSet):
    serializer_class = NotificationDeviceSerializer
    permission_classes = [IsAuthenticated]
    def get_queryset(self):
        return NotificationDevice.objects.filter(user=self.request.user)
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
    @action(detail=False, methods=['post'])
    def register(self, request):
        token = request.data.get('device_token')
        device_type = request.data.get('device_type', 'mobile')
        if not token:
            return Response({"success": False, "message": "device_token required"}, status=400)
        device, created = NotificationDevice.objects.update_or_create(
            user=request.user,
            device_token=token,
            defaults={'device_type': device_type, 'is_active': True, 'last_used': now()}
        )
        return Response({"success": True, "message": "Device registered", "data": NotificationDeviceSerializer(device).data})

# ============ CHAT ============
class ChatRoomViewSet(viewsets.ModelViewSet):
    serializer_class = ChatRoomSerializer
    permission_classes = [IsAuthenticated]
    def get_queryset(self):
        return ChatRoom.objects.filter(participants=self.request.user)
    def perform_create(self, serializer):
        room = serializer.save()
        room.participants.add(self.request.user)

class MessageViewSet(viewsets.ModelViewSet):
    serializer_class = MessageSerializer
    permission_classes = [IsAuthenticated]
    def get_queryset(self):
        return Message.objects.filter(room__participants=self.request.user)
    def perform_create(self, serializer):
        serializer.save(sender=self.request.user)

# ============ TRACKING ============
class TrackingSessionViewSet(viewsets.ModelViewSet):
    serializer_class = TrackingSessionSerializer
    permission_classes = [IsAuthenticated]
    def get_queryset(self):
        return TrackingSession.objects.filter(user=self.request.user)
    def perform_create(self, serializer):
        serializer.save(user=self.request.user, status='ACTIVE', started_at=now())
    @action(detail=True, methods=['post'])
    def end(self, request, pk=None):
        session = self.get_object()
        session.status = 'ENDED'
        session.ended_at = now()
        session.save()
        return Response(TrackingSessionSerializer(session).data)

class VehicleLocationViewSet(viewsets.ModelViewSet):
    serializer_class = VehicleLocationSerializer
    permission_classes = [IsAuthenticated]
    def get_queryset(self):
        return VehicleLocation.objects.filter(vehicle__user=self.request.user)
    @action(detail=False, methods=['post'])
    def update_location(self, request):
        vehicle_id = request.data.get('vehicle_id')
        lat = request.data.get('latitude')
        lng = request.data.get('longitude')
        if not vehicle_id or lat is None or lng is None:
            return Response({"success": False, "message": "vehicle_id, latitude, longitude required"}, status=400)
        location = VehicleLocation.objects.create(
            vehicle_id=vehicle_id,
            latitude=lat,
            longitude=lng,
            recorded_at=now()
        )
        return Response(VehicleLocationSerializer(location).data)

class MechanicLocationViewSet(viewsets.ModelViewSet):
    serializer_class = MechanicLocationSerializer
    permission_classes = [IsAuthenticated]
    def get_queryset(self):
        return MechanicLocation.objects.filter(mechanic=self.request.user)
    @action(detail=False, methods=['post'])
    def update_location(self, request):
        lat = request.data.get('latitude')
        lng = request.data.get('longitude')
        is_online = request.data.get('is_online', True)
        if lat is None or lng is None:
            return Response({"success": False, "message": "latitude, longitude required"}, status=400)
        try:
            mechanic = MechanicProfile.objects.get(user=request.user)
        except MechanicProfile.DoesNotExist:
            return Response({"success": False, "message": "User is not a mechanic"}, status=400)
        location = MechanicLocation.objects.create(
            mechanic=mechanic,
            latitude=float(lat),
            longitude=float(lng),
            is_online=is_online,
            recorded_at=now()
        )
        return Response(MechanicLocationSerializer(location).data, status=201)

# ============ NEARBY MECHANICS ============
from math import radians, sin, cos, sqrt, atan2

def haversine(lat1, lon1, lat2, lon2):
    R = 6371
    dlat = radians(lat2 - lat1)
    dlon = radians(lon2 - lon1)
    a = sin(dlat/2)**2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlon/2)**2
    c = 2 * atan2(sqrt(a), sqrt(1-a))
    return R * c

class NearbyMechanicsView(generics.ListAPIView):
    serializer_class = MechanicProfileSerializer
    permission_classes = [IsAuthenticated]
    def get_queryset(self):
        lat = self.request.query_params.get('lat')
        lng = self.request.query_params.get('lng')
        radius = float(self.request.query_params.get('radius', 10))
        if lat is None or lng is None:
            return MechanicProfile.objects.none()
        lat = float(lat)
        lng = float(lng)
        mechanics = MechanicProfile.objects.filter(is_available=True)
        nearby = []
        for m in mechanics:
            if m.latitude and m.longitude:
                dist = haversine(lat, lng, float(m.latitude), float(m.longitude))
                if dist <= radius:
                    nearby.append(m.id)
        return MechanicProfile.objects.filter(id__in=nearby)

# ============ GEOFENCE ============
class GeofenceViewSet(viewsets.ModelViewSet):
    serializer_class = GeofenceSerializer
    permission_classes = [IsAuthenticated]
    def get_queryset(self):
        return Geofence.objects.filter(user=self.request.user)
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

# ============ PASSWORD RESET ============
class PasswordResetRequestView(APIView):
    permission_classes = [AllowAny]
    def post(self, request):
        email = request.data.get('email')
        if not email:
            return Response({"success": False, "message": "Email is required"}, status=400)
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return Response({"success": False, "message": "User with this email does not exist."}, status=404)
        code = ''.join(random.choices('0123456789', k=6))
        PasswordResetCode.objects.filter(user=user).delete()
        PasswordResetCode.objects.create(
            user=user,
            code=code,
            expires_at=now() + timedelta(minutes=10)
        )
        print(f"Password reset code for {email}: {code}")
        return Response({
            "success": True,
            "message": "Password reset code sent. Check terminal for the code.",
            "email": email
        })

class PasswordResetVerifyView(APIView):
    permission_classes = [AllowAny]
    def post(self, request):
        email = request.data.get('email')
        code = request.data.get('code')
        if not email or not code:
            return Response({"success": False, "message": "Email and code required"}, status=400)
        try:
            user = User.objects.get(email=email)
            reset_code = PasswordResetCode.objects.get(user=user, code=code, is_used=False)
            if reset_code.is_expired():
                return Response({"success": False, "message": "Code has expired"}, status=400)
            return Response({"success": True, "message": "Code verified successfully"})
        except (User.DoesNotExist, PasswordResetCode.DoesNotExist):
            return Response({"success": False, "message": "Invalid email or code"}, status=400)

class PasswordResetConfirmView(APIView):
    permission_classes = [AllowAny]
    def post(self, request):
        email = request.data.get('email')
        code = request.data.get('code')
        new_password = request.data.get('new_password')
        if not email or not code or not new_password:
            return Response({"success": False, "message": "Email, code, and new password required"}, status=400)
        if len(new_password) < 6:
            return Response({"success": False, "message": "Password must be at least 6 characters"}, status=400)
        try:
            user = User.objects.get(email=email)
            reset_code = PasswordResetCode.objects.get(user=user, code=code, is_used=False)
            if reset_code.is_expired():
                return Response({"success": False, "message": "Code has expired"}, status=400)
            user.set_password(new_password)
            user.save()
            reset_code.is_used = True
            reset_code.save()
            return Response({"success": True, "message": "Password reset successfully"})
        except (User.DoesNotExist, PasswordResetCode.DoesNotExist):
            return Response({"success": False, "message": "Invalid email or code"}, status=400)

# ============ SERVICE DIAGNOSIS (AI) ============
class ServiceDiagnosisView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        vehicle_make = request.data.get('vehicle_make', 'Unknown')
        vehicle_model = request.data.get('vehicle_model', 'Unknown')
        vehicle_year = request.data.get('vehicle_year', '')
        symptoms = request.data.get('symptoms', '').lower()
        additional_info = request.data.get('additional_info', '')
        diagnosis_id = f"DX-{uuid.uuid4().hex[:8].upper()}"
        possible_causes = []
        recommended_actions = []
        safety_warnings = []
        should_call_mechanic = True
        mechanic_specialty = "General Mechanic"
        if "zima" in symptoms or "start" in symptoms or "stall" in symptoms:
            possible_causes.append("Engine belt broken or loose")
            possible_causes.append("Fuel delivery problem (clogged filter or pump failure)")
            possible_causes.append("Battery or alternator failure")
            possible_causes.append("Ignition system fault (spark plugs or coils)")
            recommended_actions.append("Check engine belt tension and condition")
            recommended_actions.append("Check fuel pump and filter")
            recommended_actions.append("Test battery voltage and alternator output")
            recommended_actions.append("Inspect spark plugs and ignition coils")
            safety_warnings.append("Do not attempt to start the vehicle if you suspect fuel leak")
            safety_warnings.append("If you smell fuel, turn off the engine immediately")
            mechanic_specialty = "Engine Specialist"
        if "overheat" in symptoms or "joto" in symptoms:
            possible_causes.append("Coolant level low")
            possible_causes.append("Thermostat stuck closed")
            possible_causes.append("Radiator fan failure")
            recommended_actions.append("Check coolant level when engine is cold")
            recommended_actions.append("Inspect radiator fan operation")
            safety_warnings.append("Never open radiator cap while engine is hot")
            mechanic_specialty = "Cooling System Specialist"
        if "brake" in symptoms or "breki" in symptoms:
            possible_causes.append("Brake pads worn out")
            possible_causes.append("Brake fluid low")
            possible_causes.append("Brake rotor damage")
            recommended_actions.append("Check brake pad thickness")
            recommended_actions.append("Check brake fluid level")
            safety_warnings.append("Brake failure can cause serious accidents")
            mechanic_specialty = "Brake Specialist"
        if "engine light" in symptoms or "check engine" in symptoms:
            possible_causes.append("O2 sensor failure")
            possible_causes.append("Mass air flow sensor issue")
            possible_causes.append("Catalytic converter problem")
            recommended_actions.append("Read OBD-II codes using a scanner")
            recommended_actions.append("Check O2 sensor readings")
            mechanic_specialty = "Auto Electrician"
        if not possible_causes:
            possible_causes.append(f"Unknown issue with {vehicle_make} {vehicle_model}")
            recommended_actions.append("Visit a certified mechanic for physical inspection")
            safety_warnings.append("Do not drive if you feel unsafe")
            mechanic_specialty = "General Mechanic"
        if vehicle_make.lower() in ['toyota', 'land cruiser']:
            possible_causes.append("Common issue with toyota land cruiser models (check recalls)")
        response_data = {
            "diagnosis_id": diagnosis_id,
            "possible_causes": possible_causes[:5],
            "recommended_actions": recommended_actions[:4],
            "safety_warnings": safety_warnings[:2],
            "should_call_mechanic": should_call_mechanic,
            "mechanic_specialty": mechanic_specialty
        }
        return Response({
            "success": True,
            "message": "Diagnosis complete",
            "data": response_data
        })

# ============ PAYMENT GATEWAY (SELCOM) ============
class PaymentGatewayInitiateView(APIView):
    permission_classes = [IsAuthenticated]
    def post(self, request):
        amount = request.data.get('amount')
        phone_number = request.data.get('phone_number')
        purpose = request.data.get('purpose', 'BOOKING')
        description = request.data.get('description', '')
        if not amount or not phone_number:
            return Response({"success": False, "message": "Amount and phone number required"}, status=400)
        reference = f"PAY-{uuid.uuid4().hex[:8].upper()}"
        external_reference = f"EXT-{uuid.uuid4().hex[:12].upper()}"
        payment = Payment.objects.create(
            user=request.user,
            amount=amount,
            currency='TZS',
            provider='SELCOM',
            method='MOBILE_MONEY',
            purpose=purpose,
            description=description,
            reference=reference,
            external_reference=external_reference,
            phone_number=phone_number,
            status='PENDING'
        )
        return Response({
            "success": True,
            "message": "Payment initiated. Use code 123456 for testing.",
            "data": {
                "reference": reference,
                "amount": str(amount),
                "status": "PENDING",
                "instructions": "Dial *150*01# and enter code 123456",
                "code": "123456"
            }
        })

class PaymentGatewayVerifyView(APIView):
    permission_classes = [IsAuthenticated]
    def post(self, request):
        reference = request.data.get('reference')
        if not reference:
            return Response({"success": False, "message": "Reference required"}, status=400)
        try:
            payment = Payment.objects.get(reference=reference, user=request.user)
        except Payment.DoesNotExist:
            try:
                payment = Payment.objects.get(reference=reference)
            except Payment.DoesNotExist:
                return Response({"success": False, "message": "Payment not found"}, status=404)
        payment.status = 'COMPLETED'
        payment.completed_at = now()
        payment.save()
        return Response({
            "success": True,
            "message": "Payment verified",
            "data": {
                "reference": payment.reference,
                "status": payment.status,
                "amount": str(payment.amount),
                "phone_number": payment.phone_number,
                "purpose": payment.purpose,
                "completed_at": payment.completed_at
            }
        })

# ============ GOOGLE LOGIN ============
from rest_framework_simplejwt.tokens import RefreshToken
from datetime import timedelta

# ============ GOOGLE LOGIN (SECURE) ============
# GoogleLoginView moved to api/google_login_views.py for security.
# It now uses Firebase Admin SDK to verify tokens.
from .google_login_views import GoogleLoginView  # noqa: F401

# ============ ADMIN STATISTICS ============
class AdminStatsView(APIView):
    permission_classes = [IsAuthenticated]
    def get(self, request):
        if request.user.role != 'SUPER_ADMIN' and not request.user.is_superuser:
            return Response({"success": False, "message": "Admin access required"}, status=403)
        total_users = User.objects.count()
        total_mechanics = MechanicProfile.objects.count()
        total_bookings = Booking.objects.count()
        total_payments = Payment.objects.count()
        total_reviews = Review.objects.count()
        total_vehicles = Vehicle.objects.count()
        return Response({
            "success": True,
            "data": {
                "total_users": total_users,
                "total_mechanics": total_mechanics,
                "total_bookings": total_bookings,
                "total_payments": total_payments,
                "total_reviews": total_reviews,
                "total_vehicles": total_vehicles,
            }
        })

# ============ MECHANIC BOOKING ACTIONS ============
class MechanicBookingActionView(APIView):
    permission_classes = [IsAuthenticated]
    def post(self, request, booking_id):
        try:
            booking = Booking.objects.get(id=booking_id)
        except Booking.DoesNotExist:
            return Response({"success": False, "message": "Booking not found"}, status=404)
        if booking.mechanic.user != request.user:
            return Response({"success": False, "message": "Not authorized"}, status=403)
        action = request.data.get('action')
        if action not in ['ACCEPT', 'REJECT']:
            return Response({"success": False, "message": "Action must be ACCEPT or REJECT"}, status=400)
        if action == 'ACCEPT':
            booking.status = 'ACCEPTED'
            booking.notes = request.data.get('notes', '')
            eta_minutes = request.data.get('eta_minutes', 30)
            booking.metadata = {'eta_minutes': eta_minutes, 'eta_started_at': now().isoformat()}
            booking.save()
            Notification.objects.create(
                recipient=booking.customer,
                notification_type='BOOKING_ACCEPTED',
                title='Mechanic Accepted',
                message=f'Your booking #{booking.id} has been accepted. ETA: {eta_minutes} minutes.'
            )
            return Response({
                "success": True,
                "message": "Booking accepted",
                "data": {"status": booking.status, "eta_minutes": eta_minutes}
            })
        elif action == 'REJECT':
            booking.status = 'REJECTED'
            booking.notes = request.data.get('notes', '')
            booking.save()
            Notification.objects.create(
                recipient=booking.customer,
                notification_type='BOOKING_REJECTED',
                title='Booking Rejected',
                message=f'Your booking #{booking.id} has been rejected.'
            )
            return Response({
                "success": True,
                "message": "Booking rejected",
                "data": {"status": booking.status}
            })

# ============ OBD PAYMENT INITIATE ============
class OBDPaymentInitiateView(APIView):
    """
    OBD payment initiate — inatumia network detection (Vodacom, Tigo, Airtel, n.k.)
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        from decimal import Decimal
        from django.utils import timezone
        from apps.payments.detection import get_instructions, detect_network
        from apps.payments.payment_config import PAYMENT_TIMEOUT_MINUTES

        amount = Decimal("30000")
        phone_number = request.data.get("phone_number")

        if not phone_number:
            return Response(
                {
                    "success": False,
                    "message": "Phone number required",
                    "data": None,
                    "errors": {"phone_number": ["This field is required."]},
                },
                status=400,
            )

        # Detect network
        detected_network = detect_network(phone_number)

        # Unda reference
        reference = f"OBD-{uuid.uuid4().hex[:8].upper()}"

        # Pata maelekezo
        inst = get_instructions("MOBILE_MONEY", phone_number, amount, reference)

        # Provider
        try:
            from apps.payments.models import PaymentProvider
            if detected_network in [p.value for p in PaymentProvider]:
                provider_value = detected_network
            else:
                provider_value = "MOBILE_MONEY"
        except Exception:
            provider_value = "MOBILE_MONEY"

        # Unda payment
        payment = Payment.objects.create(
            user=request.user,
            amount=amount,
            currency="TZS",
            provider=provider_value,
            method="MOBILE_MONEY",
            purpose="OBD_DIAGNOSIS",
            reference=reference,
            phone_number=phone_number,
            status="PENDING",
            description="OBD-II vehicle diagnosis payment",
            expires_at=timezone.now() + timezone.timedelta(minutes=PAYMENT_TIMEOUT_MINUTES),
            metadata={
                "service": "OBD_DIAGNOSIS",
                "price_tzs": str(amount),
                "detected_network": detected_network,
                "instructions_text": inst["instructions"],
            },
        )

        # === Notify admin wote ===
        try:
            from apps.notifications.models import Notification
            from django.contrib.auth import get_user_model
            User = get_user_model()
            admins = User.objects.filter(is_staff=True, is_active=True)
            for admin in admins:
                try:
                    Notification.objects.create(
                        recipient=admin,
                        notification_type="payment",
                        title=f"💰 Malipo ya OBD — {payment.reference}",
                        message=(
                            f"User: {request.user.email}\n"
                            f"Kiasi: TSh {amount:,.0f}\n"
                            f"Mtandao: {detected_network}\n"
                            f"Namba: {phone_number}\n"
                            f"Reference: {reference}"
                        ),
                        is_sent=True,
                        metadata={"payment_id": payment.id, "type": "OBD_DIAGNOSIS"},
                    )
                except Exception:
                    pass
        except Exception:
            pass

        return Response(
            {
                "success": True,
                "message": "Malipo ya OBD yameanzishwa. Fuata maelekezo ya kulipia.",
                "data": {
                    "payment_id": payment.id,
                    "reference": payment.reference,
                    "amount": str(payment.amount),
                    "currency": payment.currency,
                    "status": payment.status,
                    "purpose": payment.purpose,
                    "detected_network": detected_network,
                    "is_detected": detected_network != "Unknown",
                    "expires_at": payment.expires_at.isoformat() if payment.expires_at else None,
                    "timeout_minutes": PAYMENT_TIMEOUT_MINUTES,
                },
                "instructions": inst["instructions"],
            },
            status=201,
        )


# ============ PAGINATION ============
from .pagination import SparePartPagination, VehiclePagination, BookingPagination, NotificationPagination

# Kwa spare parts viewset, ongeza:
# pagination_class = SparePartPagination

# Kwa vehicles viewset:
# pagination_class = VehiclePagination

# Kwa bookings viewset:
# pagination_class = BookingPagination

# Kwa notifications viewset:
# pagination_class = NotificationPagination
