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
