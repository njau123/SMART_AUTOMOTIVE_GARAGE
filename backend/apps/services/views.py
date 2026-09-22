from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.response import Response
from django.utils import timezone

from api.permissions import IsAdminOrReadOnly
from .models import ServiceCategory, Service
from .serializers import ServiceCategorySerializer, ServiceSerializer


class ServiceCategoryViewSet(viewsets.ModelViewSet):
    queryset = ServiceCategory.objects.all()
    serializer_class = ServiceCategorySerializer
    permission_classes = [IsAdminOrReadOnly]
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    pagination_class = None  # Rudisha zote bila pagination


def _notify_all_users(service, action="created"):
    """Tuma notification kwa users wote kuhusu service mpya/iliyobadilishwa."""
    try:
        from apps.notifications.models import Notification
        from django.contrib.auth import get_user_model
        User = get_user_model()

        if action == "created":
            title = f"🔧 Service Mpya: {service.name}"
            message = (
                f"Huduma mpya imeongezwa: {service.name}\n"
                f"Bei: TSh {service.base_price:,.0f}\n"
            )
        elif action == "updated":
            title = f"✏️ Service Imebadilishwa: {service.name}"
            message = f"Huduma imebadilishwa: {service.name}\nBei: TSh {service.base_price:,.0f}\n"
        elif action == "deleted":
            title = f"❌ Service Imefutwa: {service.name}"
            message = f"Huduma imefutwa: {service.name}\n"
        else:
            return

        # Ongeza siku + muda kama zipo
        if service.available_days:
            days_map = {
                "MON": "Jumatatu", "TUE": "Jumanne", "WED": "Jumatano",
                "THU": "Alhamisi", "FRI": "Ijumaa", "SAT": "Jumamosi", "SUN": "Jumapili"
            }
            days_str = ", ".join([days_map.get(d, d) for d in service.available_days])
            message += f"Siku: {days_str}\n"
        if service.start_time and service.end_time:
            message += f"Muda: {service.start_time.strftime('%H:%M')} - {service.end_time.strftime('%H:%M')}\n"

        # Tuma kwa users wote (isipokuwa admins)
        users = User.objects.filter(is_active=True).exclude(is_staff=True)
        count = 0
        for user in users:
            try:
                Notification.objects.create(
                    recipient=user,
                    notification_type="SERVICE",
                    title=title,
                    message=message,
                    is_sent=True,
                    sent_at=timezone.now(),
                    metadata={"service_id": service.id, "action": action},
                )
                count += 1
            except Exception:
                pass
        return count
    except Exception as e:
        print(f"[NOTIFY SERVICE ERROR] {e}")
        return 0


class ServiceViewSet(viewsets.ModelViewSet):
    queryset = Service.objects.all().select_related('category')
    serializer_class = ServiceSerializer
    permission_classes = [IsAdminOrReadOnly]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def perform_create(self, serializer):
        service = serializer.save()
        # Notify users wote
        _notify_all_users(service, action="created")

    def perform_update(self, serializer):
        service = serializer.save()
        _notify_all_users(service, action="updated")

    def perform_destroy(self, instance):
        # Notify kabla ya kufuta
        _notify_all_users(instance, action="deleted")
        instance.delete()


    @action(detail=True, methods=['post'], url_path='notify-all')
    def notify_all(self, request, pk=None):
        """Admin - tuma notification kwa users wote kuhusu service hii."""
        service = self.get_object()
        count = _notify_all_users(service, action="updated")
        return Response({
            "success": True,
            "message": f"Notification imetumwa kwa users {count}",
            "data": {"sent_count": count},
        })
