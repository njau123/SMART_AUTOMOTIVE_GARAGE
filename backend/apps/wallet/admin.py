from django.contrib import admin
from .models import Wallet, Transaction, WithdrawalRequest


@admin.register(Wallet)
class WalletAdmin(admin.ModelAdmin):
    list_display = ['user', 'balance', 'status', 'transaction_count', 'created_at']
    list_filter = ['status']
    search_fields = ['user__email', 'user__first_name', 'user__last_name']
    readonly_fields = ['balance', 'total_deposits', 'total_withdrawals', 'total_spent']


@admin.register(Transaction)
class TransactionAdmin(admin.ModelAdmin):
    list_display = ['wallet', 'transaction_type', 'amount', 'status', 'created_at']
    list_filter = ['transaction_type', 'status']
    search_fields = ['wallet__user__email', 'reference']


@admin.register(WithdrawalRequest)
class WithdrawalRequestAdmin(admin.ModelAdmin):
    list_display = ['user', 'amount', 'payment_method', 'status', 'created_at']
    list_filter = ['status', 'payment_method']
    search_fields = ['user__email', 'mobile_number', 'bank_account_number']
