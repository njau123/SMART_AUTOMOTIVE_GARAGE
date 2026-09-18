from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator


class SystemSetting(models.Model):
    """System Setting Model"""
    
    key = models.CharField(max_length=100, unique=True, db_index=True)
    value = models.TextField()
    description = models.TextField(blank=True, null=True)
    
    # Data Type
    DATA_TYPES = [
        ('string', 'String'),
        ('integer', 'Integer'),
        ('boolean', 'Boolean'),
        ('json', 'JSON'),
        ('decimal', 'Decimal'),
    ]
    data_type = models.CharField(max_length=20, choices=DATA_TYPES, default='string')
    
    # Category
    CATEGORY_CHOICES = [
        ('general', 'General'),
        ('payment', 'Payment'),
        ('notification', 'Notification'),
        ('email', 'Email'),
        ('security', 'Security'),
        ('feature', 'Feature'),
        ('appearance', 'Appearance'),
        ('integration', 'Integration'),
    ]
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES, default='general')
    
    # Status
    is_active = models.BooleanField(default=True)
    is_public = models.BooleanField(default=False)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['category', 'key']

    def __str__(self):
        return f"{self.key} = {self.value}"

    def get_value(self):
        """Get value with proper type conversion"""
        if self.data_type == 'integer':
            return int(self.value)
        elif self.data_type == 'boolean':
            return self.value.lower() in ['true', '1', 'yes']
        elif self.data_type == 'decimal':
            return float(self.value)
        elif self.data_type == 'json':
            import json
            try:
                return json.loads(self.value)
            except:
                return {}
        return self.value

    @classmethod
    def get_setting(cls, key, default=None):
        """Get setting value by key"""
        try:
            setting = cls.objects.get(key=key, is_active=True)
            return setting.get_value()
        except cls.DoesNotExist:
            return default

    @classmethod
    def set_setting(cls, key, value, description=None, data_type='string', category='general'):
        """Set or update setting"""
        setting, created = cls.objects.get_or_create(key=key)
        setting.value = str(value)
        setting.data_type = data_type
        if description:
            setting.description = description
        if category:
            setting.category = category
        setting.save()
        return setting
