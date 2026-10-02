### Komponen

- Google Colab
- Drive

### Drive Directory Structure

```bash
MyDrive/
└── order_20260827_213103/
    ├── dataset/             <- letakkan video asli (tanpa watermark) di sini, format .mp4
    └── output/              <- seluruh hasil (watermarked, compressed, laporan) akan disimpan di sini
```

### Setup anti limit

1. Siapkan drive yang akan digunakan sebagai akun utama yang menyimpan `dataset` + `output`.
2. Bagikan Akses folder `order_20260827_213103` ke akun lainnya.
3. Di drive akun lainnya bukan menu `share with me` buat shortcut folder tersebut ke `root` drive.

Sharing Resource sudah siap digunakan.

### Upaya Hemat Resource

Ada usaha lain agar pengembangan bisa lebih hemat, dan tidak terlalu sering mengulang:

1. buat checkpoint di fase kritikal atau fase yang memerlukan waktu yang cukup lama, jika proses itu sifatnay iteratif dan dapat memakan waktu 20 mnt lebih, buatlah checkpoint.