from django.utils import timezone
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAdminUser
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import ContactMessage, ContactStatus
from .serializers import (
    ContactMessageCreateSerializer,
    ContactMessageSerializer,
)


class ContactCreateView(APIView):
    """Public - mtu yeyote anaweza kutuma ujumbe."""
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = ContactMessageCreateSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(
                {"success": False, "errors": serializer.errors},
                status=status.HTTP_400_BAD_REQUEST,
            )
        contact = serializer.save()
        if request.user and request.user.is_authenticated:
            contact.user = request.user
            contact.save(update_fields=["user"])
        return Response(
            {
                "success": True,
                "message": "Ujumbe wako umepokelewa. Tutawasiliana nawe hivi karibuni.",
                "data": {"id": contact.id},
            },
            status=status.HTTP_201_CREATED,
        )


class AdminContactListView(APIView):
    """Admin - kuona messages zote."""
    permission_classes = [IsAdminUser]

    def get(self, request):
        qs = ContactMessage.objects.all().order_by("-created_at")
        status_filter = request.query_params.get("status")
        if status_filter:
            qs = qs.filter(status=status_filter.upper())
        data = ContactMessageSerializer(qs[:200], many=True).data
        return Response({
            "success": True,
            "count": qs.count(),
            "data": data,
        })


class AdminContactReplyView(APIView):
    """Admin - kujibu message."""
    permission_classes = [IsAdminUser]

    def post(self, request, pk):
        try:
            msg = ContactMessage.objects.get(pk=pk)
        except ContactMessage.DoesNotExist:
            return Response(
                {"success": False, "message": "Message haipo"},
                status=status.HTTP_404_NOT_FOUND,
            )
        reply = (request.data.get("reply") or "").strip()
        if not reply:
            return Response(
                {"success": False, "message": "Reply ni lazima"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        msg.admin_reply = reply
        msg.status = ContactStatus.REPLIED
        msg.replied_at = timezone.now()
        msg.replied_by = request.user
        msg.save()
        return Response({
            "success": True,
            "message": "Reply imehifadhiwa",
            "data": ContactMessageSerializer(msg).data,
        })


class AdminContactDeleteView(APIView):
    """Admin - kufuta message baada ya kuisoma."""
    permission_classes = [IsAdminUser]

    def delete(self, request, pk):
        try:
            msg = ContactMessage.objects.get(pk=pk)
        except ContactMessage.DoesNotExist:
            return Response(
                {"success": False, "message": "Message haipo"},
                status=status.HTTP_404_NOT_FOUND,
            )
        msg.delete()
        return Response({
            "success": True,
            "message": "Message imefutwa",
        })
