"""
Backend Smoke Test - Smart Automotive Garage
==============================================
Hii script inapima backend yako yote kwa mpigo mmoja:
 1. Inahakikisha server inafanya kazi
 2. Ina-register test user
 3. Ina-login na kupata JWT token
 4. Inajaribu endpoints kuu zote (GET) kwa kutumia hiyo token
 5. Inatoa ripoti ya PASS/FAIL kwa kila kitu

JINSI YA KUENDESHA:
    python backend_smoke_test.py

Kama unahitaji "requests" library:
    pip install requests
"""

import sys
import time
import random

try:
    import requests
except ImportError:
    print("Inaonekana huna 'requests' library. Endesha hii kwanza:")
    print("    pip install requests")
    sys.exit(1)

BASE_URL = "http://127.0.0.1:8000"

results = []  # (name, ok, detail)


def check(name, method, path, expected_statuses, headers=None, json_body=None, save_as=None, store=None):
    url = BASE_URL + path
    try:
        resp = requests.request(method, url, headers=headers, json=json_body, timeout=10)
    except requests.exceptions.ConnectionError:
        results.append((name, False, "HAIWEZI KUUNGANISHA - hakikisha 'python manage.py runserver' inaendesha"))
        return None

    ok = resp.status_code in expected_statuses
    detail = f"status={resp.status_code}"
    results.append((name, ok, detail))

    if save_as and store is not None and ok:
        try:
            data = resp.json()
            store[save_as] = data
        except Exception:
            pass

    return resp


def main():
    print(f"\n{'='*60}")
    print("BACKEND SMOKE TEST - Smart Automotive Garage")
    print(f"{'='*60}\n")

    store = {}
    rand_id = random.randint(10000, 99999)
    test_email = f"smoketest{rand_id}@example.com"
    test_phone = f"+2557{random.randint(10000000, 99999999)}"
    test_password = "SmokeTest123!"

    # 1. Server inafanya kazi?
    check("Server inapokea request (admin login page)", "GET", "/admin/login/", [200])

    # 2. Public/no-auth-required endpoints (kama zipo)
    check("Auth: register bila data (inatakiwa 400)", "POST", "/api/v1/auth/register/", [400], json_body={})

    # 3. Register test user
    reg_resp = check(
        "Auth: register test user mpya",
        "POST",
        "/api/v1/auth/register/",
        [200, 201],
        json_body={
            "email": test_email,
            "first_name": "Smoke",
            "last_name": "Test",
            "phone_number": test_phone,
            "password": test_password,
        },
    )

    # 4. Login na huyo user kupata token
    login_resp = check(
        "Auth: login na test user",
        "POST",
        "/api/v1/auth/login/",
        [200],
        json_body={"email": test_email, "password": test_password},
    )

    token = None
    if login_resp is not None and login_resp.status_code == 200:
        try:
            data = login_resp.json()
            token = data.get("access") or data.get("access_token")
        except Exception:
            pass

    auth_headers = {"Authorization": f"Bearer {token}"} if token else {}

    if token:
        results.append(("Auth: JWT token imepatikana", True, "token OK"))
    else:
        results.append(("Auth: JWT token imepatikana", False, "HAIKUPATIKANA - endpoints za baadaye zitashindwa"))

    # 5. Endpoints kuu (na token, GET tu - list views)
    endpoints_to_test = [
        ("Vehicles list", "/api/v1/vehicles/"),
        ("Services list", "/api/v1/services/"),
        ("Spare parts list", "/api/v1/spare-parts/"),
        ("Bookings list", "/api/v1/bookings/"),
        ("Payments list", "/api/v1/payments/"),
        ("News list", "/api/v1/news/"),
        ("Advertisements list", "/api/v1/advertisements/"),
        ("Diagnosis scans list", "/api/v1/diagnosis/scans/"),
        ("Diagnosis history list", "/api/v1/diagnosis/history/"),
        ("Notifications list", "/api/v1/notifications/"),
        ("Chat rooms list", "/api/v1/chat/rooms/"),
        ("Chat messages list", "/api/v1/chat/messages/"),
        ("Tracking: vehicle locations", "/api/v1/tracking/vehicle-locations/"),
        ("Tracking: mechanic locations", "/api/v1/tracking/mechanic-locations/"),
        ("Tracking: geofences", "/api/v1/tracking/geofences/"),
        ("Reviews list", "/api/v1/reviews/"),
        ("Wallet detail", "/api/v1/wallet/"),
        ("Transactions list", "/api/v1/transactions/"),
        ("Mechanics list", "/api/v1/mechanics/"),
        ("User profile", "/api/v1/users/profile/"),
    ]

    for name, path in endpoints_to_test:
        check(name, "GET", path, [200], headers=auth_headers)

    # ---- RIPOTI ----
    print(f"\n{'-'*60}")
    print("RIPOTI YA MATOKEO")
    print(f"{'-'*60}\n")

    passed = 0
    failed = 0
    for name, ok, detail in results:
        status = "[PASS]" if ok else "[FAIL]"
        if ok:
            passed += 1
        else:
            failed += 1
        print(f"{status}  {name}  ({detail})")

    print(f"\n{'-'*60}")
    print(f"JUMLA: {passed} PASS, {failed} FAIL kati ya {len(results)}")
    print(f"{'-'*60}\n")

    if failed == 0:
        print("HONGERA! Backend yako inafanya kazi vizuri kutoka mwanzo hadi mwisho.")
    else:
        print("Kuna sehemu chache za kuangalia - angalia [FAIL] hapo juu.")
        print("Tuma output hii yote kwa msaada zaidi.")


if __name__ == "__main__":
    main()
