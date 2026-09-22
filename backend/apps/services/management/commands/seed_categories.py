"""
Seed categories zote za mifumo ya gari.
Run: python manage.py seed_categories
"""
from django.core.management.base import BaseCommand
from apps.services.models import ServiceCategory


CATEGORIES = [
    ("Brake System", "Mfumo wa breki — brake pads, discs, fluid, ABS"),
    ("Steering System", "Mfumo wa usukani — power steering, rack, alignment"),
    ("Ignition System", "Mfumo wa kuwasha — spark plugs, coils, starter"),
    ("Engine System", "Injini — oil, filter, timing belt, overhaul"),
    ("Transmission/Gearbox", "Gearbox — manual, automatic, clutch"),
    ("Suspension System", "Suspension — shock absorbers, springs, bushings"),
    ("Electrical System", "Umeme — battery, alternator, wiring, lights"),
    ("Cooling System", "Mfumo wa kupoza — radiator, water pump, thermostat"),
    ("Exhaust System", "Exhaust — muffler, catalytic converter, pipes"),
    ("Fuel System", "Mafuta — fuel pump, injectors, carburetor, tank"),
    ("Air Conditioning", "AC — compressor, gas refill, cooling coil"),
    ("Body & Paint", "Body — dents, painting, welding, panel beating"),
    ("Tire & Wheel", "Matairi — balancing, alignment, rotation, puncture"),
    ("Diagnostics & Scan", "Scanner — OBD-II, ECU, error codes, AI diagnosis"),
    ("Interior & Upholstery", "Ndani — seats, dashboard, carpet, roof lining"),
    ("Windshield & Glass", "Kioo — windshield, side mirrors, window repair"),
    ("Lighting System", "Taa — headlights, taillights, indicators, fog lights"),
    ("Wipers & Washers", "Wipers — blades, motor, washer fluid"),
    ("Lock & Security", "Usalama — central lock, alarm, immobilizer, keys"),
    ("Hybrid/EV System", "Hybrid/EV — battery pack, motor, charging"),
    ("Turbo & Supercharger", "Turbo — boost, intercooler, wastegate"),
    ("Oil & Lubrication", "Mafuta ya injini — engine oil, gearbox oil, grease"),
    ("General Service", "Huduma ya jumla — checkup, tuning, maintenance"),
]


class Command(BaseCommand):
    help = "Seed categories zote za mifumo ya gari"

    def handle(self, *args, **options):
        created = 0
        skipped = 0
        for name, desc in CATEGORIES:
            obj, is_created = ServiceCategory.objects.get_or_create(
                name=name,
                defaults={"description": desc, "is_active": True},
            )
            if is_created:
                created += 1
                self.stdout.write(f"  + {name}")
            else:
                skipped += 1

        self.stdout.write(self.style.SUCCESS(
            f"OK: {created} categories created, {skipped} already existed"
        ))
