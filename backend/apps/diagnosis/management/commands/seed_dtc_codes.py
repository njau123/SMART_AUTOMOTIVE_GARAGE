from django.core.management.base import BaseCommand

from apps.diagnosis.models import (
    DTCCode,
    DTCSystem,
    DTCCategory,
    DiagnosisSeverity,
)


DTC_DATA = [
    {
        "code": "P0300",
        "system": DTCSystem.POWERTRAIN,
        "category": DTCCategory.ENGINE,
        "title": "Random/Multiple Cylinder Misfire Detected",
        "description": (
            "The engine control module has detected "
            "random or multiple cylinder misfires."
        ),
        "possible_causes": [
            "Worn spark plugs",
            "Faulty ignition coils",
            "Fuel injector problem",
            "Low fuel pressure",
            "Vacuum leak",
            "Low engine compression",
            "Crankshaft or camshaft sensor problem",
        ],
        "possible_symptoms": [
            "Engine shaking",
            "Rough idle",
            "Poor acceleration",
            "Check engine light",
            "Reduced fuel economy",
        ],
        "diagnostic_steps": [
            "Check freeze-frame data",
            "Inspect spark plugs",
            "Inspect ignition coils",
            "Check fuel pressure",
            "Check injector operation",
            "Perform compression test if necessary",
        ],
        "recommended_repairs": [
            "Replace faulty spark plugs",
            "Repair or replace ignition components",
            "Repair fuel delivery problem",
            "Repair vacuum leak",
            "Perform engine mechanical inspection",
        ],
        "severity": DiagnosisSeverity.HIGH,
        "is_emission_related": True,
    },
    {
        "code": "P0301",
        "system": DTCSystem.POWERTRAIN,
        "category": DTCCategory.ENGINE,
        "title": "Cylinder 1 Misfire Detected",
        "description": (
            "A misfire has been detected on cylinder 1."
        ),
        "possible_causes": [
            "Faulty spark plug",
            "Faulty ignition coil",
            "Fuel injector failure",
            "Low compression",
            "Vacuum leak",
        ],
        "possible_symptoms": [
            "Engine vibration",
            "Rough idle",
            "Poor acceleration",
            "Check engine light",
        ],
        "diagnostic_steps": [
            "Inspect cylinder 1 spark plug",
            "Test ignition coil",
            "Inspect injector",
            "Check compression",
            "Check intake leaks",
        ],
        "recommended_repairs": [
            "Replace defective ignition component",
            "Replace faulty injector",
            "Repair intake leak",
            "Repair mechanical engine problem",
        ],
        "severity": DiagnosisSeverity.HIGH,
        "is_emission_related": True,
    },
    {
        "code": "P0302",
        "system": DTCSystem.POWERTRAIN,
        "category": DTCCategory.ENGINE,
        "title": "Cylinder 2 Misfire Detected",
        "description": (
            "A misfire has been detected on cylinder 2."
        ),
        "possible_causes": [
            "Faulty spark plug",
            "Faulty ignition coil",
            "Fuel injector problem",
            "Low compression",
            "Vacuum leak",
        ],
        "possible_symptoms": [
            "Engine vibration",
            "Rough idle",
            "Poor acceleration",
            "Check engine light",
        ],
        "diagnostic_steps": [
            "Inspect spark plug",
            "Test ignition coil",
            "Test fuel injector",
            "Check compression",
        ],
        "recommended_repairs": [
            "Replace faulty spark plug",
            "Replace faulty coil",
            "Repair injector",
            "Repair mechanical engine problem",
        ],
        "severity": DiagnosisSeverity.HIGH,
        "is_emission_related": True,
    },
    {
        "code": "P0303",
        "system": DTCSystem.POWERTRAIN,
        "category": DTCCategory.ENGINE,
        "title": "Cylinder 3 Misfire Detected",
        "description": (
            "A misfire has been detected on cylinder 3."
        ),
        "possible_causes": [
            "Ignition failure",
            "Fuel injector failure",
            "Low compression",
            "Vacuum leak",
        ],
        "possible_symptoms": [
            "Engine shaking",
            "Rough idle",
            "Poor acceleration",
            "Check engine light",
        ],
        "diagnostic_steps": [
            "Inspect spark plug",
            "Inspect ignition coil",
            "Test injector",
            "Perform compression test",
        ],
        "recommended_repairs": [
            "Replace defective ignition component",
            "Repair fuel system",
            "Repair engine mechanical problem",
        ],
        "severity": DiagnosisSeverity.HIGH,
        "is_emission_related": True,
    },
    {
        "code": "P0304",
        "system": DTCSystem.POWERTRAIN,
        "category": DTCCategory.ENGINE,
        "title": "Cylinder 4 Misfire Detected",
        "description": (
            "A misfire has been detected on cylinder 4."
        ),
        "possible_causes": [
            "Faulty spark plug",
            "Ignition coil failure",
            "Fuel injector problem",
            "Low compression",
        ],
        "possible_symptoms": [
            "Engine vibration",
            "Rough idle",
            "Poor acceleration",
            "Check engine light",
        ],
        "diagnostic_steps": [
            "Inspect spark plug",
            "Test ignition coil",
            "Test injector",
            "Check engine compression",
        ],
        "recommended_repairs": [
            "Replace faulty ignition component",
            "Repair injector",
            "Repair mechanical engine problem",
        ],
        "severity": DiagnosisSeverity.HIGH,
        "is_emission_related": True,
    },
    {
        "code": "P0171",
        "system": DTCSystem.POWERTRAIN,
        "category": DTCCategory.FUEL,
        "title": "System Too Lean - Bank 1",
        "description": (
            "The engine is operating with a fuel mixture "
            "that is too lean on bank 1."
        ),
        "possible_causes": [
            "Vacuum leak",
            "Dirty or faulty MAF sensor",
            "Low fuel pressure",
            "Faulty oxygen sensor",
            "Fuel injector restriction",
        ],
        "possible_symptoms": [
            "Rough idle",
            "Poor acceleration",
            "Engine hesitation",
            "Reduced fuel economy",
            "Check engine light",
        ],
        "diagnostic_steps": [
            "Check fuel trims",
            "Inspect vacuum system",
            "Inspect MAF sensor",
            "Check fuel pressure",
            "Inspect oxygen sensor readings",
        ],
        "recommended_repairs": [
            "Repair vacuum leak",
            "Clean or replace MAF sensor",
            "Repair fuel delivery system",
            "Replace faulty sensor",
        ],
        "severity": DiagnosisSeverity.MEDIUM,
        "is_emission_related": True,
    },
    {
        "code": "P0420",
        "system": DTCSystem.POWERTRAIN,
        "category": DTCCategory.EMISSIONS,
        "title": "Catalyst System Efficiency Below Threshold",
        "description": (
            "The catalytic converter efficiency is below "
            "the expected threshold."
        ),
        "possible_causes": [
            "Failed catalytic converter",
            "Oxygen sensor failure",
            "Engine misfire",
            "Exhaust leak",
            "Incorrect fuel mixture",
        ],
        "possible_symptoms": [
            "Check engine light",
            "Reduced fuel economy",
            "Exhaust odor",
            "Reduced engine performance",
        ],
        "diagnostic_steps": [
            "Check oxygen sensor readings",
            "Inspect exhaust system",
            "Check for engine misfires",
            "Compare upstream and downstream O2 readings",
        ],
        "recommended_repairs": [
            "Repair exhaust leak",
            "Repair engine misfire",
            "Replace defective oxygen sensor",
            "Replace catalytic converter if confirmed faulty",
        ],
        "severity": DiagnosisSeverity.MEDIUM,
        "is_emission_related": True,
    },
    {
        "code": "P0101",
        "system": DTCSystem.POWERTRAIN,
        "category": DTCCategory.ENGINE,
        "title": "Mass Air Flow Sensor Performance",
        "description": (
            "The measured mass air flow is outside "
            "the expected operating range."
        ),
        "possible_causes": [
            "Dirty MAF sensor",
            "Faulty MAF sensor",
            "Air intake leak",
            "Blocked air filter",
            "Electrical wiring problem",
        ],
        "possible_symptoms": [
            "Poor acceleration",
            "Rough idle",
            "Engine hesitation",
            "Poor fuel economy",
        ],
        "diagnostic_steps": [
            "Inspect air filter",
            "Inspect intake system",
            "Inspect MAF sensor",
            "Check MAF wiring",
            "Compare MAF readings with expected values",
        ],
        "recommended_repairs": [
            "Clean MAF sensor",
            "Replace MAF sensor if faulty",
            "Repair intake leak",
            "Replace blocked air filter",
        ],
        "severity": DiagnosisSeverity.MEDIUM,
        "is_emission_related": True,
    },
    {
        "code": "P0113",
        "system": DTCSystem.POWERTRAIN,
        "category": DTCCategory.ENGINE,
        "title": "Intake Air Temperature Sensor High Input",
        "description": (
            "The intake air temperature sensor signal "
            "is higher than the expected range."
        ),
        "possible_causes": [
            "Disconnected IAT sensor",
            "Open circuit",
            "Faulty IAT sensor",
            "Damaged wiring",
        ],
        "possible_symptoms": [
            "Poor fuel economy",
            "Poor engine performance",
            "Check engine light",
        ],
        "diagnostic_steps": [
            "Inspect IAT sensor connector",
            "Inspect wiring",
            "Check sensor resistance",
            "Check live temperature data",
        ],
        "recommended_repairs": [
            "Repair wiring",
            "Reconnect sensor",
            "Replace faulty IAT sensor",
        ],
        "severity": DiagnosisSeverity.MEDIUM,
        "is_emission_related": True,
    },
    {
        "code": "P0128",
        "system": DTCSystem.POWERTRAIN,
        "category": DTCCategory.ENGINE,
        "title": "Coolant Thermostat Temperature Below Regulating Temperature",
        "description": (
            "The engine coolant temperature does not reach "
            "the expected operating temperature within the "
            "required time."
        ),
        "possible_causes": [
            "Thermostat stuck open",
            "Coolant temperature sensor problem",
            "Low coolant level",
            "Cooling system problem",
        ],
        "possible_symptoms": [
            "Low engine temperature",
            "Poor fuel economy",
            "Weak cabin heating",
            "Check engine light",
        ],
        "diagnostic_steps": [
            "Check coolant level",
            "Monitor coolant temperature",
            "Inspect thermostat",
            "Test coolant temperature sensor",
        ],
        "recommended_repairs": [
            "Replace thermostat",
            "Repair coolant leak",
            "Replace faulty temperature sensor",
        ],
        "severity": DiagnosisSeverity.LOW,
        "is_emission_related": True,
    },
    {
        "code": "P0130",
        "system": DTCSystem.POWERTRAIN,
        "category": DTCCategory.EMISSIONS,
        "title": "Oxygen Sensor Circuit Malfunction Bank 1 Sensor 1",
        "description": (
            "The oxygen sensor circuit for bank 1 sensor 1 "
            "has been detected as malfunctioning."
        ),
        "possible_causes": [
            "Faulty oxygen sensor",
            "Damaged wiring",
            "Connector problem",
            "Exhaust leak",
            "ECU circuit problem",
        ],
        "possible_symptoms": [
            "Poor fuel economy",
            "Rough idle",
            "Engine hesitation",
            "Check engine light",
        ],
        "diagnostic_steps": [
            "Inspect sensor wiring",
            "Inspect connector",
            "Check sensor voltage",
            "Inspect exhaust for leaks",
        ],
        "recommended_repairs": [
            "Repair wiring",
            "Repair connector",
            "Replace oxygen sensor",
            "Repair exhaust leak",
        ],
        "severity": DiagnosisSeverity.MEDIUM,
        "is_emission_related": True,
    },
]


class Command(BaseCommand):
    help = "Seed common automotive OBD-II DTC codes."

    def handle(self, *args, **options):
        created_count = 0
        updated_count = 0

        for item in DTC_DATA:
            code = item["code"]

            defaults = {
                key: value
                for key, value in item.items()
                if key != "code"
            }

            dtc, created = DTCCode.objects.update_or_create(
                code=code,
                defaults=defaults,
            )

            if created:
                created_count += 1
            else:
                updated_count += 1

        self.stdout.write(
            self.style.SUCCESS(
                "DTC seed completed successfully."
            )
        )

        self.stdout.write(
            f"Created: {created_count}"
        )

        self.stdout.write(
            f"Updated: {updated_count}"
        )

        self.stdout.write(
            f"Total DTC records: {DTCCode.objects.count()}"
        )
