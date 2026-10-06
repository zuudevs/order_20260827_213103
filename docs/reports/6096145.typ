#set page(
	paper: "a4",
	margin: (top: 2.5cm, bottom: 2.5cm, left: 3cm, right: 2.5cm),
)

#set text(
	font: "Times New Roman",
	size: 12pt,
)

#set par(
	justify: true,
	leading: 0.65em,
)

#let REPORSITORY_BASE_URL = "https://github.com/zuudevs/order_20260827_213103"

= Laporan Progress

== Implementasi Pixel-Domain Watermark dan Pengujian Robustness terhadap Neural Codec

*Snapshot*: 2026-10-04 11:45:20 UTC\
*Notebook*: #link(REPORSITORY_BASE_URL + "/blob/main/src/main.ipynb")[main.ipynb]\
*Commit Hash*: `6096145325dda8511eb3dda5c243602030b27c98`

== 1. Ringkasan

Implementasi pada notebook menggunakan pendekatan *pixel-domain watermarking*. Payload yang digunakan adalah teks `"sabila"` yang dikonversi menjadi 48 bit.

Watermark tidak ditanam menggunakan neural watermark encoder maupun latent representation. Neural Codec digunakan setelah proses embedding untuk menguji apakah watermark masih dapat diekstraksi dari frame hasil rekonstruksi.

Alur yang digunakan pada notebook adalah:

#align(center)[

#image("../../assets/001-6096145.png", width: 17%)
]

*Bukti Requirement:*

Notebook secara eksplisit menyatakan bahwa watermark ditanam langsung pada nilai pixel, sedangkan `bmshj2018-hyperprior` digunakan untuk proses compression/reconstruction.

Bukti source:

```text
src/main.ipynb
- payload "sabila"
- pixel-domain watermark embedding
- Neural Codec bmshj2018-hyperprior
- extraction dari reconstructed frame
```

== 2. Payload Watermark

Payload yang digunakan:

```text
sabila
```

Enam karakter ASCII menghasilkan:

```text
6 byte x 8 bit = 48 bit
```

Representasi bit:

#align(center)[
#table(
		columns: 6,
		align: center,
		[01110011], [01100001], [01100010],
		[01101001], [01101100], [01100001],
		[s], [a], [b],
		[i], [l], [a],
	)
]

Notebook menetapkan:

```python
PAYLOAD_TEXT = 'sabila'
```

dan:

```python
GRID, CELL = (6, 8), 8
```

Sehingga:

```text
6 x 8 = 48 block
```

dan satu block digunakan untuk satu bit payload.
#pagebreak()
== 3. Konfigurasi Pixel-Domain Watermark

Notebook menggunakan parameter:

#align(center)[
	#table(
		columns: 2,
		align: (left, left),
		[Parameter], [Nilai],
		[Payload], [`sabila`],
		[Payload size], [48 bit],
		[Grid], [6 x 8],
		[Jumlah block], [48],
		[Pattern cell], [8 x 8 pixel],
		[Embedding strength], [6],
		[Key], [2024],
	)
]

Pattern watermark dibuat berdasarkan informasi key, frame index, dan bit index.

Embedding dilakukan langsung terhadap pixel.

Source notebook juga melakukan pemeriksaan terhadap perubahan pixel dengan menghitung:

```bash
pixel_before_rgb
pixel_after_rgb
pixel_diff_rgb
mean_rgb_before
mean_rgb_after
mean_abs_diff
```

Dengan demikian, notebook tidak hanya menyimpan frame hasil embedding, tetapi juga menyediakan data yang dapat digunakan untuk mengaudit perubahan pixel.

== 4. Bukti Mapping Payload ke Pixel

Bagian ini merupakan salah satu bukti penting yang sebelumnya belum saya jelaskan dengan benar.

Notebook memiliki fungsi:

```python
payload_mapping_table(H, W, bits_read=None, scores=None)
```

Fungsi tersebut digunakan untuk membuat tabel hubungan:

#align(center)[
	#image("../../assets/002-6096145.png")
]

Notebook kemudian membuat:

```python
df_map = payload_mapping_table(
    H_v,
    W_v,
    bits_dec_v,
    score_dec_v
)
```

dan menyimpan hasil mapping ke:

```bash
payload_mapping_<video>.csv
```

Notebook juga melakukan assertion:

```python
assert all(chk_m.values()),
       'mapping tidak identik dengan hasil embedding'
```

Artinya, klaim bahwa notebook mempunyai mekanisme mapping payload → block → hasil extraction bukan asumsi laporan.

== 5. Bukti Audit Pixel

Notebook menyediakan audit pixel pada setiap block.

Data yang direkam mencakup:

```bash
block
box_y0y1x0x1
bit
pixel_before_rgb
pixel_after_rgb
pixel_diff_rgb
mean_rgb_before
mean_rgb_after
mean_abs_diff
correlation_score
decoded_bit
```

Contoh struktur audit:

#align(center)[
	#image("../../assets/003-6096145.png", width: 15%)
]

Notebook juga menghitung apakah perubahan pixel aktual sesuai dengan formula embedding.

Pemeriksaan yang digunakan mencakup:

```text
Delta aktual == rumus
STRENGTH x (2b - 1) x pattern
```

dengan clipping pixel 0-255 diperhitungkan.

Notebook kemudian melakukan pemeriksaan bahwa bit yang tertanam sesuai dengan payload pada:

```text
48/48 block
```

Ini merupakan bukti programatik bahwa payload memang dipetakan dan diperiksa pada domain pixel.

== 6. Visualisasi Watermark

Notebook juga memiliki visualisasi khusus untuk audit watermark.

Visualisasi tersebut membuat layout 2 x 2 dan menampilkan:

```text
Frame Asli
Frame Setelah Watermark
Pixel Difference
Informasi extraction / audit
```

Frame watermarked juga diberi label block:

```text
nomor blok : bit
```

Contoh konsep label:

```text
0:1
1:0
2:1
...
47:0
```

Notebook menggunakan grid untuk memperlihatkan posisi masing-masing bit pada frame.

Dengan demikian, klaim bahwa notebook memiliki visualisasi mapping watermark memang didukung oleh source.
#pagebreak()
== 7. Bukti Neural Codec

Notebook menggunakan:

```text
bmshj2018-hyperprior
```

dengan:

```text
quality = 3
pretrained = True
frozen = True
eval mode
```

Notebook secara eksplisit menjelaskan bahwa:

```python
codec.compress()
```

menghasilkan:

```text
strings + shape
```

dan bahwa `strings` diperlakukan sebagai:

```text
compressed representation / bitstream
```

Notebook kemudian menjalankan:

```python
codec.decompress(
    enc['strings'],
    enc['shape']
)
```

dan mengambil:

```python
['x_hat']
```

sebagai reconstructed frame.

Alur aktual yang terdapat di source adalah:

#align(center)[
	#image("../../assets/004-6096145.png")
]

Ini adalah bukti yang lebih kuat daripada sekadar menyebut nama model karena notebook memang memanggil fungsi compression dan decompression.

== 8. Bukti Compressed Representation

Notebook menghitung compressed representation dari seluruh bagian `strings`.

Source notebook secara eksplisit menjalankan konsep:

```python
enc = codec.compress(x)

total += compressed_bytes(
    enc['strings']
)
```

`compressed_bytes()` menghitung byte dari compressed representation.

BPP kemudian dihitung berdasarkan total compressed bytes dan jumlah pixel frame.

Notebook juga menyimpan metadata compressed representation dan hash untuk kebutuhan audit.

Namun, penting dibedakan:

*Source notebook membuktikan bahwa pengukuran compressed representation diimplementasikan.*

Nilai hasil eksperimen hanya boleh dicantumkan apabila output run yang menghasilkan nilai tersebut tersedia sebagai bukti.

== 9. Extraction dari Reconstructed Frame

Notebook tidak melakukan extraction langsung dari frame asli.

Source menggunakan:

```python
codec.decompress(
    enc['strings'],
    enc['shape']
)['x_hat']
```

untuk memperoleh reconstructed frame.

Reconstructed frame tersebut kemudian menjadi input extraction.

Dengan demikian jalur pengujian adalah:

#align(center)[
	#image("../../assets/005-6096145.png")
]

== 10. Statistical Detection

Notebook menggunakan detection berdasarkan kecocokan bit.

Payload terdiri dari:

```text
48 bit
```

dan detection menggunakan hipotesis:

```python
P(bit cocok) = 0.5
```

Notebook menetapkan false-alarm probability:

```python
P_FALSE_ALARM = 1e-4
```

serta menentukan minimum match berdasarkan distribusi binomial.

== 11. False Positive Test

Notebook memiliki bagian khusus:

```text
False Positive Control
```

Deskripsinya menyatakan bahwa frame asli tanpa watermark melewati:

#align(center)[
	#image("../../assets/006-6096145.png")
]

Tujuan pengujian adalah memeriksa apakah extractor mendeteksi `"sabila"` pada frame yang sebenarnya tidak pernah diberi watermark.

Namun, *hasil angka false-positive tidak saya nyatakan sebagai hasil runtime yang telah diverifikasi langsung dari output notebook dalam laporan ini.*

Nilai `0/30` atau `0.00%` hanya boleh dimasukkan jika output run yang bersangkutan dapat ditunjukkan kembali.

== 12. Strength Sweep dan Imperceptibility

Notebook memiliki bagian khusus untuk:

```text
audit & imperceptibility
```

dan menyediakan proses *strength sweep*.

Source membuat artifact:

```text
strength_sweep_s<strength>.json
```

serta:

```bash
strength_sweep_<RUN_ID>.csv
```

Data strength sweep mencatat antara lain:

```text
strength
video
ber
bit_accuracy
detection_status
detection_p_value
psnr_codec_db
bpp
```

Dengan demikian, notebook memang sudah dirancang untuk mengevaluasi hubungan antara embedding strength dan kemampuan detection. Namun *Saya tidak akan menyimpulkan bahwa strength tertentu sudah optimal atau watermark sudah "tak kasat mata" tanpa melihat hasil sweep tersebut.*

Nilai PSNR saja juga tidak cukup untuk menyatakan watermark benar-benar imperceptible secara visual.

== 13. Visualisasi Empat Panel

Notebook juga memiliki visualisasi akhir 2 x 2.

Source menampilkan:

```python
ORIGINAL FRAME
```

```python
WATERMARKED FRAME
```

```python
NEURAL CODEC RECONSTRUCTED FRAME
```

serta panel keempat untuk hasil watermark/detection.

Pada panel Neural Codec, source juga menampilkan informasi:

```text
Codec
Quality
Compressed bytes
```

Sementara frame watermarked menampilkan:

```python
PSNR
SSIM
STRENGTH
KEY
```

Dengan demikian, klaim bahwa notebook sudah memiliki konsep final 4-panel visualization memang didukung oleh source.

== 14. Hasil Numerik yang Tercatat

Repository memiliki laporan eksperimen sebelumnya #link(REPORSITORY_BASE_URL + "/blob/main/docs/reports/d94c2d5.typ")[d94c2d5.typ]

Laporan tersebut mencatat hasil:

#align(center)[
	#table(
		columns: 2,
		align: (left, right),
		[Metric], [Nilai yang tercatat],
		[Jumlah video], [30],
		[Mean BER], [0.0076],
		[Mean Bit Accuracy], [99.24%],
		[Detection], [30/30],
		[Mean PSNR Watermark], [32.89 dB],
		[Mean PSNR Codec], [29.04 dB],
		[Mean BPP], [0.297],
		[False Positive], [0/30],
	)
]

Nilai-nilai tersebut *bukan saya klaim sebagai hasil runtime baru yang saya eksekusi sekarang*. Statusnya adalah #link(REPORSITORY_BASE_URL + "/blob/main/docs/reports/d94c2d5.typ")[d94c2d5.typ] Laporan tersebut menyatakan bahwa nilai tersebut berasal dari eksekusi eksperimen sebelumnya. Karena itu, untuk laporan final, angka-angka tersebut harus dianggap sebagai *hasil snapshot eksperimen yang tercatat di repository*, bukan sebagai hasil eksperimen baru yang diverifikasi ulang dalam sesi ini.

== 15. Bukti yang Dapat Dipertanggungjawabkan

#align(center)[
	#table(
		columns: 3,
		align: (left, center, left),
		[Pernyataan], [Status], [Bukti],
		[Payload `"sabila"` = 48 bit], [TERBUKTI], [`PAYLOAD_TEXT`, payload conversion],
		[Grid 6 x 8], [TERBUKTI], [`GRID, CELL = (6, 8), 8`],
		[Pixel-domain embedding], [TERBUKTI], [Source embedding function],
		[Pixel before/after audit], [TERBUKTI], [`pixel_before_rgb`, `pixel_after_rgb`],
		[Pixel delta audit], [TERBUKTI], [`pixel_diff_rgb`, `mean_abs_diff`],
		[Payload mapping], [TERBUKTI], [`payload_mapping_table()`],
		[48/48 block validation], [TERBUKTI], [Assertion/check pada notebook],
		[`bmshj2018-hyperprior`], [TERBUKTI], [Codec initialization],
		[`codec.compress()`], [TERBUKTI], [Source `codec.compress(x)`],
		[`codec.decompress()`], [TERBUKTI], [Source `codec.decompress(...)`],
		[Extraction reconstructed frame], [TERBUKTI], [`x_hat` → extraction],
		[False-positive test exists], [TERBUKTI], [Cell/section `False Positive Control`],
		[Strength sweep exists], [TERBUKTI], [`strength_sweep_*.csv/json`],
		[4-panel visualization exists], [TERBUKTI], [Source `plt.subplots(2, 2)`],
		[Mean BER = 0.0076], [TERCATAT], [`docs/reports/d94c2d5.typ`],
		[Bit Accuracy = 99.24%], [TERCATAT], [`docs/reports/d94c2d5.typ`],
		[Detection 30/30], [TERCATAT], [`docs/reports/d94c2d5.typ`],
		[PSNR watermark = 32.89 dB], [TERCATAT], [`docs/reports/d94c2d5.typ`],
		[PSNR codec = 29.04 dB], [TERCATAT], [`docs/reports/d94c2d5.typ`],
		[BPP = 0.297], [TERCATAT], [`docs/reports/d94c2d5.typ`],
		[False positive = 0/30], [TERCATAT], [`docs/reports/d94c2d5.typ`],
		[Strength terbaik], [BELUM DIBUKTIKAN], [Output sweep belum dijadikan bukti di laporan],
		[Watermark benar-benar imperceptible], [BELUM DIBUKTIKAN], [Perlu evaluasi visual + sweep],
	)
]

== 16. Kesimpulan

Berdasarkan pemeriksaan terhadap source `src/main.ipynb`, implementasi berikut dapat dinyatakan telah terbukti secara programatik:

+ payload `"sabila"` digunakan sebagai payload watermark;
+ payload direpresentasikan sebagai 48 bit;
+ 48 bit dipetakan ke grid 6 x 8;
+ watermark ditanam langsung pada domain pixel;
+ perubahan pixel dapat diaudit;
+ mapping payload ke block dapat diaudit;
+ bit hasil embedding diperiksa terhadap payload;
+ Neural Codec `bmshj2018-hyperprior` digunakan;
+ `codec.compress()` digunakan untuk menghasilkan compressed representation;
+ `codec.decompress()` digunakan untuk menghasilkan reconstructed frame;
+ extraction dilakukan terhadap reconstructed frame;
+ false-positive test tersedia;
+ strength sweep tersedia;
+ visualisasi original, watermarked, reconstructed, dan detection tersedia.

Dengan demikian, *implementasi inti pipeline sudah memiliki bukti source yang jelas.*

Namun, laporan tidak boleh menyamakan keberadaan kode dengan keberhasilan hasil eksperimen. Oleh karena itu *Hasil numerik seperti BER 0.0076, Bit Accuracy 99.24%, detection 30/30, PSNR 32.89 dB, PSNR 29.04 dB, BPP 0.297, dan false-positive 0/30 hanya dicantumkan sebagai hasil yang tercatat pada `docs/reports/d94c2d5.typ`.*

Nilai tersebut tidak dinyatakan sebagai hasil runtime baru yang telah diverifikasi ulang dalam penyusunan laporan ini.

Selain itu, *belum ada dasar yang cukup untuk menyatakan bahwa watermark sudah benar-benar tidak kasat mata bagi manusia hanya berdasarkan source code atau satu nilai PSNR.*

Untuk menyatakan klaim tersebut secara sahih, laporan final harus menyertakan output *strength sweep* dan bukti visual original-versus-watermarked pada konfigurasi strength yang dipilih.

== 17. Batasan Laporan

Laporan ini sengaja tidak mencantumkan:

* nilai metric per-video yang tidak terlihat pada bukti source yang tersedia;
* nilai strength terbaik;
* klaim bahwa watermark sudah sepenuhnya imperceptible;
* klaim bahwa seluruh output runtime terbaru sudah diverifikasi ulang;
* klaim perbandingan dengan codec lain;
* klaim robustness terhadap codec selain `bmshj2018-hyperprior`.

Hal tersebut dihilangkan agar laporan tidak mengandung hasil eksperimen yang tidak dapat ditelusuri kembali ke bukti.

== 18. Daftar Bukti Repository

Bukti utama yang digunakan dalam penyusunan laporan #link(REPORSITORY_BASE_URL + "/blob/main/src/main.ipynb")[main.ipynb] Memuat implementasi pipeline, codec, extraction, payload mapping, pixel audit, false-positive test, strength sweep, dan visualisasi.

#link(REPORSITORY_BASE_URL + "/blob/main/docs/reports/d94c2d5.typ")[d94c2d5.typ] memuat snapshot hasil eksperimen numerik yang sebelumnya telah dilaporkan. #link(REPORSITORY_BASE_URL + "/blob/main/mermaids/001-pipeline.mmd")[001-pipeline.mmd] memuat alur payload -> pixel-domain watermark -> Neural Codec.

```text
mermaids/002-pipeline-codec.mmd
```

Memuat alur:

codec.compress()
→ strings + shape
→ codec.decompress()
→ reconstructed frame

```text
docs/architecture.md
```

Memuat batasan dan arsitektur penelitian, termasuk penggunaan pixel-domain watermarking dan `bmshj2018-hyperprior`.
