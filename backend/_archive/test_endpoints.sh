#!/bin/bash
BASE="http://localhost:8000/api/v1"
EMAIL="emma@example.com"
PASSWORD="123456"

echo "===== 1. LOGIN ====="
LOGIN_RESPONSE=$(curl -s -X POST "$BASE/auth/login/" -H "Content-Type: application/json" -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")
echo "$LOGIN_RESPONSE" | python -m json.tool

# Extract access token
ACCESS=$(echo "$LOGIN_RESPONSE" | python -c "import sys,json; print(json.load(sys.stdin).get('access',''))")
if [ -z "$ACCESS" ]; then
    echo "Login failed. Hatuwezi kuendelea na tests."
    exit 1
fi

echo ""
echo "===== 2. PROFILE ====="
curl -s "$BASE/mechanics/profile/" -H "Authorization: Bearer $ACCESS" | python -m json.tool

echo ""
echo "===== 3. AI DIAGNOSIS ====="
curl -s -X POST "$BASE/diagnosis/diagnose/" -H "Authorization: Bearer $ACCESS" -H "Content-Type: application/json" -d '{"symptoms":"gari linazima ghafla"}' | python -m json.tool

echo ""
echo "===== 4. SPARE PARTS ====="
curl -s "$BASE/spare-parts/" -H "Authorization: Bearer $ACCESS" | python -m json.tool

echo ""
echo "===== 5. MECHANICS AVAILABLE ====="
curl -s "$BASE/mechanics/?region=Dar%20es%20Salaam" -H "Authorization: Bearer $ACCESS" | python -m json.tool

echo ""
echo "===== 6. WALLET ====="
curl -s "$BASE/wallet/" -H "Authorization: Bearer $ACCESS" | python -m json.tool

echo ""
echo "===== 7. NOTIFICATIONS (list) ====="
curl -s "$BASE/notifications/" -H "Authorization: Bearer $ACCESS" | python -m json.tool

echo ""
echo "===== 8. BOOKINGS (list) ====="
curl -s "$BASE/bookings/" -H "Authorization: Bearer $ACCESS" | python -m json.tool

echo ""
echo "===== 9. ADMIN STATS (admin user) ====="
ADMIN_LOGIN=$(curl -s -X POST "$BASE/auth/login/" -H "Content-Type: application/json" -d '{"email":"njaufredrick0@gmail.com","password":"A929292a"}')
ADMIN_ACCESS=$(echo "$ADMIN_LOGIN" | python -c "import sys,json; print(json.load(sys.stdin).get('access',''))")
if [ -n "$ADMIN_ACCESS" ]; then
    curl -s "$BASE/admin/stats/" -H "Authorization: Bearer $ADMIN_ACCESS" | python -m json.tool
else
    echo "Admin login failed"
fi

echo ""
echo "===== 10. ADMIN USERS ====="
if [ -n "$ADMIN_ACCESS" ]; then
    curl -s "$BASE/admin/users/" -H "Authorization: Bearer $ADMIN_ACCESS" | python -m json.tool
fi

echo ""
echo "===== 11. ADMIN MECHANICS ====="
if [ -n "$ADMIN_ACCESS" ]; then
    curl -s "$BASE/admin/mechanics/" -H "Authorization: Bearer $ADMIN_ACCESS" | python -m json.tool
fi

echo ""
echo "===== 12. SEND NOTIFICATION (admin) ====="
if [ -n "$ADMIN_ACCESS" ]; then
    curl -s -X POST "$BASE/notifications/send/" -H "Authorization: Bearer $ADMIN_ACCESS" -H "Content-Type: application/json" -d '{"title":"Test Notification","body":"Hii ni notification kutoka kwa admin"}' | python -m json.tool
fi

echo ""
echo "===== 13. REGISTER DEVICE TOKEN ====="
if [ -n "$ACCESS" ]; then
    curl -s -X POST "$BASE/notifications/devices/register/" -H "Authorization: Bearer $ACCESS" -H "Content-Type: application/json" -d '{"device_token":"test_device_token_123","device_type":"web"}' | python -m json.tool
fi
