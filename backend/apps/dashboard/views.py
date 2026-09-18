from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAdminUser
from django.contrib.auth import get_user_model
from apps.mechanics.models import MechanicProfile
from apps.bookings.models import Booking
from apps.spare_parts.models import SparePart
from apps.payments.models import Payment
from django.db.models import Sum

User = get_user_model()

class AdminStatsView(APIView):
    permission_classes = [IsAdminUser]
    def get(self, request):
        stats = {
            'users': User.objects.count(),
            'mechanics': MechanicProfile.objects.count(),
            'bookings': Booking.objects.count(),
            'spare_parts': SparePart.objects.count(),
            'revenue': str(Payment.objects.filter(status='success').aggregate(total=Sum('amount'))['total'] or 0),
        }
        return Response(stats)
