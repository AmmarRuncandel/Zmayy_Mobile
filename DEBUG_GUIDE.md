# 🔍 Panduan Debugging - Zmayy Mobile

## Console Logging System

Aplikasi Zmayy Mobile kini dilengkapi dengan sistem logging terstruktur untuk mempermudah audit runtime dan debugging.

---

## 📊 Format Log

### 1. API Request Log
```
[API Request] <METHOD> <URL> | Token Attached: <true/false>
```

**Contoh:**
```
[API Request] GET https://api.zmayy.com/api/auth/mobile-session | Token Attached: true
[API Request] POST https://api.zmayy.com/api/map/visible | Token Attached: true
[API Request] GET https://api.zmayy.com/api/chat/history | Token Attached: false
```

### 2. API Error Log
```
[API Error] <URL> | Status: <CODE> | Muatan: <BODY/ERROR_MESSAGE>
```

**Contoh:**
```
[API Error] https://api.zmayy.com/api/map/visible | Status: 401 UNAUTHORIZED | Muatan: Session expired, redirecting to login
[API Error] https://api.zmayy.com/api/chat/send | Status: 500 | Muatan: Internal server error
[API Error] https://api.zmayy.com/api/map/visible | Status: TIMEOUT | Muatan: Request timeout after 15s
[API Error] https://api.zmayy.com/api/auth/login | Status: NETWORK_ERROR | Muatan: SocketException: Failed host lookup
```

### 3. Session Sync Log
```
[Session Sync] User ID: <id> | Display Name Loaded: <display_name>
```

**Contoh:**
```
[Session Sync] User ID: 550e8400-e29b-41d4-a716-446655440000 | Display Name Loaded: John Doe
[Session Sync] User ID: 7c9e6679-7425-40de-944b-e07fc1f90ae7 | Display Name Loaded: jane_smith
```

### 4. Map Sync Log
```
[Map Sync] Ditemukan <jumlah> entitas di sekitar koordinat saat ini
```

**Contoh:**
```
[Map Sync] Ditemukan 5 entitas di sekitar koordinat saat ini
[Map Sync] Ditemukan 0 entitas di sekitar koordinat saat ini
[Map Sync] Ditemukan 12 entitas di sekitar koordinat saat ini
```

---

## 🛠️ Cara Menggunakan Log

### 1. Menjalankan dengan Log Lengkap
```bash
flutter run --verbose
```

### 2. Filter Log Spesifik

#### Filter semua log API:
```bash
flutter run | grep "\[API"
```

#### Filter hanya error:
```bash
flutter run | grep "\[API Error\]"
```

#### Filter session sync:
```bash
flutter run | grep "\[Session Sync\]"
```

#### Filter map sync:
```bash
flutter run | grep "\[Map Sync\]"
```

### 3. Menyimpan Log ke File
```bash
flutter run > app_logs.txt 2>&1
```

---

## 🐛 Debugging Common Issues

### Issue 1: Token Tidak Terkirim
**Gejala:**
```
[API Request] GET /api/map/visible | Token Attached: false
[API Error] /api/map/visible | Status: 401 UNAUTHORIZED | Muatan: Missing token
```

**Solusi:**
1. Cek apakah user sudah login
2. Verifikasi token tersimpan di SecureStorage:
```dart
final token = await SecureStorage.readToken();
print('Token: $token');
```
3. Cek apakah token expired (auto-logout akan terjadi)

---

### Issue 2: Session Tidak Tersinkronisasi
**Gejala:**
- Display name tidak muncul di UI
- Avatar initials tidak sesuai

**Solusi:**
1. Cek log session sync:
```
[Session Sync] User ID: ... | Display Name Loaded: ...
```
2. Verifikasi backend mengembalikan data lengkap:
```json
{
  "session_valid": true,
  "user": { "id": "...", "email": "..." },
  "profile": {
    "id": "...",
    "username": "...",
    "display_name": "...",
    "avatar_initials": "..."
  }
}
```
3. Cek SecureStorage:
```dart
final profile = await SecureStorage.readProfile();
print('Profile: $profile');
```

---

### Issue 3: Map Tidak Menampilkan User
**Gejala:**
```
[Map Sync] Ditemukan 0 entitas di sekitar koordinat saat ini
```

**Solusi:**
1. Verifikasi GPS permission granted
2. Cek koordinat yang dikirim:
```dart
print('Lat: $lat, Lng: $lng');
```
3. Verifikasi backend mengembalikan data:
```bash
curl "https://api.zmayy.com/api/map/visible?lat=-6.2&lng=106.8" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

### Issue 4: Marker Warna Salah
**Gejala:**
- Teman muncul dengan ikon hitam
- Stranger muncul dengan ikon emas

**Solusi:**
1. Cek response dari backend:
```json
[
  {
    "id": "...",
    "username": "...",
    "relation_type": "friend",  // Harus 'friend' atau 'stranger'
    "is_online": true,
    "distance_km": 0.5,
    "last_lat": -6.2,
    "last_lng": 106.8
  }
]
```
2. Verifikasi logika di `map_screen.dart`:
```dart
final isFriend = user.relationType == 'friend';
```

---

### Issue 5: Auto-Logout Tidak Terjadi
**Gejala:**
- Respons 401 tapi tidak redirect ke login

**Solusi:**
1. Cek log error:
```
[API Error] ... | Status: 401 UNAUTHORIZED | Muatan: Session expired, redirecting to login
```
2. Verifikasi Global Navigator Key terdaftar:
```dart
// Di main.dart
MaterialApp(
  navigatorKey: AppNavigator.navigatorKey,
  ...
)
```

---

## 📱 Testing Checklist

### Login Flow
- [ ] Log `[API Request] POST /api/auth/mobile-login | Token Attached: false`
- [ ] Log `[Session Sync] User ID: ... | Display Name Loaded: ...`
- [ ] Token tersimpan di SecureStorage
- [ ] Display name muncul di Profile Panel

### Map Flow
- [ ] Log `[API Request] GET /api/map/visible | Token Attached: true`
- [ ] Log `[Map Sync] Ditemukan X entitas di sekitar koordinat saat ini`
- [ ] Marker teman berwarna emas
- [ ] Marker stranger berwarna hitam
- [ ] Online indicator muncul untuk user online

### Error Handling
- [ ] 401 → Auto-logout dan redirect ke login
- [ ] Timeout → Log error timeout
- [ ] Network error → Log error network
- [ ] Invalid JSON → Log parsing error

### Ghost Mode
- [ ] Saat ghost mode aktif, tidak ada request ke `/api/map/visible`
- [ ] Map tidak menampilkan user lain
- [ ] Badge menampilkan "—" untuk jumlah user

---

## 🔧 Advanced Debugging

### 1. Flutter DevTools
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

### 2. Network Inspector
Gunakan Charles Proxy atau Proxyman untuk inspect HTTP traffic:
1. Setup proxy di device/emulator
2. Install SSL certificate
3. Monitor semua request/response

### 3. Dart Observatory
```bash
flutter run --observatory-port=8888
```
Buka browser: `http://localhost:8888`

### 4. Log Level
Ubah log level di `api_client.dart`:
```dart
// Info log (level 800)
developer.log('[API Request] ...', level: 800);

// Error log (level 1000)
developer.log('[API Error] ...', level: 1000);
```

---

## 📞 Support

Jika masih mengalami masalah:
1. Kumpulkan log lengkap: `flutter run > debug.log 2>&1`
2. Screenshot error di UI
3. Cek backend logs untuk korelasi
4. Hubungi tim backend untuk verifikasi API

---

**Last Updated:** 12 Mei 2026
**Version:** 1.0.0
