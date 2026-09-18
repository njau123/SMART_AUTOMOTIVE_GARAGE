from rest_framework import viewsets, permissions, filters
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
    queryset = Category.objects.filter(is_active=True)
    serializer_class = CategorySerializer
    permission_classes = [permissions.AllowAny]


class BrandViewSet(viewsets.ModelViewSet):
    queryset = Brand.objects.filter(is_active=True)
    serializer_class = BrandSerializer
    permission_classes = [permissions.AllowAny]


class SparePartViewSet(viewsets.ModelViewSet):
    queryset = SparePart.objects.filter(is_active=True)
    permission_classes = [permissions.AllowAny]
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
