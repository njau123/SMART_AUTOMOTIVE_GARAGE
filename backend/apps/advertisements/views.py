from rest_framework import viewsets, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAdminUser
from rest_framework.response import Response
from .models import Advertisement
from .serializers import AdvertisementSerializer

class AdvertisementViewSet(viewsets.ModelViewSet):
    serializer_class = AdvertisementSerializer
    permission_classes = [permissions.AllowAny]
    queryset = Advertisement.objects.filter(is_active=True)  # corrected field

@api_view(['GET'])
@permission_classes([IsAdminUser])
def admin_ads(request):
    ads = Advertisement.objects.all().values('id', 'title', 'description', 'is_active', 'created_at')
    return Response(list(ads))

@api_view(['POST'])
@permission_classes([IsAdminUser])
def admin_create_ad(request):
    Advertisement.objects.create(
        title=request.data.get('title'),
        description=request.data.get('description'),
        image=request.data.get('image_url', ''),
        is_active=request.data.get('is_active', True),
    )
    return Response({'message': 'Ad created'}, status=201)
