from rest_framework import serializers
from .models import Wallet, Transaction, WithdrawalRequest, TransactionStatus


class WalletSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source='user.get_full_name', read_only=True)
    
    class Meta:
        model = Wallet
        fields = [
            'id', 'user', 'user_name', 'balance', 'currency',
            'daily_limit', 'monthly_limit', 'status',
            'total_deposits', 'total_withdrawals', 'total_spent',
            'transaction_count', 'last_transaction_at',
            'is_active', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'balance', 'total_deposits', 'total_withdrawals', 'created_at']


class TransactionSerializer(serializers.ModelSerializer):
    wallet_user = serializers.CharField(source='wallet.user.get_full_name', read_only=True)
    
    class Meta:
        model = Transaction
        fields = [
            'id', 'wallet', 'wallet_user', 'transaction_type',
            'amount', 'balance_before', 'balance_after',
            'status', 'description', 'reference', 'metadata',
            'failure_reason', 'created_at', 'updated_at', 'completed_at'
        ]


class WithdrawalRequestSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source='user.get_full_name', read_only=True)
    
    class Meta:
        model = WithdrawalRequest
        fields = [
            'id', 'user', 'user_name', 'wallet', 'amount',
            'payment_method', 'bank_name', 'bank_account_name',
            'bank_account_number', 'mobile_network', 'mobile_number',
            'status', 'admin_notes', 'failure_reason',
            'transaction', 'created_at', 'updated_at', 'processed_at'
        ]


class DepositSerializer(serializers.Serializer):
    amount = serializers.DecimalField(max_digits=15, decimal_places=2, min_value=1)
    description = serializers.CharField(required=False, allow_blank=True)


class WithdrawSerializer(serializers.Serializer):
    amount = serializers.DecimalField(max_digits=15, decimal_places=2, min_value=1)
    payment_method = serializers.CharField()
    mobile_number = serializers.CharField(required=False, allow_blank=True)
    bank_name = serializers.CharField(required=False, allow_blank=True)
    bank_account_name = serializers.CharField(required=False, allow_blank=True)
    bank_account_number = serializers.CharField(required=False, allow_blank=True)
