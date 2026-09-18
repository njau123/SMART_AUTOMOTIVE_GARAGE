from rest_framework import serializers
from .models import Media


class MediaSerializer(serializers.ModelSerializer):
    uploaded_by_name = serializers.CharField(source='uploaded_by.get_full_name', read_only=True)
    file_url = serializers.ReadOnlyField()
    file_name = serializers.ReadOnlyField()
    
    class Meta:
        model = Media
        fields = [
            'id', 'title', 'file', 'file_url', 'file_name',
            'file_type', 'file_size', 'category', 'description',
            'uploaded_by', 'uploaded_by_name', 'metadata',
            'is_active', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'file_url', 'file_name']
