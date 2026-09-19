from django.urls import path
from .payment_unified import PaymentInitiateUnifiedView
from .views import (
    PaymentConfirmManualView,
    EarningsView,
    PaymentInitiateView,
    PaymentSubmitReferenceView,
    PaymentListView,
    PaymentDetailView,
    AdminPaymentListView,
    AdminPaymentVerifyView,
)

app_name = "payments"

urlpatterns = [
    # User
    path("payments/unified/initiate/", PaymentInitiateUnifiedView.as_view(), name="payment-unified-initiate"),
    path("payments/initiate/", PaymentInitiateView.as_view(), name="payment-initiate"),
    path("payments/confirm-manual/", PaymentConfirmManualView.as_view(), name="payment-confirm-manual"),
    path("payments/my/", PaymentListView.as_view(), name="payment-list"),
    path("payments/<int:pk>/", PaymentDetailView.as_view(), name="payment-detail"),
    path("payments/<int:pk>/submit-reference/", PaymentSubmitReferenceView.as_view(), name="payment-submit-reference"),
    path("earnings/", EarningsView.as_view(), name="earnings"),

    # Admin
    path("admin/payments/", AdminPaymentListView.as_view(), name="admin-payment-list"),
    path("admin/payments/<int:pk>/verify/", AdminPaymentVerifyView.as_view(), name="admin-payment-verify"),
]
