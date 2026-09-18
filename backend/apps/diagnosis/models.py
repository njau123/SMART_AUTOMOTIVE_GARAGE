from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone

User = get_user_model()


class DTCSystem(models.TextChoices):
    POWERTRAIN = "POWERTRAIN", "Powertrain"
    CHASSIS = "CHASSIS", "Chassis"
    BODY = "BODY", "Body"
    NETWORK = "NETWORK", "Network"
    GENERIC = "GENERIC", "Generic"


class DTCCategory(models.TextChoices):
    ENGINE = "ENGINE", "Engine"
    TRANSMISSION = "TRANSMISSION", "Transmission"
    EMISSIONS = "EMISSIONS", "Emissions"
    FUEL = "FUEL", "Fuel"
    IGNITION = "IGNITION", "Ignition"
    COOLING = "COOLING", "Cooling"
    BRAKE = "BRAKE", "Brake"
    ELECTRICAL = "ELECTRICAL", "Electrical"
    COMMUNICATION = "COMMUNICATION", "Communication"
    OTHER = "OTHER", "Other"


class DiagnosisSeverity(models.TextChoices):
    LOW = "LOW", "Low"
    MEDIUM = "MEDIUM", "Medium"
    HIGH = "HIGH", "High"
    CRITICAL = "CRITICAL", "Critical"


class DTCCode(models.Model):
    code = models.CharField(max_length=10, unique=True)

    system = models.CharField(
        max_length=30,
        choices=DTCSystem.choices,
        default=DTCSystem.GENERIC,
    )

    category = models.CharField(
        max_length=30,
        choices=DTCCategory.choices,
        default=DTCCategory.OTHER,
    )

    title = models.CharField(max_length=255, blank=True)

    description = models.TextField(blank=True)

    detailed_description = models.TextField(blank=True)

    symptoms = models.JSONField(default=list, blank=True)

    possible_symptoms = models.JSONField(default=list, blank=True)

    possible_causes = models.JSONField(default=list, blank=True)

    diagnostic_steps = models.JSONField(default=list, blank=True)

    recommended_actions = models.JSONField(default=list, blank=True)

    recommended_repair = models.TextField(blank=True)

    recommended_repairs = models.JSONField(default=list, blank=True)

    # Kept for backwards compatibility with the older diagnosis schema.
    solutions = models.TextField(blank=True)

    severity = models.CharField(
        max_length=20,
        choices=DiagnosisSeverity.choices,
        default=DiagnosisSeverity.MEDIUM,
    )

    is_common = models.BooleanField(default=False)

    is_active = models.BooleanField(default=True)

    is_emission_related = models.BooleanField(default=False)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.code} - {self.title or self.description}"

class DiagnosisSession(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='diagnosis_sessions')
    vehicle = models.ForeignKey('vehicles.Vehicle', on_delete=models.SET_NULL, null=True, blank=True)
    mechanic = models.ForeignKey('mechanics.MechanicProfile', on_delete=models.SET_NULL, null=True, blank=True)
    session_id = models.CharField(max_length=50, unique=True, blank=True, null=True)
    source = models.CharField(max_length=20, choices=[('MANUAL', 'Manual'), ('OBD', 'OBD-II'), ('FLUTTER', 'Flutter'), ('MECHANIC', 'Mechanic')], default='MANUAL')
    status = models.CharField(max_length=20, choices=[('PENDING', 'Pending'), ('CONNECTING', 'Connecting'), ('SCANNING', 'Scanning'), ('PROCESSING', 'Processing'), ('COMPLETED', 'Completed'), ('COMPLETED_WITH_DTC', 'Completed with DTC'), ('FAILED', 'Failed'), ('CANCELLED', 'Cancelled')], default='PENDING')
    started_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    mileage = models.PositiveIntegerField(null=True, blank=True)
    battery_voltage = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    protocol = models.CharField(max_length=100, blank=True)
    device_name = models.CharField(max_length=100, blank=True)
    device_mac_address = models.CharField(max_length=50, blank=True)
    raw_data = models.JSONField(default=dict, blank=True)
    summary = models.TextField(blank=True)
    notes = models.TextField(blank=True)
    error_message = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.session_id or self.id} - {self.status}"

class DiagnosisDTC(models.Model):
    session = models.ForeignKey(DiagnosisSession, on_delete=models.CASCADE, related_name='dtcs')
    dtc_code = models.ForeignKey(DTCCode, on_delete=models.CASCADE)
    raw_code = models.CharField(max_length=20, blank=True)
    status = models.CharField(max_length=20, choices=[('ACTIVE', 'Active'), ('PENDING', 'Pending'), ('HISTORICAL', 'Historical')], default='ACTIVE')
    detected_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('session', 'raw_code')

    def __str__(self):
        return f"{self.dtc_code.code} - {self.session.session_id}"

class OBDPID(models.Model):
    pid = models.CharField(max_length=10, unique=True)
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    unit = models.CharField(max_length=20, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.pid

class OBDReading(models.Model):
    session = models.ForeignKey(DiagnosisSession, on_delete=models.CASCADE, related_name='readings')
    pid = models.ForeignKey(OBDPID, on_delete=models.CASCADE)
    value = models.DecimalField(max_digits=14, decimal_places=4, null=True, blank=True)
    unit = models.CharField(max_length=20, blank=True)
    timestamp = models.DateTimeField(default=timezone.now)

    def __str__(self):
        return f"{self.pid.pid} = {self.value} {self.unit}"

class OBDScanEvent(models.Model):
    session = models.ForeignKey(DiagnosisSession, on_delete=models.CASCADE, related_name='events')
    event_type = models.CharField(max_length=50)
    description = models.TextField(blank=True)
    data = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.event_type} - {self.created_at}"

class DiagnosisEntitlement(models.Model):
    user = models.OneToOneField('accounts.User', on_delete=models.CASCADE, related_name='diagnosis_entitlement')
    free_diagnosis_used = models.BooleanField(default=False)
    free_diagnosis_date = models.DateField(null=True, blank=True)
    paid_diagnosis_count = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user.email} - Free: {not self.free_diagnosis_used}"
