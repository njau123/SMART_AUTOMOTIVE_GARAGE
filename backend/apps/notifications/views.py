from rest_framework import viewsets, status
from rest_framework.decorators import api_view, permission_classes, action
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from rest_framework.response import Response
from django.utils import timezone

from .models import NotificationDevice, Notification
from .serializers import NotificationSerializer, NotificationCreateSerializer


# ==================== USER NOTIFICATIONS ====================
class NotificationViewSet(viewsets.ModelViewSet):
    """User anaona, ana-mark read, na ku-delete notifications zake."""
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = []

    def get_queryset(self):
        return Notification.objects.filter(
            recipient=self.request.user
        ).order_by('-created_at')

    def get_serializer_class(self):
        if self.action == 'create':
            return NotificationCreateSerializer
        return NotificationSerializer

    @action(detail=True, methods=['post'], url_path='mark-read')
    def mark_read(self, request, pk=None):
        notif = self.get_object()
        notif.is_read = True
        notif.read_at = timezone.now()
        notif.save(update_fields=['is_read', 'read_at', 'updated_at'])
        return Response({'success': True, 'message': 'Marked as read'})

    @action(detail=False, methods=['post'], url_path='mark-all-read')
    def mark_all_read(self, request):
        updated = self.get_queryset().filter(is_read=False).update(
            is_read=True, read_at=timezone.now()
        )
        return Response({'success': True, 'updated': updated})

    @action(detail=False, methods=['delete'], url_path='delete-all')
    def delete_all(self, request):
        deleted, _ = self.get_queryset().delete()
        return Response({'success': True, 'deleted': deleted})

    @action(detail=True, methods=['post'], url_path='dismiss')
    def dismiss(self, request, pk=None):
        notif = self.get_object()
        notif.is_dismissed = True
        notif.dismissed_at = timezone.now()
        notif.save(update_fields=['is_dismissed', 'dismissed_at', 'updated_at'])
        return Response({'success': True, 'message': 'Dismissed'})


# ==================== DEVICE REGISTRATION ====================
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def register_device(request):
    token = request.data.get('device_token')
    device_type = request.data.get('device_type', 'android')
    if not token:
        return Response({'error': 'device_token required'}, status=400)
    NotificationDevice.objects.update_or_create(
        user=request.user,
        device_token=token,
        defaults={'device_type': device_type, 'is_active': True}
    )
    return Response({'success': True, 'message': 'Device registered'})


@api_view(['POST'])
@permission_classes([IsAdminUser])
def send_admin_notification(request):
    title = request.data.get('title')
    message = request.data.get('message') or request.data.get('body')
    if not title or not message:
        return Response({'error': 'title and message required'}, status=400)
    devices = NotificationDevice.objects.filter(is_active=True)
    tokens = [d.device_token for d in devices]
    return Response({'sent': len(tokens)})
