# Modul A - Backup dan Recovery

Pemilik: Faris | Rakan kongsi: Haziq (Modul B) | Kemas kini: 10 Nov 2026
Arahan lengkap: [[Modul A - Arahan rg-backup]]

## Status ringkas

Modul A **berfungsi di Pi** (backup berjadual, restore dengan pengesahan hash, pin/unpin). Belum disambung dengan detector Modul B.

| Item (dari Status Projek 7 Nov) | Status |
|---|---|
| Snapshot berjadual dan berversi | Siap (restic, timer setiap jam) |
| Tahan gangguan (klien tak boleh ubah backup) | Siap untuk prototype (repo di luar Nextcloud, root sahaja, tidak di-mount ke Docker) |
| Pengesanan integriti (SHA-256) | Siap (manifest SHA-256 + `restic check`) |
| Skrip pemulihan | Siap (per pengguna diuji; restore penuh + DB belum diuji) |
| Storan USB | Belum (repo masih atas microSD, pindah ke SSD sebelum penilaian) |
| Arahan bekukan snapshot (untuk Modul B) | Siap (`rg-backup pin --before ...`) |

## Rekabentuk

- **Alat:** restic 0.18.0 (Raspberry Pi OS trixie, arm64). Repo berenkripsi, dedup, berversi.
- **Apa yang dibackup:** folder data Nextcloud (`~/nextcloud/data`), dump DB MariaDB (`mariadb-dump --single-transaction`), `config.php`, dan manifest SHA-256 semua fail data.
- **Konsistensi:** Nextcloud dimasukkan ke maintenance mode semasa backup supaya fail dan DB selari (klien sync berhenti sementara).
- **Lokasi:** repo `/srv/rg-backup/repo`, state `/srv/rg-backup/state` (db.sql, manifest, metrics.csv, log, fail PINNED). Bukan dalam folder Nextcloud dan tidak di-mount ke container, jadi klien sync tidak boleh menyentuhnya.
- **Retention:** 24 hourly, 7 daily, 4 weekly. Dilangkau sepenuhnya semasa beku.
- **Pin:** `rg-backup pin --before MASA` pilih snapshot terakhir sebelum masa serangan, tulis ID ke fail PINNED, dan bekukan (tiada backup, tiada forget/prune). Tidak guna `restic tag` kerana ia cipta snapshot baharu dengan ID baharu.
- **Model ancaman (dari proposal):** Pi tidak compromised; attacker kawal satu komputer pengguna yang ada akses sync.

## Hasil ujian (10 Nov 2026, Pi "FYP 1")

| Ukuran | Hasil |
|---|---|
| Backup penuh pertama | 69 saat (data 1.056 GiB, repo 488.7 MB) |
| Backup tokokan | 13 saat (repo +1.4 MB, ulang dua kali termasuk satu dari timer) |
| Restore cikgu1 (287 fail) + pengesahan hash | ~14 saat ke staging |
| `--apply` (tampal ke Nextcloud + files:scan) | ~20 saat |
| Simulasi kerosakan 3 fail | 3/3 dikesan oleh manifest, 3/3 dipulihkan, 287/287 hash sepadan |
| `restic check` (10% data) | tiada ralat |
| Backup berjadual (systemd timer) | berjalan sendiri pukul 14:01 |

Nota: ujian kerosakan dibuat terus pada fail (dd), bukan melalui simulator dan sync klien. Perlu diulang dengan simulator Haziq.

## Had semasa

- Repo atas microSD yang sama dengan data (belum SSD), jadi angka masa/CPU belum mewakili setup akhir.
- Maintenance mode menghentikan sync klien sepanjang backup (13 hingga 69 saat).
- `--apply` menulis banyak fail serentak, jadi detector boleh trigger. Detector perlu dijeda semasa restore.
- Restore penuh (tanpa `--user`, termasuk DB) belum diuji. `config.php` dibackup tetapi tidak dipulihkan automatik.
- Folder staging `restore-*` terkumpul di `/srv/rg-backup` dan perlu dibersihkan.

## Baki kerja

- [ ] Haziq sambung `--snapshot-cmd` ke `rg-backup pin` (lihat [[Modul A - Arahan rg-backup]])
- [ ] Ujian hujung ke hujung: simulator, detector, pin, restore, banding hash dengan `ujian_asal`
- [ ] Uji restore penuh termasuk DB
- [ ] Pindah repo ke USB SSD, ulang ukuran (masa backup/restore, saiz repo, CPU/RAM Pi)
- [ ] Ukuran dengan dataset lebih besar (fail video)
- [ ] Bersihkan folder staging
- [ ] Tulis bab Modul A untuk laporan
