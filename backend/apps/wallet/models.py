from django.db import models
from django.core.validators import MinValueValidator
from apps.accounts.models import User


class Wallet(models.Model):
    """User Wallet Model"""
    
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='wallet'
    )
    
    balance = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=0,
        validators=[MinValueValidator(0)]
    )
    currency = models.CharField(max_length=3, default='TZS')
    
    daily_limit = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=500000,
        validators=[MinValueValidator(0)]
    )
    monthly_limit = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=5000000,
        validators=[MinValueValidator(0)]
    )
    
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('inactive', 'Inactive'),
        ('frozen', 'Frozen'),
        ('closed', 'Closed'),
    ]
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    
    total_deposits = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=0,
        validators=[MinValueValidator(0)]
    )
    total_withdrawals = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=0,
        validators=[MinValueValidator(0)]
    )
    total_spent = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=0,
        validators=[MinValueValidator(0)]
    )
    transaction_count = models.PositiveIntegerField(default=0)
    
    last_transaction_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user.get_full_name()} - {self.balance} {self.currency}"

    @property
    def is_active(self):
        return self.status == 'active'


class TransactionStatus(models.TextChoices):
    """Transaction status choices"""
    PENDING = "pending", "Pending"
    PROCESSING = "processing", "Processing"
    COMPLETED = "completed", "Completed"
    FAILED = "failed", "Failed"
    CANCELLED = "cancelled", "Cancelled"


class Transaction(models.Model):
    """Wallet Transaction Model"""
    
    wallet = models.ForeignKey(
        Wallet,
        on_delete=models.CASCADE,
        related_name='transactions'
    )
    
    TRANSACTION_TYPES = [
        ('deposit', 'Deposit'),
        ('withdrawal', 'Withdrawal'),
        ('payment', 'Payment'),
        ('refund', 'Refund'),
        ('bonus', 'Bonus'),
        ('fee', 'Fee'),
    ]
    transaction_type = models.CharField(max_length=20, choices=TRANSACTION_TYPES)
    
    amount = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        validators=[MinValueValidator(0)]
    )
    balance_before = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        null=True,
        blank=True
    )
    balance_after = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        null=True,
        blank=True
    )
    
    status = models.CharField(
        max_length=20,
        choices=TransactionStatus.choices,
        default=TransactionStatus.PENDING
    )
    
    description = models.CharField(max_length=255, blank=True, null=True)
    reference = models.CharField(max_length=100, blank=True, null=True, db_index=True)
    metadata = models.JSONField(default=dict, blank=True)
    failure_reason = models.TextField(blank=True, null=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    completed_at = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"{self.wallet.user.get_full_name()} - {self.transaction_type} - {self.amount}"


class WithdrawalRequest(models.Model):
    """Withdrawal Request Model"""
    
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='withdrawal_requests'
    )
    wallet = models.ForeignKey(
        Wallet,
        on_delete=models.CASCADE,
        related_name='withdrawal_requests'
    )
    
    amount = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        validators=[MinValueValidator(0)]
    )
    
    PAYMENT_METHODS = [
        ('bank', 'Bank Transfer'),
        ('mobile_money', 'Mobile Money'),
        ('cash', 'Cash'),
    ]
    payment_method = models.CharField(max_length=20, choices=PAYMENT_METHODS)
    
    bank_name = models.CharField(max_length=100, blank=True, null=True)
    bank_account_name = models.CharField(max_length=200, blank=True, null=True)
    bank_account_number = models.CharField(max_length=50, blank=True, null=True)
    
    mobile_network = models.CharField(max_length=50, blank=True, null=True)
    mobile_number = models.CharField(max_length=20, blank=True, null=True)
    
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('processing', 'Processing'),
        ('completed', 'Completed'),
        ('failed', 'Failed'),
        ('cancelled', 'Cancelled'),
    ]
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    
    admin_notes = models.TextField(blank=True, null=True)
    failure_reason = models.TextField(blank=True, null=True)
    
    transaction = models.OneToOneField(
        Transaction,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='withdrawal_request'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    processed_at = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"{self.user.get_full_name()} - {self.amount} - {self.status}"
