from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator
from apps.accounts.models import User
from apps.vehicles.models import Vehicle


class Category(models.Model):
    """Spare Part Category"""
    name = models.CharField(max_length=100, unique=True)
    slug = models.SlugField(max_length=100, unique=True)
    description = models.TextField(blank=True, null=True)
    icon = models.ImageField(upload_to='spare_parts/categories/', blank=True, null=True)
    parent = models.ForeignKey(
        'self', 
        on_delete=models.CASCADE, 
        blank=True, 
        null=True, 
        related_name='subcategories'
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name


class Brand(models.Model):
    """Spare Part Brand"""
    name = models.CharField(max_length=100, unique=True)
    slug = models.SlugField(max_length=100, unique=True)
    logo = models.ImageField(upload_to='spare_parts/brands/', blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    is_verified = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name


class SparePart(models.Model):
    """Spare Part Model"""
    
    # Basic Information
    name = models.CharField(max_length=200)
    slug = models.SlugField(max_length=200, unique=True)
    description = models.TextField()
    short_description = models.CharField(max_length=300, blank=True)
    
    # Category and Brand
    category = models.ForeignKey(
        Category, 
        on_delete=models.CASCADE, 
        related_name='spare_parts'
    )
    brand = models.ForeignKey(
        Brand, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        related_name='spare_parts'
    )
    
    # Part Numbers
    part_number = models.CharField(max_length=100, db_index=True, blank=True, default='')
    oem_number = models.CharField(max_length=100, blank=True, null=True)
    
    # Vehicle Compatibility
    compatible_vehicle_makes = models.JSONField(default=list)
    compatible_vehicle_models = models.JSONField(default=list)
    compatible_years = models.JSONField(default=list)
    
    # Specifications
    specifications = models.JSONField(default=dict)
    features = models.JSONField(default=list)
    
    # Pricing
    price = models.DecimalField(
        max_digits=10, 
        decimal_places=2,
        validators=[MinValueValidator(0)]
    )
    discount_price = models.DecimalField(
        max_digits=10, 
        decimal_places=2, 
        blank=True, 
        null=True,
        validators=[MinValueValidator(0)]
    )
    
    # Stock
    stock_quantity = models.PositiveIntegerField(default=0)
    minimum_stock = models.PositiveIntegerField(default=5)
    
    # Images
    main_image = models.ImageField(upload_to='spare_parts/images/', blank=True, null=True)
    additional_images = models.JSONField(default=list, blank=True)
    
    # Condition and Status
    CONDITION_CHOICES = [
        ('new', 'New'),
        ('used', 'Used'),
        ('refurbished', 'Refurbished'),
    ]
    condition = models.CharField(max_length=20, choices=CONDITION_CHOICES, default='new')
    
    STATUS_CHOICES = [
        ('available', 'Available'),
        ('out_of_stock', 'Out of Stock'),
        ('discontinued', 'Discontinued'),
    ]
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='available')
    
    # Additional Info
    weight = models.DecimalField(
        max_digits=8, 
        decimal_places=2, 
        blank=True, 
        null=True,
        help_text="Weight in kg"
    )
    warranty_period = models.PositiveIntegerField(default=0, help_text="Warranty in months")
    
    # Admin Controls
    is_active = models.BooleanField(default=True)
    is_featured = models.BooleanField(default=False)
    is_on_sale = models.BooleanField(default=False)
    views_count = models.PositiveIntegerField(default=0)
    orders_count = models.PositiveIntegerField(default=0)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name='created_spare_parts'
    )

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.name} - {self.part_number}"

    @property
    def final_price(self):
        if self.discount_price and self.discount_price < self.price:
            return self.discount_price
        return self.price

    @property
    def discount_percentage(self):
        if self.discount_price and self.discount_price < self.price:
            return round(((self.price - self.discount_price) / self.price) * 100, 2)
        return 0

    @property
    def is_in_stock(self):
        return self.stock_quantity > 0

    def reduce_stock(self, quantity):
        if self.stock_quantity >= quantity:
            self.stock_quantity -= quantity
            self.save()
            return True
        return False


# ==================== ORDER MODEL ====================
import uuid as _uuid
from django.utils import timezone as _tz


class SparePartOrder(models.Model):
    """Oda ya spare part — user anaagiza, anaweka delivery details."""

    class Status(models.TextChoices):
        PENDING_PAYMENT = "PENDING_PAYMENT", "Pending Payment"
        PAID = "PAID", "Paid"
        PROCESSING = "PROCESSING", "Processing"
        OUT_FOR_DELIVERY = "OUT_FOR_DELIVERY", "Out for Delivery"
        DELIVERED = "DELIVERED", "Delivered"
        CANCELLED = "CANCELLED", "Cancelled"

    class DeliveryType(models.TextChoices):
        DELIVERY = "DELIVERY", "Delivery to Location"
        PICKUP = "PICKUP", "Pickup at Garage"

    order_number = models.CharField(max_length=50, unique=True, editable=False, db_index=True)
    user = models.ForeignKey(
        "accounts.User", on_delete=models.PROTECT,
        related_name="spare_part_orders",
    )
    spare_part = models.ForeignKey(
        SparePart, on_delete=models.PROTECT,
        related_name="orders",
    )
    quantity = models.PositiveIntegerField(default=1)
    unit_price = models.DecimalField(max_digits=12, decimal_places=2)
    total_price = models.DecimalField(max_digits=12, decimal_places=2)

    # Delivery details (user anajaza baada ya payment)
    delivery_type = models.CharField(
        max_length=20, choices=DeliveryType.choices,
        default=DeliveryType.DELIVERY,
    )
    delivery_location = models.CharField(max_length=255, blank=True)
    delivery_region = models.CharField(max_length=100, blank=True)
    delivery_date = models.DateField(null=True, blank=True)
    delivery_time = models.CharField(max_length=20, blank=True)
    delivery_notes = models.TextField(blank=True)

    # Contact
    contact_phone = models.CharField(max_length=20, blank=True)

    # Payment link
    payment_reference = models.CharField(max_length=100, blank=True, db_index=True)
    payment_status = models.CharField(max_length=20, default="UNPAID")

    status = models.CharField(
        max_length=30, choices=Status.choices,
        default=Status.PENDING_PAYMENT, db_index=True,
    )

    # Admin
    admin_notes = models.TextField(blank=True)
    delivered_at = models.DateTimeField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "spare_part_orders"
        ordering = ["-created_at"]

    def save(self, *args, **kwargs):
        if not self.order_number:
            self.order_number = f"ORD-{_uuid.uuid4().hex[:10].upper()}"
        if self.spare_part and self.quantity:
            self.total_price = self.spare_part.price * self.quantity
            self.unit_price = self.spare_part.price
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.order_number} - {self.spare_part.name}"
