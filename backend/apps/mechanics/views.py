from django.db import transaction
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated, IsAdminUser, AllowAny
from rest_framework.response import Response
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import get_user_model
from django.utils import timezone
from .models import MechanicProfile

User = get_user_model()

PENDING_DOMAIN = '@pending.automotivegarage.com'


def _make_tokens(user):
    """Tengeneza JWT tokens za kuingia."""
    refresh = RefreshToken.for_user(user)
    return {'refresh': str(refresh), 'access': str(refresh.access_token)}


# ==================== MECHANIC ACTIVATION ====================
class MechanicActivateView(APIView):
    """
    Mechanic ana-activate account yake (admin-created).
    Input: registration_number, full_name, phone, email, password
    """
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        data = request.data
        reg_no = (data.get('registration_number') or '').strip().upper()
        full_name = (data.get('full_name') or '').strip()
        phone = (data.get('phone') or '').strip()
        email = (data.get('email') or '').strip().lower()
        password = data.get('password') or ''
        # Region confirm — mechanic anaweza kubadilisha
        new_region = (data.get('region') or '').strip()
        region_confirmed = data.get('region_confirmed', False)

        # Validation
        if not all([reg_no, full_name, phone, email, password]):
            return Response(
                {'success': False, 'message': 'Sehemu zote ni lazima'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if not reg_no.startswith('ME-'):
            return Response(
                {'success': False, 'message': 'Registration number lazima ianze na ME-'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if len(password) < 6:
            return Response(
                {'success': False, 'message': 'Password lazima iwe herufi 6 au zaidi'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Find profile by reg number
        profile = MechanicProfile.objects.select_related('user').filter(
            verification_documents__registration_number=reg_no
        ).first()
        if not profile:
            return Response(
                {'success': False, 'message': f'Namba {reg_no} haipo kwenye mfumo. Wasiliana na admin.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        user = profile.user

        # Check kama imesha-activate
        if user.email and not user.email.endswith(PENDING_DOMAIN):
            return Response(
                {'success': False, 'message': 'Akaunti hii imesha-activate. Tafadhali ingia.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Verify phone
        if (user.phone_number or '').strip() != phone:
            return Response(
                {'success': False, 'message': 'Namba ya simu haifanani na iliyosajiliwa'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Verify name (case-insensitive, whitespace-normalized)
        stored = ' '.join((profile.business_name or '').split()).lower()
        given = ' '.join(full_name.split()).lower()
        if stored != given:
            return Response(
                {'success': False, 'message': 'Jina halifanani na lililosajiliwa'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Check email haijatumika
        if User.objects.filter(email=email).exclude(id=user.id).exists():
            return Response(
                {'success': False, 'message': 'Email hii imetumika. Tumia nyingine.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Activate
        with transaction.atomic():
            user.email = email
            user.set_password(password)
            user.is_active = True
            user.plain_password = password  # Kwa admin viewing
            user.save(update_fields=['email', 'password', 'is_active', 'plain_password'])

            # Handle region — kama new_region tofauti na iliyopo, weka kama pending
            if new_region and new_region != profile.region:
                # Weka pending_region kwa admin approval
                docs = dict(profile.verification_documents or {})
                docs['pending_region'] = new_region
                docs['region_change_requested_at'] = timezone.now().isoformat()
                profile.verification_documents = docs
                profile.save(update_fields=['verification_documents'])
                # Notify admin (baadaye tutaongeza)
                print(f"[REGION CHANGE] {full_name}: {profile.region} → {new_region}")

            profile.is_active = True
            profile.save(update_fields=['is_active'])

        tokens = _make_tokens(user)

        return Response({
            'success': True,
            'message': f'Karibu {full_name}! Akaunti yako ime-activate.',
            'data': {
                'user_id': user.id,
                'registration_number': reg_no,
                'email': email,
                'role': 'MECHANIC',
                **tokens,
            },
        }, status=status.HTTP_201_CREATED)


# ==================== MECHANIC LOGIN ====================
class MechanicLoginView(APIView):
    """
    Mechanic ana-login kwa ME-XXXX au email + password.
    Returns: {success, data: {access, refresh, user}}
    """
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        identifier = (
            request.data.get('identifier')
            or request.data.get('registration_number')
            or request.data.get('email')
            or ''
        ).strip()
        password = request.data.get('password') or ''

        if not identifier or not password:
            return Response(
                {'success': False, 'message': 'ME number / email na password ni lazima'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Find user
        user = None
        if identifier.upper().startswith('ME-'):
            profile = MechanicProfile.objects.select_related('user').filter(
                verification_documents__registration_number=identifier.upper()
            ).first()
            if profile:
                user = profile.user
        else:
            user = User.objects.filter(email__iexact=identifier).first()

        if not user or not user.check_password(password):
            return Response(
                {'success': False, 'message': 'Namba au password si sahihi'},
                status=status.HTTP_401_UNAUTHORIZED,
            )

        if not user.is_active:
            return Response(
                {'success': False, 'message': 'Akaunti haija-activate. Tafadhali jisajili kwanza.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        if user.role != 'MECHANIC':
            return Response(
                {'success': False, 'message': 'Akaunti hii si ya mechanic'},
                status=status.HTTP_403_FORBIDDEN,
            )

        tokens = _make_tokens(user)
        profile = getattr(user, 'mechanic_profile', None)
        reg_no = ''
        if profile and isinstance(profile.verification_documents, dict):
            reg_no = profile.verification_documents.get('registration_number', '')

        return Response({
            'success': True,
            'message': 'Karibu tena!',
            'data': {
                'access': tokens['access'],
                'refresh': tokens['refresh'],
                'user': {
                    'id': user.id,
                    'email': user.email,
                    'first_name': user.first_name,
                    'last_name': user.last_name,
                    'phone_number': user.phone_number,
                    'role': user.role,
                    'registration_number': reg_no,
                    'specialist': profile.expertise if profile else '',
                    'region': profile.region if profile else '',
                    'is_available': profile.is_available if profile else False,
                    'profile_image': profile.profile_image.url if profile and profile.profile_image else None,
                },
            },
        })


# ==================== MECHANIC PROFILE ====================
class MechanicProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            profile = MechanicProfile.objects.get(user=request.user)
        except MechanicProfile.DoesNotExist:
            return Response({'error': 'Profile not found'}, status=404)

        reg_no = ''
        if isinstance(profile.verification_documents, dict):
            reg_no = profile.verification_documents.get('registration_number', '')

        return Response({
            'id': profile.id,
            'business_name': profile.business_name,
            'registration_number': reg_no,
            'professional_title': profile.professional_title,
            'expertise': profile.expertise,
            'specialties': profile.specialties,
            'region': profile.region,
            'district': profile.district,
            'rating': float(profile.rating) if profile.rating else 0,
            'review_count': profile.review_count,
            'is_available': profile.is_available,
            'is_active': profile.is_active,
            'profile_image': profile.profile_image.url if profile.profile_image else None,
        })


# ==================== ADMIN ====================
@api_view(['GET'])
@permission_classes([IsAdminUser])
def admin_mechanics(request):
    profiles = MechanicProfile.objects.select_related('user').all()
    data = []
    for p in profiles:
        reg_no = ''
        if isinstance(p.verification_documents, dict):
            reg_no = p.verification_documents.get('registration_number', '')
        data.append({
            'id': p.id,
            'user_id': p.user.id,
            'full_name': p.business_name or p.user.get_full_name() or p.user.email,
            'email': p.user.email,
            'phone_number': p.user.phone_number,
            'registration_number': reg_no,
            'business_name': p.business_name,
            'professional_title': p.professional_title,
            'expertise': p.expertise,
            'specialties': p.specialties,
            'region': p.region,
            'district': p.district,
            'is_available': p.is_available,
            'is_active': p.is_active,
            'is_verified': p.is_verified,
            'rating': float(p.rating) if p.rating else 0,
        })
    return Response({'success': True, 'data': data})


@api_view(['POST'])
@permission_classes([IsAdminUser])
def toggle_mechanic(request, mechanic_id):
    try:
        profile = MechanicProfile.objects.get(id=mechanic_id)
    except MechanicProfile.DoesNotExist:
        return Response({'error': 'Not found'}, status=404)

    available = request.data.get('available', not profile.is_available)
    profile.is_available = bool(available)
    profile.save(update_fields=['is_available'])

    return Response({
        'success': True,
        'message': 'Availability updated',
        'is_available': profile.is_available,
    })


# ==================== LEGACY (kwa backward compat) ====================
class RegisterMechanicView(APIView):
    """Legacy - tumia MechanicActivateView badala yake."""
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        return Response(
            {'success': False, 'message': 'Tumia /api/v1/mechanics/activate/ badala yake'},
            status=status.HTTP_410_GONE,
        )


# ==================== TOGGLE AVAILABILITY ====================
class ToggleAvailabilityView(APIView):
    """Mechanic ana-toggle is_available (online/offline)."""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            profile = MechanicProfile.objects.get(user=request.user)
        except MechanicProfile.DoesNotExist:
            return Response(
                {'success': False, 'message': 'Mechanic profile haipo'},
                status=status.HTTP_404_NOT_FOUND,
            )

        # Kama value imetumwa, tumia hiyo. La sivyo, toggle.
        if 'is_available' in request.data:
            new_value = bool(request.data.get('is_available'))
        else:
            new_value = not profile.is_available

        profile.is_available = new_value
        profile.save(update_fields=['is_available'])

        return Response({
            'success': True,
            'message': f'Sasa uko {"ONLINE" if new_value else "OFFLINE"}',
            'data': {
                'is_available': profile.is_available,
            },
        })


class MyAssignedJobsView(APIView):
    """Mechanic — kazi zake (assigned)."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        from apps.bookings.models import Booking
        from apps.bookings.serializers import BookingSerializer

        try:
            profile = MechanicProfile.objects.get(user=request.user)
        except MechanicProfile.DoesNotExist:
            return Response(
                {'success': False, 'message': 'Mechanic haipo'},
                status=status.HTTP_404_NOT_FOUND,
            )

        qs = Booking.objects.filter(mechanic=profile).order_by('-created_at')
        return Response({
            'success': True,
            'count': qs.count(),
            'data': BookingSerializer(qs, many=True).data,
        })

# ==================== FORGOT PASSWORD (ME + Phone) ====================
class MechanicResetPasswordView(APIView):
    """
    Mechanic ana-reset password.
    Input: registration_number (ME-XXXX), phone, new_password
    Validation: ME + phone lazima zilingane na admin-created record.
    """
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        reg_no = (request.data.get('registration_number') or '').strip().upper()
        phone = (request.data.get('phone') or '').strip()
        new_password = request.data.get('new_password') or ''

        # Validation
        if not all([reg_no, phone, new_password]):
            return Response(
                {'success': False, 'message': 'ME number, phone, na password mpya ni lazima'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if not reg_no.startswith('ME-'):
            return Response(
                {'success': False, 'message': 'Registration number lazima ianze na ME-'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if len(new_password) < 6:
            return Response(
                {'success': False, 'message': 'Password mpya lazima iwe herufi 6 au zaidi'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Find profile by ME number
        profile = MechanicProfile.objects.select_related('user').filter(
            verification_documents__registration_number=reg_no
        ).first()
        if not profile:
            return Response(
                {'success': False, 'message': f'Namba {reg_no} haipo kwenye mfumo'},
                status=status.HTTP_404_NOT_FOUND,
            )

        # Verify phone
        if (profile.user.phone_number or '').strip() != phone:
            return Response(
                {'success': False, 'message': 'Namba ya simu haifanani na iliyosajiliwa'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Check kama user amesha-activate
        if profile.user.email and profile.user.email.endswith(PENDING_DOMAIN):
            return Response(
                {'success': False, 'message': 'Akaunti haija-activate. Tumia "Activate" kwanza.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Update password
        with transaction.atomic():
            profile.user.set_password(new_password)
            profile.user.save(update_fields=['password'])

        return Response({
            'success': True,
            'message': 'Password yako imebadilishwa. Unaweza kuingia sasa.',
        })
