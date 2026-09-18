from django.apps import AppConfig


class DiagnosisConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.diagnosis'
    verbose_name = 'Diagnosis'

    def ready(self):
        """Import signals when app is ready"""
        try:
            import apps.diagnosis.signals  # noqa
        except ImportError:
            pass
