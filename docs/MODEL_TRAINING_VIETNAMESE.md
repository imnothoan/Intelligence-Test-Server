# Hướng Dẫn Train Model - Intelligence Test Server

## Mục Lục
1. [CAT Algorithm - Không Cần Train](#cat-algorithm---không-cần-train)
2. [Anti-Cheat Model Training](#anti-cheat-model-training)
3. [Dataset Collection](#dataset-collection)
4. [Training Process](#training-process)
5. [Model Deployment](#model-deployment)

---

## CAT Algorithm - Không Cần Train

### Giới Thiệu
**CAT (Computerized Adaptive Testing)** sử dụng **IRT (Item Response Theory)** để điều chỉnh độ khó câu hỏi tự động.

### ❌ KHÔNG CẦN TRAIN MODEL ML!

CAT của chúng ta sử dụng **thuật toán thống kê**, không phải Machine Learning:
- ✅ Sử dụng công thức toán học IRT 1-Parameter Logistic Model
- ✅ Maximum Likelihood Estimation (MLE)
- ✅ Fisher Information
- ✅ **Không cần dataset huấn luyện**
- ✅ **Không cần GPU**
- ✅ **Chạy real-time trên server**

### Cách Hoạt Động

#### 1. Độ Khó Câu Hỏi (Difficulty Parameter `b`)
Mỗi câu hỏi có `difficulty` từ 0.0 đến 1.0:
```typescript
{
  id: "uuid",
  question_text: "What is 5 + 7?",
  difficulty: 0.15,  // Dễ (0.0-0.2)
  ...
}
```

#### 2. Năng Lực Học Sinh (Ability `θ`)
Được ước tính từ -3 đến +3:
- `-3`: Rất yếu
- `0`: Trung bình
- `+3`: Xuất sắc

#### 3. Xác Suất Trả Lời Đúng
```
P(θ, b) = 1 / (1 + e^(-(θ - b)))
```

Ví dụ:
- Học sinh `θ = 0` (trung bình), câu hỏi `b = 0.5` (khó): P ≈ 38%
- Học sinh `θ = 0` (trung bình), câu hỏi `b = 0.0` (dễ): P ≈ 50%
- Học sinh `θ = 1` (khá), câu hỏi `b = 0.5` (khó): P ≈ 62%

### Hiệu Chỉnh Độ Khó (Calibration)

#### Phương Pháp 1: Manual (Nhanh - 5 phút)
Giáo viên đánh giá chủ quan:
```sql
UPDATE questions 
SET difficulty = 0.15 
WHERE topic = 'Math - Elementary' AND question_text LIKE '%+%';

UPDATE questions 
SET difficulty = 0.55 
WHERE topic = 'Math - High School' AND question_text LIKE '%derivative%';
```

#### Phương Pháp 2: Dựa Trên Dữ Liệu (Khuyến Nghị - 30 phút)
Sau khi có dữ liệu thi thật:

```sql
-- Tính tỷ lệ đúng cho mỗi câu hỏi
WITH question_stats AS (
    SELECT 
        ea.responses->>'question_id' as question_id,
        COUNT(*) as total_attempts,
        SUM(CASE WHEN (ea.responses->>'is_correct')::boolean THEN 1 ELSE 0 END) as correct_count
    FROM exam_attempts ea,
    jsonb_array_elements(ea.responses) as response
    GROUP BY ea.responses->>'question_id'
)
SELECT 
    q.id,
    q.question_text,
    q.difficulty as old_difficulty,
    -- Công thức đơn giản: difficulty = 1 - accuracy
    1 - (qs.correct_count::decimal / qs.total_attempts) as suggested_difficulty
FROM questions q
JOIN question_stats qs ON q.id::text = qs.question_id
WHERE qs.total_attempts >= 20  -- Chỉ câu có đủ dữ liệu
ORDER BY q.difficulty;
```

**Áp dụng calibration:**
```sql
-- Update difficulty dựa trên accuracy thực tế
UPDATE questions q
SET difficulty = (
    SELECT 1 - (
        SUM(CASE WHEN (ea.responses->>'is_correct')::boolean THEN 1 ELSE 0 END)::decimal / 
        COUNT(*)
    )
    FROM exam_attempts ea,
    jsonb_array_elements(ea.responses) as response
    WHERE ea.responses->>'question_id' = q.id::text
    GROUP BY ea.responses->>'question_id'
    HAVING COUNT(*) >= 20
)
WHERE EXISTS (
    SELECT 1 
    FROM exam_attempts ea
    WHERE ea.responses @> jsonb_build_array(jsonb_build_object('question_id', q.id::text))
);
```

#### Phương Pháp 3: IRT Calibration (Pro - 2-3 giờ)
Sử dụng R package `mirt`:

**Cài đặt R và packages:**
```R
install.packages("mirt")
install.packages("DBI")
install.packages("RPostgres")
```

**Script calibration:**
```R
library(mirt)
library(DBI)
library(RPostgres)

# Kết nối Supabase
con <- dbConnect(
    Postgres(),
    host = "db.xxxxx.supabase.co",
    dbname = "postgres",
    user = "postgres",
    password = "your-password"
)

# Lấy dữ liệu responses
query <- "
    SELECT 
        ea.student_id,
        response->>'question_id' as question_id,
        (response->>'is_correct')::boolean as is_correct
    FROM exam_attempts ea,
    jsonb_array_elements(ea.responses) as response
    WHERE ea.status = 'completed'
"
data <- dbGetQuery(con, query)

# Chuyển sang matrix format (students x questions)
response_matrix <- dcast(data, student_id ~ question_id, value.var = "is_correct")
response_matrix <- as.matrix(response_matrix[,-1])  # Remove student_id

# Fit 1PL model (Rasch)
model <- mirt(response_matrix, 1, itemtype = "Rasch")

# Extract difficulty parameters
params <- coef(model, simplify = TRUE)
difficulty_estimates <- params$items[, "d"]  # difficulty parameter

# Update database
for (i in 1:length(difficulty_estimates)) {
    question_id <- colnames(response_matrix)[i]
    difficulty <- plogis(difficulty_estimates[i])  # Convert to 0-1 scale
    
    dbExecute(con, sprintf(
        "UPDATE questions SET difficulty = %f WHERE id = '%s'",
        difficulty, question_id
    ))
}

dbDisconnect(con)
print("Calibration complete!")
```

### Thang Điểm CAT
Chuyển từ ability (-3 to +3) sang điểm (0-100):
```typescript
score = 50 + (ability * 50 / 3)
```

Ví dụ:
- `θ = -3` → Score = 0
- `θ = 0` → Score = 50
- `θ = +3` → Score = 100

---

## Anti-Cheat Model Training

### Tổng Quan
Anti-cheat sử dụng **Computer Vision** để phát hiện gian lận qua webcam.

### Option 1: Sử Dụng BlazeFace (Khuyến Nghị - 0đ)

**Ưu điểm:**
- ✅ **KHÔNG CẦN TRAIN**
- ✅ Pre-trained model từ TensorFlow
- ✅ Nhẹ, nhanh (chạy trên browser)
- ✅ Miễn phí 100%

**Cài đặt (Client-side):**
```bash
npm install @tensorflow/tfjs
npm install @tensorflow-models/blazeface
```

**Code sử dụng:**
```typescript
import * as blazeface from '@tensorflow-models/blazeface';

// Load model (chỉ 1 lần)
const model = await blazeface.load();

// Detect faces
const predictions = await model.estimateFaces(videoElement, false);

// Check violations
if (predictions.length === 0) {
    // ⚠️ No face detected
    reportWarning('no_face');
} else if (predictions.length > 1) {
    // ⚠️ Multiple faces
    reportWarning('multiple_faces');
}
```

**Kết quả:**
- Phát hiện khuôn mặt: ✅
- Đếm số người: ✅
- Tốc độ: ~60 FPS
- Độ chính xác: ~95%

### Option 2: Train Custom Model (Nâng Cao)

**Khi nào cần:**
- Phát hiện hành vi gian lận phức tạp
- Nhận diện cảm xúc (looking away, distracted)
- Phát hiện thiết bị điện tử

#### Step 1: Thu Thập Dataset

**A. Tự Thu Thập (Khuyến Nghị)**
```bash
# Tạo thư mục
mkdir -p dataset/normal
mkdir -p dataset/cheating
mkdir -p dataset/no_face
mkdir -p dataset/multiple_faces
```

**Script thu thập:**
```python
import cv2
import os
from datetime import datetime

def collect_data(category, num_images=500):
    """Thu thập ảnh từ webcam"""
    cap = cv2.VideoCapture(0)
    count = 0
    
    print(f"Collecting {num_images} images for category: {category}")
    print("Press SPACE to capture, Q to quit")
    
    while count < num_images:
        ret, frame = cap.read()
        cv2.imshow('Data Collection', frame)
        
        key = cv2.waitKey(1)
        if key == ord(' '):  # Space bar
            filename = f"dataset/{category}/img_{count}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.jpg"
            cv2.imwrite(filename, frame)
            count += 1
            print(f"Captured {count}/{num_images}")
        elif key == ord('q'):
            break
    
    cap.release()
    cv2.destroyAllWindows()

# Thu thập từng loại
collect_data('normal', 500)        # Học sinh tập trung
collect_data('cheating', 500)      # Nhìn xuống, quay đi
collect_data('no_face', 200)       # Không có mặt
collect_data('multiple_faces', 200) # Nhiều người
```

**B. Download Dataset Công Khai**
```bash
# WIDER FACE dataset (faces)
wget http://mmlab.ie.cuhk.edu.hk/projects/WIDERFace/support/bbx_annotation/wider_face_split.zip

# CelebA dataset (faces with attributes)
# https://mmlab.ie.cuhk.edu.hk/projects/CelebA.html

# Custom gaze dataset
# https://www.mpi-inf.mpg.de/departments/computer-vision-and-machine-learning/research/gaze-based-human-computer-interaction/appearance-based-gaze-estimation-in-the-wild
```

**Cấu trúc dataset tối thiểu:**
```
dataset/
├── train/
│   ├── normal/       (800 ảnh)
│   ├── cheating/     (800 ảnh)
│   ├── no_face/      (400 ảnh)
│   └── multiple/     (400 ảnh)
├── validation/
│   ├── normal/       (100 ảnh)
│   ├── cheating/     (100 ảnh)
│   ├── no_face/      (50 ảnh)
│   └── multiple/     (50 ảnh)
└── test/
    ├── normal/       (100 ảnh)
    ├── cheating/     (100 ảnh)
    ├── no_face/      (50 ảnh)
    └── multiple/     (50 ảnh)
```

#### Step 2: Data Augmentation
```python
from tensorflow.keras.preprocessing.image import ImageDataGenerator

datagen = ImageDataGenerator(
    rotation_range=20,
    width_shift_range=0.2,
    height_shift_range=0.2,
    shear_range=0.2,
    zoom_range=0.2,
    horizontal_flip=True,
    brightness_range=[0.8, 1.2],
    fill_mode='nearest'
)

# Tăng dataset lên 3x
datagen.flow_from_directory(
    'dataset/train',
    target_size=(224, 224),
    batch_size=32,
    save_to_dir='dataset/augmented',
    save_format='jpg'
)
```

#### Step 3: Train Model

**Option A: Google Colab (Khuyến Nghị - MIỄN PHÍ)**

1. Truy cập [Google Colab](https://colab.research.google.com)
2. Tạo notebook mới
3. Enable GPU: Runtime → Change runtime type → GPU

```python
# Cài đặt
!pip install tensorflow opencv-python

# Upload dataset lên Colab hoặc mount Google Drive
from google.colab import drive
drive.mount('/content/drive')

# Import
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers
import numpy as np

# Load data
train_ds = keras.utils.image_dataset_from_directory(
    '/content/drive/MyDrive/dataset/train',
    image_size=(224, 224),
    batch_size=32
)
val_ds = keras.utils.image_dataset_from_directory(
    '/content/drive/MyDrive/dataset/validation',
    image_size=(224, 224),
    batch_size=32
)

# Model Architecture - MobileNetV2 (nhẹ, phù hợp web)
base_model = keras.applications.MobileNetV2(
    input_shape=(224, 224, 3),
    include_top=False,
    weights='imagenet'  # Pre-trained
)
base_model.trainable = False  # Freeze base model

# Add custom layers
model = keras.Sequential([
    base_model,
    layers.GlobalAveragePooling2D(),
    layers.Dense(128, activation='relu'),
    layers.Dropout(0.5),
    layers.Dense(4, activation='softmax')  # 4 classes
])

# Compile
model.compile(
    optimizer='adam',
    loss='sparse_categorical_crossentropy',
    metrics=['accuracy']
)

# Train
history = model.fit(
    train_ds,
    validation_data=val_ds,
    epochs=20,
    callbacks=[
        keras.callbacks.EarlyStopping(patience=3),
        keras.callbacks.ModelCheckpoint('best_model.h5', save_best_only=True)
    ]
)

# Evaluate
test_loss, test_acc = model.evaluate(val_ds)
print(f'Test accuracy: {test_acc:.2%}')

# Save model
model.save('anticheat_model.h5')
```

**Option B: Train Locally (Nếu có GPU)**
```python
# Tương tự code trên nhưng chạy local
# Cần: NVIDIA GPU, CUDA, cuDNN

# Check GPU
print(tf.config.list_physical_devices('GPU'))
```

**Option C: Simple CNN (Nếu không có GPU)**
```python
# Model nhẹ hơn
model = keras.Sequential([
    layers.Conv2D(32, 3, activation='relu', input_shape=(224, 224, 3)),
    layers.MaxPooling2D(),
    layers.Conv2D(64, 3, activation='relu'),
    layers.MaxPooling2D(),
    layers.Conv2D(128, 3, activation='relu'),
    layers.GlobalAveragePooling2D(),
    layers.Dense(64, activation='relu'),
    layers.Dropout(0.5),
    layers.Dense(4, activation='softmax')
])

# Train tương tự
```

#### Step 4: Convert to TensorFlow.js
```bash
# Cài đặt tensorflowjs converter
pip install tensorflowjs

# Convert Keras model → TF.js
tensorflowjs_converter \
    --input_format keras \
    anticheat_model.h5 \
    ./tfjs_model/
```

Kết quả:
```
tfjs_model/
├── model.json        # Model architecture
├── group1-shard1of1.bin
└── group1-shard2of1.bin
```

#### Step 5: Deploy Model

**A. Deploy trên Server**
```bash
# Copy model vào public folder của client
cp -r tfjs_model/ /path/to/client/public/models/anticheat/
```

**B. Load và Sử Dụng (Client)**
```typescript
import * as tf from '@tensorflow/tfjs';

// Load model
const model = await tf.loadLayersModel('/models/anticheat/model.json');

// Predict
function detectCheating(videoElement: HTMLVideoElement) {
    const tensor = tf.browser.fromPixels(videoElement)
        .resizeNearestNeighbor([224, 224])
        .expandDims(0)
        .toFloat()
        .div(255.0);
    
    const prediction = model.predict(tensor) as tf.Tensor;
    const probabilities = prediction.dataSync();
    
    // Classes: [normal, cheating, no_face, multiple]
    const maxProb = Math.max(...probabilities);
    const classIndex = probabilities.indexOf(maxProb);
    
    const classes = ['normal', 'cheating', 'no_face', 'multiple_faces'];
    
    if (classes[classIndex] !== 'normal' && maxProb > 0.7) {
        reportWarning(classes[classIndex]);
    }
    
    // Cleanup
    tensor.dispose();
    prediction.dispose();
}

// Run every 2 seconds
setInterval(() => detectCheating(video), 2000);
```

### Performance Metrics

**BlazeFace:**
- Size: ~150 KB
- Speed: 60 FPS (browser)
- Accuracy: 95%+ (face detection)
- Cost: $0

**Custom Model:**
- Size: 2-5 MB (MobileNetV2)
- Speed: 20-30 FPS (browser)
- Accuracy: 85-90% (với dataset tốt)
- Cost: $0 (Colab) hoặc ~$0.5/hour (GCP)

---

## Model Deployment

### Folder Structure
```
client/
├── public/
│   └── models/
│       ├── blazeface/       # BlazeFace (auto-download from CDN)
│       └── anticheat/       # Custom model (if used)
│           ├── model.json
│           └── *.bin
└── src/
    └── services/
        ├── antiCheatService.ts    # Load và sử dụng model
        └── websocketService.ts    # Gửi warnings về server
```

### Integration với Server

**Client gửi warning:**
```typescript
// antiCheatService.ts
async detectAndReport(attemptId: string) {
    const violation = await this.detect();
    
    if (violation) {
        // Send to server via HTTP
        await apiClient.reportCheatWarning(attemptId, {
            timestamp: new Date().toISOString(),
            type: violation.type,
            severity: violation.severity,
            details: violation.confidence
        });
        
        // Also send via WebSocket for real-time
        ws.send(JSON.stringify({
            type: 'cheat_warning',
            data: {
                attemptId,
                warning: violation
            }
        }));
    }
}
```

**Server xử lý warning:**
```typescript
// Already implemented in attemptController.ts
export const submitWarning = asyncHandler(async (req, res) => {
    const { attemptId } = req.params;
    const warning = req.body;
    
    // Save to database
    await supabaseAdmin
        .from('exam_attempts')
        .update({
            anti_cheat_warnings: /* append warning */,
            flagged: /* check if should flag */
        })
        .eq('id', attemptId);
    
    // Broadcast via WebSocket to instructors
    websocketService.broadcastToExam(examId, {
        type: 'cheat_warning',
        data: { attemptId, warning }
    });
});
```

---

## Kết Luận

### Tóm Tắt

| Tính Năng | Phương Pháp | Cost | Thời Gian | Độ Chính Xác |
|-----------|-------------|------|-----------|--------------|
| **CAT Algorithm** | Thuật toán IRT | $0 | 0 giây | 100% (toán học) |
| **CAT Calibration** | SQL queries | $0 | 30 phút | 85-95% |
| **Anti-Cheat Basic** | BlazeFace | $0 | 0 giây | 95% |
| **Anti-Cheat Custom** | TensorFlow + Colab | $0 | 2-4 giờ | 85-90% |

### Khuyến Nghị

**Bắt đầu:**
1. ✅ Sử dụng CAT algorithm có sẵn
2. ✅ Calibrate difficulty bằng dữ liệu thật
3. ✅ Dùng BlazeFace cho anti-cheat

**Sau này (nếu cần):**
4. Train custom anti-cheat model trên Colab
5. Deploy model lên CDN
6. Fine-tune dựa trên feedback

### Hỗ Trợ

- Google Colab: https://colab.research.google.com
- TensorFlow.js: https://www.tensorflow.org/js
- BlazeFace: https://github.com/tensorflow/tfjs-models/tree/master/blazeface
- Supabase: https://supabase.com/docs
