# Laporan Audit Menyeluruh (Comprehensive Project Audit)

> Historical audit of the implementation before the 2.2.0 repairs. Its version labels, line numbers and findings below are preserved as the original record, not a current open-issue list. Current fixes, evidence, limitations and release gates are in [RELEASE.md](RELEASE.md) and [TESTING.md](TESTING.md).

**Proyek:** Download Organizer Pro  
**Versi Repositori Saat Ini:** v2.1.1 (berdasarkan `CHANGELOG.md`) / v2.0.0 (`docs/PRD.md`)  
**Tanggal Audit:** 9 November 2026  
**Cakupan Audit:** Kebutuhan Produk (PRD), Logika Bisnis (Core Engine), Antarmuka Pengguna (GUI & CLI), Keamanan (Security), Performa & Skalabilitas, Kualitas Kode (Style Guide), Pipeline Build, Pengujian (Testing), dan Dokumentasi.

---

## Ringkasan Eksekutif (Executive Summary)

Secara tampilan luar, **Download Organizer Pro** terlihat sangat rapi: memiliki arsitektur modular (15 modul `.psm1`), antarmuka WPF Desktop GUI, pipeline kompilasi `.exe`, CI/CD GitHub Actions, serta dokumentasi yang lengkap.

Namun, setelah dilakukan **audit mendalam baris demi baris terhadap seluruh kode sumber dan membandingkannya dengan `docs/PRD.md` serta dokumentasi lainnya**, ditemukan **banyak kekurangan kritis dan bug fundamental**. Beberapa fitur utama yang diklaim selesai di `README.md` dan `ROADMAP.md` ternyata **tidak terhubung (dead code)**, **rusak secara fungsional**, atau **hanya ada di konfigurasi tanpa pernah dieksekusi di kode**.

### Statistik Temuan Audit
- **🔴 Kritis (Critical Bugs & Broken Features):** 9 temuan
- **🟠 Tinggi (Security & Data Integrity Risks):** 5 temuan
- **🟡 Sedang (Performance, Architecture & GUI Issues):** 7 temuan
- **🔵 Rendah (Style Guide, Testing & Documentation Drift):** 7 temuan

---

## 1. 🔴 Temuan Kritis: Bug Fungsional & Fitur yang Rusak

### 1.1. `SmartClassifier.psm1` Mengabaikan Kategori File & Mencampur Subkategori Lintas Kategori
- **Lokasi:** `modules/SmartClassifier.psm1` (Baris 5–75 & 100–140)
- **Masalah:**
  1. Fungsi `Invoke-SmartClassification` memanggil `Get-SmartCategory -FileName $file.Name -SmartRules $SmartRules` **tanpa meneruskan `$file.Category`**.
  2. Di dalam `Get-SmartCategory`, kode melakukan iterasi ke **seluruh kategori** yang ada di `$SmartRules` (`Documents`, `Archives`, `Images`) tanpa memfilter apakah aturan tersebut milik kategori file yang sedang diperiksa.
  3. Akibatnya, sebuah file gambar seperti `project_screenshot.png` (yang dikategorikan sebagai `Images` oleh `Classifier.psm1`) akan cocok dengan aturan `Archives -> Projects` (karena `Priority: 100` lebih tinggi dari `Images -> Screenshots` yang `Priority: 50`). File tersebut akhirnya dipindahkan ke `Images\Projects` (subkategori milik `Archives`!). Bahkan file aplikasi seperti `resume_builder_setup.exe` (`Applications`) akan dipindahkan ke `Applications\CV`.
  4. Selain itu, `Format-FileName` (`modules/Utils.psm1` baris 46–65) mengubah titik (`.`) menjadi spasi pada nama file **termasuk ekstensinya** (`file.pdf` menjadi `"file pdf"`), dan pencocokan keyword menggunakan substring regex (`$normalizedName -match [regex]::Escape($keyword.ToLower())`) tanpa batas kata (*word boundary* `\b`). Akibatnya, file bernama `fullscreen.mp4` akan cocok dengan keyword `"screen"` (`Screenshots`), atau `curriculum_video.mp4` masuk ke `Videos\CV`.
- **Solusi:**
  - Teruskan `-Category $file.Category` ke `Get-SmartCategory` dan hanya evaluasi `$SmartRules.($file.Category)`.
  - Gunakan `[System.IO.Path]::GetFileNameWithoutExtension($FileName)` sebelum normalisasi agar ekstensi file tidak ikut dicocokkan sebagai keyword.

---

### 1.2. Bug *Infinite Nesting* & *Self-Renaming* Saat Mode `-Recurse` Aktif
- **Lokasi:** `modules/Scanner.psm1` (Baris 18–32) & `modules/Mover.psm1` (Baris 64–84)
- **Masalah:**
  - Ketika pengguna menjalankan `-Recurse` (atau mengaktifkan checkbox *Recurse Subfolders* di GUI), `Get-DownloadFiles` akan memindai seluruh file di dalam subfolder, **termasuk file yang sudah berada di dalam folder kategori** (misal: `Downloads\Documents\CV\Resume.pdf`).
  - Saat `Move-OrganizerFiles` memproses file tersebut, target tujuannya adalah `Downloads\Documents\CV\Resume.pdf` (sama persis dengan lokasi asalnya!).
  - Karena `New-UniqueFilePath` mengecek `if (-not (Test-Path $Destination))` dan melihat file tersebut sudah ada di tujuan (yaitu dirinya sendiri!), `New-UniqueFilePath` mengubah namanya menjadi `Resume (1).pdf` lalu memindahkan file itu ke folder yang sama dengan nama baru `Resume (1).pdf`!
  - Jika dijalankan berulang kali, file akan terus berubah nama menjadi `Resume (1) (1).pdf`, `Resume (1) (1) (1).pdf`, dst.
- **Solusi:**
  - Di `Scanner.psm1`: Kecualikan folder kategori utama (`$config.Categories.PSObject.Properties.Name`) saat melakukan pemindaian rekursif, atau
  - Di `Mover.psm1`: Cek apakah `$file.FullPath -eq $destination` (case-insensitive) sebelum memanggil `New-UniqueFilePath`. Jika sudah berada di folder tujuan yang benar, tandai sebagai `Skipped`.

---

### 1.3. Fitur Real-Time Folder Watcher (`-Watcher`) Rusak Total (Tidak Berfungsi)
- **Lokasi:** `modules/Watcher.psm1` (Baris 68–97) & `DownloadOrganizer.ps1` (Baris 114–123)
- **Masalah Ganda:**
  1. **Bug Scope Variabel di `Register-ObjectEvent` (`Watcher.psm1`):**
     Di baris 68–97, scriptblock `$action` menggunakan variabel `$DebounceSeconds` dan `$ScriptPath`. Dalam PowerShell, scriptblock `-Action` pada `Register-ObjectEvent` berjalan di *dynamic module scope* tersendiri dan **tidak mewarisi variabel lokal fungsi pemanggil (`Start-OrganizerWatcher`)** kecuali dikirim melalui parameter `-MessageData` dan diakses lewat `$Event.MessageData`.
     Akibatnya, saat ada file baru masuk ke folder Downloads:
     - `$DebounceSeconds` bernilai `$null`
     - `$ScriptPath` bernilai `$null`, sehingga pemanggilan `$ScriptPath.EndsWith(".exe", ...)` di baris 82 melempar *NullReferenceException*.
     - Karena ada blok `catch { # Ignore errors }` kosong di baris 88–90, error tersebut ditelan diam-diam dan **Watcher tidak pernah mengeksekusi pengorganisasian file sama sekali!**
  2. **CLI `-Watcher` Langsung Keluar (`DownloadOrganizer.ps1`):**
     Di baris 114–123, ketika pengguna menjalankan `.\DownloadOrganizer.ps1 -Watcher` dari terminal, skrip memanggil `Start-OrganizerWatcher`, mencetak *"Press Ctrl+C to stop"*, lalu langsung mengeksekusi **`return`**! Jika dijalankan via `powershell.exe -File DownloadOrganizer.ps1 -Watcher`, proses PowerShell langsung berhenti seketika itu juga.
  3. **Hanya Memantau Event `Created`, Bukan `Renamed`:**
     Browser modern (Chrome, Edge, Firefox) mengunduh file dengan nama sementara (`*.crdownload` / `*.part`) saat event `Created` terjadi (yang di-skip oleh baris 74 `Watcher.psm1`), lalu **me-rename** file tersebut menjadi `.pdf`/`.zip` setelah unduhan selesai (memicu event `Renamed`, bukan `Created`!). Karena `Watcher.psm1` hanya mendaftarkan `-EventName "Created"`, unduhan dari browser **tidak akan pernah terdeteksi** setelah selesai diunduh!
- **Solusi:**
  - Teruskan `@{ ScriptPath = $ScriptPath; DebounceSeconds = $DebounceSeconds }` melalui `-MessageData` pada `Register-ObjectEvent`, dan baca melalui `$Event.MessageData` di dalam `$action`.
  - Daftarkan juga event `Renamed` selain `Created`.
  - Gunakan loop `while ($true) { Start-Sleep -Seconds 1 }` di `DownloadOrganizer.ps1` saat mode `-Watcher` dijalankan dari CLI.

---

### 1.4. Enam Pengaturan di `config.json` Adalah *Dead Configuration* (Tidak Pernah Dipakai)
- **Lokasi:** `config.json` (Baris 2–22), `DownloadOrganizer.ps1`, `modules/Mover.psm1`
- **Masalah:** Sesuai `PRD.md` (FR-001, FR-008, Bagian 7), seluruh perilaku aplikasi harus dikendalikan dari `config.json`. Namun, **6 pengaturan di `config.json` diabaikan sama sekali oleh kode**:
  1. `"Overwrite": false` — Divalidasi wajib ada oleh `Validation.psm1` (baris 178), tetapi **sama sekali tidak pernah dibaca atau diteruskan ke `Mover.psm1`**! `Mover.psm1` selalu melakukan *auto-rename*. Strategi `Overwrite` dan `Skip` yang dijanjikan di `PRD.md` (FR-008) dan `CONFIGURATION.md` tidak diimplementasikan.
  2. `"MoveUnknownFiles": true` — Tidak pernah dicek di `Classifier.psm1` maupun `Mover.psm1`. File dengan ekstensi tak dikenal selalu dipindahkan ke folder `Others` meskipun pengguna mengubahnya menjadi `false`.
  3. `"CreateCategoryFolders": true` — Tidak pernah dicek di `Mover.psm1`. Folder selalu dibuat otomatis meskipun diset `false`.
  4. `"CreateLogs": true` — Tidak pernah dicek di `DownloadOrganizer.ps1`. File log tetap selalu dibuat meskipun diset `false`.
  5. `"Verbose": false` — Tidak pernah digunakan untuk mengatur `$VerbosePreference = 'Continue'` di `DownloadOrganizer.ps1`.
  6. `"ScheduleIntervalMinutes": 60` — Tidak pernah dibaca di mana pun.

---

### 1.5. Modul `DuplicateDetector.psm1` Adalah *Dead Code* (Tidak Pernah Dipanggil)
- **Lokasi:** `modules/DuplicateDetector.psm1`, `DownloadOrganizer.ps1` (Baris 55)
- **Masalah:**
  - Modul `DuplicateDetector.psm1` di-import di `DownloadOrganizer.ps1` (baris 55) dan bahkan tidak di-import di `GUI.psm1`.
  - Baik `DownloadOrganizer.ps1` maupun `GUI.psm1` **tidak pernah memanggil `Get-DuplicateFiles` atau `Test-FileDuplicate` sama sekali** dalam alur eksekusi!
  - Meskipun fitur *SHA256 Duplicate Detection* dipromosikan di `README.md` dan `ROADMAP.md` sebagai fitur utama, kenyataannya kode tersebut hanya dipanggil di dalam unit test (`DuplicateDetector.Tests.ps1`) dan tidak pernah digunakan saat aplikasi berjalan.

---

### 1.6. Modul `Scheduler.psm1` Tidak Memiliki Akses dari CLI Maupun GUI
- **Lokasi:** `modules/Scheduler.psm1`, `DownloadOrganizer.ps1` (Baris 61), `modules/GUI.psm1`
- **Masalah:**
  - `Scheduler.psm1` di-import di `DownloadOrganizer.ps1`, namun tidak ada parameter CLI (seperti `-Schedule` atau `-Unschedule`) di `DownloadOrganizer.ps1` dan tidak ada tombol di `GUI.psm1` untuk memanggil `Register-OrganizerTask` / `Unregister-OrganizerTask`. Pengguna biasa tidak bisa menggunakan fitur penjadwalan ini tanpa memanggil fungsi modul secara manual dari shell.

---

### 1.7. Bug Status & Logging pada Mode `-DryRun` (Semua File Dicatat Sebagai ERROR/Failed!)
- **Lokasi:** `modules/Mover.psm1` (Baris 94–105), `modules/Logger.psm1` (Baris 140–163), `modules/Summary.psm1` (Baris 54–61), `modules/ReportGenerator.psm1` (Baris 267–268)
- **Masalah Berantai:**
  1. Saat `-DryRun` aktif, `Mover.psm1` menandai objek `$file.MarkSkipped("DryRun Mode")`, tetapi objek hasil yang dimasukkan ke `$results` diberi properti `Status = "Moved (DryRun)"`.
  2. Selanjutnya, `Write-MoveLog` di `Logger.psm1` (baris 140) mengecek:
     ```powershell
     if ($item.Status -eq "Moved") { ... } else { Write-OrganizerLog -Level ERROR -Message "Failed: ..." }
     ```
     Karena `"Moved (DryRun)"` tidak sama dengan `"Moved"`, **setiap file pada mode DryRun dicatat ke file log sebagai `[ERROR] Failed: namafile | tujuan`!**
  3. Di `Summary.psm1` (baris 54–56), `Get-OrganizerSummary` menghitung `$movedFiles` dengan filter `$_.Status -eq "Moved"` dan `$skippedFiles` dengan `$_.Status -eq "Skipped"`. Akibatnya, saat `-DryRun` dijalankan di CLI, ringkasan menampilkan **`Files moved: 0`**, **`Failed: 0`**, **`Skipped: 0`**!
  4. Lebih parah lagi, karena log dipenuhi baris `[ERROR] Failed:`, fungsi `Get-OrganizerStatistics` (`ReportGenerator.psm1` baris 268) menghitung semua simulasi DryRun sebagai kegagalan operasi permanen pada dashboard statistik!

---

### 1.8. Ketidaksinkronan Eksekusi GUI vs CLI (`GUI.psm1`)
- **Lokasi:** `modules/GUI.psm1` (Baris 336–473)
- **Masalah:**
  1. **Tidak Menulis Log Harian:** Saat pengorganisasian dijalankan lewat tombol `START ORGANIZING` di GUI (`GUI.psm1` baris 336–416), fungsi `Initialize-Logger`, `Write-OrganizerLog`, dan `Write-MoveLog` **sama sekali tidak dipanggil**. Akibatnya, pengguna yang memakai GUI tidak pernah memiliki catatan log di `logs/organizer-YYYY-MM-DD.log`, dan ketika mereka menekan tombol `STATS REPORT` di GUI, hasilnya selalu `0`!
  2. **Durasi Laporan HTML Selalu 0 Detik:** Di `GUI.psm1` baris 401:
     ```powershell
     $summary = Get-OrganizerSummary -Files $classifiedFiles -Results $moveResults -StartTime (Get-Date) -EndTime (Get-Date)
     ```
     Karena `StartTime` dan `EndTime` sama-sama diisi `(Get-Date)` setelah proses selesai, durasi eksekusi selalu `0` detik.
  3. **Checkbox GUI Mengabaikan `config.json`:** Status awal checkbox di XAML (`ChkSmartRules`, `ChkDryRun`, `ChkRecurse`, `ChkExportHTML`, `ChkExportCSV`) di-hardcode di XAML (misal `ChkExportHTML` selalu `True` walaupun di `config.json` nilainya `false`).
  4. **Path dengan Environment Variable Gagal di GUI:** Jika pengguna mengetik `%USERPROFILE%\Downloads` di kotak teks `TxtFolderPath`, tombol `START ORGANIZING` tidak memanggil `Resolve-EnvironmentPath`, sehingga `Test-Path -LiteralPath $targetFolder` gagal.

---

### 1.9. Kelemahan Mekanisme Undo (`Undo.psm1`)
- **Lokasi:** `modules/Undo.psm1` (Baris 52–113), `DownloadOrganizer.ps1` (Baris 126–137)
- **Masalah:**
  1. Setelah `Invoke-UndoOperation` selesai mengembalikan file dari `transaction-YYYY-MM-DD-HHmmss.json`, **file transaksi JSON tersebut tidak dihapus atau diganti namanya** (misal menjadi `.undone.json`).
  2. Akibatnya, jika pengguna menekan tombol `UNDO LAST MOVE` untuk kedua kalinya (bermaksud membatalkan transaksi sebelumnya lagi), `Get-UndoLog` tetap mengambil file transaksi terbaru yang sama (`$undoLogs[0]`), tidak menemukan file di `DestinationPath`, dan melaporkan `Restored: 0 file(s)`. Transaksi-transaksi yang lebih lama tidak pernah bisa di-undo.
  3. `Move-Item -LiteralPath $entry.DestinationPath -Destination $entry.SourcePath -Force` menggunakan flag `-Force`, yang berarti jika di folder `Downloads` asal sudah ada file baru dengan nama yang sama, file baru tersebut akan **ditimpa (dihapus permanen)** tanpa peringatan! Hal ini melanggar prinsip keamanan di `PRD.md` (Bagian 6 - Safety) dan `SECURITY.md`.

---

## 2. 🟠 Temuan Tinggi: Kerentanan Keamanan & Integritas Data

### 2.1. Kerentanan *Command Injection* via `Invoke-Expression` di `Scheduler.psm1`
- **Lokasi:** `modules/Scheduler.psm1` (Baris 48–51, 80–83, 112–115)
- **Masalah:**
  ```powershell
  $schtasksCmd = "schtasks /Create /TN `"$TaskName`" /TR `"$command $args`" /SC MINUTE /MO $IntervalMinutes /F"
  $output = Invoke-Expression $schtasksCmd 2>&1
  ```
  - Menggunakan `Invoke-Expression` untuk menjalankan perintah eksternal dengan penggabungan string (`$TaskName`, `$ScriptPath`) sangat berbahaya. Jika `$TaskName` atau `$ScriptPath` mengandung tanda kutip atau sub-ekspresi PowerShell (seperti `$(...)` atau `;`), kode arbitrer akan dieksekusi.
  - Selain itu, di baris 48, `"` di dalam `/TR `"$command $args`"` যেখানে `$args` sendiri mengandung `"` (`-File "$ScriptPath"`) menghasilkan string perintah dengan kutip yang rusak (`schtasks /Create ... /TR "powershell.exe ... -File "C:\...\DownloadOrganizer.ps1" -Silent"`), sehingga **`schtasks.exe` akan gagal membuat task jika `$ScriptPath` memiliki spasi**! Dan karena `Invoke-Expression` pada binary eksternal tidak melempar exception PowerShell saat `schtasks.exe` keluar dengan exit code non-zero, `Register-OrganizerTask` **selalu mengembalikan `$true` meskipun pembuatan task gagal!**
- **Solusi:**
  - Jangan pernah gunakan `Invoke-Expression`. Panggil langsung dengan operator call `& schtasks.exe /Create /TN $TaskName ...` dan periksa `$LASTEXITCODE -eq 0`.

---

### 2.2. Kerentanan *HTML Injection / Stored XSS* pada Laporan HTML (`ReportGenerator.psm1`)
- **Lokasi:** `modules/ReportGenerator.psm1` (Baris 144–155)
- **Masalah:**
  ```powershell
  $fileRows += "<tr><td>$($item.File)</td><td>$($item.Category)</td><td>$($item.SubCategory)</td><td><span class='$statusClass'>$($item.Status)</span></td><td>$($item.Destination)</td></tr>`n"
  ```
  - Nama file (`$item.File`), kategori, dan tujuan dimasukkan langsung ke dalam template HTML tanpa *HTML encoding*.
  - Jika terdapat file unduhan dengan karakter spesial HTML atau nama berbahaya (misalnya `"><script>...</script>.pdf` atau `file<1>.txt`), tampilan tabel HTML akan rusak atau mengeksekusi JavaScript saat pengguna membuka laporan HTML di browser.
- **Solusi:**
  - Bungkus seluruh nilai dinamis menggunakan `[System.Net.WebUtility]::HtmlEncode(...)`.

---

### 2.3. Bug Wildcard Karakter `[` dan `]` pada Nama File (`Mover.psm1` & `Utils.psm1`)
- **Lokasi:** `modules/Mover.psm1` (Baris 80–82), `modules/Utils.psm1` (Baris 109, 143, 179, 203), `modules/Logger.psm1` (Baris 107)
- **Masalah:**
  - Di folder `Downloads`, sangat umum ditemukan nama file yang mengandung kurung siku seperti `Document[1].pdf`, `[SubIndo] Movie [1080p].mkv`, atau `invoice[2026].xlsx`.
  - Di PowerShell, parameter `-Path` pada `Test-Path`, `Move-Item`, `Get-FileHash`, dan `Add-Content` menginterpretasikan `[` dan `]` sebagai **pola wildcard regex**!
  - Pada `Mover.psm1` baris 80:
    ```powershell
    Move-Item -Path $file.FullPath -Destination $destination
    ```
    dan pada `Utils.psm1` baris 143 & 179:
    ```powershell
    if (-not (Test-Path $Destination))
    ```
    Ketika memproses file bernama `laporan[1].pdf`:
    - `Move-Item -Path` akan mencari file bernama `laporan1.pdf` (karena `[1]` dianggap wildcard karakter `1`), tidak menemukannya, atau gagal memindahkan file!
    - `Test-Path $Destination` di `New-UniqueFilePath` juga gagal mendeteksi konflik nama file dengan benar.
- **Solusi:**
  - Selalu gunakan **`-LiteralPath`** (bukan `-Path`) pada `Move-Item`, `Test-Path`, `Get-FileHash`, `Get-Content`, `Set-Content`, dan `Add-Content`.

---

### 2.4. Tidak Ada Validasi *Path Traversal* pada Nama Kategori & Subkategori (`Validation.psm1`)
- **Lokasi:** `modules/Validation.psm1` (Baris 42–106)
- **Masalah:**
  - `SECURITY.md` (baris 64) mengklaim: *"Missing directories are created only inside the configured destination"*.
  - Namun `Validation.psm1` tidak memvalidasi nama kunci pada `Categories` maupun `SmartRules`. Jika konfigurasi memiliki kategori bernama `"..\\..\\FolderLain"` atau karakter tidak valid (`:`, `*`, `?`, `<`, `>`, `|`), `Join-Path $BasePath $file.DestinationPath` akan mengarahkan pemindahan file keluar dari folder `DownloadsPath`.
- **Solusi:**
  - Validasi bahwa setiap nama kategori dan subkategori tidak mengandung `..`, `/`, `\`, atau karakter dari `[System.IO.Path]::GetInvalidFileNameChars()`.

---

### 2.5. Masalah *Single-Instance Mutex* & Argumen CLI pada `Launcher.cs` (`build.ps1`)
- **Lokasi:** `build.ps1` (Baris 94–153)
- **Masalah:**
  1. **Gagal saat Crash (*AbandonedMutexException*):** Jika proses aplikasi sebelumnya dimatikan paksa (via Task Manager atau crash), mutex berada dalam status *abandoned*, atau jika dijalankan di komputer dengan multi-user Windows, penggunaan prefix `"Global\\..."` dapat menyebabkan `UnauthorizedAccessException` antar sesi pengguna. Lebih baik gunakan `"Local\\..."`.
  2. **Mengabaikan Argumen Command-Line:** `static void Main()` di `Launcher.cs` tidak menerima `string[] args` dan selalu meng-hardcode `-GUI` (baris 133). Padahal `Watcher.psm1` (baris 83) berusaha menjalankan `DownloadOrganizerPro.exe -Silent`. Ketika `Watcher` memanggil `DownloadOrganizerPro.exe -Silent`, executable tersebut justru mencoba membuka GUI kedua, tertahan oleh Mutex (`if (!createdNew) return;`), dan langsung keluar tanpa mengorganisasi file!
  3. **Bukan *Standalone Executable* Murni:** `README.md` dan `BUILD_GUIDE.md` menyebut `dist/DownloadOrganizerPro.exe` sebagai *standalone executable* (bahkan menyebut `PS2EXE` di `README.md` baris 104). Faktanya, `DownloadOrganizerPro.exe` hanyalah *wrapper launcher* C# berukuran kecil yang memanggil `powershell.exe -File DownloadOrganizer.ps1` dan tetap membutuhkan folder `modules/` serta `DownloadOrganizer.ps1` di sebelahnya.

---

## 3. 🟡 Temuan Sedang: Performa, Skalabilitas & Arsitektur

### 3.1. Target Performa 10.000 File (`PRD.md` Bagian 6) Terhambat oleh Algoritma $O(N \times M)$ dan I/O Berulang
`PRD.md` dan `ARCHITECTURE.md` menetapkan target performa minimal **10.000 file** dengan penggunaan memori rendah dan *hashtable lookup*. Namun implementasi saat ini memiliki 4 *bottleneck* besar:
1. **Pencarian Kategori Linear (`Classifier.psm1` baris 22–30):**
   Untuk setiap file, `Find-CategoryByExtension` melakukan loop `foreach ($category in $Categories.PSObject.Properties)` dan mengecek `$extension -in $category.Value`. Seharusnya ekstensi dipetakan satu kali di awal ke dalam `[hashtable]` (`$extMap['pdf'] = 'Documents'`) sehingga pencarian menjadi $O(1)$.
2. **Evaluasi Regex & `Sort-Object` Pipeline per File (`SmartClassifier.psm1` baris 23–73):**
   Untuk 10.000 file, fungsi `Get-SmartCategory` dipanggil 10.000 kali. Di setiap pemanggilan, ia melakukan nested loop, memanggil `[regex]::Escape($keyword.ToLower())` berulang-ulang, membuat `PSCustomObject`, dan menjalankan pipeline `@($matchedItems) | Sort-Object Score -Descending | Select-Object -First 1`. Di PowerShell, membangun pipeline `Sort-Object` 10.000 kali memakan waktu puluhan detik.
3. **Penulisan Disk (`Add-Content`) per File di `Logger.psm1` (Baris 138–165):**
   `Write-MoveLog` memanggil `Write-OrganizerLog` di dalam loop `foreach ($item in $Results)`, yang berarti membuka, menulis, dan menutup file log (`Add-Content`) sebanyak **10.000 kali**! Seharusnya seluruh baris log dikumpulkan dalam `List[string]` dan ditulis sekaligus dalam satu operasi `Add-Content`.
4. **Loop `New-UniqueFilePath` Berpotensi Lambat (`Utils.psm1` baris 164–179):**
   Jika ada ratusan file bernama sama (misal `image.jpg`), loop `do ... until (-not (Test-Path $candidate))` selalu mengecek dari `(1)`, `(2)`, `(3)` dst. dari awal untuk setiap file ($O(K^2)$ operasi sistem file).

---

### 3.2. UI Freezing pada WPF Desktop GUI (`GUI.psm1`)
- **Lokasi:** `modules/GUI.psm1` (Baris 336–416)
- **Masalah:**
  - Di `CHANGELOG.md` (v2.1.1), disebutkan bahwa pembatasan 500 item pada DataGrid ditambahkan untuk mencegah UI freeze.
  - Namun, proses `Get-DownloadFiles`, `Set-FileCategory`, `Invoke-SmartClassification`, dan `Move-OrganizerFiles` untuk ribuan file tetap dijalankan **secara sinkron di dalam UI Thread** (`$btnStart.Add_Click`). Selama proses pemindahan file berlangsung, jendela WPF akan membeku (*Not Responding*) dan konsol log (`TxtLogConsole`) tidak akan memperbarui tampilan sampai seluruh proses selesai.
- **Solusi:**
  - Jalankan pipeline pengorganisasian di background *Runspace* (`[PowerShell]::Create()`) atau gunakan `Dispatcher.Invoke` secara berkala agar jendela WPF tetap responsif.

---

### 3.3. Tidak Ada Module Manifest (`.psd1`) & Ketergantungan Antar Modul yang Rapuh
- **Lokasi:** Seluruh file `modules/*.psm1`, `DownloadOrganizer.ps1` (Baris 48–63)
- **Masalah:**
  - `ARCHITECTURE.md` (baris 509–512) menyatakan: *"Every module should be independently testable and minimize dependencies."*
  - Kenyataannya, modul-modul saling bergantung secara implisit melalui *global session state* tanpa deklarasi `#Requires` atau `NestedModules`:
    - `Config.psm1` memanggil `Resolve-EnvironmentPath` (`Utils.psm1`) dan `Test-OrganizerConfiguration` (`Validation.psm1`).
    - `Scanner.psm1` memanggil `New-OrganizerFile` (`Models.psm1`).
    - `SmartClassifier.psm1` memanggil `Format-FileName` (`Utils.psm1`).
    - `DuplicateDetector.psm1` memanggil `Get-FileSHA256` (`Utils.psm1`).
    - `Mover.psm1` memanggil `Initialize-Directory` dan `New-UniqueFilePath` (`Utils.psm1`).
    - `Summary.psm1` memanggil `New-OrganizerSummary` (`Models.psm1`).
  - Jika sebuah modul di-import sendiri tanpa meng-import `Models.psm1` dan `Utils.psm1` terlebih dahulu, modul tersebut langsung error saat dijalankan.

---

## 4. 🔵 Temuan Rendah: Pelanggaran Style Guide, Kualitas Kode & Testing

### 4.1. Pelanggaran Langsung terhadap `docs/STYLEGUIDE.md` & `docs/DEVELOPMENT.md`
1. **Larangan `Write-Host` di Dalam Modul (`STYLEGUIDE.md` baris 366–378):**
   - *"Do not use `Write-Host` inside modules. Console output belongs in `DownloadOrganizer.ps1`."*
   - **Dilanggar di:** `modules/Summary.psm1` (`Show-OrganizerSummary` baris 108–153 menggunakan 24 pemanggilan `Write-Host`).
2. **Batas Ukuran Fungsi Maksimal 80 Baris & Modul Maksimal 400 Baris (`STYLEGUIDE.md` baris 437–458):**
   - **Dilanggar di:** `modules/GUI.psm1` memiliki **502 baris**, dan fungsi tunggal `Show-OrganizerGUI` memiliki **455 baris** (baris 27–481).
3. **Larangan Variabel Global (`DEVELOPMENT.md` baris 133):**
   - *"Avoid global variables"*
   - **Dilanggar di:** `modules/Watcher.psm1` menggunakan `$Global:OrganizerWatcherInstance` (seharusnya cukup `$script:OrganizerWatcherInstance`).
4. **Penggunaan Kata Kerja (Verb) Tidak Standar PowerShell (`STYLEGUIDE.md` baris 188–216):**
   - Fungsi helper `Normalize-FileName` dan `Ensure-Directory` (`Utils.psm1`), `Classify-Files` (`Classifier.psm1`), serta `Apply-SmartClassification` (`SmartClassifier.psm1`) menggunakan verb yang tidak disetujui PowerShell (`Normalize`, `Ensure`, `Classify`, `Apply`). Meskipun tidak di-export di `Export-ModuleMember`, fungsi-fungsi tersebut tidak pernah dipanggil di dalam modulnya sendiri sehingga menjadi **dead code** yang membingungkan.
5. **Inkonsistensi Line Endings (`STYLEGUIDE.md` baris 49–53):**
   - `STYLEGUIDE.md` mewajibkan `LF`, namun file seperti `config.json`, `Models.psm1`, `Validation.psm1`, `Config.psm1`, dan sebagian besar file di `docs/` menggunakan `CRLF`.

---

### 4.2. *Dead Code* & Duplikasi Logika di Dalam Modul
1. **Double Increment Variabel yang Tidak Dipakai di `Mover.psm1` (Baris 53–61):**
   ```powershell
   $total = $Files.Count
   $current = 0

   foreach ($file in $Files) {

       $current++

       $current++
   ```
   Variabel `$current` di-increment **dua kali** berturut-turut di setiap iterasi, dan baik `$total` maupun `$current` **tidak pernah digunakan sama sekali** di seluruh fungsi `Move-OrganizerFiles`!
2. **Fungsi Utilitas yang Dibuat Tapi Tidak Dipakai (`Utils.psm1`):**
   - `Test-IsNullOrWhiteSpace` (baris 5–14) didefinisikan tapi tidak pernah dipanggil di mana pun.
   - `Convert-BytesToMB` (baris 24–40) dan `Format-Duration` (baris 212–244) sudah dibuat di `Utils.psm1`, tetapi `Models.psm1` (baris 187), `Summary.psm1` (baris 66 & 143), `ReportGenerator.psm1` (baris 142), dan `GUI.psm1` (baris 388) malah menulis ulang rumus `[Math]::Round(... / 1MB, 2)` dan perhitungan durasi secara manual!
3. **Properti *Fallback* Fiktif di `Summary.psm1` & `ReportGenerator.psm1`:**
   - Di `Summary.psm1` (baris 114–116) dan `ReportGenerator.psm1` (baris 138–140), terdapat pengecekan `$Summary.TotalScanned`, `$Summary.TotalMoved`, dan `$Summary.TotalFailed`. Class `OrganizerSummary` di `Models.psm1` (dengan `Set-StrictMode -Version Latest`) tidak memiliki properti tersebut (namanya adalah `TotalFiles`, `Moved`, `Failed`). Jika `$Summary.TotalFiles` kebetulan `$null`, mengakses `$Summary.TotalScanned` justru akan melempar *PropertyNotFoundException* karena `StrictMode` aktif!

---

### 4.3. Kelemahan Suite Pengujian (`tests/`) vs `docs/TESTING.md`
1. **Sintaks Pester v3 yang Usang:**
   - Seluruh 14 file unit test menggunakan sintaks Pester v3 (`Should Be`, `Should Not Be`, `Should Throw`) tanpa tanda hubung (`-`). Pada Pester v5 (yang digunakan di GitHub Actions `windows-latest`), sintaks lama ini sudah *deprecated*.
2. **Cakupan Test (Test Coverage) Semu pada Fitur Kompleks:**
   - Klaim di `ROADMAP.md` (baris 16): *"Test Suite Coverage: 100% Core Engine & GUI Modules (49 Pester unit tests passing)."*
   - Faktanya, banyak skenario penting sama sekali belum diuji:
     - `Scheduler.Tests.ps1`: Hanya berisi **1 test** (`Get-OrganizerTask` untuk task yang tidak ada). Fungsi `Register-OrganizerTask` dan `Unregister-OrganizerTask` **0% teruji** (itulah sebabnya bug kutip `schtasks` tidak ketahuan).
     - `Watcher.Tests.ps1`: Hanya menguji `Start` dan `Stop` watcher, **tidak menguji pembuatan file baru**, sehingga bug fatal `$Event.MessageData` pada `Watcher.psm1` lolos dari pengujian.
     - `Scanner.Tests.ps1`: Sama sekali tidak menguji parameter `-Recurse`, `-IgnorePatterns`, `-MinAgeDays`, `-MaxAgeDays`, `-MinSizeBytes`, dan `-MaxSizeBytes`.
     - `Mover.Tests.ps1`: Sama sekali tidak menguji mode `-DryRun` (sehingga bug log `[ERROR] Failed` saat DryRun tidak terdeteksi).
3. **Struktur Direktori Test Tidak Sesuai `docs/TESTING.md`:**
   - `docs/TESTING.md` (baris 41–64) mendokumentasikan adanya folder `tests/Integration/Organizer.Tests.ps1`, `tests/Integration/Workflow.Tests.ps1`, `tests/Fixtures/`, dan `tests/TestData/`. **Tidak satu pun dari folder dan file tersebut ada di repositori.**

---

### 4.4. Inkonsistensi Dokumentasi yang Parah (Documentation Drift)
Meskipun `DEVELOPMENT.md` menekankan prinsip *Documentation-First Development*, terdapat banyak kontradiksi tajam antar dokumen:

| Dokumen | Inkonsistensi / Masalah |
| :--- | :--- |
| **`docs/CONFIGURATION.md`** | 1. Mendokumentasikan nama setting yang **salah/tidak ada di kode**: `CreateMissingFolders`, `OverwriteExisting`, `RenameDuplicates`, `GenerateLog`, `ShowSummary` (baris 41–48 & 78–153).<br>2. Mendokumentasikan struktur JSON `SmartRules` yang **berbeda total** (baris 206–214 & 449–455: `"SmartRules": { "CV": { "Category": "Documents", ... } }`). Jika pengguna mengikuti panduan ini, aplikasi akan **crash saat validasi** karena `Validation.psm1` mengharuskan struktur `"SmartRules": { "Documents": { "CV": ... } }`! |
| **`docs/PRD.md`** | Masih tertulis **Version 2.0.0 (Draft)** dan di Bagian 8 (*Out of Scope*) menyatakan GUI, Scheduler, Background Service, dan File Watcher berada di luar cakupan, padahal semuanya sudah ada di codebase v2.1.1. |
| **`README.md` & `ARCHITECTURE.md`** | 1. Menyebut `build.ps1` sebagai *"Automated PS2EXE Executable Compiler"*, padahal `build.ps1` menggunakan `csc.exe` (C# Wrapper), bukan modul `PS2EXE`.<br>2. Link dokumentasi di `README.md` (baris 167–186) menggunakan hardcoded absolute path lokal komputer penulis: `file:///c:/Users/zidan/Desktop/Coding/PROJEK/DownloadOrganizerPro/...` (bahkan path-nya salah karena kurang satu folder `download-organizer-pro` dan **tidak akan bisa diklik di GitHub** oleh orang lain!). |
| **Versi Aplikasi** | Tidak konsisten di berbagai tempat:<br>- `PRD.md`: `2.0.0`<br>- `DownloadOrganizer.ps1`: `2.1`<br>- `README.md` / `ARCHITECTURE.md` / `GUI.psm1`: `2.1.0`<br>- `CHANGELOG.md`: `2.1.1` |

---

## 5. Rencana Perbaikan yang Direkomendasikan (Action Plan / Prioritas)

Untuk membawa **Download Organizer Pro** menjadi produk yang benar-benar solid dan siap produksi (*production-ready*), berikut urutan prioritas perbaikannya:

### Prioritas 1 — Perbaikan Bug Fungsional & Keamanan (Segera)
1. **Perbaiki `SmartClassifier.psm1`**: Batasi pencarian `Get-SmartCategory` hanya pada kategori file yang bersangkutan (`$file.Category`), dan pisahkan ekstensi file saat menormalisasi nama file di `Format-FileName`.
2. **Perbaiki `Scanner.psm1` & `Mover.psm1`**:
   - Gunakan `-LiteralPath` di semua operasi file (`Move-Item`, `Test-Path`, `Get-FileHash`) agar nama file dengan karakter `[1]` tidak gagal.
   - Cegah pemindahan ulang file yang sudah berada di dalam folder kategori tujuan saat mode `-Recurse` aktif.
3. **Perbaiki `Watcher.psm1` & `DownloadOrganizer.ps1`**:
   - Gunakan `-MessageData` pada `Register-ObjectEvent` agar `$ScriptPath` dan `$DebounceSeconds` terbaca di dalam event action.
   - Tambahkan pemantauan event `Renamed` (untuk menangkap selesainya unduhan `.crdownload` -> `.pdf`).
   - Tambahkan *blocking loop* (`while ($true) { Start-Sleep 1 }`) saat `-Watcher` dipanggil dari CLI.
4. **Perbaiki `Scheduler.psm1`**: Hapus `Invoke-Expression`, ganti dengan pemanggilan native `& schtasks.exe ...` dan validasi `$LASTEXITCODE`.
5. **Perbaiki XSS di `ReportGenerator.psm1`**: Encode seluruh variabel nama file/kategori dengan `[System.Net.WebUtility]::HtmlEncode()`.

### Prioritas 2 — Integrasi Fitur yang Terputus & Sinkronisasi Konfigurasi
1. **Hubungkan Pengaturan `config.json` yang Mati**:
   - Terapkan `Overwrite`, `MoveUnknownFiles`, `CreateCategoryFolders`, `CreateLogs`, dan `Verbose` ke dalam alur eksekusi.
2. **Integrasikan `DuplicateDetector.psm1` dan `Scheduler.psm1`**:
   - Panggil `Get-DuplicateFiles` di pipeline utama/GUI (atau tambahkan opsi `-DetectDuplicates`), serta tambahkan parameter CLI `-Schedule` / `-Unschedule` dan tombolnya di GUI.
3. **Perbaiki Alur `DryRun` & `Undo`**:
   - Pastikan status `Moved (DryRun)` dicatat sebagai `[INFO] [DRY-RUN]` di `Logger.psm1` (bukan `[ERROR] Failed:`) dan dihitung sebagai `Skipped` (atau properti `DryRunMoved`) di `Summary.psm1`.
   - Tandai atau hapus file `transaction-*.json` setelah berhasil di-undo, dan jangan gunakan `Move-Item -Force` tanpa pengecekan konflik saat melakukan undo.
4. **Sinkronkan `GUI.psm1`**:
   - Panggil `Logger.psm1` saat GUI mengeksekusi pemindahan file, catat `$startTime` sebelum proses dimulai untuk laporan HTML, dan baca nilai default checkbox dari `$config.Settings`.

### Prioritas 3 — Optimasi Performa, Refactoring & Dokumentasi
1. **Optimasi 10.000 File**:
   - Gunakan `[hashtable]` untuk lookup ekstensi di `Classifier.psm1`.
   - Tulis log secara *batch* di `Write-MoveLog` (`Logger.psm1`).
   - Hapus double increment `$current++` di `Mover.psm1`.
2. **Perbarui Dokumentasi & Unit Tests**:
   - Ganti semua link lokal `file:///c:/Users/zidan/...` di `README.md` menjadi *relative markdown links* (`docs/GUI_GUIDE.md`, dll.).
   - Samakan skema `SmartRules` dan nama properti `Settings` di `docs/CONFIGURATION.md` dengan `config.json`.
   - Tambahkan unit test untuk `-Recurse`, `-IgnorePatterns`, `-DryRun`, karakter `[1]`, dan skenario lintas kategori pada `SmartClassifier`.



## Status verifikasi dan perbaikan 2.2.0 (2026-11-09)

Laporan di atas dipertahankan sebagai catatan historis. Ada **21 subbagian temuan**, bukan 28; jumlah modul implementasi saat audit adalah **16**, dan sesudah penambahan Organizer/Transactions menjadi **18**. Batas panjang fungsi/modul pada style guide adalah rekomendasi.

Contoh yang direproduksi pada kode lama: `project_banner.png` menjadi `Images\Projects`, dan `resume_builder_setup.exe` menjadi `Applications\CV`. Keduanya sekarang tetap pada kategori ekstensi masing-masing tanpa subkategori lintas kategori. Self-renaming saat recursive direproduksi; klaim infinite nesting literal tidak dikonfirmasi secara terpisah. Klaim exploit scheduler tidak diuji dengan menjalankan payload; penghapusan Invoke-Expression dan forwarding argumen literal diverifikasi melalui kode serta mock/integrasi.

| ID | Status / bukti perbaikan |
|---|---|
| 1.1 | Lulus regresi kategori, stem filename, batas kata, frasa, skor seri, dan pipeline input. |
| 1.2 | Lulus pengulangan dan benchmark: 0 file dipindahkan ulang pada eksekusi kedua; scanner tetap recursive dan mengabaikan reparse/operasional. |
| 1.3 | Created/Renamed nyata, debounce, MessageData, forwarding folder/config, dan cleanup lulus pada sandbox. |
| 1.4 | Setting dihubungkan ke pipeline bersama; regresi boolean dan prioritas Verbose/conflict lulus. |
| 1.5 | Duplikat SHA256, file kosong, isi berbeda berukuran sama, dan hash gagal diuji; semua file dipertahankan. |
| 1.6 | CLI/GUI schedule terhubung; unit memakai mock; registrasi task nyata bernama GUID berhasil dan dibersihkan. Kontrol GUI masih perlu smoke interaktif. |
| 1.7 | Status Planned konsisten pada model, log, summary dan laporan; DryRun tanpa kategori/backup/transaksi lulus. |
| 1.8 | CLI dan runspace GUI memakai Invoke-Organizer; default checkbox dan kontrak hasil diuji. Smoke visual GUI masih terbuka. |
| 1.9 | Undo reverse-order, source conflict, partial retry, crash/torn journal, legacy manifest, overwrite dan isi backup lulus. |
| 2.1 | Scheduler memakai ScheduledTasks, executable/argumen terpisah, current user Interactive/Limited; tidak ada Invoke-Expression. |
| 2.2 | Seluruh teks dinamis HTML termasuk kategori dan metrik di-encode; kelas CSS dibatasi; regresi injection lulus. |
| 2.3 | Operasi file literal dan API .NET non-overwriting; nama [1] dan Unicode diuji. |
| 2.4 | Komponen direktori Windows, traversal, tujuan absolut dan junction ditolak; regresi lulus. |
| 2.5 | Launcher meneruskan args, mutex GUI Local, silent worker independen; build fresh-output dan smoke portable lulus. |
| 3.1 | Lookup/pola/reservasi disiapkan per batch, log batch dan StringBuilder HTML diterapkan. Benchmark dicatat; first run lebih lambat karena keselamatan, bukan klaim speedup. |
| 3.2 | Worker STA terpisah, queue/dispatcher timer, penutupan menunggu worker, dan batas 500 baris diterapkan; pengujian visual interaktif masih diperlukan. |
| 3.3 | Manifest agregat 2.2.0 dan import dependensi eksplisit; tanpa Force reimport yang mereset state. |
| 4.1 | Wrapper privat tanpa pemanggil dihapus, summary menjadi teks terformat, XAML dipisah, LF diatur; batas panjang tetap rekomendasi. |
| 4.2 | Orkestrasi/summary/status dipakai bersama; helper presentasi digunakan tanpa menambah dependensi model. |
| 4.3 | Pester dipin 5.7.1, BeforeAll, sandbox fixtures, mock scheduler, assertion integration dan CI dua engine; 104 test lulus lokal di masing-masing engine. |
| 4.4 | README, konfigurasi, PRD, arsitektur, GUI/build/testing/development, roadmap dan konteks diperbarui. Coverage terukur 79,15%; changelog lama dipertahankan. |

Angka benchmark, batas pengukuran, dan gate rilis yang belum selesai ada di [RELEASE.md](RELEASE.md). Paket tetap unreleased sampai pemeriksaan GUI interaktif dan peninjauan CI remote selesai. Backup overwrite membutuhkan penyimpanan; statistik log DryRun lama yang ambigu tidak diperbaiki otomatis.
