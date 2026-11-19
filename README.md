# Hill Cipher Lab

Aplikasi Flutter lintas platform (**Windows Desktop & Android**) yang berjalan **100% offline** tanpa package eksternal dan tanpa database untuk simulasi, visualisasi rumus matriks, serta analisis frekuensi **Hill Cipher (2×2 & 3×3)**.

## Fitur Utama
- **Mesin Hill Cipher Pure Dart**: mendukung ordo 2×2 dan 3×3, validasi determinan modulo 26 (`gcd(det, 26) == 1`), perhitungan invers determinan, adjoin (minor → kofaktor → transpose), serta matriks invers kunci $K^{-1} \pmod{26}$.
- **Lab Kriptografi**: input matriks angka atau kata kunci (`4/4` atau `9/9`), generator kunci acak valid, mode *Smart Preserve* untuk mempertahankan posisi spasi & huruf besar/kecil, serta tombol *Tukar ke Input* untuk uji balik cepat.
- **Bedah Rumus**: jabaran langkah demi langkah mulai dari transformasi huruf, determinan, adjoin, $K^{-1}$, hingga perkalian matriks per blok.
- **Analisis Frekuensi**: grafik batang ganda (*bar chart*) murni widget Flutter membandingkan distribusi A–Z sebelum dan sesudah proses beserta skor *Index of Coincidence*.
- **Riwayat & Brankas Kunci**: preset kunci bawaan 2×2 dan 3×3, simpan kunci sesi ke RAM, dan muat ulang riwayat uji balik.

## Persiapan Kompilasi di Laptop dengan Flutter SDK
Folder platform (`android/` dan `windows/`) perlu di-generate sekali menggunakan Flutter CLI di komputer yang sudah memiliki SDK:

```bash
flutter create . --platforms=android,windows --project-name hill_cipher_lab
flutter pub get
flutter test
```

Menjalankan aplikasi:
```bash
# Windows Desktop
flutter run -d windows

# Build APK Android (release)
flutter build apk --release
```
