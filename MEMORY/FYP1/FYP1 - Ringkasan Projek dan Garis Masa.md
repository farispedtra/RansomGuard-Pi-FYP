# FYP1 - Ringkasan Projek dan Garis Masa

Kemas kini: 10 Nov 2026
Modul: [[Modul A - Backup dan Recovery]] | [[Modul B - Detection dan Containment]]
Lain-lain: [[Modul B - Arahan Command]] | [[Modul B - Masalah dan Penyelesaian]] | [[FYP1 - Cadangan Penambahbaikan]]

## Projek

**RansomGuard Pi: A Raspberry Pi-Based Backup and Ransomware Early-Detection System for a Learning Center Cloud Server (Nextcloud)**

- Pasangan: Haziq (Modul B, detection dan containment) dan Tuan Muhammad Faris (Modul A, backup dan recovery)
- Penyelia: Dr. Farahwahida
- Program: BIT (Hons) Computer System Security, UniKL MIIT, IPB49804 Final Year Project 1

## Status (10 Nov 2026)

- Pertemuan penyelia 5 Nov: proposal okey tetapi ada perubahan. **Perubahan tepat belum dicatat di sini** (tambah bila diketahui).
- Penyelia mahu lihat prototype.
- Modul B: prototype berfungsi (lihat nota Modul B).
- Modul A (Faris): berfungsi di Pi, repo `farispedtra/RansomGuard-Pi-FYP` (private, Haziq collaborator). Antara muka `rg-backup pin --before MASA` sedia. Belum disambung dengan detector.
- Status Projek 7 Nov (dokumen lama) menyatakan Modul A belum bermula; sudah lapuk, rujuk nota Modul A.

## Garis masa FYP1 (Oktober 2026)

| Minggu | Tarikh | Tindakan |
|---|---|---|
| 4 hingga 5 | 2 hingga 15 Nov | Kemas kini topik dengan penyelaras, Gantt chart, bersedia defence |
| 6 hingga 7 | 16 hingga 30 Nov | Proposal defence (16 Nov dialih ke 17 Nov, Cybersecurity Day) |
| 8 | 7 hingga 13 Dis | Bab 1 dan Bab 2 |
| 9 | 14 hingga 20 Dis | Hantar Bab 1 dan 2, mula Bab 3, prototype bermula |
| 10 hingga 11 | 21 Dis hingga 3 Jan | Hantar Bab 3, prototype minimum 30% |
| 12 | 4 hingga 10 Jan | Slaid dan mock presentation |
| 13 | 11 hingga 17 Jan | Pembentangan akhir (35%) |
| 14 | 18 hingga 22 Jan | Laporan FYP1 (35%) |

Markah: progress 30% (minimum 5 pertemuan penyelia, 10% kehadiran taklimat), pembentangan 35%, laporan Bab 1 hingga 3 35%.

## Keperluan handbook baharu (Bachelor of Cybersecurity, Sep 2026)

- Nama **research methodology** (cadangan: Design Science Research) dan **development model** (Prototyping atau Iterative). Elak Scrum.
- Baseline, metrik (detection rate, false positive rate, masa pengesanan, fail terjejas, CPU/RAM Pi) dan kriteria berjaya.
- Gantt: baris ikut fasa methodology, bukan bab.
- Literature review 30 hingga 40 sumber, kebanyakan 5 tahun terkini. Proposal ada 5 buat masa ini.
- Deklarasi etika (ujian di lab sendiri, simulator selamat).
- Objektif biasanya 3, boleh diukur dan dikaitkan dengan Bab 3, 5 dan 6.
- Borang proposal dalam project Claude masih template kosong, pastikan versi yang dihantar sudah diisi.

## Kertas penyelidikan (RansomGuard)

| Kertas | Hasil utama | Kaitan |
|---|---|---|
| Aryan dan Shetty, Nextcloud + TrueNAS + QEMU/KVM | Storan awan selamat dan murah, tiada pengesanan ransomware | Asas senibina dan jurang |
| Deceive, Detect, Defend (JCSSE 2025) | 98.4% berbanding 92.5% RTrap, decoy file | Idea canary |
| Integrity-Gated File Monitoring (Amoruso, 2026) | 100% full, kira-kira 90% partial encryption, magic number dan spot-entropy | Modul A dan B, rename atomik sebagai kerja masa depan |
| Policy-based framework (Huertas Celdran, NOMS 2022) | TPR 94.91% dan 89.80% pada Raspberry Pi | Pi sesuai sebagai platform |
| Ranker (IEEE TIFS 2024) | Precision 99.89%, recall 98.98%, FPR 0.11%, 97.16% pada keluarga tidak dilihat | Baseline ketepatan |

## Dokumen yang telah dibuat (dalam Claude)

- Ringkasan Prototype Modul B dan Laporan Setup serta Panduan Arahan (Claude Docs)
- Penerangan proposal EN dan BM (DOCX), skrip pembentangan
- Status Modul A vs B (DOCX) dan Cadangan Penambahbaikan (DOCX): salinan dalam folder `Lampiran/`
- Draf proposal dan slaid pembentangan (PDF) dan laporan setup: ada dalam Claude (project FYP 1)
- Nota: DOCX penerangan proposal EN dan BM masih senaraikan artikel lama (Kodali); perlu dikemas kini

## Perkara perlu dibetulkan dalam proposal

- Ayat IoT, "3 key articles" berbanding 5 baris jadual, angka Ranker "22" (22 keluarga tidak dilihat), angka Aryan dan Shetty 50% berbanding kira-kira 13%
- Penyelia tersenarai dengan tajuk computer vision: tanya sama ada bidang ini sesuai dibimbing

## Tugasan seterusnya

- [ ] Dapatkan senarai perubahan sebenar daripada Dr. Farahwahida
- [ ] Draf methodology dan Gantt ikut fasa
- [ ] Kemas kini proposal dan slaid untuk defence minggu 6 hingga 7
- [ ] Sambung Modul B ke `rg-backup pin` (Modul A sudah sedia), ujian hujung ke hujung dengan simulator
- [ ] Ukur CPU/RAM Pi dan ujian false positive lebih besar
