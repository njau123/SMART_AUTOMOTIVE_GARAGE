from django.core.management.base import BaseCommand

from apps.diagnosis.models import OBDPID


class Command(BaseCommand):
    help = "Seed standard OBD-II Mode 01 PIDs."

    PIDS = [
        {
            "pid": "0105",
            "name": "Engine Coolant Temperature",
            "description": "Engine coolant temperature.",
            "unit": "°C",
            "mode": "01",
            "formula": "A - 40",
            "min_value": -40,
            "max_value": 215,
            "is_live_data": True,
            "is_supported": True,
        },
        {
            "pid": "010B",
            "name": "Intake Manifold Absolute Pressure",
            "description": "Intake manifold absolute pressure.",
            "unit": "kPa",
            "mode": "01",
            "formula": "A",
            "min_value": 0,
            "max_value": 255,
            "is_live_data": True,
            "is_supported": True,
        },
        {
            "pid": "010C",
            "name": "Engine RPM",
            "description": "Engine revolutions per minute.",
            "unit": "rpm",
            "mode": "01",
            "formula": "((A * 256) + B) / 4",
            "min_value": 0,
            "max_value": 16383.75,
            "is_live_data": True,
            "is_supported": True,
        },
        {
            "pid": "010D",
            "name": "Vehicle Speed",
            "description": "Vehicle road speed.",
            "unit": "km/h",
            "mode": "01",
            "formula": "A",
            "min_value": 0,
            "max_value": 255,
            "is_live_data": True,
            "is_supported": True,
        },
        {
            "pid": "010E",
            "name": "Timing Advance",
            "description": "Ignition timing advance.",
            "unit": "degrees",
            "mode": "01",
            "formula": "(A / 2) - 64",
            "min_value": -64,
            "max_value": 63.5,
            "is_live_data": True,
            "is_supported": True,
        },
        {
            "pid": "010F",
            "name": "Intake Air Temperature",
            "description": "Intake air temperature.",
            "unit": "°C",
            "mode": "01",
            "formula": "A - 40",
            "min_value": -40,
            "max_value": 215,
            "is_live_data": True,
            "is_supported": True,
        },
        {
            "pid": "0110",
            "name": "Mass Air Flow",
            "description": "Mass airflow rate.",
            "unit": "g/s",
            "mode": "01",
            "formula": "((A * 256) + B) / 100",
            "min_value": 0,
            "max_value": 655.35,
            "is_live_data": True,
            "is_supported": True,
        },
        {
            "pid": "0111",
            "name": "Throttle Position",
            "description": "Absolute throttle position.",
            "unit": "%",
            "mode": "01",
            "formula": "(A * 100) / 255",
            "min_value": 0,
            "max_value": 100,
            "is_live_data": True,
            "is_supported": True,
        },
        {
            "pid": "011F",
            "name": "Run Time Since Engine Start",
            "description": "Time elapsed since engine started.",
            "unit": "seconds",
            "mode": "01",
            "formula": "(A * 256) + B",
            "min_value": 0,
            "max_value": 65535,
            "is_live_data": True,
            "is_supported": True,
        },
        {
            "pid": "012F",
            "name": "Fuel Level Input",
            "description": "Fuel tank level.",
            "unit": "%",
            "mode": "01",
            "formula": "(A * 100) / 255",
            "min_value": 0,
            "max_value": 100,
            "is_live_data": True,
            "is_supported": True,
        },
        {
            "pid": "0131",
            "name": "Distance Since Codes Cleared",
            "description": "Distance travelled since DTCs were cleared.",
            "unit": "km",
            "mode": "01",
            "formula": "(A * 256) + B",
            "min_value": 0,
            "max_value": 65535,
            "is_live_data": False,
            "is_supported": True,
        },
        {
            "pid": "0142",
            "name": "Control Module Voltage",
            "description": "Vehicle control module voltage.",
            "unit": "V",
            "mode": "01",
            "formula": "((A * 256) + B) / 1000",
            "min_value": 0,
            "max_value": 65.535,
            "is_live_data": True,
            "is_supported": True,
        },
        {
            "pid": "0146",
            "name": "Ambient Air Temperature",
            "description": "Ambient air temperature.",
            "unit": "°C",
            "mode": "01",
            "formula": "A - 40",
            "min_value": -40,
            "max_value": 215,
            "is_live_data": True,
            "is_supported": True,
        },
        {
            "pid": "014C",
            "name": "Commanded Throttle Actuator",
            "description": "Commanded throttle actuator position.",
            "unit": "%",
            "mode": "01",
            "formula": "(A * 100) / 255",
            "min_value": 0,
            "max_value": 100,
            "is_live_data": True,
            "is_supported": True,
        },
    ]

    def handle(self, *args, **options):
        created_count = 0
        updated_count = 0

        for pid_data in self.PIDS:
            pid = pid_data["pid"]

            defaults = {
                key: value
                for key, value in pid_data.items()
                if key != "pid"
            }

            obj, created = OBDPID.objects.update_or_create(
                pid=pid,
                defaults=defaults,
            )

            if created:
                created_count += 1
            else:
                updated_count += 1

        self.stdout.write(
            self.style.SUCCESS(
                f"OBD-II PID seed completed. Created: {created_count}, Updated: {updated_count}"
            )
        )
