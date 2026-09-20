from rest_framework import serializers
from .models import Category, Brand, SparePart


class CategorySerializer(serializers.ModelSerializer):
    subcategories = serializers.SerializerMethodField()
    
    class Meta:
        model = Category
        fields = ['id', 'name', 'slug', 'description', 'icon', 'parent', 'subcategories', 'is_active']

    def get_subcategories(self, obj):
        subcategories = obj.subcategories.filter(is_active=True)
        return CategorySerializer(subcategories, many=True).data


class BrandSerializer(serializers.ModelSerializer):
    class Meta:
        model = Brand
        fields = ['id', 'name', 'slug', 'logo', 'description', 'is_verified', 'is_active']


class SparePartListSerializer(serializers.ModelSerializer):
    category_name = serializers.CharField(source='category.name', read_only=True)
    brand_name = serializers.CharField(source='brand.name', read_only=True)
    final_price = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    is_in_stock = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = SparePart
        fields = [
            'id', 'name', 'slug', 'part_number', 'main_image',
            'category_name', 'brand_name', 'price', 'discount_price',
            'final_price', 'stock_quantity', 'is_in_stock',
            'condition', 'status', 'is_featured', 'is_on_sale'
        ]


class SparePartDetailSerializer(serializers.ModelSerializer):
    category = CategorySerializer(read_only=True)
    brand = BrandSerializer(read_only=True)
    final_price = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    is_in_stock = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = SparePart
        fields = [
            'id', 'name', 'slug', 'description', 'short_description',
            'category', 'brand', 'part_number', 'oem_number',
            'compatible_vehicle_makes', 'compatible_vehicle_models',
            'compatible_years', 'specifications', 'features',
            'price', 'discount_price', 'final_price',
            'stock_quantity', 'minimum_stock', 'main_image',
            'additional_images', 'condition', 'status',
            'weight', 'warranty_period', 'is_active', 'is_featured',
            'is_on_sale', 'is_in_stock', 'views_count', 'orders_count',
            'created_at', 'updated_at'
        ]


# ==================== ORDER SERIALIZERS ====================
from .models import SparePartOrder


class SparePartOrderCreateSerializer(serializers.Serializer):
    """Create order — user anaagiza spare part."""
    spare_part_id = serializers.IntegerField()
    quantity = serializers.IntegerField(min_value=1, default=1)
    contact_phone = serializers.CharField(max_length=20, required=False, allow_blank=True)


class SparePartOrderDeliverySerializer(serializers.Serializer):
    """User anajaza delivery details baada ya payment."""
    delivery_type = serializers.ChoiceField(
        choices=["DELIVERY", "PICKUP"],
        default="DELIVERY",
    )
    delivery_location = serializers.CharField(max_length=255, required=False, allow_blank=True)
    delivery_region = serializers.CharField(max_length=100, required=False, allow_blank=True)
    delivery_date = serializers.DateField(required=False, allow_null=True)
    delivery_time = serializers.CharField(max_length=20, required=False, allow_blank=True)
    delivery_notes = serializers.CharField(required=False, allow_blank=True)


class SparePartOrderSerializer(serializers.ModelSerializer):
    spare_part_name = serializers.CharField(source="spare_part.name", read_only=True)
    spare_part_image = serializers.SerializerMethodField()
    user_full_name = serializers.SerializerMethodField()
    user_email = serializers.CharField(source="user.email", read_only=True)

    class Meta:
        model = SparePartOrder
        fields = [
            "id", "order_number", "user", "user_full_name", "user_email",
            "spare_part", "spare_part_name", "spare_part_image",
            "quantity", "unit_price", "total_price",
            "delivery_type", "delivery_location", "delivery_region",
            "delivery_date", "delivery_time", "delivery_notes",
            "contact_phone", "payment_reference", "payment_status",
            "status", "admin_notes", "delivered_at",
            "created_at", "updated_at",
        ]
        read_only_fields = ["id", "order_number", "created_at", "updated_at"]

    def get_spare_part_image(self, obj):
        request = self.context.get("request")
        if obj.spare_part and obj.spare_part.main_image:
            url = obj.spare_part.main_image.url
            if request:
                return request.build_absolute_uri(url)
            return url
        return None

    def get_user_full_name(self, obj):
        if obj.user:
            return f"{obj.user.first_name} {obj.user.last_name}".strip() or obj.user.email
        return ""
