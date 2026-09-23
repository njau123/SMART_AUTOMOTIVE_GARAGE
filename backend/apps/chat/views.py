from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.utils import timezone
from .models import ChatRoom, Message, MessageAttachment, UserChatStatus, ChatNotification, ChatBlock
from .serializers import (
    ChatRoomSerializer, ChatRoomCreateSerializer,
    MessageSerializer, MessageCreateSerializer, MessageAttachmentSerializer,
    UserChatStatusSerializer,
    ChatNotificationSerializer, ChatBlockSerializer
)


class ChatRoomViewSet(viewsets.ModelViewSet):
    """Chat Room ViewSet"""
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        # Admin au Super Admin wanaweza kuona rooms zote
        if user.is_staff or user.is_superuser or user.role in ['ADMIN', 'SUPER_ADMIN']:
            return ChatRoom.objects.all()
        return ChatRoom.objects.filter(participants=user, status='active')

    def get_serializer_class(self):
        if self.action == 'create':
            return ChatRoomCreateSerializer
        return ChatRoomSerializer

    def create(self, request, *args, **kwargs):
        """Override create — rudisha full ChatRoomSerializer."""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)

        # Rudisha full serializer (na id, participants, n.k.)
        room = serializer.instance
        full = ChatRoomSerializer(room, context={'request': request})
        return Response({
            'success': True,
            'message': 'Chat room imeundwa',
            'data': full.data,
        }, status=status.HTTP_201_CREATED)

    def destroy(self, request, *args, **kwargs):
        """Futa chat room — participant pekee anaweza."""
        room = self.get_object()
        user = request.user

        # Hakikisha user ni participant au admin
        is_participant = room.participants.filter(id=user.id).exists()
        is_admin = user.is_staff or user.is_superuser or user.role in ['ADMIN', 'SUPER_ADMIN']

        if not (is_participant or is_admin):
            return Response(
                {
                    'success': False,
                    'message': 'Hauna ruhusa kufuta chat hii',
                    'data': None,
                    'errors': {'detail': 'Permission denied'},
                },
                status=status.HTTP_403_FORBIDDEN,
            )

        room_name = room.name or f'Chat #{room.id}'
        room.delete()

        return Response({
            'success': True,
            'message': f'Chat "{room_name}" imefutwa',
            'data': None,
            'errors': None,
        }, status=status.HTTP_200_OK)

    def perform_create(self, serializer):
        from apps.accounts.models import User
        # Save room
        room = serializer.save()
        # Ongeza creator kama participant
        room.participants.add(self.request.user)
        # Ongeza participant_ids wengine
        participant_ids = self.request.data.get('participant_ids', [])
        if participant_ids:
            users = User.objects.filter(id__in=participant_ids).exclude(id=self.request.user.id)
            room.participants.add(*users)
        # Sasisha name kama haipo — tumia jina la participant mwingine
        if not room.name and room.participants.count() >= 2:
            other = room.participants.exclude(id=self.request.user.id).first()
            if other:
                room.name = other.get_full_name() or other.email
                room.save(update_fields=['name'])

    @action(detail=True, methods=['get'])
    def messages(self, request, pk=None):
        """Get messages in a room"""
        room = self.get_object()
        limit = request.query_params.get('limit', 50)
        offset = request.query_params.get('offset', 0)
        
        try:
            limit = int(limit)
            offset = int(offset)
        except ValueError:
            limit = 50
            offset = 0
        
        messages = room.messages.all()[offset:offset+limit]
        total = room.messages.count()
        
        serializer = MessageSerializer(messages, many=True, context={'request': request})
        return Response({
            'success': True,
            'message': 'Messages retrieved',
            'data': {
                'messages': serializer.data,
                'total': total,
                'limit': limit,
                'offset': offset
            }
        })

    @action(detail=True, methods=['post'])
    def mark_read(self, request, pk=None):
        """Mark all messages as read"""
        room = self.get_object()
        user = request.user
        
        messages = room.messages.filter(is_read=False).exclude(sender=user)
        count = 0
        
        for message in messages:
            message.mark_as_read(user)
            count += 1
        
        return Response({
            'success': True,
            'message': f'Marked {count} messages as read',
            'data': {'marked_count': count}
        })

    @action(detail=True, methods=['post'])
    def add_participants(self, request, pk=None):
        """Add participants to room"""
        room = self.get_object()
        user_ids = request.data.get('user_ids', [])
        
        if not user_ids:
            return Response({
                'success': False,
                'message': 'user_ids is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        from apps.accounts.models import User
        users = User.objects.filter(id__in=user_ids)
        room.participants.add(*users)
        
        return Response({
            'success': True,
            'message': f'Added {len(users)} participants',
            'data': ChatRoomSerializer(room, context={'request': request}).data
        })


class MessageViewSet(viewsets.ModelViewSet):
    """Message ViewSet"""
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        return Message.objects.filter(room__participants=user)

    def get_serializer_class(self):
        if self.action == 'create':
            return MessageCreateSerializer
        return MessageSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        # Rudisha MessageSerializer (na ID + sender_name)
        instance = serializer.instance
        full = MessageSerializer(instance, context={'request': request})
        return Response(full.data, status=status.HTTP_201_CREATED)

    def perform_create(self, serializer):
        message = serializer.save(sender=self.request.user)
        # Update room last message
        message.room.update_last_message(message)
        
        # Create notifications for other participants
        sender_name = self.request.user.get_full_name() or self.request.user.email
        for participant in message.room.participants.all():
            if participant != self.request.user:
                # 1. DB notification
                ChatNotification.objects.create(
                    recipient=participant,
                    message=message,
                    room=message.room,
                    notification_type='new_message'
                )

                # 2. FCM PUSH (popup kwenye simu)
                try:
                    from apps.notifications.services import send_notification_to_user
                    send_notification_to_user(
                        user=participant,
                        title=f"Ujumbe kutoka {sender_name}",
                        message=(message.content or 'New message')[:100],
                        notification_type='message',
                        data={
                            'type': 'chat_message',
                            'room_id': str(message.room.id),
                            'room_name': message.room.name or '',
                            'message_id': str(message.id),
                            'sender_name': sender_name,
                        },
                    )
                    print(f"[FCM] Sent to {participant.email}")
                except Exception as e:
                    print(f"[FCM ERROR] {e}")

    @action(detail=True, methods=['post'])
    def read(self, request, pk=None):
        """Mark message as read"""
        message = self.get_object()
        message.mark_as_read(request.user)
        return Response({
            'success': True,
            'message': 'Message marked as read',
            'data': MessageSerializer(message, context={'request': request}).data
        })

    @action(detail=True, methods=['post'], url_path='delete-message')
    def delete_message(self, request, pk=None):
        """Soft delete — sender pekee."""
        message = self.get_object()

        if message.sender_id != request.user.id:
            return Response(
                {'success': False, 'message': 'Hauna ruhusa kufuta message hii'},
                status=status.HTTP_403_FORBIDDEN,
            )

        if message.is_deleted:
            return Response(
                {'success': False, 'message': 'Message imefutwa tayari'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        message.soft_delete(request.user)

        return Response({
            'success': True,
            'message': 'Message imefutwa',
            'data': MessageSerializer(message, context={'request': request}).data,
        })

    @action(detail=True, methods=['post'], url_path='edit-message')
    def edit_message(self, request, pk=None):
        """Edit message — sender pekee, text tu."""
        message = self.get_object()

        new_content = (request.data.get('content') or '').strip()
        if not new_content:
            return Response(
                {'success': False, 'message': 'Content ni lazima'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if message.sender_id != request.user.id:
            return Response(
                {'success': False, 'message': 'Hauna ruhusa ku-edit message hii'},
                status=status.HTTP_403_FORBIDDEN,
            )

        if message.is_deleted:
            return Response(
                {'success': False, 'message': 'Message imefutwa, haiwezi ku-edit'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if message.message_type != 'text':
            return Response(
                {'success': False, 'message': 'Edit inaruhusiwa kwa text tu'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        message.edit_content(new_content)

        return Response({
            'success': True,
            'message': 'Message imeupdate',
            'data': MessageSerializer(message, context={'request': request}).data,
        })




# ==================== ATTACHMENT UPLOAD ====================
class MessageAttachmentViewSet(viewsets.ModelViewSet):
    """ViewSet ya kupakia attachments (image, video, audio, doc) kwenye message."""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = MessageAttachmentSerializer

    def get_queryset(self):
        user = self.request.user
        return MessageAttachment.objects.filter(message__room__participants=user)

    def create(self, request, *args, **kwargs):
        import os
        import cloudinary
        import cloudinary.uploader

        message_id = request.data.get('message_id')
        if not message_id:
            return Response(
                {'success': False, 'message': 'message_id ni lazima'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            message = Message.objects.get(id=message_id)
        except Message.DoesNotExist:
            return Response(
                {'success': False, 'message': 'Message haipo'},
                status=status.HTTP_404_NOT_FOUND,
            )

        if not message.room.participants.filter(id=request.user.id).exists():
            return Response(
                {'success': False, 'message': 'Huna ruhusa'},
                status=status.HTTP_403_FORBIDDEN,
            )

        uploaded_file = request.FILES.get('file')
        if not uploaded_file:
            return Response(
                {'success': False, 'message': 'file ni lazima'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Kikomo cha size (50 MB)
        max_size = 50 * 1024 * 1024
        if uploaded_file.size > max_size:
            return Response(
                {'success': False, 'message': 'File ni kubwa mno (kikomo 50 MB)'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Tambua file_type
        file_name = uploaded_file.name.lower()

        if any(file_name.endswith(e) for e in ['.jpg', '.jpeg', '.png', '.gif', '.webp']):
            file_type = 'image'
            resource_type = 'image'
        elif any(file_name.endswith(e) for e in ['.mp4', '.mov', '.avi', '.webm']):
            file_type = 'video'
            resource_type = 'video'
        elif any(file_name.endswith(e) for e in ['.mp3', '.wav', '.m4a', '.ogg', '.aac']):
            file_type = 'audio'
            resource_type = 'video'  # Cloudinary ina-handle audio kama video
        elif file_name.endswith('.pdf') or any(file_name.endswith(e) for e in ['.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx']):
            file_type = 'document'
            resource_type = 'raw'
        else:
            file_type = 'file'
            resource_type = 'raw'

        # ============ CLOUDINARY UPLOAD ============
        try:
            cloudinary.config(
                cloud_name=os.environ.get('CLOUDINARY_CLOUD_NAME', ''),
                api_key=os.environ.get('CLOUDINARY_API_KEY', ''),
                api_secret=os.environ.get('CLOUDINARY_API_SECRET', ''),
            )

            upload_result = cloudinary.uploader.upload(
                uploaded_file,
                resource_type=resource_type,
                folder='smart_garage/chat',
                use_filename=True,
                unique_filename=True,
            )

            cloudinary_url = upload_result.get('secure_url', '')
            if not cloudinary_url:
                raise Exception('Cloudinary haikurudi secure_url')

        except Exception as e:
            return Response(
                {'success': False, 'message': f'Cloudinary upload imeshindwa: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

        # Save attachment (file_url = Cloudinary, file = null)
        attachment = MessageAttachment.objects.create(
            message=message,
            file=None,
            file_url=cloudinary_url,
            file_name=uploaded_file.name,
            file_size=uploaded_file.size,
            file_type=file_type,
            metadata={
                'cloudinary_public_id': upload_result.get('public_id', ''),
                'cloudinary_format': upload_result.get('format', ''),
                'cloudinary_bytes': upload_result.get('bytes', 0),
            },
        )

        # Update message
        message.message_type = file_type
        if not message.content or message.content == '':
            message.content = uploaded_file.name
        if not message.media_urls:
            message.media_urls = []
        message.media_urls.append(cloudinary_url)
        message.save()

        return Response({
            'success': True,
            'message': 'File imepakiwa',
            'data': MessageAttachmentSerializer(attachment, context={'request': request}).data,
        }, status=status.HTTP_201_CREATED)


class UserChatStatusViewSet(viewsets.ModelViewSet):
    """User Chat Status ViewSet"""
    serializer_class = UserChatStatusSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.is_superuser or (user.role == 'ADMIN' or user.role == 'SUPER_ADMIN'):
            return UserChatStatus.objects.all()
        return UserChatStatus.objects.filter(user=user)

    @action(detail=False, methods=['post'])
    def set_online(self, request):
        """Set user online"""
        status, created = UserChatStatus.objects.get_or_create(user=request.user)
        status.set_online()
        return Response({
            'success': True,
            'message': 'Status set to online',
            'data': UserChatStatusSerializer(status).data
        })

    @action(detail=False, methods=['post'])
    def set_offline(self, request):
        """Set user offline"""
        status = UserChatStatus.objects.filter(user=request.user).first()
        if status:
            status.set_offline()
            return Response({
                'success': True,
                'message': 'Status set to offline',
                'data': UserChatStatusSerializer(status).data
            })
        return Response({
            'success': False,
            'message': 'User status not found'
        }, status=status.HTTP_404_NOT_FOUND)


class ChatNotificationViewSet(viewsets.ModelViewSet):
    """Chat Notification ViewSet"""
    serializer_class = ChatNotificationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return ChatNotification.objects.filter(recipient=self.request.user)

    @action(detail=True, methods=['post'])
    def mark_as_read(self, request, pk=None):
        """Mark notification as read"""
        notification = self.get_object()
        notification.mark_as_read()
        return Response({
            'success': True,
            'message': 'Notification marked as read',
            'data': ChatNotificationSerializer(notification).data
        })

    @action(detail=False, methods=['post'])
    def mark_all_read(self, request):
        """Mark all notifications as read"""
        notifications = self.get_queryset().filter(is_read=False)
        count = notifications.update(is_read=True, read_at=timezone.now())
        return Response({
            'success': True,
            'message': 'All notifications marked as read',
            'data': {'marked_count': count}
        })


class ChatBlockViewSet(viewsets.ModelViewSet):
    """Chat Block ViewSet"""
    serializer_class = ChatBlockSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.is_superuser or (user.role == 'ADMIN' or user.role == 'SUPER_ADMIN'):
            return ChatBlock.objects.all()
        return ChatBlock.objects.filter(blocker=user)

    @action(detail=False, methods=['post'])
    def block_user(self, request):
        """Block a user"""
        user_id = request.data.get('user_id')
        reason = request.data.get('reason', '')
        
        if not user_id:
            return Response({
                'success': False,
                'message': 'user_id is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        from apps.accounts.models import User
        try:
            blocked = User.objects.get(id=user_id)
        except User.DoesNotExist:
            return Response({
                'success': False,
                'message': 'User not found'
            }, status=status.HTTP_404_NOT_FOUND)
        
        if blocked == request.user:
            return Response({
                'success': False,
                'message': 'You cannot block yourself'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        block, created = ChatBlock.objects.get_or_create(
            blocker=request.user,
            blocked=blocked,
            defaults={'reason': reason}
        )
        
        if created:
            return Response({
                'success': True,
                'message': f'Blocked {blocked.get_full_name()}',
                'data': ChatBlockSerializer(block).data
            })
        else:
            return Response({
                'success': False,
                'message': 'User is already blocked'
            }, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=['post'])
    def unblock_user(self, request):
        """Unblock a user"""
        user_id = request.data.get('user_id')
        
        if not user_id:
            return Response({
                'success': False,
                'message': 'user_id is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        deleted, _ = ChatBlock.objects.filter(
            blocker=request.user,
            blocked_id=user_id
        ).delete()
        
        if deleted:
            return Response({
                'success': True,
                'message': 'User unblocked successfully'
            })
        else:
            return Response({
                'success': False,
                'message': 'User not found in block list'
            }, status=status.HTTP_404_NOT_FOUND)
