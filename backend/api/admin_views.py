"""
Admin-only endpoints for Smart Automotive Garage.
"""
import uuid
from django.contrib.auth import get_user_model
from django.db.models import Sum, Count
from django.utils import timezone
from django.utils.text import slugify
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAdminUser
from rest_framework import status

from apps.advertisements.models import Advertisement
from apps.news.models import News, NewsCategory
from apps.services.models import Service, ServiceCategory
from apps.spare_parts.models import SparePart, Category as SpareCat, Brand
from apps.mechanics.models import MechanicProfile
from apps.bookings.models import Booking
from apps.payments.models import Payment

User = get_user_model()


class AdminCheckView(APIView):
    """Returns info about current user - kama ni admin."""
    permission_classes = [IsAdminUser]

    def get(self, request):
        return Response({
            'success': True,
            'is_admin': True,
            'user': {
                'id': request.user.id,
                'email': request.user.email,
                'first_name': request.user.first_name,
                'last_name': request.user.last_name,
                'full_name': getattr(request.user, 'full_name', '') or request.user.email,
                'role': getattr(request.user, 'role', 'USER'),
                'is_superuser': request.user.is_superuser,
            },
        })


class AdminStatsView(APIView):
    permission_classes = [IsAdminUser]

    def get(self, request):
        total_users = User.objects.count()
        total_mechanics = MechanicProfile.objects.count()
        total_bookings = Booking.objects.count()
        total_spare_parts = SparePart.objects.count()
        total_services = Service.objects.count()
        total_news = News.objects.count()
        total_ads = Advertisement.objects.count()

        revenue = (
            Payment.objects.filter(status__in=['COMPLETED', 'SUCCESS'])
            .aggregate(total=Sum('amount'))['total'] or 0
        )

        recent_users = list(
            User.objects.order_by('-created_at').values(
                'id', 'email', 'first_name', 'last_name', 'created_at'
            )[:5]
        )

        return Response({
            'success': True,
            'data': {
                'total_users': total_users,
                'total_mechanics': total_mechanics,
                'total_bookings': total_bookings,
                'total_spare_parts': total_spare_parts,
                'total_services': total_services,
                'total_news': total_news,
                'total_ads': total_ads,
                'total_revenue': float(revenue),
                'recent_users': recent_users,
            },
        })


class AdminAdvertisementFullCreateView(APIView):
    permission_classes = [IsAdminUser]

    def post(self, request):
        data = request.data
        title = (data.get('title') or '').strip()
        description = (data.get('description') or '').strip()
        ad_type = data.get('advertisement_type', 'BANNER')
        target_url = (data.get('target_url') or '').strip()

        if not title:
            return Response(
                {'success': False, 'message': 'Title is required'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        ad = Advertisement.objects.create(
            reference=f"AD-{uuid.uuid4().hex[:8].upper()}",
            title=title,
            description=description,
            advertisement_type=ad_type,
            target_url=target_url,
            status='active',
            is_active=True,
            start_at=timezone.now(),
            end_at=timezone.now() + timezone.timedelta(days=90),
            created_by=request.user,
        )

        if 'image' in request.FILES:
            ad.image = request.FILES['image']
        if 'video' in request.FILES:
            ad.video = request.FILES['video']
        ad.save()

        return Response({
            'success': True,
            'message': 'Advertisement created',
            'data': {
                'id': ad.id,
                'reference': ad.reference,
                'title': ad.title,
                'has_image': bool(ad.image),
                'has_video': bool(ad.video),
            },
        }, status=status.HTTP_201_CREATED)


class AdminNewsFullCreateView(APIView):
    permission_classes = [IsAdminUser]

    def post(self, request):
        data = request.data
        title = (data.get('title') or '').strip()
        content = (data.get('content') or '').strip()
        summary = (data.get('summary') or content[:200]).strip()
        video_url = (data.get('video_url') or '').strip()

        if not title or not content:
            return Response(
                {'success': False, 'message': 'Title and content are required'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        news = News.objects.create(
            title=title,
            slug=slugify(title)[:50] + '-' + str(int(timezone.now().timestamp())),
            summary=summary,
            content=content,
            author=request.user,
            status='published',
            published_at=timezone.now(),
            video_url=video_url if video_url else None,
        )

        if 'featured_image' in request.FILES:
            news.featured_image = request.FILES['featured_image']
        if 'video_file' in request.FILES:
            news.video_file = request.FILES['video_file']
        news.save()

        try:
            from apps.notifications.services import send_notification_to_all_users
            send_notification_to_all_users(
                title=f'New: {title}',
                body=summary[:100],
                notification_type='news',
            )
        except Exception:
            pass

        return Response({
            'success': True,
            'message': 'News created and users notified',
            'data': {'id': news.id, 'title': news.title},
        }, status=status.HTTP_201_CREATED)


class AdminNotificationSendView(APIView):
    permission_classes = [IsAdminUser]

    def post(self, request):
        title = (request.data.get('title') or '').strip()
        message = (request.data.get('message') or '').strip()

        if not title or not message:
            return Response(
                {'success': False, 'message': 'Title and message are required'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            from apps.notifications.services import send_notification_to_all_users
            result = send_notification_to_all_users(
                title=title,
                message=message,
                notification_type='SYSTEM',
            )
            # result ni list ya Notification objects - hatuwezi kuserialize
            # Tunatumia count tu
            sent_count = len(result) if isinstance(result, list) else 0
            return Response({
                'success': True,
                'message': f'Notification sent to {sent_count} users',
                'data': {'sent_count': sent_count},
            })
        except Exception as e:
            import traceback
            traceback.print_exc()
            return Response({
                'success': True,
                'message': f'Saved (push failed: {e})',
                'data': {'sent_count': 0, 'error': str(e)},
            }, status=200)


class AdminMechanicsListView(APIView):
    permission_classes = [IsAdminUser]

    def get(self, request):
        mechanics = MechanicProfile.objects.select_related('user').all()
        data = []
        for m in mechanics:
            data.append({
                'id': m.id,
                'user_id': m.user.id,
                'full_name': (m.user.full_name or m.user.email),
                'email': m.user.email,
                'phone_number': m.user.phone_number,
                'business_name': m.business_name,
                'expertise': m.expertise,
                'is_available': m.is_available,
            })
        return Response({'success': True, 'data': data})


class AdminMechanicToggleView(APIView):
    permission_classes = [IsAdminUser]

    def post(self, request, mechanic_id):
        try:
            m = MechanicProfile.objects.get(id=mechanic_id)
        except MechanicProfile.DoesNotExist:
            return Response(
                {'success': False, 'message': 'Mechanic not found'},
                status=status.HTTP_404_NOT_FOUND,
            )

        m.is_available = not m.is_available
        m.save()

        return Response({
            'success': True,
            'message': f'Mechanic is now {"available" if m.is_available else "unavailable"}',
            'data': {'id': m.id, 'is_available': m.is_available},
        })


class AdminUsersListView(APIView):
    permission_classes = [IsAdminUser]

    def get(self, request):
        users = User.objects.order_by('-created_at').values(
            'id', 'email', 'first_name', 'last_name',
            'phone_number', 'role', 'is_active', 'created_at',
        )[:100]
        return Response({'success': True, 'data': list(users)})


class AdminPaymentListView(APIView):
    permission_classes = [IsAdminUser]

    def get(self, request):
        payments = Payment.objects.select_related('user').order_by('-created_at')[:100]
        data = []
        for p in payments:
            data.append({
                'id': p.id,
                'reference': p.reference,
                'user_email': p.user.email if p.user else None,
                'user_name': (p.user.full_name if p.user and p.user.full_name else (p.user.email if p.user else None)),
                'amount': float(p.amount) if p.amount else 0,
                'currency': p.currency,
                'provider': p.provider,
                'status': p.status,
                'purpose': p.purpose,
                'phone_number': p.phone_number,
                'created_at': p.created_at.isoformat() if p.created_at else None,
            })
        return Response({'success': True, 'data': data})


class AdminPaymentVerifyView(APIView):
    permission_classes = [IsAdminUser]

    def post(self, request, payment_id):
        try:
            p = Payment.objects.get(id=payment_id)
        except Payment.DoesNotExist:
            return Response(
                {'success': False, 'message': 'Payment not found'},
                status=status.HTTP_404_NOT_FOUND,
            )

        p.status = 'COMPLETED'
        p.completed_at = timezone.now()
        p.save()

        try:
            from apps.notifications.services import send_notification_to_user
            send_notification_to_user(
                user=p.user,
                title='Payment Confirmed',
                body=f'Malipo yako ya TSh {p.amount} yamethibitishwa. Asante!',
                notification_type='payment',
            )
        except Exception:
            pass

        return Response({
            'success': True,
            'message': f'Payment {p.reference} marked as completed',
            'data': {'id': p.id, 'status': p.status},
        })


class AdminBookingsListView(APIView):
    permission_classes = [IsAdminUser]

    def get(self, request):
        bookings = Booking.objects.select_related('customer', 'mechanic').order_by('-created_at')[:50]
        data = []
        for b in bookings:
            data.append({
                'id': b.id,
                'booking_number': getattr(b, 'booking_number', ''),
                'customer_email': b.customer.email if b.customer else None,
                'mechanic_name': (b.mechanic.user.full_name if b.mechanic and b.mechanic.user.full_name else None),
                'status': b.status,
                'created_at': b.created_at.isoformat() if b.created_at else None,
            })
        return Response({'success': True, 'data': data})


class AdminUserBlockView(APIView):
    """Admin - block/unblock user (hawezi ku-login)."""
    permission_classes = [IsAdminUser]

    def post(self, request, pk):
        try:
            user = User.objects.get(pk=pk)
        except User.DoesNotExist:
            return Response(
                {"success": False, "message": "User haipo"},
                status=status.HTTP_404_NOT_FOUND,
            )
        if user.role == 'ADMIN' or user.is_superuser:
            return Response(
                {"success": False, "message": "Hauwezi ku-block admin"},
                status=status.HTTP_403_FORBIDDEN,
            )
        action = (request.data.get("action") or "block").lower()
        if action == "block":
            user.is_active = False
            user.save(update_fields=["is_active"])
            msg = f"User {user.email} ameblock"
        elif action == "unblock":
            user.is_active = True
            user.save(update_fields=["is_active"])
            msg = f"User {user.email} amefunguliwa"
        else:
            return Response(
                {"success": False, "message": "Action si sahihi"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        return Response({
            "success": True,
            "message": msg,
            "data": {"id": user.id, "is_active": user.is_active},
        })


class AdminUserDeleteView(APIView):
    """Admin - delete user (soft delete — email isitumike tena)."""
    permission_classes = [IsAdminUser]

    def delete(self, request, pk):
        try:
            user = User.objects.get(pk=pk)
        except User.DoesNotExist:
            return Response(
                {"success": False, "message": "User haipo"},
                status=status.HTTP_404_NOT_FOUND,
            )
        if user.role == 'ADMIN' or user.is_superuser:
            return Response(
                {"success": False, "message": "Hauwezi kumfuta admin"},
                status=status.HTTP_403_FORBIDDEN,
            )
        # Soft delete — rename email ili isitumike tena
        original_email = user.email
        user.email = f"deleted_{user.id}_{original_email}"
        user.is_active = False
        user.save(update_fields=["email", "is_active"])
        return Response({
            "success": True,
            "message": f"User {original_email} amefutwa",
            "data": {"id": user.id},
        })
