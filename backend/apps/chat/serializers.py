from rest_framework import serializers
from .models import ChatRoom, Message, MessageAttachment, UserChatStatus, ChatNotification, ChatBlock


class ChatRoomSerializer(serializers.ModelSerializer):
    participants_details = serializers.SerializerMethodField()
    last_message_details = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()
    participant_count = serializers.IntegerField(read_only=True)
    
    class Meta:
        model = ChatRoom
        fields = [
            'id', 'room_type', 'name', 'participants',
            'participants_details', 'participant_count',
            'booking', 'last_message', 'last_message_at',
            'last_message_sender', 'last_message_details',
            'status', 'unread_count',
            'metadata', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def get_participants_details(self, obj):
        participants = obj.participants.all()
        return [{
            'id': user.id,
            'full_name': user.get_full_name(),
            'email': user.email,
            'profile_image': user.profile_image.url if user.profile_image else None
        } for user in participants]

    def get_last_message_details(self, obj):
        if obj.last_message:
            return {
                'content': obj.last_message,
                'sender': obj.last_message_sender.get_full_name() if obj.last_message_sender else None,
                'time': obj.last_message_at
            }
        return None

    def get_unread_count(self, obj):
        if 'request' in self.context:
            user = self.context['request'].user
            return obj.unread_count_for_user(user)
        return 0


class ChatRoomCreateSerializer(serializers.ModelSerializer):
    participant_ids = serializers.ListField(
        child=serializers.IntegerField(),
        write_only=True,
        required=False,
        default=list,
    )

    class Meta:
        model = ChatRoom
        fields = ['room_type', 'name', 'participant_ids', 'booking', 'metadata']
        extra_kwargs = {
            'booking': {'required': False, 'allow_null': True},
            'metadata': {'required': False},
            'name': {'required': False, 'allow_blank': True, 'allow_null': True},
        }

    def create(self, validated_data):
        # Ondoa participant_ids — haipo kwenye ChatRoom model
        validated_data.pop('participant_ids', None)
        # Tengeneza room bila participants kwanza
        return ChatRoom.objects.create(**validated_data)

class MessageSerializer(serializers.ModelSerializer):
    sender_name = serializers.CharField(source='sender.get_full_name', read_only=True)
    sender_image = serializers.SerializerMethodField()
    reply_to_content = serializers.SerializerMethodField()
    is_mine = serializers.SerializerMethodField()
    formatted_time = serializers.SerializerMethodField()
    
    class Meta:
        model = Message
        fields = [
            'id', 'room', 'sender', 'sender_name',
            'sender_image', 'content', 'message_type',
            'media_urls', 'latitude', 'longitude',
            'reply_to', 'reply_to_content', 'is_read',
            'read_by', 'read_at', 'delivery_status',
            'is_mine', 'formatted_time', 'metadata',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'sender', 'created_at', 'updated_at']

    def get_sender_image(self, obj):
        if obj.sender.profile_image:
            return obj.sender.profile_image.url
        return None

    def get_reply_to_content(self, obj):
        if obj.reply_to:
            return obj.reply_to.content[:100]
        return None

    def get_is_mine(self, obj):
        request = self.context.get('request')
        if request and hasattr(request, 'user') and request.user.is_authenticated:
            return obj.sender_id == request.user.id
        return False

    def get_formatted_time(self, obj):
        return obj.created_at.strftime('%H:%M')


class MessageCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Message
        fields = [
            'room', 'content', 'message_type', 'media_urls',
            'latitude', 'longitude', 'reply_to', 'metadata'
        ]


class MessageAttachmentSerializer(serializers.ModelSerializer):
    file_url_final = serializers.SerializerMethodField()

    class Meta:
        model = MessageAttachment
        fields = [
            'id', 'message', 'file', 'file_url', 'file_url_final',
            'file_name', 'file_size', 'file_type', 'thumbnail',
            'metadata', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']

    def get_file_url_final(self, obj):
        """Rudisha Cloudinary URL kama ipo, la sivyo local file URL."""
        if obj.file_url:
            return obj.file_url
        if obj.file:
            request = self.context.get('request')
            try:
                url = obj.file.url
                return request.build_absolute_uri(url) if request else url
            except Exception:
                return None
        return None


class UserChatStatusSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source='user.get_full_name', read_only=True)
    
    class Meta:
        model = UserChatStatus
        fields = [
            'id', 'user', 'user_name', 'status',
            'last_seen', 'is_typing', 'typing_in_room',
            'typing_updated_at'
        ]
        read_only_fields = ['id', 'last_seen']


class ChatNotificationSerializer(serializers.ModelSerializer):
    recipient_name = serializers.CharField(source='recipient.get_full_name', read_only=True)
    sender_name = serializers.CharField(source='message.sender.get_full_name', read_only=True)
    message_preview = serializers.CharField(source='message.content', read_only=True)
    room_name = serializers.CharField(source='room.name', read_only=True)
    formatted_time = serializers.SerializerMethodField()
    
    class Meta:
        model = ChatNotification
        fields = [
            'id', 'recipient', 'recipient_name', 'message',
            'message_preview', 'sender_name', 'room',
            'room_name', 'notification_type', 'is_read',
            'read_at', 'formatted_time', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']

    def get_formatted_time(self, obj):
        return obj.created_at.strftime('%H:%M')


class ChatBlockSerializer(serializers.ModelSerializer):
    blocker_name = serializers.CharField(source='blocker.get_full_name', read_only=True)
    blocked_name = serializers.CharField(source='blocked.get_full_name', read_only=True)
    
    class Meta:
        model = ChatBlock
        fields = [
            'id', 'blocker', 'blocker_name', 'blocked',
            'blocked_name', 'reason', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']
