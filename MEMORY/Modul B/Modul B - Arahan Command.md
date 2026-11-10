# Modul B - Arahan Command

Ringkasan Modul B: [[Modul B - Detection dan Containment]] | Masalah biasa: [[Modul B - Masalah dan Penyelesaian]]

Ganti `<IP_Pi>`, `<pengguna_pi>`, `<TOKEN_DASHBOARD>` dengan nilai sebenar. **Jangan tulis token Telegram, token dashboard atau kata laluan dalam nota ini.**

## Nextcloud (Docker Compose di Pi)

```bash
cd ~/nextcloud
docker compose up -d            # hidupkan Nextcloud + MariaDB
docker compose ps               # semak status
docker compose logs -f app      # log akses Apache (IP, akaun, WebDAV)
docker compose down             # matikan
```

Compose guna `restart: unless-stopped`, jadi hidup semula sendiri selepas reboot. Alamat: `http://<IP_Pi>:8080` (pastikan `<IP_Pi>` ada dalam trusted_domains).

Cipta atau reset pengguna:

```bash
docker compose exec -u www-data app php occ user:resetpassword <nama_pengguna>
docker compose exec -u www-data app php occ files:scan --all
```

## Hantar fail ke Pi (daripada laptop)

```powershell
scp -r .\ransomguard <pengguna_pi>@<IP_Pi>:~/
ssh <pengguna_pi>@<IP_Pi>
```

## Pasang kebergantungan di Pi

```bash
python3 --version               # 3.9 atau lebih baru
pip install watchdog            # jika ralat: tambah --break-system-packages
```

## Ujian automatik

```bash
cd ~/ransomguard
python3 run_test.py             # 13 senario: 8 serangan, 5 normal; hasil dalam results.json
```

## Demo CLI (dua terminal)

```bash
python3 make_demo.py ~/rg_demo
# Terminal 1
python3 detector.py --watch ~/rg_demo
# Terminal 2
python3 simulator.py --target ~/rg_demo --mode full --delay 0.3
python3 simulator.py --target ~/rg_demo --mode partial --skip-canary
python3 workload.py --target ~/rg_demo --kind bulk     # normal | bulk | sync | video
```

Simulator hanya jalan jika folder sasaran ada fail `.ransomguard_testbed`.

## Pada Nextcloud sebenar

```bash
sudo sysctl fs.inotify.max_user_watches=524288
# dry-run: rekod dan beritahu sahaja, tiada sekatan sebenar
sudo -E python3 detector.py --watch ~/nextcloud/data/<pengguna>/files --respond --contacts contacts.json
# sekat IP sebenar (2 minit, kemudian dibuka semula)
sudo -E python3 detector.py --watch ~/nextcloud/data/<pengguna>/files --respond --contain --unblock-after 120 --contacts contacts.json
# letak canary dalam setiap sub-folder
sudo -E python3 detector.py --watch ~/nextcloud/data/<pengguna>/files --create-canaries
```

`-E` mengekalkan pembolehubah persekitaran (Telegram, SMTP) semasa `sudo`.

## Dashboard admin

```bash
cd ~/ransomguard
sudo python3 dashboard.py --events events.jsonl --docker-dir ~/nextcloud --token <TOKEN_DASHBOARD>
# buka: http://<IP_Pi>:5000/?token=<TOKEN_DASHBOARD>
```

Mesti guna `sudo` (arahan docker) dan jalan dari folder yang sama dengan detector. Jika port 5000 sudah digunakan, tambah `--port`.

## Sekat dan buka IP

```bash
sudo python3 respond.py --list
sudo python3 respond.py --block <IP_penyerang>
sudo python3 respond.py --unblock <IP_penyerang>
```

IP loopback, IP Pi sendiri dan `--allow-ip` tidak disekat. Hanya IP dengan sekurang-kurangnya 3 tindakan tulis sekitar alert yang disekat.

## Alert Telegram dan e-mel

```bash
export TELEGRAM_BOT_TOKEN="<token_dari_BotFather>"   # taip di terminal sahaja
export TELEGRAM_CHAT_ID="<chat_id_admin>"
# e-mel (belum diuji)
export RG_SMTP_HOST=smtp.gmail.com RG_SMTP_PORT=587
export RG_SMTP_USER=... RG_SMTP_PASS=... RG_SMTP_FROM=...   # kata laluan aplikasi
```

Setiap pengguna tekan *Start* pada bot dahulu, kemudian `chat_id` dimasukkan dalam `contacts.json` (rujuk `contacts.example.json`). Jika token pernah terdedah, `/revoke` di @BotFather dan jana semula.

## Sambungan ke Modul A

Detector panggil arahan pin Modul A sendiri bila alert tercetus (lihat [[Modul A - Arahan rg-backup]]). Tambah `--snapshot-cmd`:

```bash
sudo -E python3 detector.py --watch ~/nextcloud/data/<pengguna>/files --respond --contain --unblock-after 120 \
    --contacts contacts.json --snapshot-cmd '/usr/local/sbin/rg-backup pin --before "{time}"'
```

- `{time}` = masa isyarat serangan pertama tolak `--pin-margin` (lalai 5 saat), ISO 8601 dengan zon waktu. `{epoch}` = saat.
- Hasil direkod dalam `events.jsonl` (`snapshot_pin`). Kod keluar 1 = tiada snapshot sebelum masa itu (backup kekal beku). Jika pin gagal, admin dapat Telegram.
- Pin jalan dalam thread berasingan dan tak menghalang sekatan IP atau notifikasi.
- Selepas pulih: `sudo rg-backup unpin`.
- Ujian unit: `python3 test_snapshot_hook.py` (7 ujian, skrip pin palsu). **Belum diuji dengan `rg-backup` sebenar di Pi.**
