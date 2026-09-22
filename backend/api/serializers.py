from rest_framework import serializers
from django.contrib.auth import get_user_model
from apps.mechanics.models import MechanicProfile
from apps.vehicles.models import Vehicle
from apps.services.models import Service, ServiceCategory
from apps.spare_parts.models import SparePart, Category, Brand
from apps.bookings.models import Booking
from apps.wallet.models import Wallet, Transaction
from apps.payments.models import Payment
from apps.news.models import News
from apps.advertisements.models import Advertisement
from apps.diagnosis.models import DiagnosisSession, DiagnosisDTC, OBDReading, OBDScanEvent, DTCCode
from apps.reviews.models import Review
from apps.tracking.models import TrackingSession, VehicleLocation, MechanicLocation, Geofence
from apps.chat.models import ChatRoom, Message
from apps.notifications.models import Notification, NotificationDevice

User = get_user_model()

# ============ USER ============
class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)
    class Meta:
        model = User
        fields = ['id', 'email', 'first_name', 'last_name', 'phone_number', 'password']
    def create(self, validated_data):
        return User.objects.create_user(**validated_data)

class UserProfileSerializer(serializers.ModelSerializer):
    profile_image_url = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            'id', 'email', 'first_name', 'middle_name', 'last_name',
            'phone_number', 'role', 'profile_image', 'profile_image_url',
            'is_email_verified', 'is_phone_verified',
            'created_at',
        ]
        read_only_fields = ['id', 'email', 'role', 'created_at']

    def get_profile_image_url(self, obj):
        # 1. Kama profile_image ipo (local file)
        if obj.profile_image:
            request = self.context.get('request')
            try:
                url = obj.profile_image.url
                return request.build_absolute_uri(url) if request else url
            except Exception:
                pass
        # 2. Kama profile_image_url ipo (Google external URL)
        if getattr(obj, 'profile_image_url', None):
            return obj.profile_image_url
        return None


class MechanicProfileSerializer(serializers.ModelSerializer):
    full_name = serializers.SerializerMethodField()
    email = serializers.CharField(source='user.email', read_only=True)
    phone_number = serializers.CharField(source='user.phone_number', read_only=True)
    profile_image_url = serializers.SerializerMethodField()
    rating_average = serializers.SerializerMethodField()
    total_reviews = serializers.SerializerMethodField()

    class Meta:
        model = MechanicProfile
        fields = [
            'id', 'user', 'full_name', 'email', 'phone_number',
            'business_name', 'expertise', 'is_available',
            'latitude', 'longitude',
            'profile_image_url',
            'rating_average', 'total_reviews',
            'experience',
        ]
        read_only_fields = ['id', 'user']

    def get_full_name(self, obj):
        try:
            return obj.user.get_full_name() or obj.user.email.split('@')[0]
        except Exception:
            return 'Mechanic'

    def get_profile_image_url(self, obj):
        request = self.context.get('request')
        img = getattr(obj.user, 'profile_image', None)
        if not img:
            img = getattr(obj, 'profile_image', None)
        if not img:
            return None
        try:
            return request.build_absolute_uri(img.url) if request else img.url
        except Exception:
            return None

    def get_rating_average(self, obj):
        try:
            from django.db.models import Avg
            return round(obj.reviews.aggregate(Avg('rating'))['rating__avg'] or 0, 1)
        except Exception:
            return 0.0

    def get_total_reviews(self, obj):
        try:
            return obj.reviews.count()
        except Exception:
            return 0


class VehicleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Vehicle
        fields = ['id', 'make', 'model', 'year', 'registration_number', 'vin',
                  'engine_type', 'engine_capacity_cc', 'fuel_type', 'transmission',
                  'color', 'mileage_km', 'vehicle_image', 'is_primary', 'is_active',
                  'notes', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']

# ============ SERVICE ============
class ServiceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Service
        fields = [
            'id', 'name', 'description',
            'base_price', 'estimated_duration_minutes',
            'category', 'is_active', 'created_at',
        ]

# ============ SPARE PART ============
class SparePartSerializer(serializers.ModelSerializer):
    class Meta:
        model = SparePart
        fields = [
            'id', 'name', 'slug', 'description', 'short_description',
            'brand', 'category', 'part_number', 'price', 'stock_quantity',
            'main_image', 'condition', 'status', 'is_active',
        ]

# ============ BOOKING ============
class BookingSerializer(serializers.ModelSerializer):
    class Meta:
        model = Booking
        fields = ['id', 'customer', 'mechanic', 'vehicle', 'service',
                  'scheduled_date', 'scheduled_time', 'status', 'notes',
                  'created_at', 'updated_at']
        read_only_fields = ['id', 'customer', 'created_at', 'updated_at']

# ============ DIAGNOSIS ============
class DTCCodeSerializer(serializers.ModelSerializer):
    class Meta:
        model = DTCCode
        fields = ['id', 'code', 'description', 'possible_causes', 'solutions']

class DiagnosisSessionSerializer(serializers.ModelSerializer):
    class Meta:
        model = DiagnosisSession
        fields = ['id', 'user', 'vehicle', 'mechanic', 'session_id', 'source',
                  'status', 'started_at', 'completed_at', 'mileage',
                  'battery_voltage', 'protocol', 'device_name', 'device_mac_address',
                  'raw_data', 'summary', 'notes', 'error_message',
                  'created_at', 'updated_at']
        read_only_fields = ['id', 'user', 'created_at', 'updated_at']
    def create(self, validated_data):
        request = self.context.get('request')
        if request and hasattr(request, 'user'):
            validated_data['user'] = request.user
        return super().create(validated_data)

class DiagnosisDTCSerializer(serializers.ModelSerializer):
    dtc_code = DTCCodeSerializer(read_only=True)

    class Meta:
        model = DiagnosisDTC
        fields = [
            'id',
            'session',
            'dtc_code',
            'raw_code',
            'status',
            'detected_at',
        ]
        read_only_fields = ['id', 'detected_at']

class OBDReadingSerializer(serializers.ModelSerializer):
    class Meta:
        model = OBDReading
        fields = ['id', 'session', 'pid', 'value', 'unit', 'timestamp']

class OBDScanEventSerializer(serializers.ModelSerializer):
    class Meta:
        model = OBDScanEvent
        fields = ['id', 'session', 'event_type', 'description', 'data', 'created_at']

# ============ REVIEWS ============
class ReviewSerializer(serializers.ModelSerializer):
    customer_name = serializers.SerializerMethodField()
    class Meta:
        model = Review
        fields = ['id', 'customer_name', 'mechanic', 'booking', 'service',
                  'overall_rating', 'comment', 'status', 'is_verified',
                  'created_at', 'updated_at']
        read_only_fields = ['id', 'customer', 'created_at', 'updated_at']
    def get_customer_name(self, obj):
        return obj.customer.email
    def create(self, validated_data):
        request = self.context.get('request')
        if request and hasattr(request, 'user'):
            validated_data['customer'] = request.user
        if 'reference' not in validated_data:
            import uuid
            validated_data['reference'] = f"REV-{uuid.uuid4().hex[:8].upper()}"
        return super().create(validated_data)

# ============ WALLET ============
class WalletSerializer(serializers.ModelSerializer):
    class Meta:
        model = Wallet
        fields = ['id', 'user', 'balance', 'currency']
        read_only_fields = ['id', 'user', 'balance', 'currency']

class TransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Transaction
        fields = ['id', 'wallet', 'amount', 'transaction_type', 'status', 'reference', 'created_at']
        read_only_fields = ['id', 'wallet', 'created_at']

# ============ PAYMENT ============
class PaymentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Payment
        fields = ['id', 'user', 'amount', 'provider', 'status', 'external_reference', 'created_at']

# ============ NEWS ============
class NewsSerializer(serializers.ModelSerializer):
    class Meta:
        model = News
        fields = [
            'id', 'title', 'slug', 'summary', 'content',
            'featured_image', 'video_url', 'status',
            'published_at', 'created_at',
        ]

# ============ ADVERTISEMENT ============
class AdvertisementSerializer(serializers.ModelSerializer):
    class Meta:
        model = Advertisement
        fields = [
            'id', 'reference', 'title', 'description',
            'advertisement_type', 'image', 'video',
            'target_url', 'status', 'start_at', 'end_at',
            'priority', 'created_at',
        ]

# ============ NOTIFICATIONS ============
class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ['id', 'recipient', 'notification_type', 'title', 'message', 'is_read', 'created_at']
        read_only_fields = ['id', 'recipient', 'created_at']

class NotificationDeviceSerializer(serializers.ModelSerializer):
    class Meta:
        model = NotificationDevice
        fields = ['id', 'user', 'device_token', 'device_type', 'is_active', 'created_at']
        read_only_fields = ['id', 'user', 'created_at']

# ============ CHAT ============
class MessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = Message
        fields = ['id', 'room', 'sender', 'content', 'created_at']
        read_only_fields = ['id', 'sender', 'created_at']

class ChatRoomSerializer(serializers.ModelSerializer):
    class Meta:
        model = ChatRoom
        fields = ['id', 'name', 'room_type', 'created_at']
        read_only_fields = ['id', 'created_at']

# ============ TRACKING ============
class TrackingSessionSerializer(serializers.ModelSerializer):
    class Meta:
        model = TrackingSession
        fields = ['id', 'user', 'vehicle', 'tracking_type', 'status', 'started_at', 'ended_at']
        read_only_fields = ['id', 'user', 'created_at']

class VehicleLocationSerializer(serializers.ModelSerializer):
    class Meta:
        model = VehicleLocation
        fields = ['id', 'vehicle', 'latitude', 'longitude', 'recorded_at']
        read_only_fields = ['id', 'recorded_at']

class MechanicLocationSerializer(serializers.ModelSerializer):
    class Meta:
        model = MechanicLocation
        fields = ['id', 'mechanic', 'latitude', 'longitude', 'altitude', 'accuracy',
                  'speed_kmh', 'heading', 'is_online', 'recorded_at', 'created_at']
        read_only_fields = ['id', 'recorded_at', 'created_at']

class GeofenceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Geofence
        fields = ['id', 'user', 'vehicle', 'name', 'center_lat', 'center_lng', 'radius', 'is_active']
        read_only_fields = ['id', 'user']

# ============ PASSWORD RESET ============
from apps.accounts.models import PasswordResetCode, User

class PasswordResetRequestSerializer(serializers.Serializer):
    email = serializers.EmailField()

class PasswordResetVerifySerializer(serializers.Serializer):
    email = serializers.EmailField()
    code = serializers.CharField(max_length=6)

class PasswordResetConfirmSerializer(serializers.Serializer):
    email = serializers.EmailField()
    code = serializers.CharField(max_length=6)
    new_password = serializers.CharField(min_length=6)

# ============ VIDEO ============
class VideoSerializer(serializers.ModelSerializer):
    class Meta:
        model = News
        fields = ['id', 'title', 'content', 'image', 'video_url', 'video_file', 'created_at']
        read_only_fields = ['id', 'created_at']

# ============ AI DIAGNOSTIC ASSISTANT ============
class ServiceProblemSerializer(serializers.Serializer):
    vehicle_make = serializers.CharField(max_length=100)
    vehicle_model = serializers.CharField(max_length=100)
    vehicle_year = serializers.IntegerField()
    engine_type = serializers.CharField(max_length=50, required=False, allow_blank=True)
    fuel_type = serializers.CharField(max_length=20, required=False, allow_blank=True)
    mileage = serializers.IntegerField(required=False, allow_null=True)
    symptoms = serializers.CharField(max_length=500)
    additional_info = serializers.CharField(max_length=500, required=False, allow_blank=True)

class DiagnosisResponseSerializer(serializers.Serializer):
    possible_causes = serializers.ListField(child=serializers.CharField())
    recommended_actions = serializers.ListField(child=serializers.CharField())
    safety_warnings = serializers.ListField(child=serializers.CharField())
    should_call_mechanic = serializers.BooleanField()
    mechanic_specialty = serializers.CharField()
    diagnosis_id = serializers.CharField(required=False)
