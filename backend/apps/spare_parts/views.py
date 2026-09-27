from rest_framework import viewsets, permissions, filters
from api.permissions import IsAdminOrReadOnly
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAdminUser
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend

from .models import Category, Brand, SparePart
from .serializers import (
    CategorySerializer,
    BrandSerializer,
    SparePartListSerializer,
    SparePartDetailSerializer,
)


# ==================== PUBLIC (VIEWSETS) ====================
class CategoryViewSet(viewsets.ModelViewSet):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer
    permission_classes = [IsAdminOrReadOnly]


class BrandViewSet(viewsets.ModelViewSet):
    queryset = Brand.objects.all()
    serializer_class = BrandSerializer
    permission_classes = [IsAdminOrReadOnly]


class SparePartViewSet(viewsets.ModelViewSet):
    queryset = SparePart.objects.all()
    permission_classes = [IsAdminOrReadOnly]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['category', 'brand', 'condition', 'status', 'is_featured', 'is_on_sale']
    search_fields = ['name', 'description', 'part_number']
    ordering_fields = ['price', 'created_at']

    def get_serializer_class(self):
        if self.action == 'list':
            return SparePartListSerializer
        return SparePartDetailSerializer


# ==================== ADMIN ====================
@api_view(['GET'])
@permission_classes([IsAdminUser])
def admin_spare_parts(request):
    """Admin - orodha ya spare parts."""
    parts = SparePart.objects.all().values(
        'id', 'name', 'price', 'stock', 'status', 'is_active'
    )
    return Response({'success': True, 'data': list(parts)})


@api_view(['POST'])
@permission_classes([IsAdminUser])
def admin_add_spare_part(request):
    """Admin - ongeza spare part."""
    SparePart.objects.create(
        name=request.data.get('name'),
        slug=request.data.get('slug') or request.data.get('name', '').lower().replace(' ', '-'),
        price=request.data.get('price'),
        stock=request.data.get('stock', 0),
        description=request.data.get('description', ''),
        short_description=request.data.get('short_description', ''),
        is_active=True,
    )
    return Response({'success': True, 'message': 'Spare part added'}, status=201)


# ==================== ORDER VIEWS ====================
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from .models import SparePartOrder
from .serializers import (
    SparePartOrderCreateSerializer,
    SparePartOrderDeliverySerializer,
    SparePartOrderSerializer,
)


class OrderCreateView(APIView):
    """User — anaagiza spare part (PENDING_PAYMENT)."""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = SparePartOrderCreateSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(
                {"success": False, "errors": serializer.errors},
                status=status.HTTP_400_BAD_REQUEST,
            )

        data = serializer.validated_data
        try:
            part = SparePart.objects.get(pk=data["spare_part_id"], is_active=True)
        except SparePart.DoesNotExist:
            return Response(
                {"success": False, "message": "Spare part haipo"},
                status=status.HTTP_404_NOT_FOUND,
            )

        order = SparePartOrder.objects.create(
            user=request.user,
            spare_part=part,
            quantity=data["quantity"],
            unit_price=part.price,
            total_price=part.price * data["quantity"],
            contact_phone=data.get("contact_phone", ""),
            status=SparePartOrder.Status.PENDING_PAYMENT,
        )

        return Response({
            "success": True,
            "message": "Oda imeundwa. Tafadhali lipia kupata maelekezo ya delivery.",
            "data": SparePartOrderSerializer(order, context={"request": request}).data,
        }, status=status.HTTP_201_CREATED)




# ==================== SPARE PARTS PAYMENT (kama AI Scanner) ====================
class OrderPayDepositView(APIView):
    """User analipa spare part order — network detect + bank account + countdown."""
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        import re as _re
        from decimal import Decimal
        from django.utils import timezone
        from apps.payments.models import Payment
        from apps.payments.detection import get_instructions, detect_network
        from apps.payments.payment_config import PAYMENT_TIMEOUT_MINUTES
        import uuid as _uuid

        try:
            order = SparePartOrder.objects.get(pk=pk, user=request.user)
        except SparePartOrder.DoesNotExist:
            return Response({"success": False, "message": "Oda haipo"}, status=404)

        if order.status != "PENDING_PAYMENT":
            return Response({
                "success": False,
                "message": "Oda hii imeshalipiwa au imefutwa",
            }, status=400)

        phone = (request.data.get("phone_number") or "").strip()
        method = (request.data.get("payment_method") or "MOBILE_MONEY").upper()
        bank = (request.data.get("bank_name") or "").strip()

        bank_account = ""
        detected = "Unknown"

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
            detected = detect_network(phone)
            if detected == "Unknown":
                return Response({
                    "success": False,
                    "message": "Mtandao haujulikani. Chagua mtandao au tumia bank.",
                }, status=400)
        else:
            bank_account = _re.sub(r"[^0-9]", "", phone)
            if len(bank_account) < 8:
                return Response({
                    "success": False,
                    "message": "Account number si sahihi",
                }, status=400)

        # Unda payment
        reference = f"SP-{_uuid.uuid4().hex[:8].upper()}"
        payment = Payment.objects.create(
            user=request.user,
            amount=order.total_price,
            currency="TZS",
            provider=method,
            method=method,
            purpose="SPARE_PART",
            reference=reference,
            phone_number=phone,
            status="PENDING",
            description=f"Spare Part: {order.spare_part.name}",
            expires_at=timezone.now() + timezone.timedelta(minutes=PAYMENT_TIMEOUT_MINUTES),
            metadata={
                "order_id": order.id,
                "order_number": order.order_number,
                "type": "SPARE_PART_ORDER",
                "bank_name": bank,
                "bank_account": bank_account,
            },
        )

        # Update order
        order.payment_reference = reference
        order.payment_method = method
        order.detected_network = detected
        order.bank_account = bank_account
        order.bank_name = bank
        order.payment_countdown_ends_at = payment.expires_at
        order.save()

        inst = get_instructions(method, phone, order.total_price, reference) if method == "MOBILE_MONEY" else None

        # USSD code
        ussd_map = {
            "Vodacom": "*150*00#",
            "Tigo/Yas": "*150*01#",
            "Airtel": "*150*60#",
            "Halotel": "*150*88#",
        }

        bank_instructions = None
        if method == "BANK":
            bank_instructions = (
                f"BENKI: {bank or 'NMB'}\n"
                f"Account Number: 23210042232\n"
                f"Account Name: Automotive Smart Garage\n"
                f"Kiasi: TSh {float(order.total_price):,.0f}\n"
                f"Reference: {reference}\n\n"
                f"1. Nenda kwenye app ya benki yako\n"
                f"2. Chagua 'Transfer' au 'Send Money'\n"
                f"3. Weka account: 23210042232 (NMB)\n"
                f"4. Weka kiasi: TSh {float(order.total_price):,.0f}\n"
                f"5. Weka reference: {reference}\n"
                f"6. Thibitisha muamala"
            )

        return Response({
            "success": True,
            "message": "Malipo yameanzishwa",
            "data": {
                "payment_id": payment.id,
                "reference": reference,
                "amount": float(order.total_price),
                "order_id": order.id,
                "order_number": order.order_number,
                "payment_method": method,
                "detected_network": detected,
                "admin_number": "0759212300",
                "admin_name": "Automotive Smart Garage",
                "bank_name": bank or "NMB",
                "bank_account": "23210042232",
                "ussd_code": ussd_map.get(detected, ""),
                "countdown_seconds": PAYMENT_TIMEOUT_MINUTES * 60,
                "timeout_minutes": PAYMENT_TIMEOUT_MINUTES,
                "expires_at": payment.expires_at.isoformat(),
                "instructions_mobile": inst["instructions"] if inst else None,
                "instructions_bank": bank_instructions,
            },
        }, status=201)


class OrderListView(APIView):
    """User — oda zake."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        orders = SparePartOrder.objects.filter(user=request.user).order_by("-created_at")
        return Response({
            "success": True,
            "count": orders.count(),
            "data": SparePartOrderSerializer(orders, many=True, context={"request": request}).data,
        })


class OrderDetailView(APIView):
    """User — oda moja."""
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        try:
            order = SparePartOrder.objects.get(pk=pk, user=request.user)
        except SparePartOrder.DoesNotExist:
            return Response(
                {"success": False, "message": "Oda haipo"},
                status=status.HTTP_404_NOT_FOUND,
            )
        return Response({
            "success": True,
            "data": SparePartOrderSerializer(order, context={"request": request}).data,
        })


class OrderUpdateDeliveryView(APIView):
    """User — anaweka delivery details baada ya payment."""
    permission_classes = [IsAuthenticated]

    def put(self, request, pk):
        try:
            order = SparePartOrder.objects.get(pk=pk, user=request.user)
        except SparePartOrder.DoesNotExist:
            return Response(
                {"success": False, "message": "Oda haipo"},
                status=status.HTTP_404_NOT_FOUND,
            )

        serializer = SparePartOrderDeliverySerializer(data=request.data)
        if not serializer.is_valid():
            return Response(
                {"success": False, "errors": serializer.errors},
                status=status.HTTP_400_BAD_REQUEST,
            )

        data = serializer.validated_data
        order.delivery_type = data.get("delivery_type", "DELIVERY")
        order.delivery_location = data.get("delivery_location", "")
        order.delivery_region = data.get("delivery_region", "")
        order.delivery_date = data.get("delivery_date")
        order.delivery_time = data.get("delivery_time", "")
        order.delivery_notes = data.get("delivery_notes", "")
        order.save()

        # === Tuma notification kwa admin wote ===
        try:
            from apps.notifications.models import Notification
            from django.contrib.auth import get_user_model
            User = get_user_model()
            admins = User.objects.filter(is_staff=True, is_active=True)
            for admin in admins:
                try:
                    Notification.objects.create(
                        recipient=admin,
                        notification_type="ORDER",
                        title=f"📦 Oda Mpya — {order.order_number}",
                        message=(
                            f"Mteja: {order.user.get_full_name() or order.user.email}\n"
                            f"Bidhaa: {order.spare_part.name}\n"
                            f"Kiasi: TSh {order.total_price:,.0f}\n"
                            f"Delivery: {order.delivery_location}, {order.delivery_region}\n"
                            f"Tarehe: {order.delivery_date} saa {order.delivery_time}"
                        ),
                        is_sent=True,
                        metadata={"order_id": order.id},
                    )
                except Exception:
                    pass
        except Exception:
            pass

        return Response({
            "success": True,
            "message": "Delivery details zimehifadhiwa. Admin atawasiliana nawe.",
            "data": SparePartOrderSerializer(order, context={"request": request}).data,
        })


class OrderDeleteView(APIView):
    """User — kufuta oda yake (kama haijaanza kusafirishwa)."""
    permission_classes = [IsAuthenticated]

    def delete(self, request, pk):
        try:
            order = SparePartOrder.objects.get(pk=pk, user=request.user)
        except SparePartOrder.DoesNotExist:
            return Response(
                {"success": False, "message": "Oda haipo"},
                status=status.HTTP_404_NOT_FOUND,
            )
        if order.status in ["OUT_FOR_DELIVERY", "DELIVERED"]:
            return Response(
                {"success": False, "message": "Oda imeshaanza kusafirishwa — hauwezi kufuta"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        order.delete()
        return Response({"success": True, "message": "Oda imefutwa"})


# ==================== ADMIN ORDER VIEWS ====================


# ==================== USER SET DELIVERY GPS + PICKUP (kama maelekezo) ====================
WAREHOUSE_LAT = -6.7712
WAREHOUSE_LNG = 39.2345


def _haversine_km(lat1, lng1, lat2, lng2):
    """Umbali kati ya pointi mbili kwa km."""
    import math
    R = 6371
    dlat = math.radians(lat2 - lat1)
    dlng = math.radians(lng2 - lng1)
    a = (math.sin(dlat/2)**2 +
         math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) *
         math.sin(dlng/2)**2)
    return round(R * 2 * math.asin(math.sqrt(a)), 2)


class OrderSetDeliveryGpsView(APIView):
    """User anaweka delivery GPS + pickup date baada ya admin verify."""
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        from datetime import datetime as _dt
        from django.utils import timezone as tz

        try:
            order = SparePartOrder.objects.get(pk=pk, user=request.user)
        except SparePartOrder.DoesNotExist:
            return Response({"success": False, "message": "Oda haipo"}, status=404)

        if order.status not in ("PAID", "PROCESSING"):
            return Response({
                "success": False,
                "message": "Malipo hayajathibitishwa bado",
            }, status=400)

        # GPS
        try:
            lat = float(request.data.get("latitude", 0))
            lng = float(request.data.get("longitude", 0))
        except (ValueError, TypeError):
            return Response({"success": False, "message": "Location si sahihi"}, status=400)

        if lat == 0 and lng == 0:
            return Response({"success": False, "message": "GPS ni lazima"}, status=400)

        # Address
        address = (request.data.get("address") or "").strip()
        if not address:
            return Response({"success": False, "message": "Address ni lazima"}, status=400)

        # Pickup date (siku ya mbele, sio leo)
        date_str = (request.data.get("pickup_date") or "").strip()
        try:
            pickup_date = _dt.strptime(date_str, "%Y-%m-%d").date()
        except Exception:
            return Response({"success": False, "message": "Tarehe si sahihi"}, status=400)

        if pickup_date <= tz.now().date():
            return Response({
                "success": False,
                "message": "Chagua siku ya mbele (sio leo)",
            }, status=400)

        # Time
        pickup_time = (request.data.get("pickup_time") or "").strip()

        # Distance kutoka Mbezi Mwisho
        distance = _haversine_km(WAREHOUSE_LAT, WAREHOUSE_LNG, lat, lng)

        # ETA — chukulia 20 km/h kwa Dar traffic
        eta_minutes = max(15, int((distance / 20) * 60))

        # Update order
        order.delivery_latitude = lat
        order.delivery_longitude = lng
        order.delivery_location = address
        order.delivery_date = pickup_date
        order.delivery_time = pickup_time
        order.distance_km = distance
        order.delivery_eta_minutes = eta_minutes
        order.delivery_countdown_ends_at = tz.now() + tz.timedelta(minutes=eta_minutes)
        order.status = "OUT_FOR_DELIVERY"
        order.save()

        # Notify admin
        try:
            from apps.notifications.models import Notification
            from django.contrib.auth import get_user_model
            User = get_user_model()
            for admin in User.objects.filter(is_staff=True, is_active=True):
                Notification.objects.create(
                    recipient=admin,
                    notification_type="ORDER",
                    title=f"🚚 Delivery — {order.order_number}",
                    message=(
                        f"Mteja: {order.user.get_full_name()}\n"
                        f"Bidhaa: {order.spare_part.name}\n"
                        f"Location: {address}\n"
                        f"Umbali: {distance} km\n"
                        f"ETA: dakika {eta_minutes}\n"
                        f"Tarehe: {pickup_date} saa {pickup_time}"
                    ),
                    is_sent=True,
                    metadata={"order_id": order.id, "type": "delivery_gps_set"},
                )
        except Exception as e:
            print(f'[Notif delivery] {e}')

        return Response({
            "success": True,
            "message": f"Delivery imewekwa. Umbali: {distance} km, ETA: dakika {eta_minutes}",
            "data": SparePartOrderSerializer(order, context={"request": request}).data,
        })


class AdminOrderListView(APIView):
    """Admin — oda zote."""
    permission_classes = [IsAdminUser]

    def get(self, request):
        qs = SparePartOrder.objects.all().order_by("-created_at")
        status_filter = request.query_params.get("status")
        if status_filter:
            qs = qs.filter(status=status_filter)
        return Response({
            "success": True,
            "count": qs.count(),
            "data": SparePartOrderSerializer(qs[:200], many=True, context={"request": request}).data,
        })


class AdminOrderUpdateStatusView(APIView):
    """Admin — kubadilisha status ya oda."""
    permission_classes = [IsAdminUser]

    def post(self, request, pk):
        try:
            order = SparePartOrder.objects.get(pk=pk)
        except SparePartOrder.DoesNotExist:
            return Response(
                {"success": False, "message": "Oda haipo"},
                status=status.HTTP_404_NOT_FOUND,
            )

        new_status = request.data.get("status")
        admin_notes = request.data.get("admin_notes", "")

        valid = [c[0] for c in SparePartOrder.Status.choices]
        if new_status and new_status in valid:
            order.status = new_status
        if admin_notes:
            order.admin_notes = admin_notes

        if new_status == "DELIVERED":
            from django.utils import timezone
            order.delivered_at = timezone.now()

        order.save()

        # Notify user
        try:
            from apps.notifications.models import Notification
            Notification.objects.create(
                recipient=order.user,
                notification_type="ORDER",
                title=f"Oda yako {order.order_number} — {order.get_status_display()}",
                message=f"Status ya oda yako imebadilika kuwa: {order.get_status_display()}",
                is_sent=True,
                metadata={"order_id": order.id},
            )
        except Exception:
            pass

        return Response({
            "success": True,
            "message": "Status imebadilishwa",
            "data": SparePartOrderSerializer(order, context={"request": request}).data,
        })

# ==================== GROUP 2 — COUNTDOWN & CONFIRMATION ====================
class OrderStatusView(APIView):
    """User anaangalia status, countdown, ETA ya oda yake."""
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        from django.utils import timezone as tz
        try:
            order = SparePartOrder.objects.get(pk=pk, user=request.user)
        except SparePartOrder.DoesNotExist:
            return Response({
                "success": False,
                "message": "Oda haipo",
            }, status=status.HTTP_404_NOT_FOUND)

        now = tz.now()

        # Payment countdown
        payment_remaining = 0
        if order.payment_countdown_ends_at and order.status == "PENDING_PAYMENT":
            diff = order.payment_countdown_ends_at - now
            payment_remaining = max(0, int(diff.total_seconds()))

        # Delivery countdown
        delivery_remaining = 0
        if order.delivery_countdown_ends_at and order.status in ("PAID", "PROCESSING", "OUT_FOR_DELIVERY"):
            diff = order.delivery_countdown_ends_at - now
            delivery_remaining = max(0, int(diff.total_seconds()))

        # Is expired (payment)
        is_payment_expired = (
            order.status == "PENDING_PAYMENT"
            and order.payment_countdown_ends_at
            and now > order.payment_countdown_ends_at
        )

        # Delivery complete (countdown done)
        is_delivery_due = (
            order.delivery_countdown_ends_at
            and now > order.delivery_countdown_ends_at
            and not order.receipt_confirmed_at
        )

        return Response({
            "success": True,
            "data": {
                "order_id": order.id,
                "order_number": order.order_number,
                "status": order.status,
                "payment_status": order.payment_status,
                "is_payment_expired": is_payment_expired,
                "payment_countdown_seconds": payment_remaining,
                "delivery_countdown_seconds": delivery_remaining,
                "delivery_eta_minutes": order.delivery_eta_minutes,
                "distance_km": float(order.distance_km) if order.distance_km else None,
                "delivery_date": order.delivery_date.isoformat() if order.delivery_date else None,
                "delivery_location": order.delivery_location,
                "delivery_region": order.delivery_region,
                "is_delivery_due": is_delivery_due,
                "receipt_confirmed": order.receipt_confirmed_at is not None,
                "receipt_extended_count": order.receipt_extended_count,
                "delivered_at": order.delivered_at.isoformat() if order.delivered_at else None,
            },
        })


class OrderConfirmReceiptView(APIView):
    """User anathibitisha: YES = amepokea, NO = extend time."""
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        from django.utils import timezone as tz
        try:
            order = SparePartOrder.objects.get(pk=pk, user=request.user)
        except SparePartOrder.DoesNotExist:
            return Response({
                "success": False,
                "message": "Oda haipo",
            }, status=status.HTTP_404_NOT_FOUND)

        answer = (request.data.get("answer") or "").lower()

        if answer == "yes":
            order.receipt_confirmed_at = tz.now()
            order.status = "DELIVERED"
            order.delivered_at = tz.now()
            order.save()

            # Notify admin
            try:
                from apps.notifications.models import Notification
                from django.contrib.auth import get_user_model
                User = get_user_model()
                for admin in User.objects.filter(is_staff=True, is_active=True):
                    Notification.objects.create(
                        recipient=admin,
                        notification_type="ORDER",
                        title=f"✅ Order Delivered — {order.order_number}",
                        message=f"{order.user.email} amethibitisha kupokea {order.spare_part.name}",
                        is_sent=True,
                        metadata={"order_id": order.id},
                    )
            except Exception:
                pass

            return Response({
                "success": True,
                "message": "Asante! Oda yako imekamilika.",
                "data": {"status": "DELIVERED"},
            })

        elif answer == "no":
            return Response({
                "success": True,
                "message": "Sorry. Can you allow some extra time for our delivery in case of an emergency?",
                "data": {
                    "status": "waiting_extension",
                    "extension_minutes": 15,
                },
            })

        return Response({
            "success": False,
            "message": "Jibu YES au NO",
        }, status=status.HTTP_400_BAD_REQUEST)


class OrderExtendTimeView(APIView):
    """User ana-accept +15 min extension."""
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        from django.utils import timezone as tz
        try:
            order = SparePartOrder.objects.get(pk=pk, user=request.user)
        except SparePartOrder.DoesNotExist:
            return Response({
                "success": False,
                "message": "Oda haipo",
            }, status=status.HTTP_404_NOT_FOUND)

        try:
            minutes = int(request.data.get("minutes", 15))
        except (ValueError, TypeError):
            minutes = 15

        base = order.delivery_countdown_ends_at or tz.now()
        order.delivery_countdown_ends_at = base + tz.timedelta(minutes=minutes)
        order.receipt_extended_count += 1
        order.save()

        # Notify admin
        try:
            from apps.notifications.models import Notification
            from django.contrib.auth import get_user_model
            User = get_user_model()
            for admin in User.objects.filter(is_staff=True, is_active=True):
                Notification.objects.create(
                    recipient=admin,
                    notification_type="ORDER",
                    title=f"⚠️ Delivery Extension — {order.order_number}",
                    message=f"{order.user.email} ameongeza dakika {minutes}. Bidhaa: {order.spare_part.name}",
                    is_sent=True,
                    metadata={"order_id": order.id},
                )
        except Exception:
            pass

        return Response({
            "success": True,
            "message": f"Dakika {minutes} zimeongezwa",
            "data": {
                "delivery_countdown_ends_at": order.delivery_countdown_ends_at.isoformat(),
                "extension_minutes": minutes,
            },
        })


class OrderSetEtaView(APIView):
    """Admin ana-set ETA ya delivery (baada ya approve payment)."""
    permission_classes = [IsAdminUser]

    def post(self, request, pk):
        from django.utils import timezone as tz
        try:
            order = SparePartOrder.objects.get(pk=pk)
        except SparePartOrder.DoesNotExist:
            return Response({
                "success": False,
                "message": "Oda haipo",
            }, status=status.HTTP_404_NOT_FOUND)

        try:
            hours = int(request.data.get("hours", 0))
            minutes = int(request.data.get("minutes", 0))
            distance_km = request.data.get("distance_km")
        except (ValueError, TypeError):
            hours = 0
            minutes = 0
            distance_km = None

        total_minutes = hours * 60 + minutes
        if total_minutes <= 0:
            return Response({
                "success": False,
                "message": "Weka muda wa kufika",
            }, status=status.HTTP_400_BAD_REQUEST)

        order.delivery_eta_minutes = total_minutes
        order.delivery_started_at = tz.now()
        order.delivery_countdown_ends_at = tz.now() + tz.timedelta(minutes=total_minutes)
        if distance_km:
            try:
                order.distance_km = float(distance_km)
            except (ValueError, TypeError):
                pass
        order.status = "OUT_FOR_DELIVERY"
        order.save()

        # Notify user
        try:
            from apps.notifications.services import send_notification_to_user
            send_notification_to_user(
                user=order.user,
                title="🚚 Bidhaa yako inakuja",
                message=f"{order.spare_part.name} itafika baada ya dakika {total_minutes}.",
                notification_type="service",
                data={"order_id": order.id, "type": "delivery_eta"},
            )
        except Exception as e:
            print(f"[ETA notif] {e}")

        return Response({
            "success": True,
            "message": f"ETA imewekwa: dakika {total_minutes}",
            "data": {
                "eta_minutes": total_minutes,
                "delivery_countdown_ends_at": order.delivery_countdown_ends_at.isoformat(),
            },
        })
