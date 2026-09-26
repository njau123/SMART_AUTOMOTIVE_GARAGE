"""
Admin Mechanics Management — Create (with ME-XXXX), List, Update, Delete.
"""
from django.db import transaction
from django.utils import timezone
from rest_framework import status
from rest_framework.permissions import IsAdminUser
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.models import User
from apps.mechanics.models import MechanicProfile


# ==================== HELPER ====================
def _generate_me_number():
    """Tengeneza ME-XXXX (mfano ME-1024)."""
    import random
    for _ in range(100):
        num = random.randint(1000, 9999)
        reg = f"ME-{num}"
        # Angalia kama ipo kwenye verification_documents
        exists = MechanicProfile.objects.filter(
            verification_documents__registration_number=reg
        ).exists()
        if not exists:
            return reg
    # Kama zote zimejaa, tumia timestamp
    import time
    return f"ME-{int(time.time()) % 10000}"


# ==================== VIEWS ====================
class AdminMechanicCreateView(APIView):
    """Admin — kuunda mechanic (pre-registration) bila password."""
    permission_classes = [IsAdminUser]

    def post(self, request):
        data = request.data
        full_name = (data.get('full_name') or '').strip()
        phone = (data.get('phone') or '').strip()
        specialist = (data.get('specialist') or '').strip()
        region = (data.get('region') or '').strip()

        # Validation
        if not full_name or not phone or not specialist or not region:
            return Response(
                {'success': False, 'message': 'full_name, phone, specialist, na region ni lazima'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Angalia kama phone imetumika
        if User.objects.filter(phone_number=phone).exists():
            return Response(
                {'success': False, 'message': f'Namba {phone} imetumika'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Reg number
        reg_number = (data.get('registration_number') or '').strip()
        if not reg_number:
            reg_number = _generate_me_number()
        if not reg_number.startswith('ME-'):
            return Response(
                {'success': False, 'message': 'Registration number lazima ianze na ME-'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        # Angalia kama reg number imetumika
        if MechanicProfile.objects.filter(
            verification_documents__registration_number=reg_number
        ).exists():
            return Response(
                {'success': False, 'message': f'{reg_number} imetumika'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Unda User (placeholder email — mechanic ata-update wakati wa signup)
        import uuid
        placeholder_email = f"mech_{uuid.uuid4().hex[:10]}@pending.automotivegarage.com"

        name_parts = full_name.split()
        with transaction.atomic():
            user = User.objects.create_user(
                email=placeholder_email,
                password=None,  # ← hana password hadi atakapo-activate
                first_name=name_parts[0] if name_parts else '',
                last_name=' '.join(name_parts[1:]) if len(name_parts) > 1 else '',
                phone_number=phone,
                role='MECHANIC',
                is_active=False,  # ← hawezi ku-login hadi a-activate
            )
            user.set_unusable_password()
            user.save()

            profile = MechanicProfile.objects.create(
                user=user,
                business_name=full_name,
                professional_title=specialist,
                expertise=specialist,
                specialties=[specialist],
                region=region,
                district=data.get('district', ''),
                is_verified=True,
                verification_documents={
                    'registration_number': reg_number,
                    'created_by_admin': request.user.email,
                },
                is_active=False,
            )

        return Response({
            'success': True,
            'message': f'Mechanic "{full_name}" ameundwa kama {reg_number}',
            'data': {
                'user_id': user.id,
                'mechanic_id': profile.id,
                'registration_number': reg_number,
                'full_name': full_name,
                'phone': phone,
                'specialist': specialist,
                'region': region,
            },
        }, status=status.HTTP_201_CREATED)


class AdminMechanicDeleteView(APIView):
    """Admin — kufuta mechanic."""
    permission_classes = [IsAdminUser]

    def delete(self, request, pk):
        try:
            profile = MechanicProfile.objects.select_related('user').get(pk=pk)
        except MechanicProfile.DoesNotExist:
            return Response(
                {'success': False, 'message': 'Mechanic haipo'},
                status=status.HTTP_404_NOT_FOUND,
            )
        name = profile.business_name
        user = profile.user
        profile.delete()
        user.delete()
        return Response({
            'success': True,
            'message': f'Mechanic "{name}" amefutwa',
        })


# ==================== REGION CHANGE REQUESTS ====================
class AdminMechanicRegionChangeListView(APIView):
    """Admin — ona region change requests zote (pending)."""
    permission_classes = [IsAdminUser]

    def get(self, request):
        profiles = MechanicProfile.objects.select_related('user').all()
        pending = []
        for p in profiles:
            docs = p.verification_documents or {}
            if isinstance(docs, dict) and docs.get('pending_region'):
                reg_no = docs.get('registration_number', '')
                pending.append({
                    'mechanic_id': p.id,
                    'user_id': p.user.id,
                    'full_name': p.business_name or p.user.get_full_name(),
                    'email': p.user.email,
                    'phone_number': p.user.phone_number,
                    'registration_number': reg_no,
                    'current_region': p.region,
                    'pending_region': docs.get('pending_region'),
                    'requested_at': docs.get('region_change_requested_at', ''),
                })
        return Response({'success': True, 'data': pending})


class AdminMechanicRegionChangeApproveView(APIView):
    """Admin — approve region change."""
    permission_classes = [IsAdminUser]

    def post(self, request, pk):
        try:
            profile = MechanicProfile.objects.select_related('user').get(pk=pk)
        except MechanicProfile.DoesNotExist:
            return Response(
                {'success': False, 'message': 'Mechanic haipo'},
                status=status.HTTP_404_NOT_FOUND,
            )

        docs = dict(profile.verification_documents or {})
        pending_region = docs.get('pending_region')
        if not pending_region:
            return Response(
                {'success': False, 'message': 'Hakuna region change request'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        old_region = profile.region
        profile.region = pending_region
        docs.pop('pending_region', None)
        docs.pop('region_change_requested_at', None)
        docs['region_change_approved_at'] = timezone.now().isoformat()
        docs['region_change_approved_by'] = request.user.email
        profile.verification_documents = docs
        profile.save(update_fields=['region', 'verification_documents'])

        return Response({
            'success': True,
            'message': f'Region imebadilishwa: {old_region} → {pending_region}',
            'data': {'old_region': old_region, 'new_region': pending_region},
        })


class AdminMechanicRegionChangeRejectView(APIView):
    """Admin — reject region change."""
    permission_classes = [IsAdminUser]

    def post(self, request, pk):
        try:
            profile = MechanicProfile.objects.select_related('user').get(pk=pk)
        except MechanicProfile.DoesNotExist:
            return Response(
                {'success': False, 'message': 'Mechanic haipo'},
                status=status.HTTP_404_NOT_FOUND,
            )

        docs = dict(profile.verification_documents or {})
        rejected = docs.pop('pending_region', None)
        docs.pop('region_change_requested_at', None)
        docs['region_change_rejected_at'] = timezone.now().isoformat()
        docs['region_change_rejected_by'] = request.user.email
        profile.verification_documents = docs
        profile.save(update_fields=['verification_documents'])

        return Response({
            'success': True,
            'message': f'Region change imekataliwa ({rejected})',
            'data': {'rejected_region': rejected},
        })
