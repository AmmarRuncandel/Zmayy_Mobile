# Debugging Register/Login Timeout Issue

## Perubahan yang Sudah Dilakukan

✅ **ApiClient** sekarang punya **15-second timeout** (sebelumnya unlimited/hang forever)
✅ **Logging ditambahkan** - cek Flutter logs untuk melihat apa yg terjadi
✅ **Error messages lebih detail** - SnackBar akan show actual error bukan generic message

---

## Langkah-Langkah Diagnosis

### 1️⃣ **Cek Vercel Deployment Status**

**URL untuk test**: https://zmayy.vercel.app/api/auth/mobile-register

Buka di browser dan cek:
- ✅ Jika dapat response JSON → Vercel punya kode terbaru
- ❌ Jika dapat 404 → Kode belum ter-deploy, minta Vercel rebuild

**Cara test dari terminal:**
```bash
curl -X POST https://zmayy.vercel.app/api/auth/mobile-register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"123","username":"test"}'
```

Expected response (bukan 404):
```json
{"error":"Email and password are required."}
// atau
{"error":"Unable to create account."}
```

---

### 2️⃣ **Cek Flutter Logs untuk Error Details**

**Jalankan app dan lihat logs:**

```bash
cd d:\Project-Collage\UASPabp\zmayy_mobile
flutter run -v
```

**Cari log entry seperti:**
```
[    +123 ms] API Request: POST https://zmayy.vercel.app/api/auth/mobile-register
[    +125 ms] Register attempt: akim@gmail.com
[   +5000 ms] API Response: 400 from https://zmayy.vercel.app/api/auth/mobile-register
```

**Atau jika timeout:**
```
[   +15000 ms] Request timeout after 15s: https://zmayy.vercel.app/api/auth/mobile-register
[   +15001 ms] Register error: TimeoutException: Request timeout after 15s
```

---

### 3️⃣ **Identifikasi Root Cause dari Error/Timeout**

| Error Message | Penyebab | Solusi |
|---|---|---|
| `Connection timed out` | Emulator/device tidak bisa reach Vercel | Cek network, pastikan WiFi/internet connected |
| `HTTP 404: Not Found` | Route tidak ada di Vercel | Vercel belum update, trigger redeploy |
| `HTTP 403: Forbidden` / `JWT malformed` | Supabase RLS blocking | Check RLS policy di Supabase |
| `HTTP 400: Email already registered` | Email sudah ada | Gunakan email baru |
| `HTTP 500` | Server error | Cek Vercel logs di console.vercel.com |

---

### 4️⃣ **Verifikasi Network Connectivity dari Emulator**

**Test apakah emulator bisa reach Vercel:**

```bash
# Di dalam emulator/device, test dengan adb shell:
adb shell ping zmayy.vercel.app

# Expected output:
# PING zmayy.vercel.app (123.456.789.10): 56 data bytes
# 64 bytes from 123.456.789.10: icmp_seq=0 ttl=119 time=50.123 ms
```

Jika tidak bisa ping:
- ❌ Network problem → restart emulator, check WiFi
- ✅ Kalau ping success tapi HTTP timeout → masalah di server/proxy

---

### 5️⃣ **Check Supabase RLS Policies** ⚠️ PENTING

Di https://supabase.com → Project → Authentication → Users

Jika `profiles` table punya RLS (Row Level Security) enabled, pastikan policies allow:

**Required policies:**

```sql
-- Allow authenticated users to INSERT their own profile
CREATE POLICY "Users can insert their own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Allow authenticated users to SELECT/UPDATE their own profile
CREATE POLICY "Users can read their own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- Allow service role (backend) to do anything for admin tasks
-- (ini biasanya already exist)
```

**Cara check di Supabase console:**
1. Go to Authentication → Policies
2. Lihat `profiles` table
3. Pastikan ada policy yang allow INSERT/SELECT untuk authenticated users

Jika TIDAK ada policy:
- 🔴 RLS will block semua requests → add policies di atas
- Atau disable RLS for testing (NOT recommended for production)

---

### 6️⃣ **Check CORS Configuration (jika perlu)**

Kalau dapat error CORS di web browser:

**Current ALLOWED_ORIGINS di `app/api/_lib/mobile-rest.ts`:**
```
https://zmayy.vercel.app
http://localhost:3000
http://127.0.0.1:3000
http://localhost:3001
http://127.0.0.1:3001
```

**Catatan:** Native mobile app (Flutter) biasanya TIDAK triggered CORS (CORS hanya browser thing)

---

## Debugging Checklist

Jalankan dalam urutan ini:

- [ ] 1. Test vercel route dengan curl dari terminal (Step 1)
- [ ] 2. Jalankan app dengan `flutter run -v` dan capture logs (Step 2)
- [ ] 3. Identifikasi error message dari logs (Step 3)
- [ ] 4. Jika network problem, test emulator connectivity (Step 4)
- [ ] 5. Jika HTTP 403/JWT error, check Supabase RLS (Step 5)
- [ ] 6. Jika berhasil register, coba login juga

---

## Quick Fixes

### Jika masalahnya Vercel belum update:
```bash
# Re-push ke vercel (di folder next.js):
git add .
git commit -m "fix: add mobile auth routes with timeout"
git push origin main

# Vercel akan auto-deploy (cek di console.vercel.com)
```

### Jika masalahnya RLS Supabase:
Buka Supabase console → SQL Editor → paste policies dari Step 5

### Jika masalahnya timeout:
✅ Sudah fixed - timeout sekarang 15 detik, error message akan show detail

---

## Next Steps Setelah Fixed

1. Test register dengan email baru
2. Test login dengan email yang sudah didaftar
3. Pastikan bisa masuk ke AppShell (map view)
4. Test semua features (chat, friends, profile)

