from django.core.management.base import BaseCommand

from apps.diagnosis.models import DTCCode


class Command(BaseCommand):
    help = "Seed the Smart Automotive Garage DTC master catalogue."

    DTC_CODES = [
        {
            "code": "P0100",
            "system": "Fuel and Air Metering",
            "title": "Mass or Volume Air Flow Circuit Malfunction",
            "description": (
                "The engine control module has detected a malfunction "
                "in the mass airflow or volume airflow circuit."
            ),
            "severity": "MEDIUM",
            "symptoms": [
                "Rough engine idle",
                "Poor acceleration",
                "Reduced fuel economy",
                "Engine hesitation",
                "Check engine light",
            ],
            "possible_causes": [
                "Faulty MAF sensor",
                "Damaged MAF wiring",
                "Loose electrical connector",
                "Air intake leak",
                "Dirty air filter",
            ],
            "diagnostic_steps": [
                "Inspect the MAF sensor connector.",
                "Inspect wiring for damage.",
                "Check for air intake leaks.",
                "Inspect and clean the MAF sensor if appropriate.",
                "Compare live MAF readings with manufacturer specifications.",
            ],
            "recommended_repair": (
                "Inspect the MAF circuit and intake system. "
                "Repair wiring or replace the MAF sensor if confirmed faulty."
            ),
            "is_common": True,
            "is_active": True,
        },
        {
            "code": "P0101",
            "system": "Fuel and Air Metering",
            "title": "Mass or Volume Air Flow Circuit Range/Performance",
            "description": (
                "The MAF sensor signal is outside the expected operating "
                "range or does not match calculated engine airflow."
            ),
            "severity": "MEDIUM",
            "symptoms": [
                "Poor acceleration",
                "Rough idle",
                "Engine hesitation",
                "Poor fuel economy",
                "Check engine light",
            ],
            "possible_causes": [
                "Dirty MAF sensor",
                "Faulty MAF sensor",
                "Air intake leak",
                "Blocked air filter",
                "Wiring problem",
            ],
            "diagnostic_steps": [
                "Inspect air filter.",
                "Inspect intake pipes and clamps.",
                "Check MAF sensor readings.",
                "Inspect sensor wiring.",
                "Compare calculated and measured airflow.",
            ],
            "recommended_repair": (
                "Repair intake leaks, service the MAF sensor or replace it "
                "when testing confirms failure."
            ),
            "is_common": True,
            "is_active": True,
        },
        {
            "code": "P0102",
            "system": "Fuel and Air Metering",
            "title": "Mass or Volume Air Flow Circuit Low Input",
            "description": (
                "The MAF sensor signal is lower than the expected range."
            ),
            "severity": "MEDIUM",
            "symptoms": [
                "Low engine power",
                "Poor acceleration",
                "Rough idle",
                "Poor fuel economy",
            ],
            "possible_causes": [
                "Faulty MAF sensor",
                "Dirty sensor element",
                "Electrical wiring fault",
                "Air intake restriction",
            ],
            "diagnostic_steps": [
                "Inspect MAF wiring and connector.",
                "Inspect sensor condition.",
                "Check air intake restriction.",
                "Check live MAF data.",
            ],
            "recommended_repair": (
                "Repair the circuit or replace/service the MAF sensor "
                "after confirming the fault."
            ),
            "is_common": True,
            "is_active": True,
        },
        {
            "code": "P0103",
            "system": "Fuel and Air Metering",
            "title": "Mass or Volume Air Flow Circuit High Input",
            "description": (
                "The MAF sensor signal is higher than the expected range."
            ),
            "severity": "MEDIUM",
            "symptoms": [
                "Poor engine performance",
                "Rough idle",
                "Poor fuel economy",
                "Check engine light",
            ],
            "possible_causes": [
                "Faulty MAF sensor",
                "Wiring problem",
                "Incorrect sensor installation",
                "Electrical interference",
            ],
            "diagnostic_steps": [
                "Inspect MAF wiring.",
                "Check sensor supply voltage.",
                "Check sensor ground.",
                "Compare live MAF readings.",
            ],
            "recommended_repair": (
                "Repair the MAF circuit or replace the sensor when "
                "diagnostic testing confirms failure."
            ),
            "is_common": True,
            "is_active": True,
        },
        {
            "code": "P0110",
            "system": "Intake Air Temperature",
            "title": "Intake Air Temperature Sensor Circuit Malfunction",
            "description": (
                "The intake air temperature sensor circuit is malfunctioning."
            ),
            "severity": "MEDIUM",
            "symptoms": [
                "Poor fuel economy",
                "Hard starting",
                "Poor engine performance",
                "Check engine light",
            ],
            "possible_causes": [
                "Faulty IAT sensor",
                "Damaged wiring",
                "Loose connector",
                "Short circuit",
                "Open circuit",
            ],
            "diagnostic_steps": [
                "Inspect the IAT connector.",
                "Inspect wiring.",
                "Measure sensor resistance.",
                "Compare sensor reading with ambient temperature.",
            ],
            "recommended_repair": (
                "Repair the wiring or replace the IAT sensor if confirmed faulty."
            ),
            "is_common": True,
            "is_active": True,
        },
        {
            "code": "P0111",
            "system": "Intake Air Temperature",
            "title": "Intake Air Temperature Sensor Range/Performance",
            "description": (
                "The intake air temperature sensor reading is outside "
                "the expected operating range."
            ),
            "severity": "MEDIUM",
            "symptoms": [
                "Poor acceleration",
                "Poor fuel economy",
                "Hard starting",
                "Engine hesitation",
            ],
            "possible_causes": [
                "Faulty IAT sensor",
                "Wiring fault",
                "Air intake problem",
                "Sensor contamination",
            ],
            "diagnostic_steps": [
                "Compare IAT reading with ambient temperature.",
                "Inspect wiring.",
                "Check sensor resistance.",
                "Check connector condition.",
            ],
            "recommended_repair": (
                "Repair the circuit or replace the IAT sensor when required."
            ),
            "is_common": True,
            "is_active": True,
        },
        {
            "code": "P0120",
            "system": "Throttle/Pedal Position",
            "title": "Throttle/Pedal Position Sensor Circuit Malfunction",
            "description": (
                "The throttle or pedal position sensor circuit has "
                "been detected as faulty."
            ),
            "severity": "HIGH",
            "symptoms": [
                "Poor acceleration",
                "Engine hesitation",
                "Limp mode",
                "Unstable idle",
                "Reduced throttle response",
            ],
            "possible_causes": [
                "Faulty throttle position sensor",
                "Damaged accelerator pedal sensor",
                "Wiring fault",
                "Connector problem",
                "Throttle body fault",
            ],
            "diagnostic_steps": [
                "Inspect throttle body connector.",
                "Inspect accelerator pedal wiring.",
                "Check sensor reference voltage.",
                "Check sensor signal.",
                "Compare pedal and throttle position data.",
            ],
            "recommended_repair": (
                "Repair the electrical circuit or replace the affected "
                "sensor/throttle component after confirmation."
            ),
            "is_common": True,
            "is_active": True,
        },
        {
            "code": "P0130",
            "system": "Oxygen Sensor",
            "title": "O2 Sensor Circuit Malfunction Bank 1 Sensor 1",
            "description": (
                "The oxygen sensor circuit on Bank 1 Sensor 1 is malfunctioning."
            ),
            "severity": "MEDIUM",
            "symptoms": [
                "Poor fuel economy",
                "Rough idle",
                "Increased emissions",
                "Check engine light",
            ],
            "possible_causes": [
                "Faulty oxygen sensor",
                "Damaged sensor wiring",
                "Exhaust leak",
                "Connector problem",
                "Fuel mixture problem",
            ],
            "diagnostic_steps": [
                "Inspect O2 sensor wiring.",
                "Check sensor heater circuit.",
                "Inspect exhaust for leaks.",
                "Monitor oxygen sensor live data.",
                "Check fuel trims.",
            ],
            "recommended_repair": (
                "Repair wiring or exhaust leaks and replace the O2 sensor "
                "if confirmed defective."
            ),
            "is_common": True,
            "is_active": True,
        },
        {
            "code": "P0133",
            "system": "Oxygen Sensor",
            "title": "O2 Sensor Circuit Slow Response",
            "description": (
                "The oxygen sensor is responding more slowly than expected "
                "to changes in the air-fuel mixture."
            ),
            "severity": "MEDIUM",
            "symptoms": [
                "Poor fuel economy",
                "Increased emissions",
                "Rough idle",
                "Reduced engine performance",
            ],
            "possible_causes": [
                "Aged oxygen sensor",
                "Contaminated sensor",
                "Fuel system problem",
                "Exhaust leak",
                "Wiring issue",
            ],
            "diagnostic_steps": [
                "Check O2 sensor switching activity.",
                "Inspect exhaust system.",
                "Check fuel trims.",
                "Inspect sensor wiring.",
            ],
            "recommended_repair": (
                "Repair underlying fuel/exhaust problems and replace the "
                "sensor if testing confirms slow response."
            ),
            "is_common": True,
            "is_active": True,
        },
        {
            "code": "P0171",
            "system": "Fuel and Air Metering",
            "title": "System Too Lean Bank 1",
            "description": (
                "The engine control system has detected a lean air-fuel mixture "
                "on Bank 1."
            ),
            "severity": "HIGH",
            "symptoms": [
                "Rough idle",
                "Engine hesitation",
                "Poor acceleration",
                "Misfire",
                "Poor fuel economy",
            ],
            "possible_causes": [
                "Vacuum leak",
                "Intake manifold leak",
                "Low fuel pressure",
                "Dirty fuel injector",
                "Faulty MAF sensor",
                "Exhaust leak near oxygen sensor",
            ],
            "diagnostic_steps": [
                "Check short-term and long-term fuel trims.",
                "Inspect vacuum hoses.",
                "Check intake manifold leaks.",
                "Check fuel pressure.",
                "Inspect MAF sensor.",
                "Test fuel injectors.",
            ],
            "recommended_repair": (
                "Repair the source of unmetered air or fuel delivery "
                "problem after confirming the root cause."
            ),
            "is_common": True,
            "is_active": True,
        },
        {
            "code": "P0172",
            "system": "Fuel and Air Metering",
            "title": "System Too Rich Bank 1",
            "description": (
                "The engine control system has detected a rich air-fuel mixture "
                "on Bank 1."
            ),
            "severity": "HIGH",
            "symptoms": [
                "Black exhaust smoke",
                "Poor fuel economy",
                "Rough idle",
                "Fuel smell",
                "Poor acceleration",
            ],
            "possible_causes": [
                "Leaking fuel injector",
                "High fuel pressure",
                "Faulty MAF sensor",
                "Faulty oxygen sensor",
                "Restricted air intake",
            ],
            "diagnostic_steps": [
                "Check fuel trims.",
                "Inspect MAF readings.",
                "Check fuel pressure.",
                "Inspect fuel injectors.",
                "Inspect air intake.",
            ],
            "recommended_repair": (
                "Correct the fuel or airflow problem after diagnostic confirmation."
            ),
            "is_common": True,
            "is_active": True,
        },
        {
            "code": "P0200",
            "system": "Fuel Injector",
            "title": "Injector Circuit Malfunction",
            "description": (
                "The engine control module has detected a fuel injector "
                "circuit malfunction."
            ),
            "severity": "HIGH",
            "symptoms": [
                "Engine misfire",
                "Poor acceleration",
                "Rough idle",
                "Reduced engine power",
                "Poor fuel economy",
            ],
            "possible_causes": [
                "Faulty injector",
                "Open circuit",
                "Short circuit",
                "Damaged wiring",
                "Injector connector problem",
            ],
            "diagnostic_steps": [
                "Inspect injector connectors.",
                "Inspect wiring.",
                "Measure injector resistance.",
                "Check injector control signal.",
                "Perform injector balance testing.",
            ],
            "recommended_repair": (
                "Repair injector wiring or replace the injector if testing "
                "confirms failure."
            ),
            "is_common": True,
            "is_active": True,
        },
        {
            "code": "P0300",
            "system": "Ignition/Misfire",
            "title": "Random or Multiple Cylinder Misfire Detected",
            "description": (
                "The engine control module has detected random or multiple "
                "cylinder misfires."
            ),
            "severity": "CRITICAL",
            "symptoms": [
                "Engine shaking",
                "Rough idle",
                "Loss of power",
                "Flashing check engine light",
                "Poor acceleration",
                "Increased fuel consumption",
            ],
            "possible_causes": [
                "Worn spark plugs",
                "Faulty ignition coils",
                "Fuel injector problem",
                "Low fuel pressure",
                "Vacuum leak",
                "Low engine compression",
                "Timing problem",
            ],
            "diagnostic_steps": [
                "Check freeze-frame data.",
                "Check individual cylinder misfire counters.",
                "Inspect spark plugs.",
                "Test ignition coils.",
                "Check fuel pressure.",
                "Check injector operation.",
                "Perform compression testing when necessary.",
            ],
            "recommended_repair": (
                "Do not replace parts blindly. Diagnose the ignition, fuel, "
                "air and mechanical systems to identify the root cause."
            ),
            "is_common": True,
            "is_active": True,
        },
        {
            "code": "P0301",
            "system": "Ignition/Misfire",
            "title": "Cylinder 1 Misfire Detected",
            "description": (
                "The engine control module has detected a misfire on cylinder 1."
            ),
            "severity": "HIGH",
            "symptoms": [
                "Engine vibration",
                "Rough idle",
                "Loss of power",
                "Poor acceleration",
            ],
            "possible_causes": [
                "Faulty spark plug",
                "Faulty ignition coil",
                "Fuel injector fault",
                "Low compression",
                "Vacuum leak",
            ],
            "diagnostic_steps": [
                "Inspect cylinder 1 spark plug.",
                "Swap ignition coil with another cylinder where appropriate.",
                "Check injector operation.",
                "Perform compression test if necessary.",
            ],
            "recommended_repair": (
                "Repair the confirmed ignition, fuel or mechanical fault "
                "affecting cylinder 1."
            ),
            "is_common": True,
            "is_active": True,
        },
        {
            "code": "P0302",
            "system": "Ignition/Misfire",
            "title": "Cylinder 2 Misfire Detected",
            "description": (
                "The engine control module has detected a misfire on cylinder 2."
            ),
            "severity": "HIGH",
            "symptoms": [
                "Engine vibration",
                "Rough idle",
                "Loss of power",
                "Poor acceleration",
            ],
            "possible_causes": [
                "Faulty spark plug",
                "Faulty ignition coil",
                "Fuel injector fault",
                "Low compression",
                "Vacuum leak",
            ],
            "diagnostic_steps": [
                "Inspect cylinder 2 spark plug.",
                "Test ignition coil.",
                "Check injector operation.",
                "Perform compression testing if required.",
            ],
            "recommended_repair": (
                "Repair the confirmed cause of the cylinder 2 misfire."
            ),
            "is_common": True,
            "is_active": True,
        },
        {
            "code": "P0303",
            "system": "Ignition/Misfire",
            "title": "Cylinder 3 Misfire Detected",
            "description": (
                "The engine control module has detected a misfire on cylinder 3."
            ),
            "severity": "HIGH",
            "symptoms": [
                "Engine vibration",
                "Rough idle",
                "Loss of power",
                "Poor acceleration",
            ],
            "possible_causes": [
                "Faulty spark plug",
                "Faulty ignition coil",
                "Fuel injector fault",
                "Low compression",
                "Vacuum leak",
            ],
            "diagnostic_steps": [
                "Inspect cylinder 3 spark plug.",
                "Test ignition coil.",
                "Check injector operation.",
                "Perform compression testing if required.",
            ],
            "recommended_repair": (
                "Repair the confirmed cause of the cylinder 3 misfire."
            ),
            "is_common": True,
            "is_active": True,
        },
        {
            "code": "P0304",
            "system": "Ignition/Misfire",
            "title": "Cylinder 4 Misfire Detected",
            "description": (
                "The engine control module has detected a misfire on cylinder 4."
            ),
            "severity": "HIGH",
            "symptoms": [
                "Engine vibration",
                "Rough idle",
                "Loss of power",
                "Poor acceleration",
            ],
            "possible_causes": [
                "Faulty spark plug",
                "Faulty ignition coil",
                "Fuel injector fault",
                "Low compression",
                "Vacuum leak",
            ],
            "diagnostic_steps": [
                "Inspect cylinder 4 spark plug.",
                "Test ignition coil.",
                "Check injector operation.",
                "Perform compression testing if required.",
            ],
            "recommended_repair": (
                "Repair the confirmed cause of the cylinder 4 misfire."
            ),
            "is_common": True,
            "is_active": True,
        },
        {
            "code": "P0401",
            "system": "Exhaust Gas Recirculation",
            "title": "Exhaust Gas Recirculation Insufficient Flow",
            "description": (
                "The EGR system is delivering less exhaust gas recirculation "
                "than expected."
            ),
            "severity": "MEDIUM",
            "symptoms": [
                "Engine hesitation",
                "Rough idle",
                "Reduced performance",
                "Increased emissions",
            ],
            "possible_causes": [
                "Blocked EGR passage",
                "Faulty EGR valve",
                "Vacuum problem",
                "Faulty EGR sensor",
                "Carbon buildup",
            ],
            "diagnostic_steps": [
                "Inspect EGR valve.",
                "Inspect EGR passages.",
                "Check EGR control signal.",
                "Check related sensors.",
            ],
            "recommended_repair": (
                "Clean blocked EGR passages or repair/replace the faulty "
                "EGR component."
            ),
            "is_common": True,
            "is_active": True,
        },
        {
            "code": "P0420",
            "system": "Catalyst System",
            "title": "Catalyst System Efficiency Below Threshold Bank 1",
            "description": (
                "The catalytic converter efficiency is below the threshold "
                "expected by the engine control module."
            ),
            "severity": "MEDIUM",
            "symptoms": [
                "Check engine light",
                "Reduced fuel economy",
                "Increased emissions",
                "Occasional loss of performance",
            ],
            "possible_causes": [
                "Worn catalytic converter",
                "Exhaust leak",
                "Faulty oxygen sensor",
                "Engine misfire",
                "Rich or lean mixture",
            ],
            "diagnostic_steps": [
                "Check for other DTCs first.",
                "Inspect exhaust system for leaks.",
                "Compare upstream and downstream O2 sensor data.",
                "Check fuel trims.",
                "Check for previous misfire conditions.",
            ],
            "recommended_repair": (
                "Identify and correct the underlying engine or exhaust problem "
                "before replacing the catalytic converter."
            ),
            "is_common": True,
            "is_active": True,
        },
        {
            "code": "P0440",
            "system": "Evaporative Emission Control",
            "title": "Evaporative Emission Control System Malfunction",
            "description": (
                "The EVAP system has detected a general malfunction."
            ),
            "severity": "MEDIUM",
            "symptoms": [
                "Check engine light",
                "Fuel smell",
                "Possible difficulty starting",
            ],
            "possible_causes": [
                "Loose fuel cap",
                "EVAP leak",
                "Faulty purge valve",
                "Faulty vent valve",
                "Damaged EVAP hose",
            ],
            "diagnostic_steps": [
                "Inspect fuel cap.",
                "Inspect EVAP hoses.",
                "Perform EVAP leak test.",
                "Test purge and vent valves.",
            ],
            "recommended_repair": (
                "Repair the confirmed EVAP leak or replace the failed component."
            ),
            "is_common": True,
            "is_active": True,
        },
        {
            "code": "P0500",
            "system": "Vehicle Speed Sensor",
            "title": "Vehicle Speed Sensor Malfunction",
            "description": (
                "The vehicle speed signal is missing or outside the expected range."
            ),
            "severity": "HIGH",
            "symptoms": [
                "Speedometer malfunction",
                "Transmission shifting problems",
                "ABS warning",
                "Cruise control malfunction",
            ],
            "possible_causes": [
                "Faulty vehicle speed sensor",
                "Damaged wiring",
                "Wheel speed sensor issue",
                "ABS module communication problem",
            ],
            "diagnostic_steps": [
                "Check vehicle speed live data.",
                "Inspect sensor wiring.",
                "Check wheel speed signals.",
                "Inspect related ABS/ECU communication.",
            ],
            "recommended_repair": (
                "Repair the speed signal circuit or replace the failed sensor "
                "after proper diagnosis."
            ),
            "is_common": True,
            "is_active": True,
        },
        {
            "code": "P0600",
            "system": "Computer/Communication",
            "title": "Serial Communication Link Malfunction",
            "description": (
                "The control module has detected a communication link problem."
            ),
            "severity": "HIGH",
            "symptoms": [
                "Multiple warning lights",
                "Intermittent vehicle faults",
                "Module communication failures",
                "No-start condition in severe cases",
            ],
            "possible_causes": [
                "CAN communication fault",
                "Damaged wiring",
                "Poor electrical connection",
                "Low battery voltage",
                "Faulty control module",
            ],
            "diagnostic_steps": [
                "Check battery voltage.",
                "Scan all control modules.",
                "Check communication DTCs.",
                "Inspect CAN wiring.",
                "Check module power and ground circuits.",
            ],
            "recommended_repair": (
                "Diagnose the communication network and repair wiring, "
                "power, ground or affected module as confirmed."
            ),
            "is_common": False,
            "is_active": True,
        },
        {
            "code": "P0601",
            "system": "Computer/Communication",
            "title": "Internal Control Module Memory Check Sum Error",
            "description": (
                "The control module has detected an internal memory "
                "checksum error."
            ),
            "severity": "HIGH",
            "symptoms": [
                "Engine performance problems",
                "Intermittent faults",
                "No-start condition",
                "Multiple warning lights",
            ],
            "possible_causes": [
                "ECU internal fault",
                "Low battery voltage",
                "Electrical power interruption",
                "Software corruption",
            ],
            "diagnostic_steps": [
                "Check battery and charging voltage.",
                "Check ECU power and ground.",
                "Clear code and retest.",
                "Check for ECU software updates.",
            ],
            "recommended_repair": (
                "Repair the electrical supply first. If the fault returns, "
                "ECU programming or replacement may be required."
            ),
            "is_common": False,
            "is_active": True,
        },
    ]

    def handle(self, *args, **options):
        created_count = 0
        updated_count = 0

        for item in self.DTC_CODES:
            code = item["code"]

            defaults = {
                key: value
                for key, value in item.items()
                if key != "code"
            }

            obj, created = DTCCode.objects.update_or_create(
                code=code,
                defaults=defaults,
            )

            if created:
                created_count += 1
            else:
                updated_count += 1

        self.stdout.write(
            self.style.SUCCESS(
                f"DTC catalogue seeding completed successfully. "
                f"Created: {created_count}, "
                f"Updated: {updated_count}."
            )
        )
