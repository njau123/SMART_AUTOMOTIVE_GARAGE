from rest_framework import serializers
from django.contrib.auth import get_user_model
from apps.mechanics.models import MechanicProfile

User = get_user_model()

class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ['id', 'email', 'first_name', 'last_name', 'phone_number', 'password']

    def create(self, validated_data):
        user = User.objects.create_user(
            email=validated_data['email'],
            password=validated_data['password'],
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', ''),
            phone_number=validated_data.get('phone_number', ''),
        )
        return user

class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'email', 'first_name', 'last_name', 'phone_number', 'role', 'created_at']
        read_only_fields = ['id', 'email', 'created_at']

class MechanicProfileSerializer(serializers.ModelSerializer):
    user = UserProfileSerializer(read_only=True)
    full_name = serializers.SerializerMethodField()

    class Meta:
        model = MechanicProfile
        fields = ['id', 'user', 'business_name', 'expertise', 'is_available',
                  'latitude', 'longitude', 'rating_average', 'total_reviews', 'full_name']

    def get_full_name(self, obj):
        return f"{obj.user.first_name} {obj.user.last_name}"
