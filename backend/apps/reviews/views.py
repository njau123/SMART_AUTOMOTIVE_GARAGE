from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import Review

class MechanicReviewsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        reviews = Review.objects.filter(mechanic=request.user).order_by('-created_at')
        data = [
            {
                'id': r.id,
                'rating': r.rating,
                'comment': r.comment,
                'reviewer': r.reviewer.get_full_name() if r.reviewer else 'Anonymous',
                'created_at': r.created_at,
            }
            for r in reviews
        ]
        return Response(data)
