#!/bin/bash
echo "=============================================="
echo "  SMART AUTOMOTIVE GARAGE - FULL AUDIT"
echo "=============================================="

# 1. Backend Django
echo ""
echo "===== 1. BACKEND ====="
cd backend
if [ -f manage.py ]; then echo "[PASS] manage.py"; else echo "[FAIL] manage.py missing"; fi
python manage.py check 2>/dev/null | grep -q "System check identified no issues" && echo "[PASS] Django system check" || echo "[FAIL] Django system check"
python manage.py show_urls 2>/dev/null | grep -q "api/v1" && echo "[PASS] API URLs" || echo "[FAIL] API URLs missing"

# Endpoints
echo "-- Auth endpoints --"
curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8000/api/v1/auth/login/ -H "Content-Type: application/json" -d '{"email":"njaufredrick0@gmail.com","password":"A929292a"}' | grep -q 200 && echo "[PASS] Login endpoint" || echo "[FAIL] Login endpoint"

# 2. Firebase
echo ""
echo "===== 2. FIREBASE ====="
python manage.py shell -c "from automotive_backend.firebase_config import db; print('[PASS] Firestore connected' if db is not None else '[FAIL] Firestore')" 2>/dev/null | grep -q PASS && echo "[PASS] Firestore" || echo "[FAIL] Firestore"

# 3. Flutter apps
echo ""
echo "===== 3. FLUTTER APPS ====="
cd ..
for app in user_app mechanic_app admin_app; do
  echo "-- $app --"
  if [ -d "$app" ]; then
    echo "[PASS] $app exists"
    # Check important files
    if [ -f "$app/lib/main.dart" ]; then echo "[PASS] main.dart"; else echo "[FAIL] main.dart"; fi
    if [ -f "$app/lib/core/theme/app_theme.dart" ]; then echo "[PASS] app_theme.dart"; else echo "[FAIL] app_theme.dart"; fi
    if [ -f "$app/lib/core/services/api_service.dart" ]; then echo "[PASS] api_service.dart"; else echo "[FAIL] api_service.dart"; fi
    # Premium widgets
    if find "$app/lib" -name "premium_button.dart" | grep -q premium; then echo "[PASS] Premium button"; else echo "[FAIL] Premium button"; fi
    if find "$app/lib" -name "glass_card.dart" | grep -q glass; then echo "[PASS] Glassmorphism card"; else echo "[INFO] Glass card not found"; fi
    # Screens
    find "$app/lib/features" -name "*.dart" | wc -l | xargs -I {} echo "  Total screens: {}"
  else
    echo "[FAIL] $app missing"
  fi
done

# 4. AI Scanner
echo ""
echo "===== 4. AI DIAGNOSIS / OBD ====="
if [ -d "backend/apps/diagnosis" ]; then
  echo "[PASS] Diagnosis app"
  grep -q "obd_service" backend/apps/diagnosis/services/obd_service.py 2>/dev/null && echo "[PASS] OBD service" || echo "[WARN] OBD service incomplete"
else
  echo "[FAIL] Diagnosis app missing"
fi

# 5. Notifications
echo ""
echo "===== 5. NOTIFICATIONS ====="
if [ -f "backend/apps/notifications/views.py" ]; then
  echo "[PASS] Notification views"
  grep -q "register_device" backend/apps/notifications/views.py && echo "[PASS] register_device" || echo "[WARN] register_device missing"
  grep -q "send_admin_notification" backend/apps/notifications/views.py && echo "[PASS] send_admin_notification" || echo "[WARN] send_admin_notification missing"
else
  echo "[FAIL] Notification views missing"
fi

echo ""
echo "=============================================="
echo "  AUDIT COMPLETE"
echo "=============================================="
