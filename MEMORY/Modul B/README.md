# Modul B: Detection dan Containment (Haziq)

Status (10 Nov 2026): **berfungsi di Pi dan disahkan pada Nextcloud sebenar**. Sambungan ke Modul A (`rg-backup pin`) belum dipasang pada detector.

Kod ada dalam folder `ransomguard_prototype` (di Pi: `~/ransomguard`). Nota penuh ada dalam folder ini juga, mulakan dengan `Modul B - Arahan Command.md`.

## Apa Modul B buat

Pantau folder data Nextcloud, kesan corak ransomware, cari pengguna dan IP yang menyebabkannya, sekat IP, dan hantar amaran kepada admin dan pengguna terjejas melalui Telegram. Dashboard admin papar alert, suspek, tindakan dan jadual aktiviti.

## Komponen

| Fail | Fungsi |
|---|---|
| `detector.py` | Pantau folder (watchdog), kira skor dalam tetingkap 10 saat (ambang 12), fail umpan (canary) disentuh terus alert |
| `respond.py` | Cari suspek, sekat IP guna iptables (`DOCKER-USER`), auto-buka semula, hantar Telegram atau e-mel. CLI: `--list`, `--block`, `--unblock` |
| `dashboard.py` | Dashboard admin (port 5000, perlu token akses) |
| `simulator.py` | Simulator serangan yang selamat: hanya jalan jika folder ada fail `.ransomguard_testbed` |
| `workload.py`, `run_test.py` | Beban kerja normal dan 13 senario ujian |

Isyarat pengesanan: fail umpan, entropi Shannon, kadar perubahan fail, pertukaran extension (contoh `.locked`), dan magic number yang tak sepadan dengan jenis fail.

## Cuba cepat (di terminal Pi)

```bash
cd ~/ransomguard
python3 run_test.py          # 13 senario: 8 serangan, 5 normal, hasil dalam results.json
```

Demo dua terminal:

```bash
python3 make_demo.py ~/rg_demo
# Terminal 1
python3 detector.py --watch ~/rg_demo
# Terminal 2
python3 simulator.py --target ~/rg_demo --mode full --delay 0.3
```

Pada Nextcloud sebenar, mula dengan dry-run (rekod dan beritahu sahaja, tiada sekatan):

```bash
sudo sysctl fs.inotify.max_user_watches=524288
sudo -E python3 detector.py --watch ~/nextcloud/data/<pengguna>/files --respond --contacts contacts.json
```

Tambah `--contain --unblock-after 120` untuk sekatan IP sebenar. Senarai arahan lengkap ada dalam `Modul B - Arahan Command.md`.

## Sambung ke Modul A

Selepas alert, panggil arahan ini dengan masa serangan bermula supaya snapshot bersih dibekukan:

```bash
/usr/local/sbin/rg-backup pin --before "<masa_serangan_ISO8601>"
```

Detector sudah jalan sebagai root, jadi tak perlu `sudo`. Lihat `Modul A/README.md`.

## Peringatan

- Sekatan IP bersifat **sementara**: klien sync sambung semula, dikesan dan disekat semula. Dua akaun pada satu laptop berkongsi IP yang sama, jadi kedua-duanya terjejas.
- Jeda detector semasa `rg-backup restore --apply` (Modul A), sebab restore menulis banyak fail serentak dan boleh mencetus alert.
- Guna `sudo -E` supaya pembolehubah Telegram dan SMTP kekal. Token Telegram, token dashboard dan kata laluan **tidak** disimpan dalam repo ini. Kalau token pernah terdedah, `/revoke` di @BotFather dan jana semula.
- Nextcloud tulis muat naik sebagai fail `.part` kemudian rename, dan klien sync tukar rename tempatan kepada DELETE dan PUT. Detector dah dilaraskan untuk dua kes ini. Masalah lain ada dalam `Modul B - Masalah dan Penyelesaian.md`.

## Baki kerja

- Sambung `--snapshot-cmd` ke `rg-backup pin` dan ujian hujung ke hujung dengan simulator
- Ukur CPU dan RAM Pi, ujian false positive lebih besar (fail video, muat naik pukal)
- Sekat akaun dan batal sesi (bukan IP sahaja), servis systemd untuk detector dan dashboard
- Uji alert e-mel (SMTP belum diuji) dan tulis bab Modul B untuk laporan
