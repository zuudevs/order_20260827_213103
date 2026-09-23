= Hasil Eksperimen

#table(
	columns: 5,
	align: (left, left, center, center, left),
	[Komponen / Eksperimen], [Konfigurasi], [Hasil], [Status], [Kesimpulan],
	[*Dataset split*], [225 video → Train / Val / Test], [157 / 33 / 35], [v], [Sudah ada pemisahan data yang benar],
	[*Training watermark*], [40 video dari Train], [Berhasil training], [v], [Training pipeline berjalan],
	[*Validation*], [15 video Val, payload `sabila`], [Mencapai target], [v], [Validasi pada video unseen berjalan],
	[*Final Test `sabila`*], [35 video Test], [*35/35 = 100%*], [v], [Payload yang sudah dikenal berhasil dideteksi],
	[*Unseen `skrpsi`*], [30 video Test], [*0/30 = 0%*], [x], [Tidak generalisasi ke payload baru],
	[*Unseen `kamera`*], [30 video Test], [*0/30 = 0%*], [x], [Tidak generalisasi ke payload baru],
	[*Unseen `budiar`*], [30 video Test], [*0/30 = 0%*], [x], [Tidak generalisasi ke payload baru],
	[*Stress test*], [Quant level = 4, 20 video], [*20/20 = 100%*], [v], [Sistem masih robust pada kondisi ini],
	[*Retry mechanism*], [Stress test], [*0 retry*], [-], [Fungsi ada, tetapi belum terbukti membantu],
	[*CRF H.264*], [CRF 23–46, 15 video], [*100% legible*], [v], [Payload `sabila` tetap terbaca pada seluruh CRF yang diuji],
	[*CRF H.265*], [CRF 23–46, 15 video], [*100% legible*], [v], [Payload `sabila` tetap terbaca pada seluruh CRF yang diuji],
	[*Neural Codec*], [Quant level = 16], [Berhasil rekonstruksi], [-], [Pipeline berjalan, tetapi belum bisa disebut kompresi efisien],
	[*Compression efficiency*], [Neural Codec vs H.264/H.265], [Neural Codec lebih besar], [x], [Perbandingan belum apple-to-apple karena output Neural Codec masih disimpan lossless],
	[*Final thesis readiness*], [Semua eksperimen], [—], [x], [*Belum layak di-freeze sebagai hasil final*]
)

= Matrix keputusan akhir
#table(
	columns: 3,
	align: (left, left, left),
	[Aspek], [Kondisi Saat Ini], [Keputusan],
	[Data leakage], [Sudah dipisahkan Train/Val/Test], [Aman],
	[Generalisasi *video*], [`sabila`: 35/35], [Berhasil],
	[Generalisasi *payload*], [`skrpsi/kamera/budiar`: 0%], [Gagal],
	[Robustness compression], [H.264/H.265 CRF 23–46: 100% `sabila`], [Berhasil untuk payload tersebut],
	[Retry], [Tidak pernah terpicu], [Belum tervalidasi],
	[Neural codec compression], [Belum mengukur bitstream sebenarnya], [Belum valid sebagai klaim kompresi],
	[*Status eksperimen*], [Pipeline sudah jalan, tetapi generalisasi payload gagal], [*Baseline kuat, belum final*],

)