from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import path, include
from apps.dashboard import views as dashboard_views
from apps.accounts import views as accounts_views
from apps.mechanics import views as mechanics_views
from apps.spare_parts import views as spare_parts_views
from apps.advertisements import views as advertisements_views
from apps.notifications import views as notifications_views

urlpatterns = [
    path('api/v1/notifications/devices/register/', notifications_views.register_device),
    path('admin/', admin.site.urls),
    # === SPECIFIC routes (lazima ziwe KABLA ya api.urls ili zisimezwa) ===
    path('api/v1/', include('apps.contact.urls')),
    path('api/v1/', include('apps.payments.urls')),
    path('api/v1/', include('apps.bookings.urls')),
    path('api/v1/', include('api.urls')),
    path('api/v1/auth/', include('apps.accounts.urls')),
    path('api/v1/mechanics/', include('apps.mechanics.urls')),
    path('api/v1/diagnosis/', include('apps.diagnosis.urls')),
    path('api/v1/admin/stats/', dashboard_views.AdminStatsView.as_view()),
    path('api/v1/admin/advertisements/', advertisements_views.admin_ads),
    path('api/v1/admin/advertisements/create/', advertisements_views.admin_create_ad),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
