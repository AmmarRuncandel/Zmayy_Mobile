# 📚 Quick Reference - Zmayy Mobile

## Console Logging Cheat Sheet

### 🔍 Log Patterns

| Pattern | Location | Purpose |
|---------|----------|---------|
| `[API Request]` | ApiClient | Request sebelum terkirim |
| `[API Error]` | ApiClient | Error response atau network |
| `[Session Sync]` | AuthRepository | Sesi berhasil diserap |
| `[Map Sync]` | MapRepository | Data pemetaan diterima |
| `[Profile Update]` | ProfileRepository | Payload update profil |

---

## 🎨 Marker Color Logic

```dart
// Di MapScreen._buildMarker()
if (user.relationType == 'friend') {
  // Ikon Emas (#FCD535)
  // Teman yang sudah di-add
} else {
  // Ikon Hitam (#4B5563)
  // Stranger di sekitar
}

// Self-marker DIFILTER sebelum render
.where((u) => u.id != appState.currentUserId)
```

---

## 🔐 Token Flow

```
1. Login → Receive token
2. Save to SecureStorage (encrypted)
3. Every API call → Read token → Add to header
4. 401 Response → Clear storage → Redirect to login
```

---

## 📝 Profile Update Flow

```
1. User edit nama di ProfilePanel
2. copyWith(username: newName, displayName: newName)
3. AppState.updateProfileField()
4. Save to SecureStorage (local)
5. ProfileRepository.updateProfile() (remote)
6. Log: [Profile Update] Payload terkirim: {...}
7. UI auto-update via notifyListeners()
```

---

## 🗺️ Map Sync Flow

```
1. GPS permission → Get coordinates
2. AppState.fetchNearbyUsers(lat, lng)
3. Check ghost mode → Skip if enabled
4. MapRepository.getVisibleUsers(lat, lng)
5. GET /api/map/visible?lat=...&lng=...
6. Log: [Map Sync] Ditemukan X entitas
7. Filter self-marker
8. Render markers (friend=emas, stranger=hitam)
```

---

## 🐛 Common Issues & Solutions

### Issue: Token tidak terkirim
```bash
# Cek log
[API Request] GET /api/map/visible | Token Attached: false

# Solusi
1. Verifikasi user sudah login
2. Cek SecureStorage: await SecureStorage.readToken()
3. Cek token expired (auto-logout akan terjadi)
```

### Issue: Self-marker muncul di peta
```bash
# Cek filter di MapScreen
.where((u) => u.id != appState.currentUserId)

# Verifikasi currentUserId tersedia
print('Current User ID: ${appState.currentUserId}');
```

### Issue: Update nama gagal
```bash
# Cek log payload
[Profile Update] Payload terkirim: {...}

# Pastikan payload berisi username DAN display_name
{
  "username": "John Doe",
  "display_name": "John Doe"
}
```

---

## 🔧 Useful Commands

```bash
# Run dengan log lengkap
flutter run --verbose

# Filter log API
flutter run | grep "\[API"

# Filter log error
flutter run | grep "\[API Error\]"

# Simpan log ke file
flutter run > app_logs.txt 2>&1

# Analyze kode
flutter analyze

# Format kode
flutter format .
```

---

## 📊 State Management

```dart
// Get current user
final profile = appState.currentProfile;
final userId = appState.currentUserId;

// Update profile
await appState.updateProfileField(updatedProfile);

// Set ghost mode
await appState.setGhostMode(true);

// Get visible users
final users = appState.visibleUsers;
final friendsCount = appState.onlineFriendsCount;
final strangersCount = appState.nearbyStrangersCount;
```

---

## 🎯 Key Files

| File | Purpose |
|------|---------|
| `lib/core/api_client.dart` | HTTP client dengan logging |
| `lib/core/app_state.dart` | Global state management |
| `lib/core/secure_storage.dart` | Encrypted storage |
| `lib/features/map/map_screen.dart` | Peta dengan marker |
| `lib/features/profile/profile_panel.dart` | Panel profil user |
| `lib/data/repositories/auth_repository.dart` | Autentikasi |
| `lib/data/repositories/map_repository.dart` | Pemetaan |
| `lib/data/repositories/profile_repository.dart` | Update profil |
| `lib/data/models/user_profile.dart` | Model profil user |
| `lib/data/models/visible_user.dart` | Model user di peta |

---

## 🚀 Quick Start

```bash
# 1. Install dependencies
flutter pub get

# 2. Run app
flutter run

# 3. Monitor logs
# Terminal akan menampilkan:
# [API Request] ...
# [API Error] ...
# [Session Sync] ...
# [Map Sync] ...
# [Profile Update] ...
```

---

## 📱 Testing Checklist

### Login Flow
- [ ] Log `[API Request] POST /api/auth/mobile-login`
- [ ] Log `[Session Sync] User ID: ... | Display Name Loaded: ...`
- [ ] Token tersimpan di SecureStorage
- [ ] Display name muncul di ProfilePanel

### Map Flow
- [ ] Log `[API Request] GET /api/map/visible`
- [ ] Log `[Map Sync] Ditemukan X entitas`
- [ ] Self-marker tidak muncul
- [ ] Friend marker berwarna emas
- [ ] Stranger marker berwarna hitam

### Profile Update
- [ ] Log `[Profile Update] Payload terkirim: ...`
- [ ] Payload berisi username + display_name
- [ ] Nama langsung berubah di UI
- [ ] Update berhasil di backend

### Error Handling
- [ ] 401 → Auto-logout + redirect login
- [ ] Timeout → Log error timeout
- [ ] Network error → Log error network

---

## 💡 Pro Tips

1. **Debugging:** Gunakan `flutter run --verbose` untuk log lengkap
2. **Performance:** Ghost mode menonaktifkan map sync (hemat battery)
3. **Security:** Token disimpan encrypted di SecureStorage
4. **Logging:** Semua log menggunakan `dart:developer` (bisa difilter)
5. **State:** Gunakan Provider untuk akses AppState di widget

---

## 🔗 Related Docs

- `CHANGELOG_API_LOGGING.md` - Changelog lengkap
- `CRITICAL_FIXES.md` - Perbaikan celah logika kritis
- `DEBUG_GUIDE.md` - Panduan debugging detail
- `API_FLOW_DIAGRAM.md` - Diagram alur API visual

---

**Last Updated:** 12 Mei 2026  
**Version:** 1.0.0
