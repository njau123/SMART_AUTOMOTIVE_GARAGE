#!/bin/bash
BASE="http://localhost:8000/api/v1"

echo "======================================"
echo " 1. REGISTER (phone_number format)"
echo "======================================"
curl -s -X POST $BASE/auth/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "email":"demo@test.com",
    "password":"Demo1234!",
    "first_name":"Demo",
    "last_name":"User",
    "phone_number":"+255712345678"
  }'
echo ""

echo "======================================"
echo " 2. LOGIN"
echo "======================================"
LOGIN_RESPONSE=$(curl -s -X POST $BASE/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@test.com","password":"Demo1234!"}')

echo "$LOGIN_RESPONSE"
echo ""

TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"access":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "❌ LOGIN FAILED - No token received"
  exit 1
fi

echo "✅ Token received: ${TOKEN:0:40}..."
echo ""

echo "======================================"
echo " 3. GET PROFILE"
echo "======================================"
curl -s $BASE/users/profile/ \
  -H "Authorization: Bearer $TOKEN"
echo ""

echo "======================================"
echo " 4. ADMIN CHECK"
echo "======================================"
curl -s $BASE/admin/check/ \
  -H "Authorization: Bearer $TOKEN"
echo ""

echo "======================================"
echo " 5. SERVICES LIST"
echo "======================================"
curl -s $BASE/services/ \
  -H "Authorization: Bearer $TOKEN" | head -c 500
echo ""

echo "======================================"
echo " TEST COMPLETE"
echo "======================================"
