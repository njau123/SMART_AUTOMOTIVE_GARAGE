from django.contrib import admin
from .models import DiagnosisSession, DTCCode, DiagnosisDTC, OBDPID, OBDReading, OBDScanEvent, DiagnosisEntitlement

@admin.register(DiagnosisSession)
class DiagnosisSessionAdmin(admin.ModelAdmin):
    list_display = ['id', 'session_id', 'user', 'vehicle', 'status', 'started_at', 'completed_at']
    list_filter = ['status', 'source']
    search_fields = ['session_id', 'user__email', 'vehicle__registration_number']
    readonly_fields = ['id', 'created_at', 'updated_at']

@admin.register(DTCCode)
class DTCCodeAdmin(admin.ModelAdmin):
    list_display = ['code', 'description']
    search_fields = ['code', 'description']

@admin.register(DiagnosisDTC)
class DiagnosisDTCAdmin(admin.ModelAdmin):
    list_display = ['id', 'session', 'dtc_code', 'status', 'detected_at']
    list_filter = ['status']

@admin.register(OBDPID)
class OBDPIDAdmin(admin.ModelAdmin):
    list_display = ['pid', 'name', 'unit']

@admin.register(OBDReading)
class OBDReadingAdmin(admin.ModelAdmin):
    list_display = ['id', 'session', 'pid', 'value', 'timestamp']

@admin.register(OBDScanEvent)
class OBDScanEventAdmin(admin.ModelAdmin):
    list_display = ['id', 'session', 'event_type', 'created_at']

@admin.register(DiagnosisEntitlement)
class DiagnosisEntitlementAdmin(admin.ModelAdmin):
    list_display = ['id', 'user', 'free_diagnosis_used', 'paid_diagnosis_count', 'created_at']
    list_filter = ['free_diagnosis_used']
    search_fields = ['user__email']
