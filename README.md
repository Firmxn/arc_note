# ArcNote

Aplikasi pencatat dan manajemen pengetahuan pribadi dengan sinkronisasi lintas perangkat.

## Tentang ArcNote

ArcNote adalah aplikasi pencatat yang menggabungkan fleksibilitas seperti Notion dengan kemudahan sinkronisasi. Dibangun dengan Flutter dan Supabase untuk pengalaman yang seamless di Android, iOS, dan Desktop.

### Fitur Utama
- ✍️ **Block-based editing** - Edit catatan dengan blok teks, daftar, dan media
- 🔄 **Real-time sync** - Sinkronisasi otomatis antar perangkat
- 🔐 **Secure authentication** - Login aman dengan Supabase Auth
- 📱 **Cross-platform** - Berjalan di Android, iOS, Windows, macOS, Linux, dan Web
- 🎨 **Modern UI** - Antarmuka Material Design 3 yang responsif

## Teknologi

- **Frontend**: Flutter
- **State Management**: Riverpod
- **Backend**: Supabase
- **Local Database**: Isar
- **Routing**: GoRouter
- **Environment**: flutter_dotenv

## Struktur Proyek

```
lib/
├── src/
│   ├── core/                   # Kode inti yang dapat digunakan kembali
│   │   ├── constants/         # Konstanta aplikasi
│   │   ├── router/            # Konfigurasi routing
│   │   ├── services/          # Dependency injection dan layanan inti
│   │   └── utils/             # Utilitas dan extensions
│   ├── data/                   # Layer data
│   │   ├── datasources/       # Sumber data lokal dan remote
│   │   ├── models/            # Model data entitas
│   │   └── repositories/      # Repository pattern
│   └── features/               # Fitur-fitur aplikasi
│       ├── auth/              # Autentikasi
│       ├── notes/             # Manajemen catatan
│       └── sync/              # Sinkronisasi data
└── main.dart                  # Entry point aplikasi
```

## Getting Started

### Prerequisites

- Flutter SDK (>= 3.7.2)
- Dart SDK
- Supabase account

### Installation

1. Clone repository ini:
   ```bash
   git clone https://github.com/Firmxn/arc_note.git
   cd arc_note
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Setup environment variables:
   ```bash
   cp .env.example .env
   # Edit .env dan tambahkan Supabase URL dan anon key
   ```

4. Jalankan aplikasi:
   ```bash
   flutter run
   ```

### Development

- **Code generation**: Jalankan `flutter pub run build_runner build` untuk generate kode
- **Testing**: Jalankan `flutter test` untuk menjalankan unit tests
- **Linting**: Jalankan `flutter analyze` untuk analisis kode

## Progress

- [x] **Setup Arsitektur Core** - Struktur direktori berbasis fitur dan dependencies
- [ ] **Integrasi Supabase & Database Lokal** - Setup backend dan local storage
- [ ] **Autentikasi** - Login, signup, dan session management
- [ ] **Data Models & Repository** - Struktur data dengan sync logic
- [ ] **UI Core & Editor** - Antarmuka pengguna dan editor berbasis blok

## Contributing

1. Fork repository ini
2. Buat feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit perubahan (`git commit -m 'Add some AmazingFeature'`)
4. Push ke branch (`git push origin feature/AmazingFeature`)
5. Buka Pull Request

## License

Proyek ini dilisensikan di bawah MIT License - lihat file [LICENSE](LICENSE) untuk detail.
