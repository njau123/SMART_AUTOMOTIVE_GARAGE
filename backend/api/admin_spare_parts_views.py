"""
Admin Spare Parts Management — Create (with image), List, Update, Delete.
"""
import uuid
from django.utils.text import slugify
from rest_framework import status
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.permissions import IsAdminUser
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.spare_parts.models import SparePart, Category, Brand


# ==================== HELPERS ====================
def _safe_int(value, default=0):
    """Badilisha value kuwa int, rudisha default kama imeshindwa."""
    if value in (None, '', 'null', 'None'):
        return default
    try:
        return int(value)
    except (TypeError, ValueError):
        return default


def _safe_decimal(value, default=None):
    """Badilisha value kuwa decimal/float, rudisha default kama imeshindwa."""
    if value in (None, '', 'null', 'None'):
        return default
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


def _safe_bool(value):
    """Badilisha value kuwa boolean."""
    if value is None:
        return False
    return str(value).lower() in ('true', '1', 'yes', 'on')


def _safe_choice(value, choices, default):
    """Hakikisha value ipo kwenye choices."""
    if value is None:
        return default
    value = str(value).lower().strip()
    valid = [c[0] for c in choices]
    return value if value in valid else default


# ==================== VIEWS ====================
class AdminSparePartListView(APIView):
    """Admin — orodha ya spare parts zote (ikiwa inactive)."""
    permission_classes = [IsAdminUser]

    def get(self, request):
        parts = SparePart.objects.all().order_by('-created_at')[:200]
        data = []
        for p in parts:
            data.append({
                'id': p.id,
                'name': p.name,
                'slug': p.slug,
                'part_number': p.part_number,
                'price': str(p.price),
                'stock_quantity': p.stock_quantity,
                'condition': p.condition,
                'status': p.status,
                'is_active': p.is_active,
                'main_image': (
                    request.build_absolute_uri(p.main_image.url)
                    if p.main_image else None
                ),
                'category_name': p.category.name if p.category else None,
                'brand_name': p.brand.name if p.brand else None,
                'created_at': p.created_at.isoformat() if p.created_at else None,
            })
        return Response({'success': True, 'count': len(data), 'data': data})


class AdminSparePartCreateView(APIView):
    """Admin — kuunda spare part (na image upload)."""
    permission_classes = [IsAdminUser]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def post(self, request):
        data = request.data
        name = (data.get('name') or '').strip()
        if not name:
            return Response(
                {'success': False, 'message': 'Name ni lazima'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        price = _safe_decimal(data.get('price'), default=0.0)
        if price is None or price < 0:
            return Response(
                {'success': False, 'message': 'Price si sahihi'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Category — chagua au unda default "General"
        category = None
        category_id = data.get('category')
        if category_id:
            try:
                category = Category.objects.get(id=int(category_id))
            except (Category.DoesNotExist, ValueError, TypeError):
                category = None
        if category is None:
            category, _ = Category.objects.get_or_create(
                slug='general',
                defaults={'name': 'General', 'is_active': True},
            )

        # Brand (optional)
        brand = None
        brand_id = data.get('brand')
        if brand_id:
            try:
                brand = Brand.objects.get(id=int(brand_id))
            except (Brand.DoesNotExist, ValueError, TypeError):
                brand = None

        # Slug — lazima unique
        base_slug = slugify(name) or 'spare-part'
        slug = base_slug
        counter = 1
        while SparePart.objects.filter(slug=slug).exists():
            counter += 1
            slug = f'{base_slug}-{counter}'

        # Part number — tumia iliyotolewa au tengeneza
        part_number = (data.get('part_number') or '').strip()
        if not part_number:
            part_number = f'P-{uuid.uuid4().hex[:8].upper()}'

        # Condition — safe choice
        condition = _safe_choice(
            data.get('condition'),
            SparePart.CONDITION_CHOICES,
            'new',
        )

        # Status — safe choice (lowercase!)
        part_status = _safe_choice(
            data.get('status'),
            SparePart.STATUS_CHOICES,
            'available',
        )

        # Unda part — KILA KITU SAFE
        part = SparePart.objects.create(
            name=name,
            slug=slug,
            description=(data.get('description') or '') or name,
            short_description=(data.get('short_description') or '') or name[:200],
            category=category,
            brand=brand,
            part_number=part_number,
            price=price,
            discount_price=_safe_decimal(data.get('discount_price'), default=None),
            stock_quantity=_safe_int(data.get('stock_quantity'), default=0),
            minimum_stock=_safe_int(data.get('minimum_stock'), default=5),
            condition=condition,
            status=part_status,
            is_active=True,
            is_featured=_safe_bool(data.get('is_featured')),
            is_on_sale=_safe_bool(data.get('is_on_sale')),
            warranty_period=_safe_int(data.get('warranty_period'), default=0),
        )

        # Image upload (baada ya create)
        if 'main_image' in request.FILES:
            part.main_image = request.FILES['main_image']
            part.save(update_fields=['main_image'])

        return Response({
            'success': True,
            'message': f'Spare part "{part.name}" imeundwa',
            'data': {
                'id': part.id,
                'name': part.name,
                'slug': part.slug,
                'price': str(part.price),
                'part_number': part.part_number,
                'main_image': (
                    request.build_absolute_uri(part.main_image.url)
                    if part.main_image else None
                ),
            },
        }, status=status.HTTP_201_CREATED)


class AdminSparePartUpdateView(APIView):
    """Admin — kuhariri spare part."""
    permission_classes = [IsAdminUser]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def post(self, request, pk):
        try:
            part = SparePart.objects.get(pk=pk)
        except SparePart.DoesNotExist:
            return Response(
                {'success': False, 'message': 'Spare part haipo'},
                status=status.HTTP_404_NOT_FOUND,
            )

        data = request.data

        if data.get('name'):
            part.name = data['name'].strip()
        if data.get('description'):
            part.description = data['description']
        if data.get('part_number'):
            part.part_number = data['part_number']

        price = _safe_decimal(data.get('price'))
        if price is not None:
            part.price = price

        stock = _safe_int(data.get('stock_quantity'), default=None)
        if stock is not None:
            part.stock_quantity = stock

        if data.get('condition'):
            part.condition = _safe_choice(
                data.get('condition'),
                SparePart.CONDITION_CHOICES,
                part.condition,
            )

        if data.get('status'):
            part.status = _safe_choice(
                data.get('status'),
                SparePart.STATUS_CHOICES,
                part.status,
            )

        if data.get('is_active') is not None:
            part.is_active = _safe_bool(data.get('is_active'))

        if 'main_image' in request.FILES:
            part.main_image = request.FILES['main_image']

        part.save()
        return Response({
            'success': True,
            'message': 'Imebadilishwa',
            'data': {'id': part.id, 'name': part.name},
        })


class AdminSparePartDeleteView(APIView):
    """Admin — kufuta spare part."""
    permission_classes = [IsAdminUser]

    def delete(self, request, pk):
        try:
            part = SparePart.objects.get(pk=pk)
        except SparePart.DoesNotExist:
            return Response(
                {'success': False, 'message': 'Spare part haipo'},
                status=status.HTTP_404_NOT_FOUND,
            )
        name = part.name
        part.delete()
        return Response({
            'success': True,
            'message': f'"{name}" imefutwa',
        })
