# 📋 Zmayy Mobile — Master TODO

> Berdasarkan analisis: `goals/` screenshots (web UI), `Zmayy_Master_Spec.txt`, dan kode Flutter saat ini.
> **Prioritas: Kerjakan fase per fase secara berurutan agar hasil maksimal.**

---

## 🔍 Kondisi Saat Ini (Analisis)

| Komponen | Status | Masalah |
|---|---|---|
| Login/Register | ✅ UI ada | HTTP 405 setelah login → tidak ada redirect ke home |
| Map Screen | ⚠️ Partial | Tidak ada panel Teman/Obrolan, badge layout beda dari web |
| Chat Screen | ⚠️ Partial | Global chat — seharusnya 1-on-1 DM per teman |
| Bottom Nav | ⚠️ Partial | Label salah (Map/Chat/Settings) → harus Teman/Obrolan/Profil |
| Profile/Settings | ❌ Kosong | `SettingsScreen` hanya tombol Logout |
| Friends Panel | ❌ Tidak ada | Belum ada sama sekali |
| Ghost Mode | ❌ Tidak ada | Belum diimplementasikan |
| Notifikasi Settings | ❌ Tidak ada | Belum diimplementasikan |
| Privasi Settings | ❌ Tidak ada | Belum diimplementasikan |
| Empty States | ❌ Tidak ada | Tidak ada UI untuk kondisi kosong |
| QR / NFC / Share | ❌ Tidak ada | Belum diimplementasikan |

---

## 📦 FASE 1 — Perbaikan Foundation & Post-Login Flow

> **File terkait:** `app_shell.dart`, `core/app_state.dart`, `features/auth/login_screen.dart`

### TODO 1.1 — Fix Post-Login Navigation
- [ ] Setelah login berhasil, navigasi ke `AppShell` bukan blank screen
- [ ] Simpan `access_token`, `user`, `profile` dari response `mobile-session` ke `SecureStorage`
- [ ] Pada cold-start, cek token di `SecureStorage` → jika ada, panggil endpoint `mobile-session` untuk validasi, lalu masuk ke `AppShell`
- [ ] Jika token tidak valid/expired → redirect ke `LoginScreen`

### TODO 1.2 — Refactor Bottom Navigation Bar
- [ ] Ubah 3 tab: **Teman** (ikon `people`), **Obrolan** (ikon `chat_bubble`), **Profil** (ikon `person`)
- [ ] Tab **Map** dihilangkan dari bottom nav — Map menjadi **background fullscreen** di balik panel Teman
- [ ] Tambah label teks di bawah setiap ikon (Teman, Obrolan, Profil)
- [ ] Tombol recenter (arrow FAB gold) tetap tampil di atas map saat panel Teman aktif

### TODO 1.3 — Refactor AppShell Architecture
- [ ] `MapScreen` selalu render sebagai background layer
- [ ] Panel **Teman**, **Obrolan (list)**, **Profil** tampil sebagai slide-over panel di atas map
- [ ] `AppState` ditambahkan field: `currentUserId`, `currentProfile` (dari session)
- [ ] Buat model `UserProfile` yang menyimpan: id, username, email, avatar initials, is_ghost_mode, is_public, notify_global, notify_requests, notify_messages, notify_sound

---

## 📦 FASE 2 — Panel Teman (Friends Panel)

> **File baru:** `lib/features/friends/friends_panel.dart`, `lib/features/friends/widgets/friend_tile.dart`, `lib/data/repositories/friends_repository.dart`
> **Referensi visual:** `goals/Screenshot 2026-05-11 180150.png` & `180158.png`

### TODO 2.1 — Friends Panel UI
- [ ] Panel slide dari kiri, lebar ~85% layar, background `#0B0E11` gelap
- [ ] Header: teks "**Teman**" + tombol close (X) di kanan
- [ ] Search bar: "Cari username..." dengan ikon search (glass-style border)
- [ ] Toggle tab: **Teman** | **Permintaan** (dengan badge counter jika ada pending)
- [ ] Tab aktif: background gold `#FCD535`, teks gelap; non-aktif: transparan, teks putih

### TODO 2.2 — Tab Teman (Friend List)
- [ ] Tampilkan daftar teman dari API `/api/friends` atau Supabase `friend_requests` where status=accepted
- [ ] Setiap item: avatar (initials berwarna gold), username, subtitle "Dekat" / jarak, online dot hijau jika online
- [ ] **Empty state jika tidak ada teman:**
  - Ikon orang dengan tanda +
  - Teks: "Belum ada teman"
  - Sub-teks: "Dekati seseorang di peta untuk memulai"
- [ ] Tap pada teman → buka `ChatDetailScreen` (DM 1-on-1 dengan teman tersebut)

### TODO 2.3 — Tab Permintaan (Friend Requests)
- [ ] Tampilkan daftar permintaan masuk dari API
- [ ] Setiap item: avatar initials, username, subtitle "Dekat", tombol "**✓ Terima**" (gold)
- [ ] Tombol Terima: panggil API accept, hapus item dari list, update badge counter
- [ ] **Empty state jika tidak ada permintaan:**
  - Ikon amplop/orang
  - Teks: "Tidak ada permintaan"
  - Sub-teks: "Permintaan pertemanan akan muncul di sini"

### TODO 2.4 — Friends Repository
- [ ] `getFriends()` → GET `/api/friends`
- [ ] `getFriendRequests()` → GET `/api/friends/requests`
- [ ] `acceptFriendRequest(String requesterId)` → POST `/api/friends/accept`

---

## 📦 FASE 3 — Panel Obrolan (Chat List + DM 1-on-1)

> **File baru:** `lib/features/chat/chat_list_panel.dart`, `lib/features/chat/chat_detail_screen.dart`
> **Referensi visual:** `goals/Screenshot 2026-05-11 180225.png` & `180234.png`

### TODO 3.1 — Chat List Panel (Obrolan tab)
- [ ] Panel slide dari kiri (atau full screen), background `#0B0E11`
- [ ] Header: "**Obrolan**" + tombol close X
- [ ] List percakapan: avatar initials gold, username, preview pesan terakhir, timestamp
- [ ] **Empty state jika tidak ada obrolan:**
  - Ikon chat bubble kosong
  - Teks: "Belum ada obrolan"
  - Sub-teks: "Mulai chat dengan temanmu dari daftar Teman"

### TODO 3.2 — Chat Detail Screen (DM 1-on-1)
- [ ] Header: back arrow, avatar + username teman, subtitle "< 1 km" + "N pesan sebelum hapus otomatis"
- [ ] Banner info ephemeral: "**Mode Efemeral:** Pesan dihapus otomatis setelah 10 percakapan atau 3 jam."
- [ ] **Empty state chat:**
  - Ikon kotak dashed (seperti di screenshot)
  - Teks: "**Belum ada pesan.**"
  - Sub-teks: "Kirim pesan pertama. Pesan akan terhapus otomatis setelah 10 percakapan."
- [ ] Bubble saya: kanan, background `#FCD535`, teks `#0B0E11`
- [ ] Bubble teman: kiri, background `#181A20`, border `#2B2F36`, teks putih
- [ ] Input bar bawah: "Tulis pesan...", tombol kirim (ikon send gold)
- [ ] Area upload gambar: "Seret & lepas gambar untuk berbagi lokasi" + tombol "+ Upload"
- [ ] Auto-scroll ke pesan terbaru setiap ada pesan baru

### TODO 3.3 — Chat Pruning Rules (sesuai Spec Section 3.3)
- [ ] Max 10 pesan dalam memory
- [ ] Pesan lebih dari 3 jam → tidak ditampilkan
- [ ] Guard di: load awal, realtime insert, optimistic send, render time

### TODO 3.4 — Realtime Chat per Pair
- [ ] Channel Supabase realtime: `chat-{sortedUserId1}-{sortedUserId2}`
- [ ] Filter: `receiver_id=eq.{currentUserId}`
- [ ] Optimistic send: tambah pesan langsung ke UI, rollback jika gagal

---

## 📦 FASE 4 — Panel Profil (Profile Modal)

> **File baru:** `lib/features/profile/profile_panel.dart`
> **Referensi visual:** `goals/Screenshot 2026-05-11 180253.png`

### TODO 4.1 — Profile Panel UI
- [ ] Panel fullscreen/slide dari bawah, background `#0B0E11`
- [ ] Logo Zmayy kecil di atas, tombol X di kanan atas
- [ ] Avatar besar: lingkaran gold, initials 2 huruf username
- [ ] Nama username (bold, besar)
- [ ] Handle `@username` dengan ikon edit (pensil) → tap untuk edit username
- [ ] Email (kecil, muted)
- [ ] Status dot hijau + teks "Online"

### TODO 4.2 — Settings Row di Profil
- [ ] **Mode Hantu** — ikon mata, toggle switch kanan, subtitle "Sembunyikan lokasi dari teman"
  - Toggle ON → null kan `last_lat` & `last_lng` di Supabase (sesuai Spec 5.1)
  - Toggle OFF → resume location tracking
- [ ] **Berbagi Lokasi** — ikon pin, no toggle, subtitle "Teman & Sekitar (1km)" (informational)
- [ ] **Notifikasi** — ikon bel, tap → buka `NotificationSettingsModal`
- [ ] **Privasi & Keamanan** — ikon shield, tap → buka `PrivacySettingsModal`

### TODO 4.3 — QR & Share Section
- [ ] Section "PINDAI UNTUK TERHUBUNG"
- [ ] QR Code: generate dari URL `https://zmayy.com/u/{userId}`, warna dark-on-white
- [ ] Handle `@username` di sebelah QR
- [ ] Tombol "Salin Tautan Profil" → copy ke clipboard + snackbar konfirmasi
- [ ] Teks: "Pindai dengan Zmayy Mobile atau ketuk ponsel melalui NFC."
- [ ] Tombol "Bagikan via NFC" → NFC write → fallback share sheet → fallback clipboard

### TODO 4.4 — Logout
- [ ] Tombol "Keluar" (merah/muted) di bawah
- [ ] Sequence: clear SecureStorage → reset AppState → navigasi ke LoginScreen

---

## 📦 FASE 5 — Notification & Privacy Settings Modal

> **File baru:** `lib/features/profile/notification_settings_modal.dart`, `lib/features/profile/privacy_settings_modal.dart`
> **Referensi visual:** `goals/Screenshot 2026-05-11 180303.png` & `180313.png` & `180347.png`

### TODO 5.1 — Notification Settings Modal
- [ ] Modal bottom sheet / dialog dengan header "Notifikasi" + tombol X
- [ ] Toggle: **Aktifkan Notifikasi** (master switch) — `notify_global`
- [ ] Section "JENIS NOTIFIKASI":
  - Toggle: **Permintaan Teman** — `notify_requests`
  - Toggle: **Pesan** — `notify_messages`
- [ ] Section "SUARA":
  - Toggle: **Suara Notifikasi** — `notify_sound`
- [ ] Semua toggle: instant-save ke Supabase `profiles` (tanpa tombol simpan)
- [ ] Tombol "Selesai" di bawah → tutup modal
- [ ] Jika master `notify_global` OFF → disable visual toggle lainnya

### TODO 5.2 — Privacy & Security Modal
- [ ] Modal dengan header "Privasi & Keamanan" + tombol X
- [ ] Section "VISIBILITAS":
  - Toggle: **Profil Publik** — `is_public` — subtitle "Izinkan pengguna di sekitar (±1km) melihat kamu di peta"
  - Instant-save ke Supabase
- [ ] Section "AKUN":
  - Tombol **Hapus Akun** (merah dengan ikon trash)
  - Tap → muncul konfirmasi inline: "Hapus Akun Secara Permanen?"
  - Teks: "Tindakan ini **tidak dapat dibatalkan**..."
  - Dua tombol: **Batal** | **Lanjutkan** (merah)
- [ ] Tombol "Selesai" di bawah

---

## 📦 FASE 6 — Map UI Fixes & Overlay Badges

> **File:** `lib/features/map/map_screen.dart`
> **Referensi visual:** `goals/Screenshot 2026-05-11 180136.png`

### TODO 6.1 — Map Overlay Badge Fix
- [ ] Badge kiri bawah: dua baris terpisah (bukan horizontal)
- [ ] Baris 1: ikon orang + "N pengguna di sekitar" (teks abu `#D1D5DB`)
- [ ] Baris 2: dot hijau `#22c55e` + "N teman online" (teks gold `#FCD535`)
- [ ] Jika ghost mode aktif → tampilkan "—" (dash) sebagai pengganti angka

### TODO 6.2 — Map Marker Parity
- [ ] Marker teman: avatar initials (2 huruf), border gold `#FCD535`, bg `#181A20`, teks gold, glow `rgba(252,213,53,0.45)`
- [ ] Marker stranger: border abu `#4B5563`, bg `#111318`, teks abu `#9CA3AF`, glow `rgba(75,85,99,0.3)`
- [ ] Tap marker → popup kecil dengan username dan jarak (bukan SnackBar)

### TODO 6.3 — Recenter Button
- [ ] FAB gold (ikon panah/navigation) di kanan bawah
- [ ] Tap → re-center map ke posisi user saat ini

### TODO 6.4 — Ghost Mode Effect pada Map
- [ ] Saat ghost mode aktif: stop location stream, null-kan koordinat di DB
- [ ] Badge menjadi "—", marker user sendiri tidak tampil ke orang lain

---

## 📦 FASE 7 — State Management & Data Layer

> **File terkait:** `lib/core/app_state.dart`, `lib/data/repositories/`

### TODO 7.1 — Extend AppState
- [ ] Tambahkan: `currentProfile` (UserProfile model)
- [ ] Tambahkan: `friends` (List<Friend>)
- [ ] Tambahkan: `friendRequests` (List<FriendRequest>)
- [ ] Tambahkan: `chatConversations` (List<Conversation> — daftar DM)
- [ ] Tambahkan: `isGhostMode` (dari profile, dengan setter yang trigger DB update)
- [ ] Tambahkan: `notifySound`, `notifyGlobal`, dll
- [ ] Method: `toggleGhostMode()`, `updateNotifSetting()`, `updatePrivacy()`

### TODO 7.2 — Friends Repository
- [ ] Implementasikan semua method dari TODO 2.4

### TODO 7.3 — Chat Repository Refactor
- [ ] Ubah dari global chat → DM per pair
- [ ] `getDMHistory(friendId)` → history 1-on-1
- [ ] `sendDM(friendId, text)` → kirim ke receiver spesifik
- [ ] `getConversations()` → list semua percakapan aktif

### TODO 7.4 — Location Stream (Continuous GPS)
- [ ] Gunakan `Geolocator.getPositionStream()` bukan `getCurrentPosition` sekali saja
- [ ] Setiap update: kirim lat/lng ke Supabase `profiles.last_lat`, `last_lng`, `updated_at`
- [ ] Pause stream jika ghost mode aktif

---

## 📦 FASE 8 — Polish & Empty States

### TODO 8.1 — Empty State Components
- [ ] Buat widget reusable `ZmayyEmptyState({icon, title, subtitle})`
- [ ] Gunakan di: Friends list, Requests list, Chat list, Chat detail

### TODO 8.2 — Sound Effects
- [ ] Implementasi suara kirim pesan (bip singkat ascending)
- [ ] Implementasi suara toggle (dua bip)
- [ ] Gated oleh `notify_sound` dari profile

### TODO 8.3 — Deep Link Handler
- [ ] Handle incoming deep link `/u/{userId}` → jika belum login → ke login, jika sudah → addFriend flow

### TODO 8.4 — Auth State Guard
- [ ] Pada cold-start: cek token → validasi via `mobile-session` → AppShell atau Login
- [ ] Protected screens tidak bisa diakses tanpa sesi valid

---

## 🗂️ File yang Akan Dibuat/Dimodifikasi

```
lib/
├── core/
│   └── app_state.dart              [MODIFY — extend state]
├── data/
│   ├── models/
│   │   ├── user_profile.dart       [NEW]
│   │   ├── friend.dart             [NEW]
│   │   └── conversation.dart       [NEW]
│   └── repositories/
│       ├── friends_repository.dart [NEW]
│       └── chat_repository.dart    [MODIFY — DM support]
├── features/
│   ├── auth/
│   │   └── login_screen.dart       [MODIFY — fix post-login nav]
│   ├── map/
│   │   └── map_screen.dart         [MODIFY — badge + marker fix]
│   ├── friends/
│   │   ├── friends_panel.dart      [NEW]
│   │   └── widgets/
│   │       └── friend_tile.dart    [NEW]
│   ├── chat/
│   │   ├── chat_list_panel.dart    [NEW]
│   │   └── chat_detail_screen.dart [NEW]
│   ├── profile/
│   │   ├── profile_panel.dart      [NEW]
│   │   ├── notification_settings_modal.dart [NEW]
│   │   └── privacy_settings_modal.dart      [NEW]
│   └── settings/
│       └── settings_screen.dart    [REPLACE → jadi ProfilePanel]
└── app_shell.dart                  [MODIFY — nav + layout refactor]
```

---

## ⚡ Urutan Pengerjaan yang Disarankan

1. **FASE 1** — Post-login fix (agar bisa test semua fitur berikutnya)
2. **FASE 7** — State management & data layer (fondasi untuk semua fitur)
3. **FASE 2** — Friends panel (UI + API)
4. **FASE 3** — Chat panel + DM 1-on-1
5. **FASE 4** — Profile panel
6. **FASE 5** — Settings modals (notif + privasi)
7. **FASE 6** — Map fixes
8. **FASE 8** — Polish (empty states, sound, deep link)

> [!IMPORTANT]
> Kerjakan satu fase selesai dulu sebelum lanjut ke fase berikutnya. Konfirmasi ke user setelah setiap fase selesai agar bisa di-test di emulator.
