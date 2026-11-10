# RansomGuard Pi

**A Raspberry Pi-Based Backup and Ransomware Early-Detection System for a Learning Center Cloud Server (Nextcloud)**

Projek Tahun Akhir 1 (IPB49804), BIT (Hons) Computer System Security, UniKL MIIT.
Penyelia: Dr. Farahwahida. Pasukan: Haziq (Modul B) dan Tuan Muhammad Faris (Modul A).

## Apa projek ini

Pusat pembelajaran kecil biasanya simpan bahan guru dan kerja pelajar dalam satu pelayan awan peribadi. Kalau satu komputer pelajar atau guru dijangkiti ransomware, klien sync akan hantar fail yang dah dienkripsi ke pelayan, lalu merebak ke semua peranti yang disegerakkan.

RansomGuard Pi ialah prototype murah atas Raspberry Pi 4 (8GB) yang menjalankan Nextcloud dalam Docker, dengan dua lapisan perlindungan:

1. **Kesan awal dan bendung** (Modul B): pantau perubahan fail, kenal pasti pengguna dan IP yang mencurigakan, sekat IP, dan hantar amaran.
2. **Backup dan pulih** (Modul A): snapshot berjadual yang klien tak boleh ubah, dan pemulihan fail yang bersih.

## Bagaimana ia berfungsi

```
Klien sync (guru/pelajar)  ->  Nextcloud (Docker, Raspberry Pi)
                                  |                 |
                          Modul B: detector     Modul A: rg-backup
                          (pantau fail,         (restic, snapshot setiap jam,
                           sekat IP, Telegram)   disimpan atas USB SSD)
                                  |                 ^
                                  +-- serangan dikesan: rg-backup pin --before <masa>
                                      (bekukan snapshot bersih sebelum serangan)
```

Sambungan antara dua modul (`pin`) sudah sedia di sisi Modul A, tetapi belum disambung ke detector.

## Modul

| Modul | Pemilik | Fungsi | Status (10 Nov 2026) |
|---|---|---|---|
| **A: Backup dan Recovery** | Faris | Backup berenkripsi dan berversi dengan restic (fail, dump DB, manifest SHA-256), pemulihan dengan pengesahan hash, pin/unpin snapshot | Berfungsi di Pi, hasil ujian awal ada |
| **B: Detection dan Containment** | Haziq | Pengesanan (fail umpan, entropi, kadar perubahan, extension, magic number), sekat IP, alert Telegram, dashboard admin | Berfungsi dan disahkan pada Nextcloud sebenar, 13 senario ujian |

Hasil awal Modul A: backup penuh pertama 69 saat (1.056 GiB), backup tokokan 13 saat, pemulihan 287 fail dengan semua hash sepadan. Butiran dalam nota Modul A.

## Struktur folder

```
README.md                  fail ini
00 - Indeks.md             indeks semua nota
FYP1/                      ringkasan projek, garis masa, cadangan penambahbaikan
Modul A/                   nota Modul A + skrip rg-backup.sh + README untuk Haziq
Modul B/                   nota Modul B (status, arahan, masalah dan penyelesaian)
Lampiran/                  dokumen DOCX (status projek, cadangan penambahbaikan)
```

Folder ini juga vault Obsidian. Buka folder `MEMORY` sebagai vault dan mulakan dari `00 - Indeks`.

## Mula dari mana

- Nak faham projek dan garis masa: `FYP1/FYP1 - Ringkasan Projek dan Garis Masa.md`
- Nak jalankan atau sambung Modul A: `Modul A/README.md`
- Nak jalankan Modul B: `Modul B/Modul B - Arahan Command.md`

## Baki kerja utama

- Sambung detector Modul B ke `rg-backup pin` dan buat ujian hujung ke hujung dengan simulator
- Ukur CPU dan RAM Pi, ujian false positive lebih besar, dan ulang ujian pemulihan dengan klien sync sebenar
- Methodology, Gantt, dan kemas kini proposal untuk defence (minggu 6 hingga 7)

## Keselamatan

Kata laluan repo backup, token Telegram dan alamat rangkaian Pi **tidak** disimpan dalam repo ini. Semuanya kekal di Pi sahaja. Simulator hanya jalan dalam folder ujian yang ada fail penanda, dan semua ujian dibuat di makmal sendiri.
