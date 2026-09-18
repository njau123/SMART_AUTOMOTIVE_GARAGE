from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Media
from .serializers import MediaSerializer


class MediaViewSet(viewsets.ModelViewSet):
    queryset = Media.objects.filter(is_active=True)
    serializer_class = MediaSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.is_super_admin or user.is_admin:
            return Media.objects.all()
        return Media.objects.filter(is_active=True)

    def perform_create(self, serializer):
        serializer.save(uploaded_by=self.request.user)

    @action(detail=False, methods=['get'])
    def by_category(self, request):
        category = request.query_params.get('category')
        if not category:
            return Response({
                'success': False,
                'message': 'category parameter is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        media = self.get_queryset().filter(category=category)
        serializer = MediaSerializer(media, many=True)
        return Response({
            'success': True,
            'message': f'Media in category {category}',
            'data': serializer.data
        })

    @action(detail=True, methods=['post'])
    def toggle_active(self, request, pk=None):
        media = self.get_object()
        media.is_active = not media.is_active
        media.save()
        return Response({
            'success': True,
            'message': f'Media {media.is_active and "activated" or "deactivated"}',
            'data': MediaSerializer(media).data
        })
