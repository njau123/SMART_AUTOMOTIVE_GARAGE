from django.urls import path

from .views import (
    DiagnosisCreateView,
    DiagnosisDetailView,
    DiagnosisHistoryView,
)

app_name = "ai_diagnosis"

urlpatterns = [
    path("create/", DiagnosisCreateView.as_view(), name="create"),
    path("history/", DiagnosisHistoryView.as_view(), name="history"),
    path("<int:pk>/", DiagnosisDetailView.as_view(), name="detail"),
]
