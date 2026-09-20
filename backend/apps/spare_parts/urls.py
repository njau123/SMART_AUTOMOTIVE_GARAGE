from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    CategoryViewSet, BrandViewSet, SparePartViewSet,
    OrderCreateView, OrderListView, OrderDetailView,
    OrderUpdateDeliveryView, OrderDeleteView,
    AdminOrderListView, AdminOrderUpdateStatusView,
)

router = DefaultRouter()
router.register(r'categories', CategoryViewSet, basename='spare-category')
router.register(r'brands', BrandViewSet, basename='spare-brand')
router.register(r'parts', SparePartViewSet, basename='spare-part')

urlpatterns = [
    path('', include(router.urls)),
    # === USER ORDERS ===
    path('orders/create/', OrderCreateView.as_view(), name='order-create'),
    path('orders/my/', OrderListView.as_view(), name='order-list'),
    path('orders/<int:pk>/', OrderDetailView.as_view(), name='order-detail'),
    path('orders/<int:pk>/delivery/', OrderUpdateDeliveryView.as_view(), name='order-delivery'),
    path('orders/<int:pk>/delete/', OrderDeleteView.as_view(), name='order-delete'),
    # === ADMIN ORDERS ===
    path('admin/orders/all/', AdminOrderListView.as_view(), name='admin-order-list'),
    path('admin/orders/<int:pk>/status/', AdminOrderUpdateStatusView.as_view(), name='admin-order-status'),
]
