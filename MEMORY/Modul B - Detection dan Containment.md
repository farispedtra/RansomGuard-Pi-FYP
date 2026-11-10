# Modul B - Detection dan Containment

Pemilik: Haziq | Rakan kongsi: Faris (Modul A) | Kemas kini: 10 Nov 2026
Modul A: [[Modul A - Backup dan Recovery]] | Ringkasan projek: [[FYP1 - Ringkasan Projek dan Garis Masa]]
Arahan: [[Modul B - Arahan Command]] | Masalah: [[Modul B - Masalah dan Penyelesaian]] | Penambahbaikan: [[FYP1 - Cadangan Penambahbaikan]]

## Status ringkas

Prototype Modul B **berfungsi di Pi dan disahkan pada Nextcloud sebenar**: pengesanan, pengenalpastian suspek (pengguna dan IP), block IP sebenar, alert Telegram kepada admin dan pengguna, auto-unblock selepas 120 saat (nilai ujian; lalai kod ialah 600 saat melalui `--unblock-after`). Ujian automatik: 13 senario (8 serangan, 5 normal).

## Komponen (kod dalam `ransomguard_prototype`)

| Fail | Fungsi |
|---|---|
| `detector.py` | Pantau folder data Nextcloud (watchdog), kira skor dalam tetingkap 10 saat, ambang 12, canary = alert serta-merta, grace 5 saat untuk fail baharu |
| `respond.py` | Cari suspek, block IP guna iptables (`DOCKER-USER`), auto-unblock, hantar Telegram atau e-mel kepada admin dan pengguna terjejas. CLI: `--list`, `--block`, `--unblock` |
| `dashboard.py` | Dashboard admin (stdlib HTTP, port 5000, token akses): alert, suspek, tindakan respons, jadual aktiviti (siapa, IP, kaedah WebDAV, klien) |
| `simulator.py` | Simulator selamat: hanya jalan jika fail penanda `.ransomguard_testbed` wujud. Mod: full, partial, slow |
| `workload.py`, `run_test.py` | Beban kerja normal dan 13 senario ujian |

## Isyarat pengesanan

- Canary (fail umpan): sentuh sahaja terus alert
- Entropi Shannon (sampel kecil)
- Kadar perubahan fail dalam tetingkap masa
- Pertukaran extension (contoh `.locked`)
- Magic number tidak sepadan dengan jenis fail

## Penemuan teknikal Nextcloud

- Muat naik ditulis sebagai `<hash>.ocTransferId<N>.part` kemudian di-rename atas fail sasaran. Detector kini anggap `.part` yang di-rename atas fail sedia ada sebagai ubahsuai.
- Klien sync menukar rename tempatan kepada DELETE fail lama + PUT fail baharu (`.locked`). Detector memadankan pasangan delete dan fail baharu.
- App `admin_audit` tidak merekod muat naik. Dashboard guna log akses Apache (`docker compose logs app`) untuk IP, akaun, kaedah dan klien.
- Block IP bersifat **sementara**: klien sync sambung semula, dikesan dan diblock semula. Trash dan versi Nextcloud beri pemulihan separa, ini justifikasi Modul A.
- Dua akaun pada satu laptop berkongsi IP yang sama.

## Setup (ringkas)

- Raspberry Pi 4, microSD 64GB, Docker Compose: Nextcloud + MariaDB, `restart: unless-stopped`, trusted domains ditetapkan.
- Akaun ujian: admin, cikgu1, Lecture 1, Megat, Ungku Megat (pelajar).
- Pembolehubah env untuk alert: `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID` (nilai **tidak** disimpan dalam nota). `chat_id` setiap pengguna dalam `contacts.json`. Guna `sudo -E` supaya env dikekalkan.
- Nilai token dan kata laluan disimpan di Pi sahaja, bukan dalam vault.

## Had dan baki kerja

- [ ] Sambung `--snapshot-cmd` ke `rg-backup pin` (Modul A sudah sedia, lihat [[Modul A - Arahan rg-backup]]) dan ujian hujung ke hujung
- [ ] Ulang ujian kerosakan Modul A menggunakan simulator dan sync klien sebenar
- [ ] Jeda detector semasa restore Modul A
- [ ] Block IP kekal atau disable akaun dan revoke sesi
- [ ] Ukur CPU dan RAM Pi
- [ ] Ujian false positive lebih besar (fail video, muat naik pukal)
- [ ] Uji alert e-mel (SMTP `RG_SMTP_*` belum diuji)
- [ ] Servis systemd untuk detector dan dashboard
- [ ] Tulis bab Modul B untuk laporan
