from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    ChatRoomViewSet, MessageViewSet, UserChatStatusViewSet,
    ChatNotificationViewSet, ChatBlockViewSet,
    MessageAttachmentViewSet,
)

router = DefaultRouter()
router.register(r'rooms', ChatRoomViewSet, basename='chat-room')
router.register(r'messages', MessageViewSet, basename='chat-message')
router.register(r'status', UserChatStatusViewSet, basename='chat-status')
router.register(r'notifications', ChatNotificationViewSet, basename='chat-notification')
router.register(r'blocks', ChatBlockViewSet, basename='chat-block')
router.register(r'attachments', MessageAttachmentViewSet, basename='message-attachment')

urlpatterns = [
    path('', include(router.urls)),
]
