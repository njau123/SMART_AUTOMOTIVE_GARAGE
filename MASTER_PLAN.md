# AUTOMOTIVE SMART GARAGE — MASTER PROJECT PLAN

**Tarehe ya Kuanzisha**: 2026-09-15
**Admin**: Fredrick Njau (njaufredrick0@gmail.com)
**Malipo Yote**: 0759212300 (Automotive Smart Garage Account — imefichwa UI)
**Location**: Maji Chumvi, Dar es Salaam
**Platform**: Flutter (user_app, mechanic_app, admin_app) + Django backend

---

## 🎯 PROJECT OVERVIEW

**Motto**: "Afya ya Gari Yako ni Jukumu Letu"

**App 3:**
- **user_app** — Kwa wateja (madereva)
- **mechanic_app** — Kwa mafundi
- **admin_app** — Kwa admin (wewe)

**Backend**: Django REST API + SQLite (baadaye PostgreSQL)

---

## ✅ VITU VINAVYOFANYA KAZI (Hadi Sasa)

### User App:
- [x] Splash screen (background image)
- [x] Homepage (background image, top nav)
- [x] Signup (jina, namba, password, gari, registration)
- [x] Login (email + password + Google)
- [x] Forgot password (email)
- [x] User Dashboard
- [x] Services page (background)
- [x] Spare Parts page (background + Buy → Order Screen)
- [x] Find Mechanics (background + Book → Booking Screen)
- [x] AI Car Scanner (OBD background)
- [x] AI Diagnosis (text-based)
- [x] Wallet (transactions, pending)
- [x] Profile
- [x] About Us, Location, Contact Us, Why Us pages
- [x] Session timeout (dakika 10)
- [x] Booking mechanic (chagua gari + service + tarehe + muda → deposit 50%)
- [x] Order spare parts (quantity + address → payment)

### Admin App:
- [x] Admin Login
- [x] Dashboard (stats)
- [x] Users list
- [x] Mechanics list
- [x] Bookings list
- [x] Payments list (verify manual)
- [x] News form
- [x] Notifications form
- [x] Ads form

### Backend:
- [x] Authentication (JWT)
- [x] Users, Mechanics, Bookings, Payments models
- [x] Contact model
- [x] Admin endpoints zote
- [x] Notifications service

---

## 🔴 MATATIZO YANAYOHITAJI KUREKEBISHWA (Priority Order)

### PHASE 1: CRITICAL (Haraka)
- [ ] **P1.1** — User haoni notifications zilizotumwa na admin
- [ ] **P1.2** — User notification page inasema "coming soon" (haifanyi kazi)
- [ ] **P1.3** — Admin dashboard overview cards hazi-click
- [ ] **P1.4** — Notifications za user zinaonekana vipi? (badge, page, list)

### PHASE 2: USER MANAGEMENT (Admin)
- [ ] **P2.1** — Admin aweze kuona details za user (bottom sheet) ✅ imekamilika
- [ ] **P2.2** — Admin aweze ku-delete user (email isitumike tena)
- [ ] **P2.3** — Admin aweze ku-block/unblock user

### PHASE 3: AI DIAGNOSIS KISWAHILI
- [ ] **P3.1** — AI ielewe Kiswahili cha mtaani ("matairi linagongagonga")
- [ ] **P3.2** — User awe na option ya kuchagua lugha (English / Kiswahili)
- [ ] **P3.3** — AI itoe sababu kamili (si "unknown cause")

### PHASE 4: CONTENT REACH (Admin → User)
- [ ] **P4.1** — Hakikisha Admin posts/advertisements/spare parts/services zinafika kwa user
- [ ] **P4.2** — Admin spare parts: kuweka picha kutoka device
- [ ] **P4.3** — Admin spare parts: details zote (name, price, condition, description, part number)
- [ ] **P4.4** — Admin spare parts: delete option
- [ ] **P4.5** — User aweze kuiona na ku-book spare part

### PHASE 5: MECHANIC APP (Kubwa)
- [ ] **P5.1** — Mechanics Registration (majina, email, ME-XXXX, specialist, region, phone, password)
- [ ] **P5.2** — Mechanics Login (ME-XXXX + password)
- [ ] **P5.3** — Forgot Password (reg no + phone → SMS code → expire dakika 3)
- [ ] **P5.4** — Mechanics Dashboard (welcome, specialist, kazi zilizo uploadiwa)
- [ ] **P5.5** — Admin anatengeneza mechanics (reg no + specialist + region + phone)
- [ ] **P5.6** — Mechanics profile image

### PHASE 6: CHAT SYSTEM (Kubwa)
- [ ] **P6.1** — Chat kati ya user na mechanic
- [ ] **P6.2** — Text messages
- [ ] **P6.3** — Voice notes
- [ ] **P6.4** — Picha
- [ ] **P6.5** — Documents (PDF, n.k.)
- [ ] **P6.6** — Notification ya chat

### PHASE 7: PAYMENTS ADMIN ↔ MECHANICS
- [ ] **P7.1** — Admin anatuma pesa kwa mechanics
- [ ] **P7.2** — Mechanics anaona balance
- [ ] **P7.3** — Mechanics ana-withdraw
- [ ] **P7.4** — Transaction history

### PHASE 8: POLISH & DEPLOY
- [ ] **P8.1** — Test kila kitu E2E
- [ ] **P8.2** — Hosting (Vercel / Firebase)
- [ ] **P8.3** — Play Store ($25)

---

## 🎯 KANUNI ZA KAZI (Rules)

1. **Kila fix, test kwanza** — sitakupa code bila kuhakikisha inafanya kazi
2. **Mabadiliko moja kwa wakati** — ili tusichanganye vitu
3. **Backup kila file** — `.bak` files kwa kila mabadiliko
4. **Hakuna ku-haribu** — kama kitu kinafanya kazi, sitakigusa
5. **Priority: critical kwanza** — si kufanya vitu vingi kwa pamoja

---

## 📝 NOTES

- Malipo yote yanaenda 0759212300 (itafichwa UI)
- Company: Automotive Smart Garage
- Bank: (baadaye)
- Payment API: Manual verification kwa sasa (admin anathibitisha)
- Domain: Baadaye
- Play Store: Baadaye ($25)
