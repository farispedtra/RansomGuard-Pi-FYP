# Modul B - Masalah dan Penyelesaian

Arahan: [[Modul B - Arahan Command]] | Ringkasan: [[Modul B - Detection dan Containment]]

## Masalah teknikal semasa pembangunan

| Masalah | Punca | Penyelesaian |
|---|---|---|
| Detector terlepas muat naik Nextcloud | Nextcloud tulis ke `<hash>.ocTransferId<N>.part` kemudian rename atas fail sasaran | Anggap `.part` yang di-rename atas fail sedia ada sebagai ubahsuai; senario ujian ditambah |
| Detector terlepas serangan melalui klien sync | Klien sync tukar rename tempatan kepada DELETE fail lama + PUT fail `.locked` | Padankan pasangan delete dan fail baharu (`_note_added`, `_note_removed`, `_pair`); disahkan pada Nextcloud sebenar |
| `admin_audit` tidak merekod muat naik | App itu tidak log muat naik fail | Dashboard baca log akses Apache (`docker compose logs app`) |
| Mesej Telegram berganda dan dakwaan "akses dihadkan" palsu semasa dry-run | Detector dan responder masing-masing hantar; ayat tak bersyarat | Detector tidak hantar sendiri bila ada responder; ayat sekatan hanya bila IP benar-benar disekat |
| Kenalan `Megat` berbeza daripada `megat` | Padanan sensitif huruf | Padanan tidak sensitif huruf dalam `respond.py` |
| Aplikasi Nextcloud dipasang, kemudian `ERR_EMPTY_RESPONSE` | Container dicipta semula; app dalam keadaan Disabled | Aktifkan semula app atau biarkan dilumpuhkan |

## Kesilapan biasa semasa setup

| Gejala | Sebab | Betulkan |
|---|---|---|
| `permission denied` pada docker.sock | Pengguna bukan dalam kumpulan docker | Guna `sudo` |
| Fail tidak jumpa semasa `docker compose`, `scp` atau `run_test.py` | Berada dalam folder salah | `cd` ke folder yang betul dahulu |
| Folder `unzip` bersarang | Zip dibuka dalam folder yang sama nama | Pindah isi ke atas satu tahap |
| Gagal padam folder ujian | Fail dimiliki root | `sudo rm -rf` |
| Port 5000 sudah digunakan | Dashboard lama masih jalan | Hentikan proses lama atau tukar port |
| Simulator enggan jalan | Tiada fail penanda `.ransomguard_testbed` | Cipta **fail** penanda (bukan folder) dalam folder ujian |
| Fail penanda terpadam di PowerShell | `-Exclude` membuang penanda | Guna `Where-Object` |
| Arahan gagal kerana `<placeholder>` | Placeholder ditaip literal | Ganti dengan nilai sebenar |
| Telegram 404 | Token palsu atau salah | Guna token sebenar daripada BotFather |
| Token terpapar dalam chat | Tersalah tampal | `/revoke` di @BotFather dan jana semula |
| Restore semasa detector berjalan | Tulisan restore dikesan sebagai serangan, alert dan pin berulang | Hentikan detector sebelum `restore --apply` |
| `.locked` muncul semula selepas restore | Klien sync laptop memuat naik salinan tempatan | Jeda sync, padam `.locked` di klien dahulu, kemudian di server |
| `.locked` kekal selepas dipadam | Salinan dalam `files_trashbin` | `occ trashbin:cleanup <pengguna>` |
| Peraturan DROP masih ada | Detector dihentikan sebelum pemasa unblock tamat | `iptables -D DOCKER-USER -s <IP>/32 -j DROP` |
| `<ID>` atau nama tempat letak dalam arahan | Tempat letak ditaip literal | Ganti dengan nilai sebenar |
| Token Telegram tidak ditetapkan | Token ditampal di hujung baris `read`, bukan di prompt | `read -rsp "Token: " VAR`, Enter, kemudian tampal token di prompt |

## Pengajaran reka bentuk

- Sekatan IP bersifat **sementara**: klien sync menyambung semula, dikesan dan disekat semula. Penyelesaian jangka panjang: lumpuhkan akaun dan batal sesi.
- Dua akaun pada satu laptop berkongsi IP yang sama, jadi sekatan menjejaskan kedua-duanya.
- Trash dan versi Nextcloud beri pemulihan separa sahaja, justifikasi Modul A.
- Siapa menghantar fail hanya dipadankan melalui masa dengan log akses (andaian, bukan bukti muktamad).
