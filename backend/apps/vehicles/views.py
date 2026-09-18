from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Vehicle
from .serializers import VehicleSerializer, VehicleCreateSerializer


class VehicleViewSet(viewsets.ModelViewSet):
    """Vehicle ViewSet - CRUD operations for user vehicles"""
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        """Return only the current user's vehicles"""
        return Vehicle.objects.filter(user=self.request.user, is_active=True)

    def get_serializer_class(self):
        if self.action == 'create':
            return VehicleCreateSerializer
        return VehicleSerializer

    def perform_create(self, serializer):
        """Set the user when creating a vehicle"""
        serializer.save(user=self.request.user)

    @action(detail=True, methods=['post'])
    def set_primary(self, request, pk=None):
        """Set a vehicle as the primary vehicle"""
        vehicle = self.get_object()
        # Remove primary status from all other vehicles
        Vehicle.objects.filter(user=request.user, is_primary=True).update(is_primary=False)
        # Set this vehicle as primary
        vehicle.is_primary = True
        vehicle.save()
        return Response({
            'success': True,
            'message': 'Vehicle set as primary',
            'data': VehicleSerializer(vehicle).data
        })

    @action(detail=False, methods=['get'])
    def primary(self, request):
        """Get the user's primary vehicle"""
        vehicle = Vehicle.objects.filter(user=request.user, is_primary=True, is_active=True).first()
        if vehicle:
            return Response({
                'success': True,
                'message': 'Primary vehicle retrieved',
                'data': VehicleSerializer(vehicle).data
            })
        return Response({
            'success': False,
            'message': 'No primary vehicle found'
        }, status=status.HTTP_404_NOT_FOUND)
