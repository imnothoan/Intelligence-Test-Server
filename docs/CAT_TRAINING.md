# CAT Model Training Guide
# Hướng Dẫn Training Mô Hình CAT (Computerized Adaptive Testing)

## 📚 Table of Contents

- [Giới thiệu / Introduction](#giới-thiệu--introduction)
- [Tại sao cần Training CAT?](#tại-sao-cần-training-cat)
- [Cách thức hoạt động](#cách-thức-hoạt-động)
- [Method 1: Manual Calibration (Quick Start)](#method-1-manual-calibration-quick-start)
- [Method 2: Data-Based Calibration](#method-2-data-based-calibration)
- [Method 3: IRT-Based Calibration (Advanced)](#method-3-irt-based-calibration-advanced)
- [Best Practices](#best-practices)

## Giới thiệu / Introduction

CAT (Computerized Adaptive Testing) là hệ thống thi thích ứng, tự động điều chỉnh độ khó câu hỏi dựa trên khả năng của học sinh.

**Lưu ý quan trọng**: Bạn **KHÔNG BẮT BUỘC** phải training CAT model. Hệ thống đã sẵn sàng hoạt động ngay khi bạn gán độ khó cho câu hỏi.

## Tại sao cần Training CAT?

### ❌ Không cần training trong các trường hợp:
- Mới bắt đầu sử dụng hệ thống
- Số lượng học sinh < 50
- Chưa có đủ dữ liệu từ các kỳ thi
- Chỉ dùng để thử nghiệm

### ✅ Nên training khi:
- Đã có 100+ học sinh làm bài
- Muốn cải thiện độ chính xác
- Có dữ liệu từ 3-6 tháng sử dụng
- Phát hiện độ khó không chính xác

## Cách thức hoạt động

### IRT (Item Response Theory) 1PL Model

CAT sử dụng mô hình IRT 1-parameter:

```
P(θ, b) = 1 / (1 + e^(-(θ - b)))
```

Trong đó:
- `θ` (theta): Ability của học sinh (-3 đến +3)
- `b`: Difficulty của câu hỏi (-3 đến +3)
- `P`: Xác suất trả lời đúng

### Quy trình CAT

1. **Khởi tạo**: Ability ban đầu = 0 (trung bình)
2. **Chọn câu hỏi**: Chọn câu có độ khó gần với ability hiện tại
3. **Học sinh trả lời**: Đúng → tăng ability, Sai → giảm ability
4. **Cập nhật ability**: Dùng Maximum Likelihood Estimation (MLE)
5. **Lặp lại** cho đến khi đạt độ chính xác hoặc hết câu hỏi

## Method 1: Manual Calibration (Quick Start)

**Thời gian**: 5 phút  
**Yêu cầu**: Hiểu biết về môn học  
**Độ chính xác**: 70-80%

### Bước 1: Xác định độ khó

Khi tạo câu hỏi, gán độ khó theo quy tắc:

```
Độ khó 0.0-1.0:

Easy (0.0 - 0.3):
- Kiến thức cơ bản, ghi nhớ
- Công thức đơn giản
- Học sinh yếu có thể làm được
Ví dụ: "2 + 2 = ?"

Medium (0.3 - 0.7):
- Vận dụng kiến thức
- Tính toán trung bình
- Đa số học sinh làm được
Ví dụ: "Tính đạo hàm của x^2"

Hard (0.7 - 1.0):
- Phân tích, tổng hợp
- Nhiều bước giải
- Chỉ học sinh giỏi làm được
Ví dụ: "Chứng minh định lý..."
```

### Bước 2: Tạo câu hỏi với API

```bash
curl -X POST http://localhost:3000/api/questions \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "multiple-choice",
    "question_text": "Tính 2 + 2 = ?",
    "options": ["3", "4", "5", "6"],
    "correct_answer": "1",
    "difficulty": 0.2,
    "topic": "Toán học cơ bản"
  }'
```

### Bước 3: Kiểm tra

Sau khi có 10-20 học sinh làm bài, xem analytics:
- Nếu câu "dễ" mà tỷ lệ đúng < 60% → Tăng độ khó
- Nếu câu "khó" mà tỷ lệ đúng > 80% → Giảm độ khó

## Method 2: Data-Based Calibration

**Thời gian**: 30 phút  
**Yêu cầu**: Python, có dữ liệu từ 50+ học sinh  
**Độ chính xác**: 85-90%

### Bước 1: Export dữ liệu từ Supabase

Trong Supabase SQL Editor:

```sql
-- Export question performance data
SELECT 
    q.id as question_id,
    q.question_text,
    q.difficulty as current_difficulty,
    COUNT(DISTINCT ea.student_id) as total_attempts,
    SUM(CASE WHEN resp->>'is_correct' = 'true' THEN 1 ELSE 0 END) as correct_count
FROM questions q
LEFT JOIN exam_attempts ea ON ea.responses @> jsonb_build_array(
    jsonb_build_object('question_id', q.id)
)
GROUP BY q.id
HAVING COUNT(DISTINCT ea.student_id) >= 10
ORDER BY q.difficulty;
```

Save kết quả vào `question_performance.csv`

### Bước 2: Tính toán độ khó mới

Create file `calibrate_cat.py`:

```python
import pandas as pd
import numpy as np

# Load data
df = pd.read_csv('question_performance.csv')

# Calculate p-value (proportion correct)
df['p_value'] = df['correct_count'] / df['total_attempts']

# Convert p-value to difficulty (0-1 scale)
# Harder questions have lower p-value, higher difficulty
df['new_difficulty'] = 1 - df['p_value']

# Normalize to 0-1 range
df['new_difficulty'] = (df['new_difficulty'] - df['new_difficulty'].min()) / \
                       (df['new_difficulty'].max() - df['new_difficulty'].min())

# Blend with current difficulty (70% new, 30% old)
df['calibrated_difficulty'] = 0.7 * df['new_difficulty'] + 0.3 * df['current_difficulty']

# Save results
df[['question_id', 'calibrated_difficulty']].to_csv('updated_difficulties.csv', index=False)

print("Calibration complete!")
print(f"Updated {len(df)} questions")
print("\nDifficulty distribution:")
print(df['calibrated_difficulty'].describe())
```

Run script:

```bash
pip install pandas numpy
python calibrate_cat.py
```

### Bước 3: Update vào database

```python
import pandas as pd
import requests

df = pd.read_csv('updated_difficulties.csv')

API_URL = 'http://localhost:3000/api'
TOKEN = 'your_jwt_token'

headers = {
    'Authorization': f'Bearer {TOKEN}',
    'Content-Type': 'application/json'
}

for _, row in df.iterrows():
    question_id = row['question_id']
    difficulty = row['calibrated_difficulty']
    
    response = requests.put(
        f'{API_URL}/questions/{question_id}',
        headers=headers,
        json={'difficulty': float(difficulty)}
    )
    
    if response.status_code == 200:
        print(f'✓ Updated question {question_id}')
    else:
        print(f'✗ Failed to update {question_id}')

print("\nAll questions updated!")
```

## Method 3: IRT-Based Calibration (Advanced)

**Thời gian**: 2-3 giờ  
**Yêu cầu**: Python, R, Statistical knowledge, 100+ responses per question  
**Độ chính xác**: 95%+

### Yêu cầu

- 100+ học sinh đã làm bài
- Mỗi câu hỏi có tối thiểu 100 responses
- Kiến thức về IRT và statistics

### Bước 1: Prepare Data

```python
import pandas as pd
import numpy as np
from sqlalchemy import create_engine

# Connect to Supabase
engine = create_engine('postgresql://user:pass@host:port/database')

# Get response data
query = """
SELECT 
    ea.student_id,
    ea.exam_id,
    jsonb_array_elements(ea.responses) as response
FROM exam_attempts ea
WHERE ea.status = 'completed'
"""

responses = pd.read_sql(query, engine)

# Parse JSON responses
responses['question_id'] = responses['response'].apply(lambda x: x['question_id'])
responses['is_correct'] = responses['response'].apply(lambda x: x.get('is_correct', False))

# Pivot to wide format (students x questions)
response_matrix = responses.pivot_table(
    index='student_id',
    columns='question_id',
    values='is_correct',
    aggfunc='first'
).fillna(-1)  # -1 for not attempted

# Save for IRT analysis
response_matrix.to_csv('irt_data.csv')
```

### Bước 2: IRT Analysis with R

Install R package:

```r
install.packages("mirt")
```

Create `irt_analysis.R`:

```r
library(mirt)

# Load data
data <- read.csv('irt_data.csv', row.names=1)

# Remove questions with < 100 responses
valid_cols <- colSums(data != -1) >= 100
data <- data[, valid_cols]

# Fit 1PL model (Rasch model)
model <- mirt(data, model=1, itemtype='Rasch', verbose=TRUE)

# Extract item parameters
params <- coef(model, IRTpars=TRUE, simplify=TRUE)
item_params <- params$items

# Difficulty parameters
difficulties <- item_params[, 'b']

# Normalize to 0-1 scale
difficulties_normalized <- (difficulties - min(difficulties)) / 
                           (max(difficulties) - min(difficulties))

# Save results
results <- data.frame(
    question_id = colnames(data),
    irt_difficulty = difficulties_normalized,
    discrimination = item_params[, 'a'],
    fit_statistics = itemfit(model)$outfit
)

write.csv(results, 'irt_results.csv', row.names=FALSE)

# Model fit statistics
print("Model Fit:")
print(M2(model))

# Plot item characteristic curves
plot(model, type='trace', which.items=1:min(20, ncol(data)))
```

Run in R:

```bash
Rscript irt_analysis.R
```

### Bước 3: Validate and Update

```python
import pandas as pd

# Load IRT results
irt_results = pd.read_csv('irt_results.csv')

# Filter questions with good fit (outfit < 1.5)
good_fit = irt_results[irt_results['fit_statistics'] < 1.5]

print(f"Questions with good fit: {len(good_fit)}/{len(irt_results)}")

# Update database (same as Method 2, Bước 3)
# Use good_fit['irt_difficulty'] as new difficulty values
```

## Best Practices

### 1. Số lượng câu hỏi

```
Recommended question bank size:
- Minimum: 50 questions
- Good: 100-200 questions
- Excellent: 300+ questions

Difficulty distribution:
- Easy (0.0-0.3): 20-30%
- Medium (0.3-0.7): 40-50%
- Hard (0.7-1.0): 20-30%
```

### 2. Tần suất calibration

```
First 3 months: Manual calibration
After 100 students: Data-based calibration (monthly)
After 500 students: IRT-based calibration (quarterly)
Ongoing: Monitor and adjust
```

### 3. Quality checks

```python
# Check difficulty distribution
def check_difficulty_distribution(difficulties):
    easy = sum(1 for d in difficulties if d < 0.3)
    medium = sum(1 for d in difficulties if 0.3 <= d < 0.7)
    hard = sum(1 for d in difficulties if d >= 0.7)
    
    total = len(difficulties)
    print(f"Easy: {easy/total*100:.1f}%")
    print(f"Medium: {medium/total*100:.1f}%")
    print(f"Hard: {hard/total*100:.1f}%")
    
    # Ideal distribution
    if 20 <= easy/total*100 <= 35 and \
       40 <= medium/total*100 <= 55:
        print("✓ Good distribution!")
    else:
        print("⚠ Adjust distribution")
```

### 4. Monitoring CAT performance

```sql
-- Check CAT effectiveness
SELECT 
    AVG(questions_administered) as avg_questions,
    AVG(standard_error) as avg_precision,
    AVG(ABS(ability_estimate)) as avg_ability
FROM exam_attempts
WHERE cat_state IS NOT NULL
  AND status = 'completed';

-- Ideal values:
-- avg_questions: 10-15 (efficient)
-- avg_precision: < 0.3 (precise)
-- avg_ability: 0.5-1.5 (good spread)
```

## Troubleshooting

### Problem: Tất cả học sinh đều điểm cao/thấp

**Solution**: Câu hỏi quá dễ/khó hoặc phân phối không đều

```python
# Adjust difficulties
df['difficulty'] = df['difficulty'] * 0.8  # Make easier
# or
df['difficulty'] = df['difficulty'] * 1.2  # Make harder
```

### Problem: CAT test quá ngắn/dài

**Solution**: Điều chỉnh CAT settings

```json
{
  "cat_settings": {
    "initial_ability": 0,
    "precision_threshold": 0.25,  // Lower = more questions
    "min_questions": 8,            // Increase minimum
    "max_questions": 25            // Decrease maximum
  }
}
```

### Problem: Một số câu hỏi không bao giờ được chọn

**Solution**: Độ khó không phù hợp hoặc quá ít câu dễ/khó

```sql
-- Find unused questions
SELECT q.id, q.difficulty, 
       COUNT(DISTINCT ea.id) as times_used
FROM questions q
LEFT JOIN exam_attempts ea ON 
    ea.responses @> jsonb_build_array(
        jsonb_build_object('question_id', q.id)
    )
GROUP BY q.id
HAVING COUNT(DISTINCT ea.id) < 5
ORDER BY q.difficulty;
```

## Resources

- [IRT on Wikipedia](https://en.wikipedia.org/wiki/Item_response_theory)
- [mirt package documentation](https://cran.r-project.org/web/packages/mirt/mirt.pdf)
- [CAT Tutorial](https://www.assess.com/cat-tutorial/)

## Summary

**Quick Start (5 minutes)**:
```bash
# Just assign difficulties manually:
Easy: 0.0-0.3
Medium: 0.3-0.7
Hard: 0.7-1.0

# Start using immediately!
```

**Regular Maintenance (monthly)**:
```bash
# Export data → Calculate new difficulties → Update database
python calibrate_cat.py
```

**Advanced Optimization (quarterly)**:
```bash
# Full IRT analysis
Rscript irt_analysis.R
```

**Remember**: CAT works immediately with manual calibration. Advanced training chỉ cần thiết khi bạn muốn tối ưu hóa độ chính xác sau khi đã có nhiều dữ liệu.
