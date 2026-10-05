= Laporan Progress

== Implementasi Pixel-Domain Watermark dan Pengujian Robustness terhadap Neural Codec

*Snapshot*: 2026-10-04 11:45:20 UTC

*Notebook*: #link("https://github.com/zuudevs/order_20260827_213103/blob/refactor/pixel-watermark-neural-codec/src/main.ipynb")[src/main.ipynb - refactor/pixel-watermark-neural-codec]

=== Ringkasan Singkat

Progress implementasi pipeline watermark telah selesai dan berhasil dieksekusi pada 30 video dataset.

Pipeline yang diimplementasikan mengikuti alur:

#align(center)[
	#image("../../assets/001-pipeline.png", width: 15%)
]

Implementasi menggunakan payload teks `"sabila"` dengan panjang 6 byte atau 48 bit. Watermark ditanam langsung pada nilai pixel dan tidak menggunakan neural watermark encoder/decoder, training, latent watermarking, maupun error-correcting code.

Neural Codec hanya digunakan sebagai penguji robustness terhadap proses kompresi dan rekonstruksi. Model yang digunakan adalah `bmshj2018-hyperprior` dari CompressAI, pretrained, frozen, dan dijalankan pada mode evaluation.

Hasil eksperimen menunjukkan:

+ 30 video berhasil diproses.
+ 30/30 video berhasil melalui pipeline watermark → Neural Codec → extraction.
+ Rata-rata BER = *0.0076*.
+ Rata-rata Bit Accuracy = *99.24%*.
+ Detection berhasil pada *30/30 video (100%)*.
+ Rata-rata PSNR watermark = *32.89 dB*.
+ Rata-rata PSNR setelah Neural Codec = *29.04 dB*.
+ Rata-rata bitrate compressed representation = *0.297 bpp*.
+ False Positive Rate = *0/30 = 0.00%*.
+ Final checkpoint berhasil mencapai status *COMPLETED*.

Dengan demikian, target utama implementasi dan pengujian pipeline telah berhasil dicapai berdasarkan hasil eksekusi notebook.

=== Hasil Analisa Progress

==== 1. Konfigurasi eksperimen berhasil ditetapkan

Konfigurasi utama pipeline ditetapkan secara eksplisit pada Cell 6.

Parameter yang digunakan:

+ Payload: `"sabila"`
+ Payload length: 48 bit
+ Frame size: `192 x 256`
+ Grid watermark: `6 x 8`
+ Jumlah blok: 48
+ Ukuran setiap blok: `32 x 32` pixel
+ Pattern cell: `8 x 8` pixel
+ Embedding strength: `6`
+ Key: `2024`
+ Neural Codec: `bmshj2018-hyperprior`
+ Codec quality: `3`
+ Codec batch: `16`
+ False-alarm threshold: `1e-4`
+ Random seed: `42`
+ Maximum video: `30`
+ Quick test: `False`

Cell 6 juga menghasilkan konfigurasi run:

```text
Device: cuda
RUN_ID    : 20261004_114520_c59f17
RUN_DIR   : /content/drive/MyDrive/order_20260827_213103/output/20261004_114520_c59f17
Checkpoint: /content/drive/MyDrive/order_20260827_213103/checkpoints/20261004_114520_c59f17
```

Hal ini membuktikan bahwa eksperimen menggunakan GPU CUDA dan setiap eksperimen memiliki `run_id` tersendiri.

==== 2. Payload 48-bit berhasil divalidasi

Cell 14 melakukan konversi payload menjadi 48 bit:
#align(center)[
	#table(
		columns: 6,
		align: center,
		[01110011], [01100001], [01100010], [01101001], [01101100], [01100001],
		[s], [a], [b], [i], [l], [a]
	)
]

Notebook juga melakukan assertion bahwa:

+ panjang payload = 48 bit;
+ jumlah blok = 48;
+ representasi bit sesuai dengan payload;
+ proses inverse decoding menghasilkan kembali `"sabila"`.

Output aktual:

```text
Watermark asli : "sabila"
Payload (48 bit): 01110011 01100001 01100010 01101001 01101100 01100001
```

Hal ini memvalidasi bahwa payload yang digunakan pada eksperimen adalah tepat 48 bit dan tidak menggunakan repetition/ECC.

==== 3. Watermark benar-benar ditanam pada domain pixel

Cell 16 mengimplementasikan generator pattern dan embedding pixel-domain.

Pattern dibangkitkan secara deterministik berdasarkan:

```text
(KEY, frame_index, bit_index)
```

sehingga hasil pattern tidak bergantung pada state random global.

Formula embedding yang digunakan adalah:

```python
I'(x,y) = clip(
	I(x,y) + STRENGTH * (2b - 1) * P(x,y),
	0,
	255
)
```

Dengan:

```text
STRENGTH = 6
KEY      = 2024
```

Grid watermark menggunakan 6 x 8 blok sehingga terdapat 48 posisi bit.

Cell 17 kemudian menjalankan embedding terhadap seluruh video.

Hasil:

```bash
30 video ber-watermark tersedia di
/content/drive/MyDrive/order_20260827_213103/output/
20261004_114520_c59f17/watermarked
```

Hal ini menunjukkan bahwa proses embedding berhasil menghasilkan artifact watermarked untuk seluruh 30 video.

==== 4. Validasi independen watermark berhasil 100%

Validasi lebih lanjut dilakukan pada Cell 29.

Untuk setiap frame, notebook melakukan validasi independen terhadap:

* jumlah blok;
* posisi blok;
* urutan bit;
* payload;
* frame yang diproses;
* jumlah total bit yang ditanam.

Contoh video pertama:

```bash
Video:
v_CricketShot_g01_c01.avi

Jumlah frame: 84
Payload: sabila (48 bit)
Grid: 6 x 8

Total bit ditanam: 4032
Harapan: 4032
```

Validasi lima frame pertama:

```bash
Frame 0 -> 48/48 bit sesuai
Frame 1 -> 48/48 bit sesuai
Frame 2 -> 48/48 bit sesuai
Frame 3 -> 48/48 bit sesuai
Frame 4 -> 48/48 bit sesuai
```

Seluruh check juga menghasilkan:

```bash
[OK] Setiap frame punya 48 blok
[OK] Posisi blok sama di tiap frame
[OK] Urutan bit b0 -> b47 (row-major)
[OK] Payload tiap frame = payload asli
[OK] Tidak ada frame terlewat
[OK] Total bit ditanam = frame x 48
```

Validasi dilakukan terhadap seluruh 30 video. Output akhir menunjukkan seluruh video memiliki:

```text
all_checks = OK
```

Contoh:
#align(center)[
	#table(
		columns: 5,
		align: (left, right, right, right, left),
		[Video], [Frames], [Bits Planted], [Frames OK], [Check],
		[`v_CricketShot_g01_c01.avi`], [84], [4032], [84], [OK],
		[`v_CricketShot_g01_c02 (1).avi`], [91], [4368], [91], [OK],
		[`v_CricketShot_g01_c03.avi`], [95], [4560], [95], [OK],
		[`v_CricketShot_g02_c01.avi`], [100], [4800], [100], [OK],
		[`v_CricketShot_g03_c04.avi`], [100], [4800], [100], [OK],
		[`v_CricketShot_g04_c03.avi`], [99], [4752], [99], [OK],
		[`v_CricketShot_g05_c01.avi`], [56], [2688], [56], [OK]
	)
]

Seluruh 30 video memiliki `frames_ok == frames` dan `all_checks == OK`.

Dengan demikian, implementasi embedding tidak hanya menghasilkan file output, tetapi juga telah diverifikasi bahwa payload benar-benar ditempatkan pada setiap frame dengan struktur 48 blok yang konsisten.

==== 5. Neural Codec berhasil dijalankan sesuai spesifikasi

Cell 9 menginisialisasi:

```text
bmshj2018-hyperprior
quality = 3
pretrained = True
frozen = True
eval mode
```

Seluruh parameter model diatur:

```python
p.requires_grad_(False)
```

sehingga tidak ada training atau optimisasi watermark pada tahap ini.

Pipeline codec menggunakan:

#align(center)[
	#image("../../assets/002-pipeline-codec.png", width: 90%)
]

Notebook secara eksplisit memperlakukan `strings` sebagai compressed representation/bitstream dan bukan latent.

Cell 19 kemudian menjalankan proses tersebut terhadap seluruh 30 video.

Output:

```text
Neural Codec (ber-watermark): ... 30/30
bpp rata-rata: 0.297
```

Hal ini memvalidasi bahwa seluruh 30 video berhasil melewati proses kompresi dan rekonstruksi.

==== 6. Compressed representation berhasil diukur

Cell 9 menghitung ukuran compressed representation dengan menjumlahkan seluruh byte pada semua bagian `strings`, bukan hanya jumlah elemen container.

Metadata yang disimpan mencakup:

+ compressed byte size;
+ BPP;
+ shape;
+ SHA-256 compressed representation.

Cell 19 kemudian menghasilkan rata-rata:

```text
BPP = 0.297
```

Contoh audit pada Cell 29:

```text
Video contoh   : v_CricketShot_g01_c01.avi
Compressed repr: 147072 byte (0.285 bpp)
```

Dengan demikian ukuran compressed representation dapat diaudit per video.

==== 7. Extraction dilakukan dari reconstructed frame

Cell 21 secara eksplisit mengambil artifact:

```python
reconstructed
```

bukan frame asli atau watermarked frame.

Extraction dilakukan dengan:

1. membagi frame menjadi 6 x 8 blok;
2. menghitung korelasi pixel dengan pattern ±1;
3. merata-ratakan score;
4. menentukan bit berdasarkan:

```text
score > 0 -> 1
score <= 0 -> 0
```

Cell 21 selesai melakukan extraction untuk seluruh 30 video.

Hal ini memvalidasi bahwa target utama robustness test benar-benar diuji melalui jalur:

```text
watermarked frame
→ Neural Codec
→ reconstructed frame
→ watermark extraction
```

dan bukan melalui frame sebelum kompresi.

==== 8. Statistical detection berhasil memenuhi threshold

Cell 23 menetapkan pengujian statistik dengan:

```bash
H0:
P(bit cocok) = 0.5
```

Jumlah bit:

```bash
n = 48
```

Threshold:

```bash
p <= 1e-4
```

Hasil perhitungan menentukan bahwa minimal diperlukan:

```bash
38/48 bit cocok
```

agar watermark dianggap terdeteksi.

Output aktual:

```bash
DETECTED jika bit cocok >= 38/48
BER <= 0.208
H0: P(bit cocok) = 0.5
p <= 0.0001
```

Ini memberikan kriteria deteksi yang eksplisit dan dapat direproduksi.

==== 9. Robustness terhadap Neural Codec berhasil

Hasil agregat pada Cell 27:

```bash
Rata-rata:
BER          = 0.0076
Bit Accuracy = 0.9924
PSNR_WM      = 32.89 dB
PSNR_Codec   = 29.04 dB
BPP          = 0.297
DETECTED     = 30/30
```

Dengan demikian:

+ BER rata-rata sekitar *0.76%*;
+ Bit Accuracy rata-rata sekitar *99.24%*;
+ seluruh 30 video tetap terdeteksi setelah melewati Neural Codec;
+ rata-rata bitrate compressed representation adalah 0.297 bpp.

Hasil ini merupakan bukti utama bahwa watermark pixel-domain yang ditanam berhasil dipertahankan setelah proses `compress()` dan `decompress()` pada Neural Codec yang digunakan.

==== 10. False Positive Control berhasil

Cell 25 menjalankan pengujian terpisah menggunakan frame asli tanpa watermark.

Jalur pengujian:

```text
Original frame
    ↓
Neural Codec compress()
    ↓
Neural Codec decompress()
    ↓
Pixel watermark extraction
    ↓
Detection
```

Tidak ada watermark yang ditanam pada input pengujian ini.

Hasil aktual:

```text
False positive rate: 0.00%
(0/30 video asli salah terdeteksi "sabila")
```

Artinya dari 30 video tanpa watermark, tidak ada satupun yang memenuhi kriteria statistical detection.

Ini merupakan validasi penting karena keberhasilan detection pada data ber-watermark tidak cukup apabila extractor juga sering mendeteksi watermark pada data yang tidak memiliki watermark.

==== 11. Metrics dan manifest berhasil dipersist

Cell 27 menghasilkan tiga artifact utama:

```bash
metrics_20261004_114520_c59f17.csv
metrics_fp_20261004_114520_c59f17.csv
manifest_20261004_114520_c59f17.json
```

Manifest menyimpan:

+ run ID
+ payload
+ payload bits
+ dataset
+ embedding configuration
+ codec configuration
+ frame configuration
+ detection configuration
+ summary metrics
+ output directories
+ output files
+ checkpoint files
+ timestamp.

Sebelum checkpoint dinaikkan ke `EVALUATED`, notebook membaca kembali CSV dan JSON untuk memastikan hasil benar-benar telah ditulis dan dapat dibaca.

==== 12. Checkpoint dan artifact validation berhasil

Notebook menggunakan beberapa checkpoint:

```text
run
frames
embed
codec
false_positive
```

Checkpoint hanya dinaikkan setelah artifact berhasil ditulis dan diverifikasi.

Cell 30 melakukan validasi akhir:

+ semua artifact wajib tersedia;
+ seluruh checkpoint mencakup semua video;
+ setiap artifact lolos `verify_entry`;
+ jumlah hasil evaluasi sesuai jumlah video;
+ jumlah false-positive result sesuai jumlah video;
+ pipeline telah mencapai minimal `EVALUATED`.

Setelah seluruh assertion berhasil, checkpoint dinaikkan menjadi:

```text
COMPLETED
```

Output aktual Cell 30:

```bash
Run 20261004_114520_c59f17 COMPLETED (30 video)
```

Ini menjadi bukti akhir bahwa keseluruhan pipeline berhasil diselesaikan tanpa artifact wajib yang hilang atau tidak valid.

=== Bukti Analisa Progress

==== Rekap bukti berdasarkan cell
#align(center)[
	#table(
		columns: 3,
		align: (left, right, left),
		[Target], [Cell], [Bukti],
		[Konfigurasi eksperimen], [6], [`sabila`, 48 bit, grid 6x8, strength 6, key 2024, codec q3],
		[GPU / run isolation], [6], [`Device: cuda`, `RUN_ID=20261004_114520_c59f17`],
		[Neural Codec], [9], [`bmshj2018-hyperprior`, pretrained, frozen, eval],
		[Frame extraction], [12], [30 video berhasil diekstrak],
		[Payload validation], [14], [`"sabila"` → 48 bit],
		[Pattern + embedding], [16], [deterministic pixel-domain embedding],
		[Watermark artifacts], [17], [30 video ber-watermark],
		[Codec compression/reconstruction], [19], [30/30 video, mean 0.297 bpp],
		[Pixel extraction], [21], [extraction dari reconstructed frame],
		[Detection criteria], [23], [threshold 38/48, p ≤ 1e-4],
		[False positive], [25], [0/30 false positive],
		[Final metrics], [27], [BER 0.0076, accuracy 0.9924, detection 30/30],
		[Watermark audit], [29], [seluruh 30 video `all_checks=OK`],
		[Final completion], [30], [`COMPLETED (30 video)`]		
	)
]

==== Ringkasan hasil kuantitatif
#align(center)[
	#table(
		columns: 2,
		align: (left, left),
		[Metric], [Hasil],
		[Jumlah video], [30],
		[Payload], [`sabila`],
		[Payload size], [48 bit],
		[Detection threshold], [38/48 bit],
		[Statistical threshold], [p <= 1e-4],
		[Mean BER], [0.0076],
		[Mean Bit Accuracy], [0.9924 / 99.24%],
		[Detection], [30/30 / 100%],
		[Mean PSNR watermark], [32.89 dB],
		[Mean PSNR codec], [29.04 dB],
		[Mean BPP], [0.297],
		[False Positive], [0/30 / 0.00%],
		[Final pipeline status], [`COMPLETED`]
	)
]

==== Bukti audit watermark

Audit Cell 29 menggunakan video:

```bash
v_CricketShot_g01_c01.avi
```

dengan:

```bash
84 frames
48 bit/frame
4032 bit total
```

Hasil validasi:

```bash
Frame 0 -> 48/48 bit sesuai
Frame 1 -> 48/48 bit sesuai
Frame 2 -> 48/48 bit sesuai
Frame 3 -> 48/48 bit sesuai
Frame 4 -> 48/48 bit sesuai
```

Seluruh check:

```bash
[OK] Setiap frame punya 48 blok
[OK] Posisi blok sama di tiap frame
[OK] Urutan bit b0 -> b47
[OK] Payload tiap frame = payload asli
[OK] Tidak ada frame terlewat
[OK] Total bit ditanam = frame x 48
```

Audit juga menunjukkan payload yang diekstrak pada reconstructed frame kembali menjadi:

```bash
01110011 01100001 01100010 01101001 01101100 01100001
```

atau:

```bash
"sabila"
```

Hal ini memberikan bukti end-to-end pada satu video bahwa payload yang ditanam dapat dibaca kembali setelah proses Neural Codec.

=== Kesimpulan Progress

Implementasi target telah berhasil diselesaikan dan divalidasi melalui eksekusi notebook.

Target utama yang berhasil dibuktikan adalah:

#set page(numbering: "1.")

+ Payload `"sabila"` berhasil direpresentasikan sebagai 48 bit.
+ Watermark berhasil ditanam langsung pada domain pixel.
+ Pattern watermark bersifat deterministic berdasarkan key, frame index, dan bit index.
+ Watermark berhasil diterapkan pada seluruh 30 video.
+ Setiap frame tervalidasi memiliki 48 blok dan payload yang benar.
+ Watermarked frame berhasil diproses menggunakan `bmshj2018-hyperprior` quality 3.
+ Proses `compress()` dan `decompress()` berhasil diselesaikan untuk seluruh 30 video.
+ Watermark berhasil diekstraksi dari reconstructed frame.
+ Detection berhasil pada 30/30 video.
+ Mean Bit Accuracy mencapai 99.24%.
+ Mean BER hanya 0.76%.
+ False Positive Rate sebesar 0.00% pada 30 video tanpa watermark.
+ BPP compressed representation berhasil diukur dengan rata-rata 0.297.
+ Artifact metrics, manifest, dan checkpoint berhasil dipersist dan diverifikasi.
+ Pipeline mencapai status akhir `COMPLETED`.

Berdasarkan hasil tersebut, implementasi pada snapshot ini dapat dinyatakan *berhasil memenuhi target pipeline pixel-domain watermark + pengujian robustness terhadap Neural Codec*.

=== Catatan

Pengujian ini membuktikan robustness terhadap Neural Codec `bmshj2018-hyperprior` quality 3 yang digunakan pada eksperimen. Hasil tidak dimaksudkan sebagai perbandingan performa antar codec karena versi implementasi ini memang hanya menggunakan satu Neural Codec.

Selain itu, FFV1 yang digunakan pada artifact watermarked hanya berfungsi sebagai format penyimpanan lossless untuk kebutuhan audit/archive dan bukan sebagai codec pembanding eksperimen.
