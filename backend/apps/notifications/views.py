from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from rest_framework.response import Response
from .models import NotificationDevice, Notification

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
    # Katika production, tumia Firebase Admin SDK hapa
    return Response({'sent': len(tokens)})
