from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .admin_views import (
    AdminCheckView,
    AdminStatsView,
    AdminAdvertisementFullCreateView,
    AdminNewsFullCreateView,
    AdminNotificationSendView,
    AdminMechanicsListView,
    AdminMechanicToggleView,
    AdminUsersListView,
    AdminUserBlockView,
    AdminUserDeleteView,
    AdminPaymentListView,
    AdminPaymentVerifyView,
    AdminBookingsListView,
)
from .admin_mechanic_views import (
    AdminMechanicCreateView,
    AdminMechanicDeleteView,
    AdminMechanicRegionChangeListView,
    AdminMechanicRegionChangeApproveView,
    AdminMechanicRegionChangeRejectView,
)
from .admin_spare_parts_views import (
    AdminSparePartListView,
    AdminSparePartCreateView,
    AdminSparePartUpdateView,
    AdminSparePartDeleteView,
)
from .password_reset_views import (
    RequestPasswordResetView,
    VerifyResetCodeView,
    ResetPasswordView,
)
from apps.news.views import NewsViewSet as NewNewsViewSet
from apps.advertisements.views import AdvertisementViewSet as NewAdvertisementViewSet
from apps.spare_parts.views import (
    OrderCreateView, OrderListView, OrderDetailView,
    OrderUpdateDeliveryView, OrderDeleteView,
    AdminOrderListView, AdminOrderUpdateStatusView,
)
from .views import (
    RegisterView, UserProfileView,
    VehicleViewSet,
    SparePartViewSet, BookingViewSet,
    PaymentViewSet,
    NewsViewSet, AdvertisementViewSet,
    DiagnosisSessionViewSet, DiagnosisHistoryViewSet,
    NotificationViewSet, NotificationDeviceViewSet,
    ChatRoomViewSet, MessageViewSet,
    TrackingSessionViewSet, VehicleLocationViewSet,
    MechanicLocationViewSet, GeofenceViewSet,
    ReviewListCreateView, ReviewDetailView,
    WalletDetailView, TransactionListView,
    MechanicListView,
    PasswordResetRequestView, PasswordResetVerifyView, PasswordResetConfirmView,
    GoogleLoginView,  # noqa: F401 (legacy, replaced by google_login_views)
    PaymentGatewayInitiateView, PaymentGatewayVerifyView
)
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from apps.services.views import ServiceViewSet as NewServiceViewSet, ServiceCategoryViewSet

# Chat views kutoka apps.chat (ina @action messages + mark_read)
from apps.chat.views import (
    ChatRoomViewSet as AppsChatRoomViewSet,
    MessageViewSet as AppsMessageViewSet,
    MessageAttachmentViewSet as AppsMessageAttachmentViewSet,
)

router = DefaultRouter()
router.register(r'vehicles', VehicleViewSet, basename='vehicle')
router.register(r'services', NewServiceViewSet, basename='service')
router.register(r'service-categories', ServiceCategoryViewSet, basename='service-category')
router.register(r'spare-parts', SparePartViewSet, basename='sparepart')
# router.register(r'bookings', BookingViewSet, basename='booking')  # replaced by apps.bookings.urls
router.register(r'payments', PaymentViewSet, basename='payment')
router.register(r'news', NewNewsViewSet, basename='news')
router.register(r'advertisements', NewAdvertisementViewSet, basename='advertisement')
router.register(r'diagnosis/scans', DiagnosisSessionViewSet, basename='diagnosis')
router.register(r'diagnosis/history', DiagnosisHistoryViewSet, basename='diagnosis-history')
router.register(r'notifications', NotificationViewSet, basename='notification')
router.register(r'notifications/devices', NotificationDeviceViewSet, basename='notification-device')
router.register(r'chat/rooms', AppsChatRoomViewSet, basename='chatroom')
router.register(r'chat/messages', AppsMessageViewSet, basename='chatmessage')
router.register(r'chat/attachments', AppsMessageAttachmentViewSet, basename='chatmessage-attachment')
router.register(r'tracking/sessions', TrackingSessionViewSet, basename='trackingsession')
router.register(r'tracking/vehicle-locations', VehicleLocationViewSet, basename='vehiclelocation')
router.register(r'tracking/mechanic-locations', MechanicLocationViewSet, basename='mechaniclocation')
router.register(r'tracking/geofences', GeofenceViewSet, basename='geofence')

urlpatterns = [
    path('users/profile/', UserProfileView.as_view(), name='user_profile'),
    path('reviews/', ReviewListCreateView.as_view(), name='review-list'),
    path('reviews/<int:pk>/', ReviewDetailView.as_view(), name='review-detail'),
    path('wallet/', WalletDetailView.as_view(), name='wallet-detail'),
    path('transactions/', TransactionListView.as_view(), name='transaction-list'),
    path('mechanics/', MechanicListView.as_view(), name='mechanic-list'),
    path('payments/gateway/initiate/', PaymentGatewayInitiateView.as_view(), name='payment-gateway-initiate'),
    path('payments/gateway/verify/', PaymentGatewayVerifyView.as_view(), name='payment-gateway-verify'),
]

urlpatterns += router.urls

# ============ AI DIAGNOSTIC ASSISTANT URL ============
from .views import ServiceDiagnosisView
urlpatterns += [
    path('diagnosis/service/', ServiceDiagnosisView.as_view(), name='service-diagnosis'),
]

# ============ OBD DIAGNOSIS PAYMENT URL ============
from .views import OBDPaymentInitiateView
urlpatterns += [
    path('diagnosis/obd-payment/initiate/', OBDPaymentInitiateView.as_view(), name='obd-payment-initiate'),
]

# ============ OBD SCAN WITH PAYMENT URL ============
from .views import DiagnosisSessionViewSet
obd_obd_scan = DiagnosisSessionViewSet.as_view({'post': 'obd_scan'})
urlpatterns += [
]


# ============ SPARE PARTS ORDER URLS ============
urlpatterns += [
    path('spare-parts/orders/create/', OrderCreateView.as_view(), name='order-create'),
    path('spare-parts/orders/my/', OrderListView.as_view(), name='order-list'),
    path('spare-parts/orders/<int:pk>/', OrderDetailView.as_view(), name='order-detail'),
    path('spare-parts/orders/<int:pk>/delivery/', OrderUpdateDeliveryView.as_view(), name='order-delivery'),
    path('spare-parts/orders/<int:pk>/delete/', OrderDeleteView.as_view(), name='order-delete'),
    path('spare-parts/admin/orders/all/', AdminOrderListView.as_view(), name='admin-order-list'),
    path('spare-parts/admin/orders/<int:pk>/status/', AdminOrderUpdateStatusView.as_view(), name='admin-order-status'),
]

# ============ CRON URLS ============
from .cron_views import expire_payments_cron
urlpatterns += [
    path('cron/expire-payments/', expire_payments_cron, name='cron-expire-payments'),
]

# ============ ADMIN URLS ============
urlpatterns += [
    path('admin/check/', AdminCheckView.as_view(), name='admin-check'),
    path('admin/stats/', AdminStatsView.as_view(), name='admin-stats'),
    path('admin/advertisements/create/', AdminAdvertisementFullCreateView.as_view()),
    path('admin/news/create/', AdminNewsFullCreateView.as_view()),
    path('admin/notifications/send/', AdminNotificationSendView.as_view()),
    path('admin/mechanics/', AdminMechanicsListView.as_view()),
    path('admin/mechanics/<int:mechanic_id>/toggle/', AdminMechanicToggleView.as_view()),
    path('admin/users/', AdminUsersListView.as_view()),
    path('admin/users/<int:pk>/block/', AdminUserBlockView.as_view(), name='admin-user-block'),
    path('admin/users/<int:pk>/delete/', AdminUserDeleteView.as_view(), name='admin-user-delete'),
    path('admin/payments/', AdminPaymentListView.as_view()),
    path('admin/payments/<int:payment_id>/verify/', AdminPaymentVerifyView.as_view()),
    path('admin/bookings/', AdminBookingsListView.as_view()),
    # ============ ADMIN SPARE PARTS (NEW) ============
    path('admin/spare-parts/all/', AdminSparePartListView.as_view(), name='admin-spareparts-list'),
    path('admin/spare-parts/create/', AdminSparePartCreateView.as_view(), name='admin-spareparts-create'),
    path('admin/spare-parts/<int:pk>/update/', AdminSparePartUpdateView.as_view(), name='admin-spareparts-update'),
    path('admin/spare-parts/<int:pk>/delete/', AdminSparePartDeleteView.as_view(), name='admin-spareparts-delete'),
    # ============ ADMIN MECHANICS (NEW) ============
    path('admin/mechanics/create/', AdminMechanicCreateView.as_view(), name='admin-mechanic-create'),
    path('admin/mechanics/region-changes/', AdminMechanicRegionChangeListView.as_view(), name='admin-mechanic-region-changes'),
    path('admin/mechanics/<int:pk>/approve-region/', AdminMechanicRegionChangeApproveView.as_view(), name='admin-mechanic-approve-region'),
    path('admin/mechanics/<int:pk>/reject-region/', AdminMechanicRegionChangeRejectView.as_view(), name='admin-mechanic-reject-region'),
    path('admin/mechanics/<int:pk>/delete/', AdminMechanicDeleteView.as_view(), name='admin-mechanic-delete'),
]
