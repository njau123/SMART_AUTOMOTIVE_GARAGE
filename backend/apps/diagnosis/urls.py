from django.urls import path
from .views import diagnose

urlpatterns = [
    path('diagnose/', diagnose, name='diagnose'),
]
