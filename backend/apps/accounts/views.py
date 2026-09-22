from django.contrib.auth import get_user_model
from django.db import transaction
from rest_framework import viewsets
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.exceptions import AuthenticationFailed
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAdminUser, AllowAny
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.tokens import RefreshToken

User = get_user_model()


class EmailTokenObtainPairSerializer(TokenObtainPairSerializer):
    username_field = 'email'

    def validate(self, attrs):
        attrs['username'] = attrs.get('email')
        try:
            data = super().validate(attrs)
            # Ongeza user data kwenye response
            user = self.user
            data['user'] = {
                'id': user.id,
                'email': user.email,
                'first_name': user.first_name,
                'middle_name': getattr(user, 'middle_name', ''),
                'last_name': user.last_name,
                'phone_number': getattr(user, 'phone_number', ''),
                'role': getattr(user, 'role', 'USER'),
                'profile_image': user.profile_image.url if user.profile_image else None,
            }
            return {
                "success": True,
                "message": "Login successful",
                "data": data,
                "errors": None,
            }
        except Exception as e:
            raise AuthenticationFailed({
                "success": False,
                "message": "Credentials not found",
                "data": None,
                "errors": {
                    "detail": "No account found with the given credentials"
                },
            })

    def get_token(self, user):
        token = super().get_token(user)
        token['email'] = user.email
        token['role'] = getattr(user, 'role', 'USER')
        return token


class EmailTokenObtainPairView(TokenObtainPairView):
    serializer_class = EmailTokenObtainPairSerializer

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        try:
            serializer.is_valid(raise_exception=True)
        except Exception:
            return Response(
                {
                    "success": False,
                    "message": "Credentials not found",
                    "data": None,
                    "errors": {
                        "detail": "No account found with the given credentials"
                    },
                },
                status=status.HTTP_401_UNAUTHORIZED,
            )
        return Response(
            {
                "success": True,
                "message": "Login successful",
                "data": serializer.validated_data,
                "errors": None,
            },
            status=status.HTTP_200_OK,
        )


class RegisterView(APIView):
    permission_classes = [AllowAny]

    @transaction.atomic
    def post(self, request):
        data = request.data

        email = (data.get('email') or '').strip().lower()
        password = data.get('password') or ''
        first_name = (data.get('first_name') or '').strip()
        middle_name = (data.get('middle_name') or '').strip()
        last_name = (data.get('last_name') or '').strip()
        phone_number = (data.get('phone_number') or '').strip()

        errors = {}
        if not email:
            errors['email'] = 'Email is required'
        if not password or len(password) < 6:
            errors['password'] = 'Password must be at least 6 characters'
        if not first_name:
            errors['first_name'] = 'First name is required'
        if not last_name:
            errors['last_name'] = 'Last name is required'
        if not phone_number:
            errors['phone_number'] = 'Phone number is required'

        if errors:
            return Response(errors, status=status.HTTP_400_BAD_REQUEST)

        if User.objects.filter(email=email).exists():
            return Response(
                {'email': 'This email is already registered'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if User.objects.filter(phone_number=phone_number).exists():
            return Response(
                {'phone_number': 'This phone number is already registered'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user = User.objects.create_user(
            email=email,
            password=password,
            first_name=first_name,
            middle_name=middle_name,
            last_name=last_name,
            phone_number=phone_number,
            is_active=True,
        )

        # Vehicle (optional but recommended)
        vehicle_data = None
        v_make = (data.get('vehicle_make') or '').strip()
        v_model = (data.get('vehicle_model') or '').strip()
        v_registration = (data.get('vehicle_registration') or '').strip().upper()
        v_year = data.get('vehicle_year')

        if v_make and v_model and v_registration:
            try:
                from apps.vehicles.models import Vehicle
                vehicle = Vehicle.objects.create(
                    user=user,
                    make=v_make,
                    model=v_model,
                    year=int(v_year) if v_year else 2020,
                    registration_number=v_registration,
                    is_primary=True,
                    is_active=True,
                )
                vehicle_data = {
                    'id': vehicle.id,
                    'make': vehicle.make,
                    'model': vehicle.model,
                    'year': vehicle.year,
                    'registration_number': vehicle.registration_number,
                    'vehicle_image': (
                        request.build_absolute_uri(vehicle.vehicle_image.url)
                        if vehicle.vehicle_image else None
                    ),
                }
            except Exception as e:
                # Rollback won't happen (transaction) - but skip vehicle
                vehicle_data = {'error': str(e)}

        # Auto-create wallet
        try:
            from apps.wallet.models import Wallet
            Wallet.objects.get_or_create(user=user)
        except Exception:
            pass

        return Response(
            {
                'success': True,
                'message': 'Registration successful! You may continue to login.',
                'user_id': user.id,
                'user': {
                    'id': user.id,
                    'email': user.email,
                    'first_name': user.first_name,
                    'middle_name': user.middle_name,
                    'last_name': user.last_name,
                    'phone_number': user.phone_number,
                    'role': getattr(user, 'role', 'USER'),
                },
                'vehicle': vehicle_data,
            },
            status=status.HTTP_201_CREATED,
        )


@api_view(['POST'])
@permission_classes([AllowAny])
def google_sign_in(request):
    id_token = request.data.get('id_token')
    if not id_token:
        return Response({'error': 'id_token is required'}, status=400)

    try:
        from firebase_admin import auth as firebase_auth
        decoded = firebase_auth.verify_id_token(id_token)
        email = decoded.get('email')
        if not email:
            return Response({'error': 'No email in token'}, status=400)

        full_name = decoded.get('name', '') or ''
        parts = full_name.split(' ', 1)

        user, created = User.objects.get_or_create(
            email=email,
            defaults={
                'first_name': parts[0] if parts else '',
                'last_name': parts[1] if len(parts) > 1 else '',
                'firebase_uid': decoded.get('uid', ''),
                'is_active': True,
            },
        )

        refresh = RefreshToken.for_user(user)
        return Response({
            'success': True,
            'access': str(refresh.access_token),
            'refresh': str(refresh),
            'created': created,
            'user': {
                'id': user.id,
                'email': user.email,
                'first_name': user.first_name,
                'last_name': user.last_name,
                'role': getattr(user, 'role', 'USER'),
            },
        })
    except Exception as e:
        return Response({'error': str(e)}, status=401)


@api_view(['GET'])
@permission_classes([IsAdminUser])
def admin_users(request):
    users = User.objects.all().values(
        'id', 'email', 'first_name', 'last_name',
        'phone_number', 'is_active',
    )
    return Response(list(users))



# ==================== ADMIN USER MANAGEMENT ====================
from rest_framework import serializers as drf_serializers
from api.permissions import IsAdminOrReadOnly


class AdminUserSerializer(drf_serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            'id', 'email', 'first_name', 'middle_name', 'last_name',
            'phone_number', 'role', 'is_active', 'is_staff',
            'is_superuser', 'created_at', 'updated_at', 'last_login',
            'is_email_verified', 'is_phone_verified', 'profile_image'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'last_login']


class AdminUserViewSet(viewsets.ModelViewSet):
    """Admin CRUD kwa users."""
    queryset = User.objects.all().order_by('-created_at')
    serializer_class = AdminUserSerializer
    permission_classes = [IsAdminOrReadOnly]
    search_fields = ['email', 'first_name', 'last_name', 'phone_number']
    from rest_framework import filters as drf_filters
    filter_backends = [drf_filters.SearchFilter, drf_filters.OrderingFilter]
    ordering_fields = ['created_at', 'email', 'last_login']
