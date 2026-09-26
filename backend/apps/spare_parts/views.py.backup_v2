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
