# Modul B - Detection dan Containment

Pemilik: Haziq | Rakan kongsi: Faris (Modul A) | Kemas kini: 11 Nov 2026
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

- Raspberry Pi 4 (RAM 8GB), microSD 64GB untuk OS, SSD USB 128GB sebagai storan kedua. Pelan storan: Nextcloud atas microSD dengan dataset ujian kecil (beberapa ratus MB); SSD untuk data dan backup dengan dua partition (kira-kira 50GB untuk backup Nextcloud dan kira-kira 70GB untuk repo backup), Docker Compose: Nextcloud + MariaDB, `restart: unless-stopped`, trusted domains ditetapkan.
- Akaun ujian: admin, cikgu1, Lecture 1, Megat, Ungku Megat (pelajar).
- Pembolehubah env untuk alert: `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID` (nilai **tidak** disimpan dalam nota). `chat_id` setiap pengguna dalam `contacts.json`. Guna `sudo -E` supaya env dikekalkan.
- Nilai token dan kata laluan disimpan di Pi sahaja, bukan dalam vault.

## Hasil ujian hook ke Modul A di Pi (10 Nov 2026, 23:08)

Detector (dry-run) dengan `--snapshot-cmd` ke `rg-backup pin`; simulator mod full dari laptop pada folder sync cikgu1 (103 fail disimulasi).

| Ukuran | Hasil |
|---|---|
| Alert pertama | skor 12 (rate, entropy, extension), 8 fail, kira-kira 2 saat selepas isyarat pertama |
| Alert kedua | skor 24 (rate, extension), 10 fail |
| Pin | `rc 0`, snapshot `1ae35049` (backup 23:00:54) dilindungi, backup dibekukan; pin kedua pilih snapshot yang sama |
| Masa alert hingga pin | kira-kira 2 saat (log Modul A 23:08:05) |
| `unpin` | 23:10:14, backup berjadual disambung semula |

Perhatian:
- Suspek (akaun, IP) **tidak dikenal pasti** semasa ujian ini: dashboard melapor "tiada aktiviti dalam log akses Nextcloud". Sedang disiasat (log Apache kosong atau IP Pi bertukar kepada 192.168.100.164).
- Telegram tidak dihantar kerana pembolehubah persekitaran tidak ditetapkan dalam terminal detector.
- Simulator habis menyulitkan 103 fail kerana mod dry-run tidak menghentikannya. Fail cikgu1 kini `.locked` dan perlu dipulihkan daripada snapshot `1ae35049`.

## Hasil ujian hujung ke hujung dengan block IP sebenar (10-11 Nov 2026, 23:51 hingga 00:14)

Detector dengan `--respond --contain --unblock-after 120 --snapshot-cmd` pada folder cikgu1; simulator mod full dari laptop.

| Ukuran | Hasil |
|---|---|
| Alert | skor 12 (rate, entropy, extension) pada 23:51:09, 8 fail |
| Suspek | `cikgu1 @ 192.168.100.163` (25 tindakan), klien Windows Nextcloud, dikenal pasti daripada log audit |
| Block IP | `blocked: true` melalui `iptables` DOCKER-USER; laptop tidak dapat buka `192.168.100.146:8080` (timeout) |
| Pin | berjaya, snapshot bersih `1ae35049` (23:00:54) dibekukan, tiada snapshot auto selepas itu |
| Restore | `rg-backup restore --snapshot 1ae35049 --user cikgu1 --apply`: 287 fail, semua hash SHA-256 sepadan, kira-kira 40 saat |
| Telegram | tidak dihantar dalam larian ini (pembolehubah persekitaran tidak ditetapkan); sebelum ini disahkan berfungsi kepada admin dan cikgu1 |

Penemuan penting:
- Restore semasa detector berjalan mencetuskan alert palsu dan pin berulang: detector mesti dijeda atau ada mod penyelenggaraan.
- Selepas restore, klien sync laptop memuat naik semula fail `.locked` tempatan. Prosedur pemulihan: jeda sync, padam `.locked` di klien, restore, kemudian sambung sync.
- Fail `.locked` yang dipadam masuk ke tong sampah Nextcloud (`files_trashbin`); bersihkan dengan `occ trashbin:cleanup`, dan `occ files:scan` selepas padam di sistem fail.
- Peraturan DROP boleh tertinggal jika detector dihentikan (Ctrl+C) sebelum pemasa auto-unblock tamat. Padam dengan `iptables -D DOCKER-USER -s <IP>/32 -j DROP`. Penyelesaian: unblock yang tahan lama (pemasa sistem atau unblock semasa detector dimulakan semula).
- Sekatan DOCKER-USER hanya melindungi port Nextcloud (8080); dashboard (5000) kekal boleh dicapai dan perlu token kukuh.
- Pin kedua pada 23:55 (alert susulan) memilih snapshot yang sama dan tidak merosakkan backup.

## Had dan baki kerja

- [x] Hook `--snapshot-cmd` siap dalam detector (10 Nov), 7 ujian unit lulus, 13 senario `run_test.py` masih lulus
- [x] Uji hook dengan `rg-backup pin` sebenar di Pi dan ujian hujung ke hujung (simulator, alert, block IP, pin, restore, banding hash) lulus pada 10-11 Nov; lihat [[Modul A - Arahan rg-backup]]
- [ ] Larian akhir dengan Telegram, block IP dan auto-unblock tanpa Ctrl+C pada detector
- [ ] Ulang ujian kerosakan Modul A menggunakan simulator dan sync klien sebenar
- [ ] Jeda detector semasa restore Modul A (disahkan perlu; lihat penemuan di atas)
- Keputusan 10 Nov (selepas bincang dengan Faris): **tangguh partition semula SSD** sehingga ujian hujung ke hujung siap; partition semula memadam repo dan menukar laluan data serentak di `docker-compose.yml`, `RG_NC_DIR` dan detector. Selepas itu partition (cadangan 55GB data dan 55GB repo, beri ruang kosong), ukur sebelum dan selepas untuk Bab 5. Jika dibuat dahulu: simpan salinan `metrics.csv`, maklum Faris, tambah `nofail` dalam fstab
- [ ] Block IP kekal atau disable akaun dan revoke sesi
- [ ] Ukur CPU dan RAM Pi
- [ ] Ujian false positive lebih besar (fail video, muat naik pukal)
- [ ] Uji alert e-mel (SMTP `RG_SMTP_*` belum diuji)
- [ ] Servis systemd untuk detector dan dashboard
- [ ] Tulis bab Modul B untuk laporan
