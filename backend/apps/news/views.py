from rest_framework import viewsets, permissions
from .models import News
from .serializers import NewsSerializer

class NewsViewSet(viewsets.ModelViewSet):
    queryset = News.objects.all().order_by('-created_at')[:5]
    serializer_class = NewsSerializer
    permission_classes = [permissions.AllowAny]
