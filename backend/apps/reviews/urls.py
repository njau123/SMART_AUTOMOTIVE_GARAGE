from django.urls import path
from .views import MechanicReviewsView

urlpatterns = [
    path('mechanic/', MechanicReviewsView.as_view(), name='mechanic-reviews'),
]
