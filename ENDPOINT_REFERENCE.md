# 📡 Endpoint Reference - Zmayy Mobile

## Quick Reference untuk Developer

---

## 🎯 **TABEL KEBENARAN ENDPOINT MUTLAK**

### Authentication & Profile

| Feature | Method | Endpoint | Repository | Payload |
|---------|--------|----------|------------|---------|
| **Login** | POST | `/api/auth/mobile-login` | AuthRepository | `{email, password}` |
| **Session** | GET | `/api/auth/mobile-session` | AuthRepository | - |
| **Register** | POST | `/api/auth/mobile-register` | AuthRepository | `{email, password, username}` |
| **Update Profile** | PATCH | `/api/profile/update` | ProfileRepository | `{username, display_name, ...}` |

---

### Friends & Social

| Feature | Method | Endpoint | Repository | Payload |
|---------|--------|----------|------------|---------|
| **Friends List** | GET | `/api/friends` | FriendsRepository | - |
| **Friend Requests** | GET | `/api/friends/requests` | FriendsRepository | - |
| **Accept Friend** | POST | `/api/friends/accept` | FriendsRepository | `{requester_id}` |

---

### Map & Location

| Feature | Method | Endpoint | Repository | Payload |
|---------|--------|----------|------------|---------|
| **Visible Users** | GET | `/api/map/visible?lat=X&lng=Y` | MapRepository | Query params |
| **Update Location** | POST | `/api/map/update-location` | MapRepository | `{lat, lng}` |

---

### Chat & Messaging

| Feature | Method | Endpoint | Repository | Payload |
|---------|--------|----------|------------|---------|
| **Chat History** | GET | `/api/chat/history` | ChatRepository | - |
| **Send Chat** | POST | `/api/chat/send` | ChatRepository | `{message, image_url?}` |
| **DM History** | GET | `/api/chat/dm/history?friend_id=X` | ChatRepository | Query params |
| **Send DM** | POST | `/api/chat/dm/send` | ChatRepository | `{receiver_id, message, image_url?}` |

---

## 🔧 **Usage Examples**

### Login
```dart
final authRepo = AuthRepository();
final profile = await authRepo.login('user@example.com', 'password123');
// Log: [API Request] POST /api/auth/mobile-login | Token Attached: false
// Log: [Session Sync] User ID: ... | Display Name Loaded: ...
```

### Update Profile
```dart
final profileRepo = ProfileRepository();
await profileRepo.updateProfile({
  'username': 'John Doe',
  'display_name': 'John Doe',
});
// Log: [Profile Update] Payload terkirim: {username: John Doe, display_name: John Doe}
// Log: [API Request] PATCH /api/profile/update | Token Attached: true
```

### Get Visible Users
```dart
final mapRepo = MapRepository();
final users = await mapRepo.getVisibleUsers(-6.2, 106.8);
// Log: [API Request] GET /api/map/visible?lat=-6.2&lng=106.8 | Token Attached: true
// Log: [Map Sync] Ditemukan 5 entitas di sekitar koordinat saat ini
```

### Update Location
```dart
final mapRepo = MapRepository();
await mapRepo.updateLocation(-6.2, 106.8);
// Log: [Map Update] Updating location: lat=-6.2, lng=106.8
// Log: [API Request] POST /api/map/update-location | Token Attached: true
```

### Get Friends
```dart
final friendsRepo = FriendsRepository();
final friends = await friendsRepo.getFriends();
// Log: [API Request] GET /api/friends | Token Attached: true
// Log: [Friends Sync] Ditemukan 10 teman
```

### Get Friend Requests
```dart
final friendsRepo = FriendsRepository();
final requests = await friendsRepo.getFriendRequests();
// Log: [API Request] GET /api/friends/requests | Token Attached: true
// Log: [Friend Requests Sync] Ditemukan 3 permintaan
```

### Accept Friend Request
```dart
final friendsRepo = FriendsRepository();
await friendsRepo.acceptFriendRequest('user-id-123');
// Log: [Friend Request] Accepting request from: user-id-123
// Log: [API Request] POST /api/friends/accept | Token Attached: true
```

### Get Chat History
```dart
final chatRepo = ChatRepository();
final messages = await chatRepo.getChatHistory();
// Log: [API Request] GET /api/chat/history | Token Attached: true
// Log: [Chat Sync] Ditemukan 15 pesan
```

### Send Chat Message
```dart
final chatRepo = ChatRepository();
final message = await chatRepo.sendMessage('Hello world!');
// Log: [Chat Send] Mengirim pesan: Hello world!
// Log: [API Request] POST /api/chat/send | Token Attached: true
```

---

## 🛡️ **Response Format Handling**

All repositories now handle multiple response formats:

### Unwrapped Array
```json
[
  {"id": "1", "name": "User 1"},
  {"id": "2", "name": "User 2"}
]
```

### Wrapped in "data"
```json
{
  "data": [
    {"id": "1", "name": "User 1"},
    {"id": "2", "name": "User 2"}
  ]
}
```

### Wrapped in custom key
```json
{
  "friends": [
    {"id": "1", "name": "User 1"}
  ]
}
```

### Empty Response
```json
null
// or
[]
// or
{"data": []}
```

All formats are handled gracefully without crashes!

---

## 🔍 **Debugging Tips**

### Check Endpoint
```bash
# Filter API requests
flutter run | grep "\[API Request\]"

# Expected output:
[API Request] GET /api/friends | Token Attached: true
[API Request] POST /api/profile/update | Token Attached: true
```

### Check Response
```bash
# Filter sync logs
flutter run | grep "Sync\]"

# Expected output:
[Friends Sync] Ditemukan 10 teman
[Map Sync] Ditemukan 5 entitas di sekitar koordinat saat ini
[Chat Sync] Ditemukan 15 pesan
```

### Check Errors
```bash
# Filter errors
flutter run | grep "\[API Error\]"

# If you see:
[API Error] /api/friends | Status: 404 | Muatan: Not Found
# → Check if endpoint exists on backend
```

---

## ⚠️ **Common Mistakes**

### ❌ Wrong Endpoint
```dart
// DON'T
await _client.patch('/api/auth/profile', payload);  // ❌ Wrong!

// DO
await _client.patch('/api/profile/update', payload); // ✅ Correct!
```

### ❌ Wrong Method
```dart
// DON'T
await _client.post('/api/map/visible', {lat, lng});  // ❌ Wrong!

// DO
await _client.post('/api/map/update-location', {lat, lng}); // ✅ Correct!
```

### ❌ Missing Token
```dart
// Token is automatically added by ApiClient
// Just make sure user is logged in and token is in SecureStorage
```

---

## 📊 **Status Codes**

| Code | Meaning | Action |
|------|---------|--------|
| 200 | Success | Process response |
| 201 | Created | Process response |
| 401 | Unauthorized | Auto-logout + redirect to login |
| 404 | Not Found | Check endpoint spelling |
| 500 | Server Error | Check backend logs |

---

## 🔗 **Related Files**

- `lib/core/api_client.dart` - HTTP client with token injection
- `lib/data/repositories/auth_repository.dart` - Authentication
- `lib/data/repositories/profile_repository.dart` - Profile updates
- `lib/data/repositories/friends_repository.dart` - Friends & requests
- `lib/data/repositories/map_repository.dart` - Map & location
- `lib/data/repositories/chat_repository.dart` - Chat & messaging

---

**Last Updated:** 12 Mei 2026  
**Version:** 1.0.1
