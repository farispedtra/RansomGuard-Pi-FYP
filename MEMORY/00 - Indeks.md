# 00 - Indeks RansomGuard Pi (FYP1)

Titik mula untuk vault ini. Kemas kini: 10 Nov 2026

Gambaran projek: lihat `README.md` di akar repo (D:\FYP 1).

## Projek
- [[FYP1 - Ringkasan Projek dan Garis Masa]]: tajuk, penyelia, garis masa, keperluan handbook, perkara perlu dibetulkan
- [[FYP1 - Cadangan Penambahbaikan]]: 18 penambahbaikan dan soal jawab penyelia
- [[FYP1 - Draf Methodology dan Gantt]]: DSR, objektif, rancangan penilaian, model ancaman, Gantt (draf)

## Modul A: Backup dan Recovery (Faris)
- [[Modul A - Backup dan Recovery]]: status, rekabentuk, hasil ujian, baki kerja
- [[Modul A - Arahan rg-backup]]: arahan, setup, perangkap
- Kod: `rg-backup.sh` dan `README.md` (untuk Haziq) dalam folder Modul A

## Modul B: Detection dan Containment (Haziq)
- [[Modul B - Detection dan Containment]]: status, komponen, isyarat pengesanan
- [[Modul B - Arahan Command]]: arahan untuk jalankan prototype
- [[Modul B - Masalah dan Penyelesaian]]: masalah teknikal dan kesilapan biasa

## Lampiran
- Folder `Lampiran`: Status Projek dan Cadangan Penambahbaikan (DOCX)

## Sambungan antara modul
Selepas alert Modul B, detector panggil `rg-backup pin --before <masa>` (Modul A) untuk bekukan snapshot bersih. Hook `--snapshot-cmd` sudah ada dalam detector (diuji dengan pin palsu); belum diuji dengan `rg-backup` sebenar di Pi. Lihat baki kerja dalam kedua-dua nota modul.
