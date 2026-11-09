# Verifikasi fungsi GUI 2.2.0 (unreleased)

Pengujian memakai sesi unik di `.tools/verification/<Scenario>-<GUID>/`. Runtime disalin dengan allowlist; log, transaksi, backup dan konfigurasi pribadi tidak disalin. Target, konfigurasi efektif, laporan dan jurnal pemulihan seluruhnya berada di sesi. Jangan mengganti target dengan Downloads pribadi.

Assertion filesystem dan konfirmasi visual adalah dua bukti terpisah. `lulus` memerlukan keduanya; default hasil visual adalah **belum diuji**. Test Pester yang menekan tombol secara otomatis tidak menggantikan pengamatan manusia. Status terbaru, konfirmasi pengguna dan temuan dicatat di [RELEASE.md](RELEASE.md); setiap sesi mempertahankan status serta evidence sendiri.

## Menjalankan

Dari root proyek, gunakan terminal Windows interaktif:

```powershell
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File tests/Invoke-Verification.ps1
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File tests/Invoke-GUIVerification.ps1 -Scenario Mixed
```

Runner pertama mencatat hash sumber lokal (termasuk perubahan belum dikomit), HEAD, OS, versi engine, STA, Pester 5.7.1, discovery/jumlah test, coverage PS5.1, parsing, manifest, build baru dan smoke portable pada kedua engine. Evidence berada di sesi `Automated-*`; ringkasan JSON tidak memerlukan akses CIM/WMI. Kedua engine dijalankan berurutan. Tidak ada commit/push atau klaim CI remote.

Runner GUI mencetak path target dan instruksi. Lakukan tindakan pada baris skenario, tunggu hasil selesai, lalu tutup jendela. Assertion dijalankan setelah GUI ditutup. Siapkan tanpa membuka GUI, atau lanjutkan sesi yang sama:

```powershell
$session = & ./tests/Invoke-GUIVerification.ps1 -Scenario UndoRetry -PrepareOnly
& ./tests/Invoke-GUIVerification.ps1 -SessionPath $session
# Hanya setelah hasil visual dikonfirmasi oleh penguji:
& ./tests/Invoke-GUIVerification.ps1 -SessionPath $session -VerifyOnly -VisualStatus lulus -Notes 'Nama penguji dan pengamatan'
```

`-VerifyOnly` tidak membuka jendela atau menjalankan organize pada target utama. DryRun menjalankan fixture pembanding terpisah; Scale menjalankan organize kedua pada target untuk memeriksa stabilitas nama. Jalankan tiap sesi dalam proses PowerShell baru agar modul dari salinan runtime tidak bercampur dengan modul proyek. `DOP_VERIFY_TARGET` adalah environment variable khusus proses tersebut; dapat dimasukkan sebagai `%DOP_VERIFY_TARGET%` pada kolom target.

## Checklist bersama

Untuk semua skenario: periksa versi `v2.2.0`, checkbox mengikuti konfigurasi, Tab/Shift+Tab, Space/Enter, resize dan keterjangkauan tombol. Catat tampilan KPI, tabel, console, laporan CSV/JSON/HTML dan STATS REPORT. Saat worker aktif, Start/Undo/Watcher/Schedule/Browse, path dan checkbox harus dinonaktifkan; setelah selesai atau error harus dapat digunakan kembali. Jangan menambah operasi selain langkah skenario, agar statistik dan transaksi tidak bercampur.

| Skenario | Tindakan penguji | Hasil wajib / assertion |
|---|---|---|
| Empty | START, STATS, tutup | 0 hasil, tanpa file kategori atau transaksi. |
| Single | Browse ke target sesi yang dicetak, START, STATS | `a.pdf` ke `Documents`, isi identik. Ulangi pada sesi baru dengan path `%DOP_VERIFY_TARGET%`. |
| Mixed | START, STATS, buka laporan | 7 hasil; PDF CV/Finance, Images, Applications, Others; spasi, Unicode dan `[1]` aman; satu duplikat ditandai, kedua salinan tetap ada. |
| SmartOff | START | Smart Rules tidak dicentang; PDF tetap di Documents tanpa subkategori. |
| UnknownOff | START | Unknown tetap di root dan dilaporkan Skipped. |
| DryRun | START | Semua 7 Planned; path/isi tetap, tanpa folder kategori, transaksi atau backup. Tujuan dibandingkan dengan eksekusi nyata pada salinan fixture. |
| Rename | START | `Documents/a.pdf` lama utuh, sumber menjadi `a (1).pdf`. |
| Skip | START | Sumber konflik dan tujuan lama tetap, `b.pdf` dipindah. |
| Overwrite | START | Tujuan berisi sumber baru; isi lama ada di backup transaksi. |
| Undo | Langsung UNDO LAST MOVE | Fixture sudah diorganisasi dengan Overwrite; sumber dan tujuan lama kembali sesuai SHA256 awal. |
| UndoConflict | Langsung UNDO LAST MOVE | Fixture sudah partial Undo; konflik `a.pdf` dilaporkan, sumber konflik, tujuan baru dan backup lama utuh. |
| UndoRetry | Langsung UNDO LAST MOVE | Fixture partial Undo sudah disiapkan dan sumber konflik disimpan di evidence; hanya satu entri tersisa dipulihkan. Entri yang sudah Undone tidak dikerjakan lagi. |
| Watcher | Browse ke target yang dicetak (berbeda dari default decoy), START WATCHER. Pada terminal lain jalankan `Feed-Watcher.ps1` di sesi dengan Created, Renamed lalu Burst. Tunggu masing-masing selesai, STOP, START, STOP, tutup | Created PDF, rename `.crdownload` ke `.exe`, 20 file burst masuk kategori yang benar. `ignored.tmp` tetap; decoy utuh. Tidak ada subscription tertinggal. Perhatikan file `.crdownload` selama jeda 3 detik tetap di root. |
| Scheduler | SCHEDULE; tunggu console Registered dan `Documents/a.pdf` muncul, baru tekan SCHEDULE lagi, tutup | Harness mengamati task GUID, memeriksa interval 17 menit dan argumen sandbox, lalu menjalankannya sekali. Tombol kedua menghapus task yang sama. Tidak menyentuh task produksi. Jika API task ditolak lingkungan, catat terhalang dan alasan. |
| Unavailable | START pada target yang tidak tersedia | Pesan folder tidak ditemukan; kontrol pulih; folder tidak dibuat. |
| Locked | START | File dikunci harness sampai jendela ditutup. Pesan kegagalan jelas, isi utuh, kontrol pulih. |
| WorkerError | START | Fixture sengaja menghalangi direktori laporan. Worker melaporkan error; file yang sudah dipindah dan jurnal tetap aman; kontrol pulih. |
| Scale | START; resize dan amati redraw/progres sampai selesai, STATS, tutup | 10.000 invoice kecil, nama berulang pada 10 batch, rekursi, smart rules, log dan tiga format laporan aktif. GUI tepat 500 baris, laporan seluruh 10.000. SHA256 utuh; organize kedua otomatis tidak memindah atau mengubah nama. |
| CloseDuringWork | START, lalu X ketika kontrol sedang nonaktif | Pesan menunggu transaksi, jendela menutup setelah worker selesai; 10.000 file utuh. Buka sesi lagi untuk memastikan dapat dibuka kembali (jangan START lagi). |
| Launcher | Jalankan build terlebih dahulu; buka skenario, tunggu `launcher.json` muncul, START pada GUI publik lalu tutup | Launcher membuka GUI dari runtime sandbox. Harness menguji launcher kedua keluar dan Silent DryRun tetap bekerja saat mutex GUI dipegang. Jangan gunakan tombol Schedule pada skenario publik; scheduler diuji terpisah dengan TaskName privat. |

Contoh feed watcher (ganti path dengan sesi yang dicetak):

```powershell
& '.tools/verification/Watcher-<GUID>/Feed-Watcher.ps1' -Action Created
& '.tools/verification/Watcher-<GUID>/Feed-Watcher.ps1' -Action Renamed
& '.tools/verification/Watcher-<GUID>/Feed-Watcher.ps1' -Action Burst
```

Watcher harus dihentikan dan dimulai kembali pada GUI sendiri, bukan proses lain. Stop sekarang menunggu worker aktif menyelesaikan transaksi; durasi Stop dapat mengikuti durasi worker. Jangan mematikan paksa proses ketika jurnal sedang ditulis.

## Evidence dan hasil

Setiap sesi menyimpan `session.json`, `instructions.txt`, `runtime/config.json`, serta `evidence/` berisi inventaris awal/akhir (path relatif, ukuran, SHA256), identitas sumber, console, statistik, hasil assertion dan pengamatan visual. GUI privat juga mencatat jumlah baris/KPI, transisi busy/idle, jeda maksimum dispatcher, estimasi feedback pertama, peak working set **proses host** dan waktu sesi (termasuk waktu penguji). Durasi operasi ada di Summary laporan; waktu sesi bukan durasi organize. Sampel timer 250 ms bukan bukti bahwa semua interaksi terasa responsif; konfirmasi manusia tetap wajib. Launcher berjalan pada proses terpisah sehingga metrik GUI privat tidak berlaku padanya.

Untuk hasil skala, jangan bandingkan langsung dengan benchmark CLI lama yang menonaktifkan log/laporan. Hashing dan jurnal durable tetap aktif. Tidak ada optimasi keselamatan transaksi demi benchmark.

Sesi dipertahankan, termasuk yang gagal. Harness menghentikan watcher miliknya, menunggu worker selesai, dan membersihkan hanya task GUID sesi; task yang masih aktif setelah batas tunggu dipertahankan dengan kegagalan cleanup yang dicatat. Tidak ada kill proses berdasarkan nama global. Sesi dapat dihapus manual setelah semua worker/task sesi selesai, dengan memverifikasi path absolut tetap di `.tools/verification/`.

Konkurensi mutasi folder diuji otomatis melalui lock lintas proses dan pemulihan setelah pemilik keluar. Mutex launcher dan mutex jendela publik berbeda: script GUI kedua juga harus dicoba secara manual dalam sesi Launcher, menggunakan `runtime/DownloadOrganizer.ps1 -GUI -ConfigPath <config sesi>`, untuk memastikan tidak muncul jendela tambahan. Probe mutex hanya melepaskan mutex bila proses pengujian memang memilikinya.

Gate publikasi tetap terbuka sampai semua skenario kritis dikonfirmasi pengguna, assertion lulus, tidak ada resource aktif tertinggal, dan CI Windows menguji snapshot sumber yang sama. Tahap setelahnya tetap terpisah: identitas visual; lokasi data/izin/lifecycle; installer/uninstaller/upgrade; lalu distribusi dan beta terbatas.
