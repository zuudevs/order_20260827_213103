#set page(
	paper: "a4",
	numbering: "1."
)

#set text(
	font: "Times New Roman",
	size: 12pt
)

= Laporan Progress
#line(length: 100%)
== Runtime Validation Neural Watermarking
#v(1em)
*Snapshot*: 2026-10-02\
*Notebook*: #link("https://github.com/zuudevs/order_20260827_213103/blob/main/src/main.ipynb")[main.ipynb]\
*Commit Hash*: `9e8afed31ebb81c05d4c4c081ac7dd8e99de299e`
#v(1em)
=== Ringkasan Singkat

Notebook berhasil dijalankan pada environment GPU dengan Google Drive sebagai sumber dataset dan penyimpanan hasil eksperimen. Runtime execution mencakup preprocessing 225 video, pembentukan payload teks `"sabila"` menjadi 48-bit, pengulangan ECC sebanyak 3 kali menjadi 144-bit, proses embedding, lossless validation, kompresi H.264, H.265, Neural Codec, ekstraksi watermark, majority-vote ECC, serta evaluasi CACS.

Hasil runtime menunjukkan bahwa Encoder--Decoder berhasil mempertahankan watermark pada kondisi lossless dengan rata-rata BER 0.0000 dan bit accuracy 1.0000. Setelah kompresi, H.264 menghasilkan 224/225 video dengan teks `"sabila"` secara persis dan H.265 menghasilkan 225/225. Neural Codec masih menjadi kondisi yang paling bermasalah karena hanya 7/225 hasil yang dapat dipulihkan menjadi teks `"sabila"` secara persis.

Dengan demikian, pipeline runtime sudah berjalan dan fondasi watermarking telah tervalidasi pada kondisi lossless serta H.264/H.265. Robustness terhadap Neural Codec masih memerlukan investigasi dan peningkatan.

=== Hasil Analisa Progress

+ *Environment dan dataset*
	
	Notebook berhasil menggunakan CUDA/GPU dan menemukan 225 video asli pada dataset. Video diproses dengan ukuran asli 320 x 240 dan frame rate 25 FPS pada data yang ditampilkan.

+ *Payload dan ECC*
	
	Payload yang digunakan adalah teks `"sabila"`. Teks tersebut dikonversi menjadi 48-bit dan kemudian direplikasi sebanyak 3 kali menggunakan repetition code sehingga panjang watermark menjadi 144-bit. Verifikasi konversi dan decoding awal menunjukkan bahwa payload 144-bit dapat dikembalikan menjadi `"sabila"`.

+ *Lossless watermark extraction*
	
	Pada kondisi lossless tanpa kompresi lossy:
	+ Ground truth: `"sabila"`
	+ Rata-rata BER: 0.0000
	+ Rata-rata bit accuracy: 1.0000
	+ Exact text recovery: 225/225 video
	
	Hasil tersebut menunjukkan bahwa jalur Encoder--Decoder dapat membawa watermark dengan benar sebelum diberikan kompresi lossy.

+ *H.264*

	Dari 225 video yang diuji:
  + Exact `"sabila"`: 224/225
  + Exact recovery rate: 99.56%
	
	Sebagian besar hasil ekstraksi H.264 menunjukkan teks `"sabila"` secara persis.

+ *H.265*

  Dari 225 video yang diuji:
  + Exact `"sabila"`: 225/225
  + Exact recovery rate: 100.00%

+ *Neural Codec*

  Dari 225 video yang diuji:
  + Exact `"sabila"`: 7/225
  + Exact recovery rate: 3.11%
  + Rata-rata bit accuracy keseluruhan pada evaluasi kompresi: 0.9175
  + Akurasi salinan ECC pertama: 0.9306
  + Akurasi salinan ECC kedua: 0.9060
  + Akurasi salinan ECC ketiga: 0.9159
  + Exact text recovery melalui majority-vote ECC pada seluruh 675 sampel: 456/675 atau 67.6%
	
	Hasil ini menunjukkan bahwa Neural Codec masih menyebabkan error watermark yang cukup besar dibandingkan H.264 dan H.265.

+ *CACS*

	CACS menggunakan watermark 144-bit dengan target false-positive probability berdasarkan uji binomial sebesar 1e-6. Hasil runtime menetapkan minimum bit cocok sebesar 101/144 dengan ambang BER 0.2986 sebagai dasar status deteksi.

	Detection Accuracy yang tercatat:
  + H.264: 100%
  + H.265: 100%
  + Neural Codec: 83.56%
	
	Nilai detection accuracy CACS tidak disamakan dengan exact text recovery. CACS menentukan status deteksi berdasarkan kesesuaian bit terhadap threshold, sedangkan exact text recovery mensyaratkan hasil decoding menjadi `"sabila"`.
#pagebreak()
=== Bukti Analisa Progress

Bukti runtime utama yang tersedia dari notebook:

#align(center)[
	#table(
		align: (left, right, right, right),
		columns: 4,
		[Metode], [Jumlah Video], [Exact `"sabila"`], [Hasil],
		[Lossless], [225], [225/225], [100.00%],
		[H.264], [225], [224/225], [99.56%],
		[H.265], [225], [225/225], [100.00%],
		[Neural Codec], [225], [7/225], [3.11%],
	)
]

Bukti tambahan:
+ Lossless BER = 0.0000.
+ Lossless bit accuracy = 1.0000.
+ Evaluasi kompresi mencakup 675 sampel, yaitu 225 video x 3 metode.
+ Rata-rata bit accuracy keseluruhan = 0.9175.
+ ECC menggunakan 3 salinan payload 48-bit.
+ CACS menggunakan 144-bit watermark.
+ CACS minimum matching bits = 101/144.
+ CACS derived BER threshold = 0.2986.
+ Detection Accuracy H.264 = 100%.
+ Detection Accuracy H.265 = 100%.
+ Detection Accuracy Neural Codec = 83.56%.
+ Grafik analisis tersimpan pada direktori output Google Drive.
+ Analisis posisi watermark per frame juga berhasil dijalankan pada video yang diuji.

=== Status Progress

#table(
	columns: 2,
	align: (left, left),
	[Komponen], [Status],
	[Notebook runtime execution], [Selesai],
	[GPU/CUDA execution], [Selesai],
	[Dataset 225 video], [Berhasil diproses],
	[Payload `"sabila"`], [Berhasil],
	[ECC 48-bit x 3 = 144-bit], [Berhasil],
	[Lossless extraction], [Berhasil],
	[H.264 extraction], [Berhasil pada 224/225],
	[H.265 extraction], [Berhasil pada 225/225],
	[Neural Codec extraction], [Belum memenuhi hasil exact recovery yang diharapkan],
	[CACS evaluation], [Berhasil dijalankan],
	[Runtime validation keseluruhan], [Berhasil, tetapi masih ada robustness issue]
)

=== Catatan dan Langkah Berikutnya

Hasil runtime menunjukkan bahwa masalah utama saat ini bukan lagi kegagalan dasar Encoder--Decoder pada kondisi lossless. Watermark dapat dipulihkan secara penuh pada 225/225 video dalam kondisi lossless.

Fokus berikutnya adalah Neural Codec. Sebelum melakukan perubahan arsitektur atau training secara spekulatif, perlu dilakukan verifikasi diagnostik setelah fine-tuning V3 untuk memastikan bahwa decoder tidak kembali menggunakan shortcut terhadap payload tetap `"sabila"`. Setelah itu, robustness terhadap Neural Codec dapat dianalisis berdasarkan hasil bit-level dan exact text recovery.

Hasil saat ini belum digunakan untuk menyatakan seluruh target penelitian telah terpenuhi. Target yang belum memiliki bukti runtime lengkap tetap dicatat sebagai belum tervalidasi.

=== Kesimpulan Progress

Runtime execution berhasil dan seluruh pipeline utama dapat dijalankan. Pada kondisi lossless, watermark `"sabila"` berhasil dipulihkan secara tepat pada seluruh 225 video dengan BER 0.0000 dan bit accuracy 1.0000. H.264 menghasilkan exact recovery 224/225 video, sedangkan H.265 menghasilkan 225/225 video.

Neural Codec masih menunjukkan robustness yang jauh lebih rendah, dengan exact recovery `"sabila"` sebesar 7/225 video. Oleh karena itu, tahap berikutnya berfokus pada validasi diagnostik pasca-fine-tuning V3 dan peningkatan robustness Neural Codec sebelum melanjutkan ke klaim pemenuhan target akhir.
