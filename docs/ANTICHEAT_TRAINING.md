# Anti-Cheat Computer Vision Model Training Guide
# Hướng Dẫn Training Mô Hình Chống Gian Lận Bằng Thị Giác Máy Tính

## 📚 Table of Contents

- [Giới thiệu](#giới-thiệu)
- [Tại sao cần Anti-Cheat?](#tại-sao-cần-anti-cheat)
- [Hệ thống mặc định (Không cần training)](#hệ-thống-mặc-định-không-cần-training)
- [Khi nào cần training custom model?](#khi-nào-cần-training-custom-model)
- [Method 1: Sử dụng BlazeFace (Recommended)](#method-1-sử-dụng-blazeface-recommended)
- [Method 2: Training Custom Model](#method-2-training-custom-model)
- [Method 3: Fine-tuning Pre-trained Models](#method-3-fine-tuning-pre-trained-models)
- [Deployment và Integration](#deployment-và-integration)
- [Best Practices](#best-practices)

## Giới thiệu

Anti-cheat system sử dụng **computer vision** để phát hiện hành vi gian lận qua webcam:

### Các hành vi phát hiện được:
1. **Không có khuôn mặt** (`no_face`) - Học sinh rời khỏi màn hình
2. **Nhiều khuôn mặt** (`multiple_faces`) - Có người khác trong phòng
3. **Nhìn đi chỗ khác** (`looking_away`) - Không tập trung vào màn hình
4. **Chuyển tab** (`tab_switch`) - Mở tab/cửa sổ khác

### Warning levels:
- **Low**: Vi phạm nhỏ, lần đầu
- **Medium**: Vi phạm lặp lại
- **High**: Vi phạm nghiêm trọng
- **Auto-flag**: Tự động đánh dấu sau 3 warnings high hoặc 10 warnings tổng

## Tại sao cần Anti-Cheat?

✅ **Nên dùng khi**:
- Thi chính thức, có điểm số quan trọng
- Thi từ xa (remote/online)
- Lo ngại gian lận
- Cần giám sát nhiều học sinh cùng lúc

❌ **Không cần khi**:
- Bài tập về nhà
- Thi thử, luyện tập
- Lớp học nhỏ (< 10 học sinh)
- Thi trực tiếp tại trường

## Hệ thống mặc định (Không cần training)

### BlazeFace Model (Google)

**Intelligence Test Platform đã tích hợp sẵn BlazeFace** - một model phát hiện khuôn mặt nhẹ, nhanh từ Google.

**Ưu điểm**:
- ✅ Không cần training
- ✅ Chạy trực tiếp trên browser (TensorFlow.js)
- ✅ Nhanh (60 FPS)
- ✅ Nhẹ (~1MB)
- ✅ Chính xác cao (95%+)

**Nhược điểm**:
- ❌ Chỉ phát hiện khuôn mặt, không phân loại hành vi phức tạp
- ❌ Không tùy chỉnh được

### Sử dụng BlazeFace

Trong client code (`Intelligence-Test` repository):

```typescript
// src/services/antiCheatService.ts
import * as blazeface from '@tensorflow-models/blazeface';
import '@tensorflow/tfjs';

class AntiCheatService {
  private model: blazeface.BlazeFaceModel | null = null;

  async initialize() {
    this.model = await blazeface.load();
    console.log('BlazeFace model loaded');
  }

  async detectFaces(videoElement: HTMLVideoElement) {
    if (!this.model) {
      await this.initialize();
    }

    const predictions = await this.model!.estimateFaces(videoElement, false);
    
    return {
      faceCount: predictions.length,
      faces: predictions.map(pred => ({
        topLeft: pred.topLeft,
        bottomRight: pred.bottomRight,
        probability: pred.probability
      }))
    };
  }

  async analyzeFrame(videoElement: HTMLVideoElement) {
    const { faceCount, faces } = await this.detectFaces(videoElement);

    // Check violations
    const warnings = [];

    if (faceCount === 0) {
      warnings.push({
        type: 'no_face',
        severity: 'medium',
        details: 'No face detected'
      });
    } else if (faceCount > 1) {
      warnings.push({
        type: 'multiple_faces',
        severity: 'high',
        details: `${faceCount} faces detected`
      });
    }

    // Check if looking away (based on face position)
    if (faceCount === 1) {
      const face = faces[0];
      const videoCenter = {
        x: videoElement.videoWidth / 2,
        y: videoElement.videoHeight / 2
      };
      
      const faceCenter = {
        x: (face.topLeft[0] + face.bottomRight[0]) / 2,
        y: (face.topLeft[1] + face.bottomRight[1]) / 2
      };

      const distance = Math.sqrt(
        Math.pow(faceCenter.x - videoCenter.x, 2) +
        Math.pow(faceCenter.y - videoCenter.y, 2)
      );

      if (distance > videoElement.videoWidth * 0.3) {
        warnings.push({
          type: 'looking_away',
          severity: 'low',
          details: 'Face not centered'
        });
      }
    }

    return warnings;
  }
}

export const antiCheatService = new AntiCheatService();
```

### Gửi warnings về server

```typescript
// Submit warning to server
async function submitWarning(attemptId: string, warning: any) {
  await fetch(`http://localhost:3000/api/attempts/${attemptId}/submit-warning`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(warning)
  });
}

// Monitor during exam
setInterval(async () => {
  const warnings = await antiCheatService.analyzeFrame(videoElement);
  
  for (const warning of warnings) {
    await submitWarning(attemptId, warning);
  }
}, 5000); // Check every 5 seconds
```

## Khi nào cần training custom model?

### ✅ Training custom model khi:

1. **Phát hiện hành vi cụ thể**:
   - Nhìn vào giấy nháp (specific to your setup)
   - Sử dụng điện thoại
   - Nói chuyện với ai đó

2. **Môi trường đặc biệt**:
   - Phòng thi có setup camera đặc biệt
   - Yêu cầu detection chính xác hơn
   - Cần phân loại nhiều hành vi phức tạp

3. **Tối ưu hiệu suất**:
   - Máy tính yếu, cần model nhẹ hơn
   - Cần FPS cao hơn
   - Bandwidth thấp

## Method 2: Training Custom Model

### Bước 1: Thu thập Dataset

**Yêu cầu**:
- 500-1000 ảnh cho mỗi class
- Webcam tương tự với học sinh sẽ dùng
- Điều kiện ánh sáng đa dạng

#### Setup thu thập

```python
import cv2
import os
from datetime import datetime

# Create directories
os.makedirs('dataset/normal', exist_ok=True)
os.makedirs('dataset/suspicious', exist_ok=True)

cap = cv2.VideoCapture(0)
mode = 'normal'  # or 'suspicious'
count = 0

print(f"Collecting images for '{mode}' class")
print("Press SPACE to capture, Q to quit, M to switch mode")

while True:
    ret, frame = cap.read()
    if not ret:
        break
    
    cv2.putText(frame, f"Mode: {mode} | Count: {count}", 
                (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
    cv2.imshow('Data Collection', frame)
    
    key = cv2.waitKey(1) & 0xFF
    
    if key == ord(' '):  # Space to capture
        filename = f"{mode}_{count}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.jpg"
        cv2.imwrite(f'dataset/{mode}/{filename}', frame)
        count += 1
        print(f"Saved: {filename}")
    
    elif key == ord('m'):  # Switch mode
        mode = 'suspicious' if mode == 'normal' else 'normal'
        count = 0
        print(f"Switched to '{mode}' mode")
    
    elif key == ord('q'):  # Quit
        break

cap.release()
cv2.destroyAllWindows()

print(f"\nTotal images collected:")
print(f"Normal: {len(os.listdir('dataset/normal'))}")
print(f"Suspicious: {len(os.listdir('dataset/suspicious'))}")
```

#### Hành vi cần thu thập

**Normal behavior** (500+ ảnh):
- Nhìn thẳng vào màn hình
- 1 khuôn mặt duy nhất
- Tập trung
- Đa dạng góc nhìn nhẹ (±15°)

**Suspicious behavior** (500+ ảnh):
- Nhìn đi chỗ khác (trái, phải, lên, xuống)
- Nhiều người trong khung hình
- Không có khuôn mặt
- Dùng điện thoại
- Nhìn vào giấy nháp

### Bước 2: Preprocessing

```python
import cv2
import numpy as np
from tensorflow.keras.preprocessing.image import ImageDataGenerator

# Data augmentation
datagen = ImageDataGenerator(
    rescale=1./255,
    rotation_range=10,
    width_shift_range=0.1,
    height_shift_range=0.1,
    shear_range=0.1,
    zoom_range=0.1,
    horizontal_flip=True,
    fill_mode='nearest',
    validation_split=0.2
)

# Load training data
train_generator = datagen.flow_from_directory(
    'dataset/',
    target_size=(224, 224),
    batch_size=32,
    class_mode='binary',
    subset='training'
)

# Load validation data
validation_generator = datagen.flow_from_directory(
    'dataset/',
    target_size=(224, 224),
    batch_size=32,
    class_mode='binary',
    subset='validation'
)

print(f"Found {train_generator.n} training images")
print(f"Found {validation_generator.n} validation images")
print(f"Classes: {train_generator.class_indices}")
```

### Bước 3: Train Model

#### Option A: Simple CNN (Lightweight)

```python
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Conv2D, MaxPooling2D, Flatten, Dense, Dropout
from tensorflow.keras.optimizers import Adam

# Build model
model = Sequential([
    # Conv block 1
    Conv2D(32, (3, 3), activation='relu', input_shape=(224, 224, 3)),
    MaxPooling2D(2, 2),
    
    # Conv block 2
    Conv2D(64, (3, 3), activation='relu'),
    MaxPooling2D(2, 2),
    
    # Conv block 3
    Conv2D(128, (3, 3), activation='relu'),
    MaxPooling2D(2, 2),
    
    # Flatten and dense layers
    Flatten(),
    Dense(128, activation='relu'),
    Dropout(0.5),
    Dense(1, activation='sigmoid')  # Binary classification
])

model.compile(
    optimizer=Adam(learning_rate=0.001),
    loss='binary_crossentropy',
    metrics=['accuracy']
)

model.summary()

# Train
history = model.fit(
    train_generator,
    epochs=20,
    validation_data=validation_generator,
    verbose=1
)

# Save model
model.save('anticheat_model_simple.h5')
```

#### Option B: MobileNetV2 (Better Accuracy)

```python
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.models import Model
from tensorflow.keras.layers import Dense, GlobalAveragePooling2D, Dropout

# Load pre-trained MobileNetV2
base_model = MobileNetV2(
    input_shape=(224, 224, 3),
    include_top=False,
    weights='imagenet'
)

# Freeze base model
base_model.trainable = False

# Add custom top layers
x = base_model.output
x = GlobalAveragePooling2D()(x)
x = Dense(128, activation='relu')(x)
x = Dropout(0.5)(x)
output = Dense(1, activation='sigmoid')(x)

model = Model(inputs=base_model.input, outputs=output)

model.compile(
    optimizer=Adam(learning_rate=0.0001),
    loss='binary_crossentropy',
    metrics=['accuracy']
)

# Train
history = model.fit(
    train_generator,
    epochs=10,
    validation_data=validation_generator
)

# Fine-tune: Unfreeze last layers
base_model.trainable = True
for layer in base_model.layers[:-20]:
    layer.trainable = False

model.compile(
    optimizer=Adam(learning_rate=0.00001),
    loss='binary_crossentropy',
    metrics=['accuracy']
)

history_fine = model.fit(
    train_generator,
    epochs=10,
    validation_data=validation_generator
)

model.save('anticheat_model_mobilenet.h5')
```

### Bước 4: Convert to TensorFlow.js

```bash
# Install tensorflowjs converter
pip install tensorflowjs

# Convert model
tensorflowjs_converter \
    --input_format keras \
    anticheat_model_mobilenet.h5 \
    tfjs_model/
```

### Bước 5: Evaluate Model

```python
import matplotlib.pyplot as plt
from sklearn.metrics import classification_report, confusion_matrix
import seaborn as sns

# Plot training history
plt.figure(figsize=(12, 4))

plt.subplot(1, 2, 1)
plt.plot(history.history['accuracy'], label='Training Accuracy')
plt.plot(history.history['val_accuracy'], label='Validation Accuracy')
plt.xlabel('Epoch')
plt.ylabel('Accuracy')
plt.legend()
plt.title('Model Accuracy')

plt.subplot(1, 2, 2)
plt.plot(history.history['loss'], label='Training Loss')
plt.plot(history.history['val_loss'], label='Validation Loss')
plt.xlabel('Epoch')
plt.ylabel('Loss')
plt.legend()
plt.title('Model Loss')

plt.tight_layout()
plt.savefig('training_history.png')

# Evaluate on test set
test_generator = datagen.flow_from_directory(
    'dataset/',
    target_size=(224, 224),
    batch_size=32,
    class_mode='binary',
    shuffle=False
)

predictions = model.predict(test_generator)
predicted_classes = (predictions > 0.5).astype(int)

# Confusion matrix
cm = confusion_matrix(test_generator.classes, predicted_classes)
plt.figure(figsize=(8, 6))
sns.heatmap(cm, annot=True, fmt='d', cmap='Blues')
plt.xlabel('Predicted')
plt.ylabel('Actual')
plt.title('Confusion Matrix')
plt.savefig('confusion_matrix.png')

# Classification report
print("\nClassification Report:")
print(classification_report(
    test_generator.classes,
    predicted_classes,
    target_names=['Normal', 'Suspicious']
))
```

## Method 3: Fine-tuning Pre-trained Models

### Using YOLO for Person Detection

```python
# YOLOv5 for detecting multiple people
import torch

# Load YOLOv5
model = torch.hub.load('ultralytics/yolov5', 'yolov5s')

def detect_people(image_path):
    results = model(image_path)
    
    # Filter for person class (class 0)
    people = results.pandas().xyxy[0]
    people = people[people['class'] == 0]
    
    return len(people), people

# Example usage
count, detections = detect_people('test_image.jpg')
print(f"Detected {count} people")
```

## Deployment và Integration

### Integrate với Client

```typescript
// src/services/customAntiCheatService.ts
import * as tf from '@tensorflow/tfjs';

class CustomAntiCheatService {
  private model: tf.LayersModel | null = null;

  async loadModel() {
    this.model = await tf.loadLayersModel('/models/anticheat/model.json');
    console.log('Custom anti-cheat model loaded');
  }

  async predict(videoElement: HTMLVideoElement): Promise<number> {
    if (!this.model) {
      await this.loadModel();
    }

    // Capture frame
    const canvas = document.createElement('canvas');
    canvas.width = 224;
    canvas.height = 224;
    const ctx = canvas.getContext('2d')!;
    ctx.drawImage(videoElement, 0, 0, 224, 224);

    // Preprocess
    const tensor = tf.browser.fromPixels(canvas)
      .toFloat()
      .div(255.0)
      .expandDims(0);

    // Predict
    const prediction = this.model!.predict(tensor) as tf.Tensor;
    const score = await prediction.data();

    // Cleanup
    tensor.dispose();
    prediction.dispose();

    return score[0]; // 0-1, higher = more suspicious
  }

  async analyze(videoElement: HTMLVideoElement) {
    const suspiciousScore = await this.predict(videoElement);

    const warnings = [];

    if (suspiciousScore > 0.7) {
      warnings.push({
        type: 'suspicious_behavior',
        severity: 'high',
        details: `Suspicious behavior detected (confidence: ${(suspiciousScore * 100).toFixed(1)}%)`
      });
    } else if (suspiciousScore > 0.5) {
      warnings.push({
        type: 'suspicious_behavior',
        severity: 'medium',
        details: `Potentially suspicious behavior (confidence: ${(suspiciousScore * 100).toFixed(1)}%)`
      });
    }

    return warnings;
  }
}

export const customAntiCheatService = new CustomAntiCheatService();
```

## Best Practices

### 1. Dataset Quality

✅ **Good practices**:
- Collect data from actual students
- Diverse lighting conditions
- Various camera angles
- Multiple people in dataset
- Balance classes (50/50 normal/suspicious)

❌ **Avoid**:
- Too little data (< 200 images per class)
- Imbalanced classes (90% normal, 10% suspicious)
- Only one person's face
- Same background for all images

### 2. Model Selection

| Model | Size | Speed | Accuracy | Use Case |
|-------|------|-------|----------|----------|
| Simple CNN | ~5MB | Very Fast | 85% | Low-end devices |
| MobileNetV2 | ~15MB | Fast | 92% | **Recommended** |
| ResNet50 | ~100MB | Moderate | 95% | High accuracy needed |
| EfficientNet | ~30MB | Moderate | 94% | Balance |

### 3. Performance Optimization

```typescript
// Throttle predictions
let lastPrediction = 0;
const predictionInterval = 3000; // 3 seconds

async function monitorWithThrottle(videoElement: HTMLVideoElement) {
  const now = Date.now();
  
  if (now - lastPrediction >= predictionInterval) {
    const warnings = await customAntiCheatService.analyze(videoElement);
    lastPrediction = now;
    return warnings;
  }
  
  return [];
}
```

### 4. False Positive Handling

```typescript
// Require multiple consecutive detections
class WarningBuffer {
  private buffer: any[] = [];
  private bufferSize = 3;

  addWarning(warning: any) {
    this.buffer.push(warning);
    if (this.buffer.length > this.bufferSize) {
      this.buffer.shift();
    }
  }

  shouldReport(): boolean {
    // Only report if warning appears in majority of recent checks
    return this.buffer.length >= this.bufferSize &&
           this.buffer.filter(w => w.type === 'suspicious_behavior').length >= 2;
  }
}
```

## Troubleshooting

### Model quá chậm

**Solution**: Reduce model size, lower resolution, increase prediction interval

```typescript
// Lower resolution
const tensor = tf.browser.fromPixels(canvas)
  .resizeBilinear([128, 128])  // Instead of 224x224
  .toFloat()
  .div(255.0)
  .expandDims(0);
```

### Nhiều false positives

**Solution**: Adjust threshold, add buffer, collect more training data

```typescript
// Higher threshold
if (suspiciousScore > 0.8) {  // Instead of 0.7
  // Report warning
}
```

### Model không accurate

**Solution**: More training data, better augmentation, different architecture

## Resources

- [TensorFlow.js Models](https://www.tensorflow.org/js/models)
- [BlazeFace](https://github.com/tensorflow/tfjs-models/tree/master/blazeface)
- [YOLOv5](https://github.com/ultralytics/yolov5)
- [OpenCV Python Tutorial](https://docs.opencv.org/master/d6/d00/tutorial_py_root.html)

## Summary

**Default (No Training)**:
- ✅ Use BlazeFace for face detection
- ✅ Works immediately
- ✅ 95% accuracy for basic cases

**Custom Model (Advanced)**:
- 📊 Collect 500+ images per class
- 🤖 Train with MobileNetV2
- 🚀 Convert to TensorFlow.js
- 📱 Deploy to client

**Remember**: Hệ thống mặc định với BlazeFace đủ tốt cho hầu hết trường hợp. Chỉ training custom model khi có yêu cầu đặc biệt!
