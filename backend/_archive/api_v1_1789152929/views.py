from rest_framework import generics, permissions
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .serializers import UserSerializer, UserProfileSerializer, MechanicProfileSerializer
from apps.mechanics.models import MechanicProfile
from django.contrib.auth import get_user_model

User = get_user_model()

class RegisterView(generics.CreateAPIView):
    serializer_class = UserSerializer
    permission_classes = [permissions.AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response({
            "message": "Registration successful! You may continue to login.",
            "user": UserSerializer(user).data
        })

class UserProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        serializer = UserProfileSerializer(request.user)
        return Response(serializer.data)

class MechanicProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            mechanic = MechanicProfile.objects.get(user=request.user)
            serializer = MechanicProfileSerializer(mechanic)
            return Response(serializer.data)
        except MechanicProfile.DoesNotExist:
            return Response({"detail": "You are not registered as a mechanic."}, status=404)

class MechanicListView(generics.ListAPIView):
    queryset = MechanicProfile.objects.filter(is_available=True)
    serializer_class = MechanicProfileSerializer
    permission_classes = [IsAuthenticated]
