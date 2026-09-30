# Master Task — Eksekusi Plan Riset End-to-End

**Status:** `In Progress` \
**Current Stage:** Stage 1 — Training until watermark readable \
**Current Blocker:** Uji A belum memenuhi target \
**Progress keseluruhan:** **8%**

> **Aturan utama:** Tahap berikutnya tidak boleh dimulai sebelum kriteria tahap sebelumnya terpenuhi. Setiap eksperimen harus menyimpan log, CSV, dan grafik dengan nama yang jelas. Eksperimen yang terhenti karena resource/time limit dicatat sebagai **INCOMPLETE**, bukan dianggap PASS/FAIL.

---

## Progress Summary

| Stage                                       | Status         | Progress |
| ------------------------------------------- | -------------- | -------: |
| Stage 1 — Training until watermark readable | In Progress |      33% |
| Stage 2 — Research claim strengthening      | Blocked      |       0% |
| Stage 3 — Standard evaluation               | Blocked      |       0% |
| Stage 4 — Verifier system                   | Blocked      |       0% |
| Stage 5 — Writing                           | Blocked      |       0% |
| **Overall**                                 | In Progress |   **8%** |

Progress keseluruhan dihitung berdasarkan 4 stage eksperimen utama dengan bobot sama. Stage 1 saat ini baru menyelesaikan 1 dari 3 diagnostic utama:

`1 / 3 × 25% ≈ 8%`

---

# Stage 1 — Training Until Watermark Readable

## T1.1 — Diagnostic A/B/C

### Uji A — Direct Latent Extraction

**Tujuan:** memastikan informasi watermark dapat dipelajari pada latent tanpa melibatkan codec.

Eksperimen:

`payload → embedder → y_w → extractor`

Kontrol:

`payload → kontrol`

### Acceptance Criteria

* [ ] A0 / latent float > **0.98**
* [ ] A1 / `round(y_w)` > **0.98**
* [ ] Control tetap sekitar chance level
* [ ] Simpan hasil training dan validation

### Current Evidence

Training terakhir:

* 1,500 steps
* `CLIPS_PER_BATCH=16`
* `CLIP_LEN=1`
* minimum unique payloads/step = **16**
* maximum frames/payload = **1**

Validation:

| Payload     | Experiment | Round | Bit Accuracy | Exact Match | ID Accuracy | CRC Accuracy |
| ----------- | ---------- | ----: | -----------: | ----------: | ----------: | -----------: |
| raw         | A0         |    No |       0.6317 |         0.0 |      0.6339 |       0.6274 |
| raw         | A1         |   Yes |       0.6302 |         0.0 |      0.6330 |       0.6246 |
| raw CTRL    | Control    |    No |       0.4952 |         0.0 |      0.4947 |       0.4961 |
| raw CTRL    | Control    |   Yes |       0.4955 |         0.0 |      0.4950 |       0.4967 |
| id_crc      | A0         |    No |   **0.6294** |         0.0 |      0.6272 |       0.6336 |
| id_crc      | A1         |   Yes |   **0.6289** |         0.0 |      0.6289 |       0.6289 |
| id_crc CTRL | Control    |    No |       0.4912 |         0.0 |      0.4938 |       0.4859 |
| id_crc CTRL | Control    |   Yes |       0.4923 |         0.0 |      0.4932 |       0.4904 |

**Status:** ❌ Gate belum terpenuhi.

A0 saat ini:

`0.6294 < 0.98`

A0 → A1:

`0.6294 → 0.6289`

Sehingga rounding belum terlihat sebagai sumber masalah utama.

---

## T1.2 — Message Diversity

**Requirement:**

Untuk training non-FFmpeg gunakan message berbeda pada setiap frame.

Target konfigurasi:

```text
CLIPS_PER_BATCH = 16
CLIP_LEN = 1
```

### Status

* [x] Implementasi message diversity
* [x] 16 frame / batch
* [x] 16 unique payload / step
* [x] Maximum 1 frame / payload
* [x] Minimum unique payloads selama simulation = 16
* [ ] Pertahankan evidence runtime pada final run

**Status:** ✅ Implemented

---

## T1.3 — Embedder

Requirement:

* raw output
* tidak menggunakan `tanh`
* tidak menggunakan `sigmoid`
* tidak menggunakan clamp
* gunakan L2 delta penalty
* final layer menggunakan small initialization

### Verification

* `delta_loss = 9.901e-05`
* delta-loss gradient terdeteksi
* 18 embedder parameters menerima gradient
* final layer weight std ≈ `1.007e-03`
* total loss:

```text
bit loss + 0.01 × delta loss
```

**Status:** ✅ Implementation verified

---

## T1.4 — Extractor

Requirement:

* HiDDeN-style convolutional extractor
* output `MSG_BITS` channels
* global spatial average pooling
* tidak menggunakan:

```text
AdaptiveAvgPool2d((2,2))
Flatten
Linear
```

### Verification

```text
features = (16, 48, 12, 16)
logits   = (16, 48)
```

**Status:** ✅ Implementation verified

---

## T1.5 — Diagnostic B — Full Codec Roundtrip

Eksperimen:

```text
payload
   ↓
embedder
   ↓
y_w
   ↓
g_s
   ↓
video
   ↓
g_a
   ↓
latent
   ↓
extractor
```

### Acceptance Criteria

* [ ] Bit accuracy > **0.95**
* [ ] 16 different messages per step
* [ ] No attack

**Status:** Blocked

Tidak boleh digunakan sebagai bukti final sebelum Uji A memenuhi target.

---

## T1.6 — Diagnostic C — Message Diversity Comparison

Bandingkan:

### B

```text
CLIPS_PER_BATCH = 16
CLIP_LEN = 1
```

dengan:

### C

```text
CLIPS_PER_BATCH = 2
CLIP_LEN = 8
```

### Tujuan

Mengetahui pengaruh message diversity terhadap kemampuan model mempelajari watermark.

### Status

* [ ] B selesai
* [ ] C selesai
* [ ] B vs C dianalisis

**Status:** Blocked

---

## T1.7 — Codec / Attack Curriculum

Tidak dimulai sebelum diagnostic A/B/C memenuhi gate.

### Phase 1

* no attack
* no image loss
* target validation bit accuracy > **0.98**

### Phase 2

Tambahkan image loss secara bertahap sampai:

* PSNR vs codec ≥ **38 dB**
* bit accuracy > **0.95**

### Phase 3

Tambahkan attack secara bertahap:

```text
Neural Codec
    ↓
H.264
    ↓
HEVC
    ↓
AV1
```

CRF:

```text
23 → 40
```

### Stage 1 Exit Criteria

* [ ] Uji A > 0.98
* [ ] Uji B > 0.95
* [ ] 30/30 video legible tanpa attack
* [ ] ≥27/30 video legible setelah HEVC CRF35 pada alpha 1.0

**Status:** Blocked

---

# Stage 2 — Research Claim Strengthening

**Status:** Blocked by Stage 1

## T2.1 — Residual Transfer

* [ ] Implement residual transfer
* [ ] Final PSNR vs original ≥ 38 dB
* [ ] SSIM ≥ 0.97
* [ ] Jika robustness turun, laporkan mode sebelum dan sesudah residual transfer

## T2.2 — Latent vs Pixel Ablation

Gunakan:

* dataset sama
* payload 48-bit
* attack sama
* epoch sama
* PSNR sama

Bandingkan BER terhadap:

* HEVC
* AV1

## T2.3 — DCT-QIM Baseline

* [ ] Implement / gunakan baseline DCT-QIM
* [ ] Samakan PSNR
* [ ] Perluas calibration limit jika diperlukan
* [ ] Simpan configuration dan result

## T2.4 — Alpha Ablation

Uji:

```text
alpha = 1.0
alpha = 1.25
alpha = 1.5
alpha = 2.0
```

## T2.5 — Video Quality

* [ ] VMAF
* [ ] Flicker analysis

### Stage 2 Exit

* [ ] PSNR ≥ 38 dB
* [ ] SSIM ≥ 0.97
* [ ] Latent-vs-pixel ablation tersedia
* [ ] DCT-QIM comparison tersedia
* [ ] Alpha comparison tersedia
* [ ] VMAF/flicker tersedia

---

# Stage 3 — Standard Evaluation

**Status:** Blocked by Stage 2

## T3.1 — Dataset

* [ ] ≥100 test videos
* [ ] ≥2 dataset/source
* [ ] UCF101 menggunakan group split
* [ ] Dataset video berkualitas tinggi seperti UVG dengan resize yang sesuai

## T3.2 — Attack Evaluation

Uji:

* [ ] CBR 500 kbps
* [ ] CBR 250 kbps
* [ ] HEVC → H.264 double compression
* [ ] Crop 10%
* [ ] Frame drop 10%
* [ ] FPS 30 → 24
* [ ] Brightness change
* [ ] Contrast change

## T3.3 — BER vs CRF

Bandingkan:

```text
Proposed method
Pixel baseline
DCT-QIM
```

pada:

```text
H.264
HEVC
AV1
```

## T3.4 — Statistical Analysis

* [ ] Mean ± SD
* [ ] 95% CI
* [ ] Paired Wilcoxon

## T3.5 — Learned Baseline

* [ ] Evaluasi baseline seperti VideoSeal (2024) jika runnable
* [ ] Jika tidak runnable, lakukan qualitative literature comparison

## T3.6 — Runtime

Ukur:

* [ ] embedding time/frame
* [ ] extraction time/frame
* [ ] milliseconds/frame
* [ ] GPU yang sama

### Stage 3 Exit

* [ ] ≥100 videos
* [ ] ≥2 sources
* [ ] BER vs CRF untuk 3 codec × 3 method
* [ ] Main numbers memiliki SD atau CI

---

# Stage 4 — Verifier System

**Status:** Blocked by Stage 3

## T4.1 — Verification Dataset

Minimal:

**≥50 video per class**

### Class 1 — Authentic

Re-compression:

* H.264
* HEVC
* AV1
* random CRF

### Class 2 — Cut

* remove 10–40% beginning/end

### Class 3 — Replaced Segment

* replace 1–2 second segment dengan video lain

### Class 4 — Covered / Blurring

* cover area
* blur area

### Class 5 — No Watermark

* original
* video dari source lain

## T4.2 — Threshold Calibration

Analisis:

* [ ] pHash distance distribution
* [ ] segment bit accuracy distribution
* [ ] authentic vs manipulated
* [ ] ROC curve

Tentukan:

```text
PHASH_THRESH
SEG_BITACC_THRESH
```

Threshold harus dijelaskan berdasarkan hasil ROC.

Target contoh dari plan:

```text
false alarm < 1%
```

## T4.3 — Performance Evaluation

* [ ] Confusion matrix
* [ ] Precision
* [ ] Recall
* [ ] Localization
* [ ] Verification time/video
* [ ] Verification time/minute

## T4.4 — Security

* [ ] `SECRET_KEY` dipindahkan ke environment / Colab Secrets
* [ ] HMAC JSON report
* [ ] SHA-256 registry
* [ ] Copy attack

Copy attack:

```text
Video A ID
    ↓
dimasukkan ke Video B
    ↓
pHash harus menolak
```

## T4.5 — Article Artifacts

* [ ] 1 screenshot interface Gradio
* [ ] 1 contoh HTML report

### Stage 4 Exit

* [ ] ≥90% verdict accuracy
* [ ] Confusion matrix
* [ ] Threshold dipilih dari ROC dan dijelaskan
* [ ] Copy attack terdeteksi

---

# Stage 5 — Writing

**Status:** Blocked

Penulisan dilakukan setelah training, claim strengthening, dan evaluation selesai.

> Kriteria detail tambahan untuk Stage 5 tidak ditambahkan karena tidak tercantum secara eksplisit pada dokumen plan yang digunakan sebagai dasar task ini.

---

# Current Blocker

Eksperimen terbaru menunjukkan:

```text
A0 = 0.6294
Target = >0.98
Gap = 0.3506
```

Control:

```text
≈ 0.49
```

Interpretasi yang didukung hasil saat ini:

* Model sudah menangkap sebagian signal watermark karena accuracy watermark ≈0.63, sementara control ≈0.49.
* Namun kemampuan ekstraksi masih jauh dari acceptance criterion.
* A0 dan A1 hampir sama (`0.6294` vs `0.6289`), sehingga rounding bukan indikasi utama sumber masalah.
* Diagnostic Level 2 belum selesai karena resource/time limit dan harus dicatat sebagai **INCOMPLETE**.

**Jangan lanjut ke HEVC / AV1 / verifier sebelum Stage 1 gate terpenuhi.**

---

# Next Action

Prioritas berikutnya:

1. **Lanjutkan investigasi Uji A.**
2. Cari penyebab A0 berhenti sekitar 0.63.
3. Jalankan eksperimen yang masih berada pada level latent/direct extraction.
4. Targetkan:

```text
A0 > 0.98
A1 > 0.98
```

5. Setelah A lolos, lanjutkan:

```text
Uji B → Uji C → Stage 1 gate
```

6. Baru setelah seluruh Stage 1 exit criteria terpenuhi, lanjut ke Stage 2.

---

## Current Evidence

Notebook yang digunakan:

`watermark_latent_neural_codec_v3_stage1_patch.ipynb`

Latest verified implementation:

```text
Implementation Verification = PASS
```

Latest training:

```text
Steps = 1,500
Training time ≈ 50.7 minutes
A0 = 0.6294
A1 = 0.6289
```

Current project state:

| Task | Progress |
|---|---|
| Implementation | 100% |
| Stage 1 diagnostics | 33% |
| Stage 1 gate | 0% |
| Stage 2 | 0% |
| Stage 3 | 0% |
| Stage 4 | 0% |
| Stage 5 | 0% |
| **Overall** | 8% |
---
# Timeline Update — 30 September 2026

## Commit Terbaru

`14134f1707c1e897732f4b65f1475e2cf7b55af1`

Notebook: `watermark_latent_neural_codec_v3_stage1.ipynb`

## Diagnostic Level 2 — COMPLETE

| Mode | Bit Accuracy | Status |
|---|---:|---|
| latent_float | 0.530 | COMPLETE |
| video_no_round | 0.510 | COMPLETE |
| video_round_ste | 0.545 | COMPLETE |

Semua mode selesai 400/400 step. Hasil belum mendekati target Uji A >0.98.

## Uji A — 6.000 Step — COMPLETE

| Payload | A0 | A1 |
|---|---:|---:|
| raw | 0.8605 | 0.8601 |
| id_crc | **0.8618** | **0.8625** |
| id_crc CTRL | 0.5011 | 0.5023 |

Target Uji A: **>0.98**.

Hasil `id_crc` meningkat dari hasil sebelumnya A0 `0.6294` menjadi `0.8618` (+0.2324), tetapi gate masih belum terpenuhi.

## Uji B/C Diagnostic — COMPLETE

| Eksperimen | Konfigurasi | Bit Accuracy | Target | Status |
|---|---|---:|---:|---|
| Uji A | 16×1 | 0.5390 | >0.98 | FAIL diagnostic |
| Uji B | 16×1 | 0.5479 | >0.95 | FAIL diagnostic |
| Uji A (2×8) | 2×8 | 0.4973 | >0.98 | FAIL diagnostic |
| Uji C | 2×8 | 0.5008 | >0.95 | FAIL diagnostic |

Run ini merupakan diagnostic 600-step dan bukan pengganti gate final Stage 1.

## Ablasi Uji A — COMPLETE

| Eksperimen | Parameter | Evaluasi |
|---|---|---:|
| `abl_lambda_delta0` | `lambda_delta=0` | 0.8175 |
| `abl_lr3e-4` | `LR=3e-4` | 0.8393 |
| `abl_init1e-2` | init layer akhir ≈ `1e-2` | **0.8595** |

Ketiga run selesai 6.000/6.000 step. Tidak ada varian yang mencapai >0.98.

## Status Setelah Eksperimen Terbaru

| Requirement | Target | Hasil Terbaru | Status |
|---|---:|---:|---|
| Uji A0 | >0.98 | 0.8618 | FAIL gate |
| Uji A1 | >0.98 | 0.8625 | FAIL gate |
| Uji B | >0.95 | 0.5479* | FAIL diagnostic |
| Uji C | dibandingkan dengan B | 0.5008* | FAIL diagnostic |
| Stage 1 Gate | seluruh exit criteria | Belum terpenuhi | BLOCKED |

*Diagnostic 600-step; tidak diperlakukan sebagai final gate evidence.

## Progress

- Implementation verification: **100%**
- Diagnostic execution: **100%**
- Stage 1 gate: **0%**
- Stage 2: **0%**
- Stage 3: **0%**
- Stage 4: **0%**
- Stage 5: **0%**

**Overall progress: 25%**

Angka 25% menunjukkan pekerjaan yang sudah dieksekusi, bukan keberhasilan model.

## Next Step

Tetap fokus pada **Uji A / latent-direct extraction** untuk mencari penyebab ceiling sekitar 0.86. Jangan membuka codec robustness, HEVC, AV1, atau Stage 2 sebelum gate Stage 1 terpenuhi.
---
# Timeline Update — 30 September 2026 — Run Terbaru

Sumber bukti: notebook yang diunggah **watermark_latent_neural_codec_v3_stage1_fixed (2).ipynb**. Tidak ada commit SHA yang dicantumkan karena hasil ini berasal dari file notebook yang diunggah, sehingga tidak diasumsikan berasal dari commit tertentu.

## Diagnostic Level 2

Ketiga eksperimen tersimpan sebagai **COMPLETE 400/400 step**:

| Mode | Bit Accuracy | Status |
|---|---:|---|
| latent_float | 0.530 | COMPLETE |
| video_no_round | 0.510 | COMPLETE |
| video_round_ste | 0.545 | COMPLETE |

Hasil ini merupakan diagnostic dan bukan gate Stage 1.

## Uji A — Run 30.000 Step

Run stage1_diag_A selesai **30.000/30.000 step**. Bukti diversity dari run tersebut:

- minimum unique payloads per step = **16**
- maksimum frame per payload = **1**
- jumlah step = **30.000**

Validasi pada **448 frame**:

| Payload | Experiment | Round | Bit Accuracy | Exact Match | ID Accuracy | CRC Accuracy |
|---|---|---|---:|---:|---:|---:|
| raw | A0 | No | 0.9993 | 0.9665 | 0.9994 | 0.9990 |
| raw | A1 | Yes | 0.9992 | 0.9643 | 0.9992 | 0.9992 |
| raw CTRL | CTRL | No | 0.4990 | 0.0000 | 0.5026 | 0.4919 |
| raw CTRL | CTRL | Yes | 0.5021 | 0.0000 | 0.5061 | 0.4941 |
| id_crc | A0 | No | **0.9987** | 0.9464 | 0.9985 | 0.9992 |
| id_crc | A1 | Yes | **0.9984** | 0.9353 | 0.9984 | 0.9985 |
| id_crc CTRL | CTRL | No | 0.5098 | 0.0000 | 0.5078 | 0.5138 |
| id_crc CTRL | CTRL | Yes | 0.5108 | 0.0000 | 0.5075 | 0.5174 |

Acceptance criterion Uji A adalah **>0.98**. Berdasarkan payload id_crc:

- A0 = **0.9987** → **PASS**
- A1 = **0.9984** → **PASS**

Control tetap sekitar chance level (sekitar 0.50). Notebook secara eksplisit menyatakan A0 dan A1 memenuhi ambang validasi.

## Ablasi Uji A — Run 30.000 Step

Tiga ablasi juga selesai **30.000/30.000 step**:

| Eksperimen | Parameter | A0 raw | A1 raw | A0 id_crc | A1 id_crc |
|---|---|---:|---:|---:|---:|
| abl_lambda_delta0 | LAMBDA_DELTA=0 | 0.9972 | 0.9972 | 0.9952 | 0.9951 |
| abl_lr3e-4 | LR=3e-4 | 0.9947 | 0.9944 | 0.9959 | 0.9953 |
| abl_init1e-2 | INIT_STD=0.01 | 0.9972 | 0.9967 | 0.9964 | 0.9965 |

Tidak ada hasil pada tabel ini yang dijadikan pengganti gate utama; tabel hanya mencatat hasil ablasi yang benar-benar tersedia di notebook.

## Status Stage 1 Setelah Run Terbaru

| Requirement | Target | Bukti terbaru | Status |
|---|---:|---|---|
| Uji A0 | >0.98 | 0.9987 (id_crc) | **PASS** |
| Uji A1 | >0.98 | 0.9984 (id_crc) | **PASS** |
| Uji B | >0.95 | 0.5479 pada diagnostic 600-step sebelumnya | **Belum menjadi gate final** |
| Uji C | dibandingkan dengan B | 0.5008 pada diagnostic 600-step sebelumnya | **Belum menjadi gate final** |
| 30/30 legible tanpa attack | 30/30 | Belum ada bukti pada notebook terbaru | **Belum diuji** |
| ≥27/30 HEVC CRF35 alpha 1.0 | ≥27/30 | Belum ada bukti pada notebook terbaru | **Belum diuji** |

Dengan demikian, **Uji A sudah lulus**, tetapi **Stage 1 belum selesai**. Tidak ada bukti pada notebook terbaru yang membenarkan klaim bahwa Uji B, legibility 30/30, atau HEVC CRF35 sudah lulus.

## Next Action Berdasarkan Gate

Karena Uji A sekarang sudah memenuhi target, langkah berikutnya adalah **menjalankan Uji B dengan konfigurasi gate yang sesuai customer** dan mengevaluasi hasilnya terhadap threshold **>0.95**. Setelah itu lanjutkan Uji C dan exit criteria Stage 1 sesuai urutan plan.

**Jangan menulis Stage 1 sebagai PASS dan jangan mengklaim robustness HEVC/AV1 sebelum bukti masing-masing tersedia.**
