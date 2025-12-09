# Lumbung Hijau

## Instalasi Backend

### 1. Konfigurasi Environment
```bash
cd backend
cp .env.example .env
```

Isi konfigurasi:
```env
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=password_anda
DB_NAME=lumbunghijau
JWT_SECRET=secret_key_anda
PORT=8080
```

### 2. Jalankan Server
```bash
go run main.go
```

Server berjalan di `http://localhost:8080`

---

## Endpoint API

### Autentikasi
| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| POST | `/register` | Daftar akun baru |
| POST | `/login` | Masuk ke akun |
| GET | `/me` | Ambil data user yang login |
| PUT | `/profile` | Update profil user |

### Penyetoran Sampah
| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| POST | `/deposits` | Buat pengajuan penyetoran |
| GET | `/deposits` | Lihat semua penyetoran saya |
| GET | `/deposits/:id` | Lihat detail penyetoran |
| POST | `/deposits/:id/photo` | Upload foto bukti |

### Notifikasi
| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| GET | `/notifications` | Lihat semua notifikasi |
| GET | `/notifications/unread-count` | Jumlah notifikasi belum dibaca |
| PUT | `/notifications/:id/read` | Tandai sudah dibaca |
| PUT | `/notifications/read-all` | Tandai semua sudah dibaca |

### Chat
| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| GET | `/chat/list` | Lihat daftar chat |
| GET | `/chat/:user_id/messages` | Lihat pesan dengan user |
| POST | `/chat/:user_id/messages` | Kirim pesan |
| GET | `/chat/unread-count` | Jumlah pesan belum dibaca |

### Admin
| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| GET | `/admin/deposits` | Lihat semua penyetoran |
| PUT | `/admin/deposits/:id/status` | Update status penyetoran |

---

## Status Penyetoran

| Status | Deskripsi |
|--------|-----------|
| `pending` | Menunggu konfirmasi admin |
| `proses` | Sedang dalam proses penjemputan |
| `completed` | Penyetoran selesai |
| `rejected` | Penyetoran ditolak |

## Role Pengguna

| Role | Akses |
|------|-------|
| `user` | Membuat penyetoran, melihat riwayat sendiri |
| `admin` | Melihat semua penyetoran, update status |

---

## Catatan

- Semua endpoint kecuali `/register` dan `/login` memerlukan token JWT
- Token dikirim melalui header `Authorization: Bearer <token>`
- Upload foto menggunakan format `multipart/form-data`
