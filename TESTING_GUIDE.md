# Complete Testing Guide untuk Register/Login Flow

## Prerequisites

Pastikan sudah:
1. Push latest code ke Vercel (`git push origin main`)
2. Tunggu deployment complete (cek di console.vercel.com)
3. Jalankan Flutter app: `flutter run -v` di terminal

---

## Test 1: Verify Vercel Deployment

**Command:**
```bash
curl -X POST https://zmayy.vercel.app/api/auth/mobile-register \
  -H "Content-Type: application/json" \
  -d '{"email":"testuser123@example.com","password":"SecurePassword123","username":"testuser"}'
```

**Expected Success Response (status 201):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "...",
  "expires_at": 1715903456,
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "testuser123@example.com",
    "created_at": "2024-05-11T10:30:00Z"
  },
  "profile": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "username": "testuser",
    "display_name": "testuser",
    "avatar_initials": "TU"
  }
}
```

**Expected Error Response (status 400):**
```json
{
  "error": "User already registered"
}
```

**If you get 404:**
```
❌ 404 Not Found
```
→ Vercel belum update, silakan trigger redeploy atau wait 5 minutes

---

## Test 2: Register via Mobile App

1. **Buka Flutter app** dengan logging enabled:
   ```bash
   cd d:\Project-Collage\UASPabp\zmayy_mobile
   flutter run -v
   ```

2. **Lihat Splash screen**, tunggu 2.5 detik

3. **Tap "Daftar" button** di login screen

4. **Input email & password:**
   - Email: `zmayy_tester_$(date +%s)@gmail.com` (unique email)
   - Password: `SecurePassword123`

5. **Tap register button** dan lihat logs di terminal

**Expected Logs:**
```
[    +123 ms] API Request: POST https://zmayy.vercel.app/api/auth/mobile-register
[    +125 ms] Register attempt: zmayy_tester_1715903456@gmail.com
[   +1500 ms] API Response: 201 from https://zmayy.vercel.app/api/auth/mobile-register
[   +1501 ms] Register response: {access_token: eyJhb..., profile: {id: 550e8400...}}
```

**Then app should:**
- ✅ Navigate to AppShell (map view)
- ✅ Load your profile
- ✅ Show chat/friends panels

---

## Test 3: Login via Mobile App

1. **Restart app** or click "Masuk" link

2. **Input credentials yang baru didaftar:**
   - Email: `zmayy_tester_1715903456@gmail.com`
   - Password: `SecurePassword123`

3. **Tap login button** dan lihat logs

**Expected Logs:**
```
[    +123 ms] API Request: POST https://zmayy.vercel.app/api/auth/mobile-login
[    +125 ms] Login attempt: zmayy_tester_1715903456@gmail.com
[   +1500 ms] API Response: 200 from https://zmayy.vercel.app/api/auth/mobile-login
[   +1501 ms] Login successful: zmayy_tester_1715903456@gmail.com
```

**Then app should:**
- ✅ Navigate to AppShell
- ✅ Load chat history
- ✅ Show map with visible users

---

## Test 4: Error Cases

### 4A: Invalid Email
```
Input: "bukan.email", password: "123"
Expected Error: "Email dan kata sandi wajib diisi."
```

### 4B: Duplicate Email
```
Input: "zmayy_tester_1715903456@gmail.com" (sudah terdaftar), password: "123"
Expected Error: "User already registered"
```

### 4C: Wrong Password
```
Input: "zmayy_tester_1715903456@gmail.com", password: "salahpassword"
Expected Error: "Invalid login credentials"
```

### 4D: Network Timeout (if endpoint not responding)
```
Expected Error: "Request timeout after 15s"
Expected Behavior: Error message dalam SnackBar, loading spinner stop
```

---

## Test 5: Validate Token Persistence

1. **Register/Login successfully**
2. **Force close app** (dalam emulator, swipe up dari bottom atau force stop)
3. **Re-open app**
4. **Verify:**
   - ✅ SplashScreen shows (2.5s wait)
   - ✅ Automatically navigates to AppShell (tidak kembali ke LoginScreen)
   - ✅ User tetap logged in
   - ✅ Profile data preserved

**If you see LoginScreen again:**
- ❌ Token tidak persisted atau validateSession failed
- Check logs: `[    +500 ms] API Response: 401 from https://zmayy.vercel.app/api/auth/mobile-session`

---

## Troubleshooting

### Issue: "Connection timed out" or "Request timeout after 15s"

**Diagnosis:**
```bash
# Test network connectivity
adb shell ping zmayy.vercel.app

# Test DNS resolution
adb shell nslookup zmayy.vercel.app

# Test HTTP directly
adb shell curl -v https://zmayy.vercel.app/api/auth/mobile-register
```

**Solutions:**
- Restart emulator: `emulator -avd Medium_Phone_API_36 -no-snapshot-load`
- Check WiFi connection
- Check Vercel status: https://status.vercel.com

---

### Issue: "HTTP 403: Forbidden" or "JWT malformed"

**Root Cause:** Supabase RLS policies not configured

**Solution:**
1. Open Supabase console
2. Go to SQL Editor
3. Run SQL from `supabase_rls_setup.sql`
4. Retry register/login

---

### Issue: "HTTP 500" or "Unable to register mobile session"

**Root Cause:** Server-side error

**Solution:**
1. Check Vercel logs: https://console.vercel.com/[project]/logs
2. Look for error messages
3. Common issues:
   - Supabase environment variables not set
   - Database connection failed
   - Missing table/column in profiles table

---

### Issue: App stuck in infinite loading

**Root Cause:** Before fix, timeout was unlimited. Now should resolve within 15s.

**Solution:**
- Update to latest version yang punya timeout
- Check logs untuk exact error
- If error shows, tap OK to dismiss and try again

---

## Success Criteria ✅

Register/Login flow is working correctly when:

- [ ] Can register with new email without timeout
- [ ] Immediately logged in after successful register
- [ ] Can login with registered email/password
- [ ] Profile loads correctly (avatar initials, username, etc.)
- [ ] Token persists after app restart
- [ ] Chat history loads
- [ ] Map view shows and loads correctly
- [ ] Error messages are descriptive (not generic)
- [ ] No infinite loading spinners

---

## Next Steps After Success

1. Test additional features:
   - Send chat message
   - Update profile
   - Add friend
   - Change privacy settings

2. Merge changes to main branch

3. Deploy to production

