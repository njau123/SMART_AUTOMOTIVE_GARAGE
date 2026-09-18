from rest_framework import viewsets, permissions
from .models import AuditLog
from .serializers import AuditLogSerializer


class AuditLogViewSet(viewsets.ModelViewSet):
    """Audit Log ViewSet"""
    queryset = AuditLog.objects.all()
    serializer_class = AuditLogSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.is_super_admin or user.is_admin:
            return AuditLog.objects.all()
        return AuditLog.objects.filter(user=user)
