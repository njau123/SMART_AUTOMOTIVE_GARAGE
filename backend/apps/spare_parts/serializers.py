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
