# FYP1 - Cadangan Penambahbaikan dan Soal Jawab Penyelia

Ringkasan projek: [[FYP1 - Ringkasan Projek dan Garis Masa]] | Dokumen penuh: `Lampiran/Cadangan_Penambahbaikan_RansomGuard_Pi.docx`

## Jawapan ringkas (30 saat)

Prototype sudah mengesan serangan melalui klien sync Nextcloud, menyekat IP penyerang, dan menghantar Telegram kepada admin dan pengguna dengan dashboard admin. Penambahbaikan seterusnya: hak akses mengikut peranan, pembendungan lebih tepat (lumpuhkan akaun, batal sesi), pemulihan fail, melindungi pengesan itu sendiri, dan pengerasan Pi dan Nextcloud.

## Senarai penambahbaikan

| # | Penambahbaikan | Usaha | Keutamaan |
|---|---|---|---|
| 1 | Hak akses mengikut peranan (pelajar baca sahaja pada bahan guru) | Rendah | Tinggi |
| 2 | 2FA untuk admin dan guru | Rendah | Tinggi |
| 3 | Brute force protection dan fail2ban | Rendah | Sederhana |
| 4 | HTTPS (reverse proxy) dan akses LAN atau VPN | Sederhana | Tinggi |
| 5 | Firewall default-deny (ufw) | Rendah | Tinggi |
| 6 | SSH kunci sahaja | Rendah | Tinggi |
| 7 | Kemas kini automatik dan audit (Lynis) | Rendah | Sederhana |
| 8 | Rahsia dalam fail persekitaran `chmod 600`, putar token | Rendah | Tinggi |
| 9 | Lumpuhkan akaun dan batal sesi (`occ user:disable`) | Sederhana | Tinggi |
| 10 | Tetingkap pengesanan panjang (serangan perlahan) | Sederhana | Sederhana |
| 11 | Semakan magic number dan struktur fail | Sederhana | Sederhana |
| 12 | Garis dasar mengikut pengguna | Sederhana | Rendah |
| 13 | Pengesanan anomali akaun (log masuk IP baharu, padam pukal) | Sederhana | Sederhana |
| 14 | Skrip pulihkan fail daripada trash dan versi Nextcloud | Sederhana | Tinggi |
| 15 | Sambungan ke Modul A (`--snapshot-cmd`) | Rendah | Tinggi |
| 16 | Servis systemd dan heartbeat Telegram | Rendah | Tinggi |
| 17 | Log tidak boleh diubah (rantai hash atau HMAC, salinan luar Pi) | Sederhana | Sederhana |
| 18 | Dashboard lebih selamat (log masuk peranan, log audit, eksport) | Sederhana | Sederhana |

## Pelan fasa

- **Sebelum demo:** 1, 5, 6, 8, 16
- **Selepas demo, FYP1:** 9, 14, ukuran CPU/RAM, ujian positif palsu lebih besar
- **FYP2:** 15, 10, 11, 13, 2, 4, 17

## Ancaman terhadap sistem sendiri

| Ancaman | Pertahanan |
|---|---|
| Mengelak pengesan (perlahan, separa, padam canary dahulu) | Tetingkap panjang, magic number, amaran jika canary hilang |
| Menyalahgunakan tindak balas (penggera palsu supaya IP sah disekat) | Senarai putih admin, had kadar sekatan, lumpuhkan akaun berbanding sekat IP |
| Mematikan pengesan | systemd, heartbeat, log selamat, pengguna khas |
| Membanjiri sistem dengan fail kecil | Had kadar pemprosesan, ukuran CPU/RAM |
| Kebocoran rahsia | Fail persekitaran 600, putar token, dashboard dengan log masuk |

## Jika penyelia bertanya

- **Kelemahan sekarang?** Sekatan IP sementara dan menyekat semua akaun pada satu peranti; sampel positif palsu kecil; detector dimulakan manual. Ada pelan penambahbaikan.
- **Kenapa bukan sekat akaun?** Akaun ialah identiti yang diserang; lumpuhkan akaun akan ditambah, sekatan IP jadi lapisan kedua.
- **Jika detector dimatikan?** systemd, heartbeat Telegram dan log bertandatangan; detector senyap dilaporkan sebagai amaran.
- **Kurangkan amaran palsu?** Ambang dipilih daripada ujian beban biasa; seterusnya semakan jenis fail dan garis dasar per pengguna.
- **Jika laptop pelajar dijangkiti?** Hak akses peranan, detector sekat dan beritahu, pulihkan daripada trash, versi atau snapshot Modul A.
- **Modul A disambung bagaimana?** Selepas alert, Modul B panggil `rg-backup pin --before <masa>` untuk bekukan snapshot bersih. Lihat [[Modul A - Arahan rg-backup]].
