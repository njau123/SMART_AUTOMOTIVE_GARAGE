from rest_framework import viewsets, permissions
from api.permissions import IsAdminOrReadOnly
from .models import News
from .serializers import NewsSerializer


class NewsViewSet(viewsets.ModelViewSet):
    queryset = News.objects.all().order_by('-created_at')
    serializer_class = NewsSerializer
    permission_classes = [IsAdminOrReadOnly]
