# 00 - Indeks RansomGuard Pi (FYP1)

Titik mula untuk vault ini. Kemas kini: 10 Nov 2026

## Projek
- [[FYP1 - Ringkasan Projek dan Garis Masa]]: tajuk, penyelia, garis masa, keperluan handbook, perkara perlu dibetulkan
- [[FYP1 - Cadangan Penambahbaikan]]: 18 penambahbaikan dan soal jawab penyelia

## Modul A: Backup dan Recovery (Faris)
- [[Modul A - Backup dan Recovery]]: status, rekabentuk, hasil ujian, baki kerja
- [[Modul A - Arahan rg-backup]]: arahan, setup, perangkap
- Kod: folder `Module A` (rg-backup.sh dan README untuk Haziq)

## Modul B: Detection dan Containment (Haziq)
- [[Modul B - Detection dan Containment]]: status, komponen, isyarat pengesanan
- [[Modul B - Arahan Command]]: arahan untuk jalankan prototype
- [[Modul B - Masalah dan Penyelesaian]]: masalah teknikal dan kesilapan biasa

## Lampiran
- Folder `Lampiran`: Status Projek dan Cadangan Penambahbaikan (DOCX)

## Sambungan antara modul
Selepas alert Modul B, detector panggil `rg-backup pin --before <masa>` (Modul A) untuk bekukan snapshot bersih. Belum disambung. Lihat baki kerja dalam kedua-dua nota modul.
