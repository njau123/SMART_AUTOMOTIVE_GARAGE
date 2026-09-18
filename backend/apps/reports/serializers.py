from rest_framework import serializers
from .models import Report


class ReportSerializer(serializers.ModelSerializer):
    created_by_name = serializers.CharField(source='created_by.get_full_name', read_only=True)

    class Meta:
        model = Report
        fields = [
            'id', 'title', 'report_type', 'data',
            'created_by', 'created_by_name', 'status',
            'file', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
