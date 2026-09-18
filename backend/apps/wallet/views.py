from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.utils import timezone
from .models import Wallet, Transaction, WithdrawalRequest, TransactionStatus
from .serializers import (
    WalletSerializer,
    TransactionSerializer,
    WithdrawalRequestSerializer,
    DepositSerializer,
    WithdrawSerializer,
)


class WalletViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.is_super_admin or user.is_admin:
            return Wallet.objects.all()
        return Wallet.objects.filter(user=user)

    def get_object(self):
        """Get user's wallet or create if doesn't exist"""
        user = self.request.user
        wallet, created = Wallet.objects.get_or_create(user=user)
        return wallet

    @action(detail=False, methods=['post'])
    def deposit(self, request):
        serializer = DepositSerializer(data=request.data)
        if not serializer.is_valid():
            return Response({
                'success': False,
                'message': 'Invalid data',
                'errors': serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)
        
        wallet = self.get_object()
        amount = serializer.validated_data['amount']
        description = serializer.validated_data.get('description', 'Deposit to wallet')
        
        try:
            transaction = wallet.deposit(amount, description)
            return Response({
                'success': True,
                'message': f"Deposited {amount} successfully",
                'data': TransactionSerializer(transaction).data
            })
        except ValueError as e:
            return Response({
                'success': False,
                'message': str(e)
            }, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=['post'])
    def withdraw(self, request):
        serializer = WithdrawSerializer(data=request.data)
        if not serializer.is_valid():
            return Response({
                'success': False,
                'message': 'Invalid data',
                'errors': serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)
        
        wallet = self.get_object()
        amount = serializer.validated_data['amount']
        
        try:
            # Create withdrawal request
            withdrawal_request = WithdrawalRequest.objects.create(
                user=request.user,
                wallet=wallet,
                amount=amount,
                payment_method=serializer.validated_data['payment_method'],
                mobile_number=serializer.validated_data.get('mobile_number'),
                bank_name=serializer.validated_data.get('bank_name'),
                bank_account_name=serializer.validated_data.get('bank_account_name'),
                bank_account_number=serializer.validated_data.get('bank_account_number'),
                status='pending'
            )
            
            return Response({
                'success': True,
                'message': 'Withdrawal request submitted successfully',
                'data': WithdrawalRequestSerializer(withdrawal_request).data
            })
        except ValueError as e:
            return Response({
                'success': False,
                'message': str(e)
            }, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=['get'])
    def balance(self, request):
        wallet = self.get_object()
        return Response({
            'success': True,
            'message': 'Balance retrieved',
            'data': {
                'balance': wallet.balance,
                'currency': wallet.currency,
                'status': wallet.status
            }
        })

    @action(detail=False, methods=['get'])
    def transactions(self, request):
        wallet = self.get_object()
        transactions = wallet.transactions.all()[:50]
        serializer = TransactionSerializer(transactions, many=True)
        return Response({
            'success': True,
            'message': 'Transactions retrieved',
            'data': serializer.data
        })


class WithdrawalRequestViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.is_super_admin or user.is_admin:
            return WithdrawalRequest.objects.all()
        return WithdrawalRequest.objects.filter(user=user)

    serializer_class = WithdrawalRequestSerializer

    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        if not request.user.is_admin:
            return Response({
                'success': False,
                'message': 'Only admins can approve withdrawals'
            }, status=status.HTTP_403_FORBIDDEN)
        
        withdrawal = self.get_object()
        if withdrawal.status != 'pending':
            return Response({
                'success': False,
                'message': f"Cannot approve request with status: {withdrawal.status}"
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            transaction = withdrawal.wallet.withdraw(
                amount=withdrawal.amount,
                description=f"Withdrawal - {withdrawal.payment_method}",
                reference=f"WD-{withdrawal.id}"
            )
            withdrawal.transaction = transaction
            withdrawal.status = 'completed'
            withdrawal.processed_at = timezone.now()
            withdrawal.save()
            
            return Response({
                'success': True,
                'message': 'Withdrawal approved successfully',
                'data': WithdrawalRequestSerializer(withdrawal).data
            })
        except ValueError as e:
            withdrawal.status = 'failed'
            withdrawal.failure_reason = str(e)
            withdrawal.save()
            return Response({
                'success': False,
                'message': str(e)
            }, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        if not request.user.is_admin:
            return Response({
                'success': False,
                'message': 'Only admins can reject withdrawals'
            }, status=status.HTTP_403_FORBIDDEN)
        
        withdrawal = self.get_object()
        if withdrawal.status != 'pending':
            return Response({
                'success': False,
                'message': f"Cannot reject request with status: {withdrawal.status}"
            }, status=status.HTTP_400_BAD_REQUEST)
        
        reason = request.data.get('reason', 'Request rejected')
        withdrawal.status = 'cancelled'
        withdrawal.failure_reason = reason
        withdrawal.save()
        
        return Response({
            'success': True,
            'message': 'Withdrawal rejected',
            'data': WithdrawalRequestSerializer(withdrawal).data
        })
