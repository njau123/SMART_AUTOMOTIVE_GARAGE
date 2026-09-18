from django.urls import path
from .views import (
    ContactCreateView,
    AdminContactListView,
    AdminContactReplyView,
    AdminContactDeleteView,
)

app_name = "contact"

urlpatterns = [
    path("contact/", ContactCreateView.as_view(), name="contact-create"),
    path("admin/contact/", AdminContactListView.as_view(), name="admin-contact-list"),
    path("admin/contact/<int:pk>/reply/", AdminContactReplyView.as_view(), name="admin-contact-reply"),
    path("admin/contact/<int:pk>/", AdminContactDeleteView.as_view(), name="admin-contact-delete"),
]
