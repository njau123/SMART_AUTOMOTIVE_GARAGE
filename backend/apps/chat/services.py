from django.db import transaction
from django.utils import timezone

from .models import (
    ChatBlock,
    Conversation,
    ConversationParticipant,
    Message,
    MessageReaction,
    MessageRead,
)


class ChatService:

    @staticmethod
    @transaction.atomic
    def create_conversation(
        *,
        customer,
        mechanic,
        conversation_type,
        title="",
    ):
        conversation = Conversation.objects.create(
            customer=customer,
            mechanic=mechanic,
            conversation_type=conversation_type,
            title=title,
        )

        ConversationParticipant.objects.bulk_create(
            [
                ConversationParticipant(
                    conversation=conversation,
                    user=customer,
                ),
                ConversationParticipant(
                    conversation=conversation,
                    user=mechanic,
                ),
            ]
        )

        return conversation

    @staticmethod
    def user_is_participant(
        *,
        conversation,
        user,
    ):
        return ConversationParticipant.objects.filter(
            conversation=conversation,
            user=user,
        ).exists()

    @staticmethod
    def is_blocked(
        *,
        sender,
        recipient,
    ):
        return ChatBlock.objects.filter(
            blocker=recipient,
            blocked_user=sender,
        ).exists()

    @staticmethod
    @transaction.atomic
    def send_message(
        *,
        conversation,
        sender,
        message_type,
        content="",
        attachment=None,
        latitude=None,
        longitude=None,
        reply_to=None,
    ):
        if not ChatService.user_is_participant(
            conversation=conversation,
            user=sender,
        ):
            raise PermissionError(
                "User is not a conversation participant."
            )

        recipient = (
            conversation.mechanic
            if sender == conversation.customer
            else conversation.customer
        )

        if recipient and ChatService.is_blocked(
            sender=sender,
            recipient=recipient,
        ):
            raise PermissionError(
                "Messaging is blocked."
            )

        message = Message.objects.create(
            conversation=conversation,
            sender=sender,
            message_type=message_type,
            content=content,
            attachment=attachment,
            latitude=latitude,
            longitude=longitude,
            reply_to=reply_to,
            status="SENT",
        )

        conversation.last_message_at = (
            timezone.now()
        )

        conversation.save(
            update_fields=[
                "last_message_at",
                "updated_at",
            ]
        )

        return message

    @staticmethod
    @transaction.atomic
    def mark_message_read(
        *,
        message,
        user,
    ):
        if not ChatService.user_is_participant(
            conversation=message.conversation,
            user=user,
        ):
            raise PermissionError(
                "User is not a conversation participant."
            )

        receipt, created = (
            MessageRead.objects.get_or_create(
                message=message,
                user=user,
            )
        )

        if created:
            message.status = "READ"

            message.save(
                update_fields=[
                    "status",
                    "updated_at",
                ]
            )

        ConversationParticipant.objects.filter(
            conversation=message.conversation,
            user=user,
        ).update(
            last_read_at=timezone.now()
        )

        return receipt

    @staticmethod
    def add_reaction(
        *,
        message,
        user,
        reaction,
    ):
        if not ChatService.user_is_participant(
            conversation=message.conversation,
            user=user,
        ):
            raise PermissionError(
                "User is not a conversation participant."
            )

        obj, _ = (
            MessageReaction.objects.update_or_create(
                message=message,
                user=user,
                defaults={
                    "reaction": reaction,
                },
            )
        )

        return obj

    @staticmethod
    def remove_reaction(
        *,
        message,
        user,
    ):
        return MessageReaction.objects.filter(
            message=message,
            user=user,
        ).delete()

    @staticmethod
    def block_user(
        *,
        blocker,
        blocked_user,
    ):
        block, created = (
            ChatBlock.objects.get_or_create(
                blocker=blocker,
                blocked_user=blocked_user,
            )
        )

        return block, created

    @staticmethod
    def unblock_user(
        *,
        blocker,
        blocked_user,
    ):
        return ChatBlock.objects.filter(
            blocker=blocker,
            blocked_user=blocked_user,
        ).delete()