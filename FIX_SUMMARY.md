# Jawaban untuk Masalah Register/Login Timeout

## 🔴 Masalah yang Dilaporkan

> "sudah mencoba regis dan login, yang terjadi hanya loading dan terus muter hingga akhirnya request time out"

### Penyebab Timeout:
1. **Tidak ada explicit timeout di HTTP client** → Request bisa hang forever
2. **Error tidak terlihat** → User hanya lihat loading spinner, tidak tahu apa masalahnya
3. **Belum di-verify:** Apakah Vercel sudah deploy? Apakah Supabase RLS blocking?

---

## ✅ Solusi yang Sudah Diimplementasikan

### 1. ApiClient Improvements (Dart)
- **Timeout ditambahkan:** 15 detik (dari unlimited)
- **Logging ditambahkan:** `dart:developer` untuk debug
- **Error handling:** Timeout exception ditangkap dengan pesan jelas

**File yang diubah:**
- `zmayy_mobile/lib/core/api_client.dart` → Add timeout, logging
- `zmayy_mobile/lib/features/auth/register_screen.dart` → Better error display
- `zmayy_mobile/lib/features/auth/login_screen.dart` → Better error display

### 2. Diagnostic Documentation
- `DEBUGGING_TIMEOUT.md` → 6-step diagnosis process
- `TESTING_GUIDE.md` → Complete testing dengan curl examples
- `supabase_rls_setup.sql` → RLS policy setup script

---

## 🎯 Jawaban untuk 3 Pertanyaan User

### Q1: "Apakah ada masalah dalam pengaturan Next.js?"

**Kemungkinan masalah di Next.js:**
- Route handler tidak ter-deploy ke Vercel
- Environment variables tidak set (SUPABASE_URL, SUPABASE_ANON_KEY)
- CORS headers tidak correct

**Cara check:**
```bash
curl https://zmayy.vercel.app/api/auth/mobile-register -X POST \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"123"}'
```

Jika dapat 404 → Route tidak ada, Vercel belum ter-deploy
Jika dapat JSON error → Vercel sudah deploy, masalahnya di logic atau RLS

---

### Q2: "Atau di mobile?"

**Kemungkinan masalah di mobile:**
- Base URL salah (`config.dart`)
- Timeout terlalu lama / no timeout at all (❌ SUDAH DIFIX)
- Error tidak visible ke user (❌ SUDAH DIFIX)
- Network connectivity issue (emulator tidak bisa reach server)

**Cara test:**
```bash
# Jalankan app dengan verbose logging
flutter run -v

# Lihat logs - cari:
# [ms] API Request: POST https://zmayy.vercel.app/...
# [ms] API Response: 201 from https://...
# atau
# [ms] Request timeout after 15s
```

---

### Q3: "Apa mungkin harus aku atur RLS atau hal lain di Supabase?"

**✅ YA, RLS bisa jadi masalah!**

Jika `profiles` table punya RLS enabled, pastikan policies ada:

```sql
-- Allow INSERT own profile
CREATE POLICY "Users can insert their own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Allow SELECT/UPDATE own profile
CREATE POLICY "Users can read/update profile" ON profiles
  FOR SELECT USING (auth.uid() = id);
```

**Cara check:** Lihat `supabase_rls_setup.sql` untuk SQL lengkap

**Jika RLS blocking:** Akan dapat error `HTTP 403: Forbidden` atau `JWT malformed`

---

## 📋 Action Items untuk User

### Step 1: Verify Deployment (5 menit)
```bash
curl -X POST https://zmayy.vercel.app/api/auth/mobile-register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"123"}'
```

**Expected:** Dapat response JSON (bukan 404)

Jika 404, push ulang ke Vercel:
```bash
git add .
git commit -m "fix: add timeout and logging to mobile auth"
git push origin main
```

---

### Step 2: Check Supabase RLS (5 menit)
1. Open https://supabase.com → Your Project
2. Go to SQL Editor
3. Paste SQL dari `supabase_rls_setup.sql`
4. Click Run

Ini akan create RLS policies yang diperlukan.

---

### Step 3: Test Register via Mobile (10 menit)

Pull latest changes ke mobile:
```bash
git pull origin main
cd zmayy_mobile
flutter run -v
```

Input email/password baru, tap register, lihat logs:

**Jika success (status 201):**
```
[ms] API Response: 201 from https://zmayy.vercel.app/api/auth/mobile-register
[ms] Register response: {access_token: eyJ...}
✅ Navigate to AppShell
```

**Jika timeout (setelah 15s):**
```
[ms] Request timeout after 15s
❌ SnackBar shows: "Request timeout after 15s"
```

**Jika RLS error (status 403):**
```
[ms] API Response: 403 from https://zmayy.vercel.app/api/auth/mobile-register
❌ SnackBar shows: "Forbidden"
→ Run supabase_rls_setup.sql
```

---

### Step 4: Test Login (5 menit)

Input email/password yang baru didaftar, tap login.

Expected behavior: Same as register (navigate to AppShell)

---

## 📊 Expected vs Actual

### Before Fix ❌
- Loading spinner terus muter
- Timeout setelah waktu lama (browser default timeout ~2 min)
- Error message generic/tidak jelas

### After Fix ✅
- Timeout cepat (15 detik)
- Error message detail di SnackBar
- Logs membantu debugging

---

## 🔍 Diagnosis Tree

```
Register/Login timeout
├─ curl https://zmayy.vercel.app/api/auth/mobile-register
│  ├─ 404 → Vercel belum deploy → git push
│  ├─ 403 → RLS blocking → run supabase_rls_setup.sql
│  ├─ 500 → Server error → check Vercel logs
│  ├─ 200/201 → Success, masalahnya di mobile
│  └─ Timeout → Network issue → test adb shell ping
└─ flutter run -v & lihat logs
   ├─ "API Response: 201" → Navigate to AppShell
   ├─ "Request timeout after 15s" → Network unreachable
   ├─ "API Response: 403" → RLS blocking
   └─ "API Response: 500" → Server error
```

---

## 📞 Quick Reference

| File | Purpose |
|------|---------|
| `DEBUGGING_TIMEOUT.md` | 6-step diagnosis guide |
| `TESTING_GUIDE.md` | Complete testing dengan curl + app tests |
| `supabase_rls_setup.sql` | RLS policies SQL |
| `zmayy_mobile/lib/core/api_client.dart` | ← 15s timeout added |
| `app/api/auth/mobile-*.ts` | Next.js routes (sudah exist) |

---

## 🚀 Next Steps

1. ✅ Pull latest code (timeout fix)
2. ✅ Verify Vercel deployment (curl test)
3. ✅ Setup Supabase RLS (SQL script)
4. ✅ Test register via mobile (flutter run -v)
5. ✅ Test login
6. ✅ Check logs untuk any remaining errors
7. 🔄 Report back dengan error message (jika ada)

Setelah semua ini fix, register/login seharusnya bisa normal tanpa timeout! 🎉

