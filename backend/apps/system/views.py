from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import SystemSetting
from .serializers import SystemSettingSerializer


class SystemSettingViewSet(viewsets.ModelViewSet):
    queryset = SystemSetting.objects.filter(is_active=True)
    serializer_class = SystemSettingSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.is_super_admin or user.is_admin:
            return SystemSetting.objects.all()
        if user.is_authenticated and not user.is_admin:
            return SystemSetting.objects.filter(is_public=True, is_active=True)
        return SystemSetting.objects.filter(is_public=True, is_active=True)

    @action(detail=False, methods=['get'])
    def public(self, request):
        """Get public settings"""
        settings = SystemSetting.objects.filter(is_public=True, is_active=True)
        serializer = SystemSettingSerializer(settings, many=True)
        return Response({
            'success': True,
            'message': 'Public settings retrieved',
            'data': serializer.data
        })

    @action(detail=False, methods=['get'])
    def by_category(self, request):
        """Get settings by category"""
        category = request.query_params.get('category')
        if not category:
            return Response({
                'success': False,
                'message': 'category parameter is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        settings = self.get_queryset().filter(category=category)
        serializer = SystemSettingSerializer(settings, many=True)
        return Response({
            'success': True,
            'message': f'Settings for category {category}',
            'data': serializer.data
        })

    @action(detail=False, methods=['post'])
    def set_value(self, request):
        """Set or update setting value"""
        key = request.data.get('key')
        value = request.data.get('value')
        description = request.data.get('description')
        data_type = request.data.get('data_type', 'string')
        category = request.data.get('category', 'general')
        
        if not key or value is None:
            return Response({
                'success': False,
                'message': 'key and value are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        setting = SystemSetting.set_setting(key, value, description, data_type, category)
        serializer = SystemSettingSerializer(setting)
        return Response({
            'success': True,
            'message': 'Setting updated successfully',
            'data': serializer.data
        })
