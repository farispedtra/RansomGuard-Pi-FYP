# Modul A - Arahan rg-backup

Ringkasan dan status: [[Modul A - Backup dan Recovery]]

Skrip: `D:\FYP 1\Module A\rg-backup.sh` (di Pi: `/usr/local/sbin/rg-backup`). Semua arahan dijalankan di **terminal Pi** dengan `sudo`.

## Antara muka untuk Modul B (Haziq)

Detector panggil ini bila serangan dikesan (detector sudah jalan sebagai root, jadi tak perlu `sudo`):

```
/usr/local/sbin/rg-backup pin --before "<masa_serangan_ISO8601>"
```

- Contoh masa: `2026-11-12T19:29:27+08:00` (juga boleh epoch saat).
- Ia **membekukan backup dan rotation** serta mencetak ID snapshot bersih terakhir sebelum masa itu.
- Jika tiada snapshot sebelum masa itu, exit code 1 dan backup kekal beku.
- Selepas admin selesai: `rg-backup unpin`.
- Tanpa `--before`, ia pilih snapshot terkini.

## Senarai arahan

| Arahan | Fungsi |
|---|---|
| `rg-backup init` | sediakan repo restic (sekali sahaja) |
| `rg-backup backup [tag]` | snapshot baharu (fail + DB + manifest) |
| `rg-backup list` | senarai snapshot |
| `rg-backup status` | status aktif/BEKU, snapshot, metrik terkini |
| `rg-backup verify [--full]` | semak integriti repo (lalai 10% data) |
| `rg-backup pin [--before MASA]` | lindungi snapshot bersih + bekukan backup |
| `rg-backup unpin` | sambung semula backup berjadual |
| `rg-backup restore ...` | pulihkan (lihat bawah) |
| `rg-backup install-timer` | pasang systemd timer (setiap jam) |

## Restore

```bash
# staging sahaja (selamat, tak ubah Nextcloud) + sahkan SHA-256
sudo rg-backup restore --user cikgu1

# tampal ke Nextcloud untuk satu pengguna
sudo rg-backup restore --user cikgu1 --apply

# snapshot tertentu (lalai: snapshot yang dipin jika ada, jika tidak yang terkini)
sudo rg-backup restore --snapshot <ID> --user cikgu1 --apply
```

`--apply` tanpa `--user` memulihkan semua fail dan DB (belum diuji lagi). **Jeda detector** sebelum `--apply`.

## Pasang pada Pi baharu

1. Hantar skrip dari laptop (PowerShell):
   `scp "D:\FYP 1\Module A\rg-backup.sh" hafa@192.168.100.146:~`
2. Di Pi:
   ```bash
   sudo apt install -y restic rsync
   sudo install -m 750 ~/rg-backup.sh /usr/local/sbin/rg-backup
   sudo rg-backup init
   sudo rg-backup backup manual
   sudo rg-backup install-timer
   ```
3. Folder Nextcloud lalai `/home/hafa/nextcloud`. Kalau lain, tetapkan `RG_NC_DIR`.

## Fail penting di Pi

| Fail | Kegunaan |
|---|---|
| `/srv/rg-backup/repo` | repo restic |
| `/srv/rg-backup/state/rg-backup.log` | log |
| `/srv/rg-backup/state/metrics.csv` | masa backup dan saiz repo (untuk penilaian) |
| `/srv/rg-backup/state/PINNED` | wujud bila beku |
| `/root/.rg-restic-pass` | kata laluan repo (Faris simpan salinan; **jangan** letak dalam nota atau chat) |

## Setup SSD (dibuat 10 Nov 2026)

SSD Transcend ESD310 128GB (`sda`) diformat ext4 (label `RGBACKUP`) dan di-mount tetap ke `/srv/rg-backup` melalui `/etc/fstab` (`noatime,nofail`). Repo lama disalin dengan rsync; salinan asal kekal di `/srv/rg-backup.old` sehingga disahkan. SSD ini untuk backup sahaja; data Nextcloud kekal atas microSD.

## Perangkap yang pernah berlaku

- `scp` dijalankan dari **PowerShell laptop**, bukan terminal Pi.
- Jangan guna `restic tag` untuk pin: ia tukar ID snapshot dan fail PINNED jadi lapuk.
- Jangan paip `rg-backup status` ke `head`: `restic` mati separuh jalan dan tinggalkan kunci basi. Gejala: `verify` atau `backup` lapor "repository is already locked"; snapshot jam masih wujud tetapi `metrics.csv` berhenti dan rotation tak jalan. Penyelesaian: `pgrep -a restic` (mesti kosong), kemudian `sudo restic -r /srv/rg-backup/repo --password-file /root/.rg-restic-pass unlock --remove-all`.
- Selepas `scp`, semak versi di Pi: `sudo grep -c "clean-pinned" /usr/local/sbin/rg-backup` mesti `0`.
