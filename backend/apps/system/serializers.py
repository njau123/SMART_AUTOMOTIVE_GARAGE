from rest_framework import serializers
from .models import SystemSetting


class SystemSettingSerializer(serializers.ModelSerializer):
    formatted_value = serializers.SerializerMethodField()
    
    class Meta:
        model = SystemSetting
        fields = [
            'id', 'key', 'value', 'formatted_value',
            'description', 'data_type', 'category',
            'is_active', 'is_public', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def get_formatted_value(self, obj):
        return obj.get_value()
