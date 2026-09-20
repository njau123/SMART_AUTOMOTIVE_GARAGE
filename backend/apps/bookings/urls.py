from django.urls import path
from .views import (
    BookingCreateView, MyBookingsView, BookingDetailView,
    PayDepositView, FinalPaymentView, CancelBookingView,
    AvailableJobsView, RequestJobView,
    MechanicPendingBookingsView,
    MechanicAcceptBookingView, MechanicRejectBookingView,
    BookingCountdownView,
    AdminBookingListView, AdminBookingAssignMechanicView,
    AdminBookingStatusView,
)

app_name = "bookings"

urlpatterns = [
    # === MECHANIC ACTIONS ===
    # === MECHANIC ACTIONS ===
    path('bookings/mechanic/pending/', MechanicPendingBookingsView.as_view(), name='mechanic-pending'),
    path('bookings/<int:pk>/accept/', MechanicAcceptBookingView.as_view(), name='booking-accept'),
    path('bookings/<int:pk>/reject/', MechanicRejectBookingView.as_view(), name='booking-reject'),
    path('bookings/<int:pk>/countdown/', BookingCountdownView.as_view(), name='booking-countdown'),

    # User
    path("bookings/create/", BookingCreateView.as_view(), name="create"),
    path("bookings/my/", MyBookingsView.as_view(), name="my-bookings"),
    path("bookings/<int:pk>/", BookingDetailView.as_view(), name="detail"),
    path("bookings/<int:pk>/pay-deposit/", PayDepositView.as_view(), name="pay-deposit"),
    path("bookings/<int:pk>/final-payment/", FinalPaymentView.as_view(), name="final-payment"),
    path("bookings/<int:pk>/cancel/", CancelBookingView.as_view(), name="cancel"),

    # Mechanic
    path("bookings/jobs/available/", AvailableJobsView.as_view(), name="available-jobs"),
    path("bookings/jobs/<int:pk>/request/", RequestJobView.as_view(), name="request-job"),
    path("bookings/<int:pk>/mechanic-accept/", MechanicAcceptBookingView.as_view(), name="mechanic-accept"),
    path("bookings/<int:pk>/mechanic-reject/", MechanicRejectBookingView.as_view(), name="mechanic-reject"),

    # Admin
    path("admin/bookings/", AdminBookingListView.as_view(), name="admin-bookings"),
    path("admin/bookings/<int:pk>/assign-mechanic/", AdminBookingAssignMechanicView.as_view(), name="admin-assign"),
    path("admin/bookings/<int:pk>/status/", AdminBookingStatusView.as_view(), name="admin-status"),
]
