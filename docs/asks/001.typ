#set page(
	paper: "a4"
)

#set text(
	font: "Times New Roman",
	size: 12pt
)

#align(center)[
	#table(
		align: center,
		columns: 2,
		[#image("assets/assume-flow.png")], [#image("assets/customer-flow.png")]
	)
]

#strong[
	Pertanyaan Berdasarkan Analisis Flow Customer Requirement
]

Dari flow customer requirement, gw pengen diklarifikasi pada tahap **extract watermark**. Setelah payload 48-bit disisipkan ke pixel/frame, video itu kan bakal melewati proses kompresi **neural codec** yang sifatnya lossy. Proses tersebut bisa bikin nilai pixel dan representasi data pada frame berubah. 

Nah klo mengikuti flowchart yang pernah kakak kasih 
#align(center)[
	#image("/assets/21-09-2026 1719.png", alt: "flowchart", width: 30%)
]
ini klo watermarknya ngga kebaca kan disisipkan ulang, itu mau berapa kali percobaan penyisipan ulang nya? apakah sampai sukses?