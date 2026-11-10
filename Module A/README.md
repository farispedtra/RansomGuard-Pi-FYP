# Modul A: Backup dan Recovery (Faris)

Status (10 Nov 2026): **berfungsi di Pi**, belum disambung dengan detector Modul B.

Skrip: `rg-backup.sh` (di Pi: `/usr/local/sbin/rg-backup`). Nota penuh ada dalam folder `vault/`, mulakan dengan `Modul A - Arahan rg-backup.md`.

## Apa Haziq boleh buat sekarang

1. **Sambung hook detector.** Bila detector kesan serangan, panggil arahan ini dengan masa serangan bermula (detector sudah jalan sebagai root, jadi tak perlu `sudo`):

   ```
   /usr/local/sbin/rg-backup pin --before "<masa_serangan_ISO8601>"
   ```

   Contoh masa: `2026-11-12T19:29:27+08:00` (epoch saat pun boleh). Ia **membekukan backup dan rotation**, dan mencetak ID snapshot bersih terakhir sebelum masa itu. Kalau tiada snapshot sebelum masa itu, exit code 1 dan backup kekal beku.

2. **Cuba arahan di terminal Pi:**

   ```bash
   rg-backup help
   sudo rg-backup status
   sudo rg-backup list
   ```

3. **Ujian hujung ke hujung bersama:**
   1. Pastikan sync selesai, kemudian `sudo rg-backup backup pre-attack`.
   2. Jalankan simulator dan detector. Detector memanggil `pin`.
   3. `sudo rg-backup status` mesti papar `BEKU`.
   4. `sudo rg-backup restore --user cikgu1` (staging + sahkan hash), kemudian `--apply` untuk tampal balik.
   5. Banding hash dengan `ujian_asal`, kemudian `sudo rg-backup unpin`.

## Peringatan

- **Jeda detector sebelum `restore --apply`.** Restore menulis banyak fail serentak, jadi detector boleh trigger.
- Jangan paip `rg-backup status` ke `head`. `restic` mati separuh jalan dan tinggalkan kunci basi. Penyelesaian ada dalam nota `Modul A - Arahan rg-backup`.
- Backup berjadual jalan setiap jam melalui systemd timer. Semasa beku (selepas `pin`), tiada backup baharu sehingga `rg-backup unpin`.
- Repo backup di `/srv/rg-backup` (SSD, bukan dalam folder Nextcloud dan tidak di-mount ke Docker). Kata laluan repo hanya di Pi dan **tidak** dalam repositori ini.

## Hasil ujian setakat ini

| Ukuran | Hasil |
|---|---|
| Backup penuh pertama | 69 saat (data 1.056 GiB, repo ~489 MB) |
| Backup tokokan | 13 saat |
| Restore cikgu1 (287 fail) + sahkan hash | ~14 saat ke staging, ~20 saat `--apply` |
| Simulasi kerosakan 3 fail | 3/3 dikesan, 3/3 dipulihkan, 287/287 hash sepadan |
