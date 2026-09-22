from django.db import migrations


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


def seed_categories(apps, schema_editor):
    ServiceCategory = apps.get_model('services', 'ServiceCategory')
    for name, desc in CATEGORIES:
        ServiceCategory.objects.get_or_create(
            name=name,
            defaults={"description": desc, "is_active": True},
        )


def unseed_categories(apps, schema_editor):
    ServiceCategory = apps.get_model('services', 'ServiceCategory')
    names = [n for n, _ in CATEGORIES]
    ServiceCategory.objects.filter(name__in=names).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('services', '0003_service_video'),
    ]

    operations = [
        migrations.RunPython(seed_categories, unseed_categories),
    ]
