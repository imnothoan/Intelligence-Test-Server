# Exam Generation Guide với Google Gemini API
# Hướng Dẫn Tạo Đề Thi Tự Động với AI (MIỄN PHÍ)

## 📚 Table of Contents

- [Giới thiệu](#giới-thiệu)
- [Setup Gemini API (FREE)](#setup-gemini-api-free)
- [Tạo câu hỏi trắc nghiệm](#tạo-câu-hỏi-trắc-nghiệm)
- [Tạo câu hỏi tự luận](#tạo-câu-hỏi-tự-luận)
- [Prompt Templates theo cấp học](#prompt-templates-theo-cấp-học)
- [Prompt Templates theo môn học](#prompt-templates-theo-môn-học)
- [Advanced Techniques](#advanced-techniques)
- [Best Practices](#best-practices)

## Giới thiệu

**Google Gemini** là AI model miễn phí từ Google, hỗ trợ tuyệt vời cho tiếng Việt.

### Tại sao chọn Gemini?

✅ **Hoàn toàn MIỄN PHÍ**
- Không cần thẻ tín dụng
- 60 requests/phút
- 1,500 requests/ngày
- Đủ cho 200+ học sinh/ngày

✅ **Hỗ trợ Tiếng Việt xuất sắc**
- Hiểu ngữ cảnh tiếng Việt
- Sinh câu hỏi tự nhiên
- Chấm bài tự luận chính xác

✅ **Dễ sử dụng**
- API đơn giản
- Tích hợp sẵn trong server
- Chỉ cần API key

## Setup Gemini API (FREE)

### Bước 1: Lấy API Key

1. Truy cập [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Đăng nhập bằng Google account
3. Click **"Get API Key"**
4. Click **"Create API key in new project"**
5. Copy API key (bắt đầu với `AIza...`)

**Lưu ý**: API key này MIỄN PHÍ và không yêu cầu thẻ tín dụng!

### Bước 2: Cấu hình Server

Thêm vào file `.env`:

```env
GEMINI_API_KEY=AIza...your-key-here
```

### Bước 3: Verify hoạt động

```bash
# Start server
npm run dev

# Test API endpoint
curl -X POST http://localhost:3000/api/questions/generate \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "topic": "Lịch sử Việt Nam",
    "difficulty": 0.5,
    "count": 5,
    "type": "multiple-choice",
    "grade_level": "high",
    "language": "vi"
  }'
```

## Tạo câu hỏi trắc nghiệm

### Basic Usage

```bash
curl -X POST http://localhost:3000/api/questions/generate \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "topic": "Toán học - Phương trình bậc 2",
    "difficulty": 0.5,
    "count": 10,
    "type": "multiple-choice",
    "grade_level": "high",
    "subject": "math",
    "language": "vi"
  }'
```

### Response

```json
{
  "success": true,
  "data": [
    {
      "id": "uuid-here",
      "type": "multiple-choice",
      "question_text": "Phương trình x² - 5x + 6 = 0 có nghiệm là:",
      "options": [
        "x₁ = 2, x₂ = 3",
        "x₁ = 1, x₂ = 6",
        "x₁ = -2, x₂ = -3",
        "Vô nghiệm"
      ],
      "correct_answer": 0,
      "difficulty": 0.5,
      "topic": "Toán học - Phương trình bậc 2",
      "explanation": "Sử dụng công thức Viète: x₁ + x₂ = 5, x₁ × x₂ = 6. Ta có x₁ = 2 và x₂ = 3."
    }
  ],
  "message": "Successfully generated 10 questions"
}
```

### JavaScript/TypeScript Client

```typescript
async function generateQuestions(config: {
  topic: string;
  difficulty: number;
  count: number;
  gradeLevel?: string;
  subject?: string;
}) {
  const response = await fetch('http://localhost:3000/api/questions/generate', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      ...config,
      type: 'multiple-choice',
      language: 'vi'
    })
  });

  const result = await response.json();
  return result.data;
}

// Usage
const questions = await generateQuestions({
  topic: 'Văn học Việt Nam thế kỷ 20',
  difficulty: 0.6,
  count: 15,
  gradeLevel: 'high',
  subject: 'literature'
});
```

## Tạo câu hỏi tự luận

### Request

```json
{
  "topic": "Phân tích tác phẩm Chí Phèo",
  "difficulty": 0.7,
  "count": 3,
  "type": "essay",
  "grade_level": "high",
  "subject": "literature",
  "language": "vi"
}
```

### Response

```json
{
  "success": true,
  "data": [
    {
      "id": "uuid-here",
      "type": "essay",
      "question_text": "Phân tích hình tượng nhân vật Chí Phèo trong tác phẩm cùng tên của Nam Cao. Qua đó, em hãy nêu lên vấn đề xã hội mà tác giả muốn đề cập.",
      "difficulty": 0.7,
      "topic": "Phân tích tác phẩm Chí Phèo",
      "explanation": "Bài làm tốt cần có: 1) Giới thiệu tác phẩm và tác giả. 2) Phân tích hình tượng Chí Phèo: xuất thân, tính cách, hành động. 3) Nguyên nhân dẫn đến số phận bi đát. 4) Vấn đề xã hội: chế độ phong kiến, sự bất công xã hội. 5) Kết luận về giá trị nhân đạo."
    }
  ]
}
```

## Prompt Templates theo cấp học

### Tiểu học (Elementary)

```typescript
const elementaryConfig = {
  topic: "Phép cộng và trừ trong phạm vi 100",
  difficulty: 0.2,
  count: 10,
  type: "multiple-choice",
  grade_level: "elementary",
  subject: "math",
  language: "vi"
};

// Gemini sẽ tạo câu hỏi phù hợp:
// - Ngôn ngữ đơn giản, dễ hiểu
// - Số liệu nhỏ (< 100)
// - Tình huống gần gũi (trái cây, đồ chơi)
```

**Ví dụ câu hỏi sinh ra**:
```
"Lan có 35 viên bi, được mẹ cho thêm 27 viên. Hỏi Lan có tất cả bao nhiêu viên bi?"
A. 52 viên
B. 62 viên ✓
C. 72 viên
D. 42 viên
```

### Trung học cơ sở (Middle School)

```typescript
const middleSchoolConfig = {
  topic: "Định luật Ôm - Vật lý",
  difficulty: 0.5,
  count: 8,
  type: "multiple-choice",
  grade_level: "middle",
  subject: "science",
  language: "vi"
};
```

**Ví dụ**:
```
"Một dây dẫn có điện trở 12Ω được mắc vào hiệu điện thế 6V. 
Cường độ dòng điện chạy qua dây dẫn là:"
A. 0.5A ✓
B. 2A
C. 72A
D. 18A

Giải thích: Áp dụng định luật Ôm: I = U/R = 6/12 = 0.5A
```

### Trung học phổ thông (High School)

```typescript
const highSchoolConfig = {
  topic: "Hàm số bậc hai và đồ thị",
  difficulty: 0.7,
  count: 12,
  type: "multiple-choice",
  grade_level: "high",
  subject: "math",
  language: "vi"
};
```

**Ví dụ**:
```
"Tìm tập giá trị của hàm số y = x² - 4x + 5"
A. [1, +∞) ✓
B. (-∞, +∞)
C. [5, +∞)
D. [-1, +∞)

Giải thích: y = (x-2)² + 1, đỉnh parabol tại (2,1), bề lõm hướng lên.
Tập giá trị: [1, +∞)
```

### Đại học (University)

```typescript
const universityConfig = {
  topic: "Cấu trúc dữ liệu - Binary Search Tree",
  difficulty: 0.8,
  count: 5,
  type: "multiple-choice",
  grade_level: "university",
  subject: "math",
  language: "vi"
};
```

**Ví dụ**:
```
"Trong Binary Search Tree (BST) cân bằng với n nodes, 
độ phức tạp trung bình của thao tác search là:"
A. O(log n) ✓
B. O(n)
C. O(n log n)
D. O(1)

Giải thích: BST cân bằng có chiều cao h = log(n), 
mỗi bước search giảm một nửa không gian tìm kiếm.
```

## Prompt Templates theo môn học

### Toán học (Math)

```typescript
const mathTopics = [
  "Phép tính cơ bản",
  "Phân số và số thập phân",
  "Phương trình bậc nhất",
  "Phương trình bậc hai",
  "Hệ phương trình",
  "Hàm số",
  "Đạo hàm",
  "Tích phân",
  "Hình học không gian",
  "Xác suất thống kê"
];

// Example
await generateQuestions({
  topic: "Tích phân - Tính diện tích hình phẳng",
  difficulty: 0.7,
  count: 10,
  gradeLevel: "high",
  subject: "math"
});
```

### Ngữ văn (Literature)

```typescript
const literatureTopics = [
  "Phân tích tác phẩm văn học",
  "Nghệ thuật miêu tả",
  "Biện pháp tu từ",
  "Văn học trung đại",
  "Văn học hiện đại",
  "Thơ ca Việt Nam",
  "Truyện ngắn",
  "Luận văn xã hội"
];

// Essay questions
await generateQuestions({
  topic: "Phân tích đoạn thơ 'Tràng giang'",
  difficulty: 0.6,
  count: 5,
  gradeLevel: "high",
  subject: "literature",
  type: "essay"
});
```

### Khoa học (Science)

```typescript
const scienceTopics = [
  "Định luật Newton",
  "Điện học cơ bản",
  "Quang học",
  "Hóa học vô cơ",
  "Hóa học hữu cơ",
  "Sinh học tế bào",
  "Di truyền học",
  "Sinh thái học"
];

await generateQuestions({
  topic: "Định luật bảo toàn năng lượng",
  difficulty: 0.5,
  count: 8,
  gradeLevel: "high",
  subject: "science"
});
```

### Lịch sử (History)

```typescript
const historyTopics = [
  "Lịch sử Việt Nam cổ đại",
  "Cuộc kháng chiến chống Pháp",
  "Cuộc kháng chiến chống Mỹ",
  "Lịch sử thế giới hiện đại",
  "Cách mạng công nghiệp",
  "Chiến tranh thế giới",
  "Phong trào giải phóng dân tộc"
];

await generateQuestions({
  topic: "Phong trào Đông Du và ý nghĩa lịch sử",
  difficulty: 0.6,
  count: 10,
  gradeLevel: "high",
  subject: "history"
});
```

### Tiếng Anh (English)

```typescript
// Generate in Vietnamese for Vietnamese students
await generateQuestions({
  topic: "Grammar - Present Perfect Tense",
  difficulty: 0.5,
  count: 15,
  gradeLevel: "middle",
  subject: "english",
  language: "vi"  // Instructions in Vietnamese
});

// Or generate in English
await generateQuestions({
  topic: "Reading Comprehension - Short Stories",
  difficulty: 0.6,
  count: 10,
  gradeLevel: "high",
  subject: "english",
  language: "en"  // All English
});
```

## Advanced Techniques

### 1. Tạo đề thi hoàn chỉnh

```typescript
async function generateCompleteExam(params: {
  subject: string;
  gradeLevel: string;
  totalQuestions: number;
}) {
  const easyCount = Math.floor(params.totalQuestions * 0.3);
  const mediumCount = Math.floor(params.totalQuestions * 0.5);
  const hardCount = params.totalQuestions - easyCount - mediumCount;

  // Easy questions
  const easyQuestions = await generateQuestions({
    topic: `${params.subject} - Câu hỏi cơ bản`,
    difficulty: 0.2,
    count: easyCount,
    gradeLevel: params.gradeLevel,
    subject: params.subject
  });

  // Medium questions
  const mediumQuestions = await generateQuestions({
    topic: `${params.subject} - Câu hỏi trung bình`,
    difficulty: 0.5,
    count: mediumCount,
    gradeLevel: params.gradeLevel,
    subject: params.subject
  });

  // Hard questions
  const hardQuestions = await generateQuestions({
    topic: `${params.subject} - Câu hỏi nâng cao`,
    difficulty: 0.8,
    count: hardCount,
    gradeLevel: params.gradeLevel,
    subject: params.subject
  });

  return [...easyQuestions, ...mediumQuestions, ...hardQuestions];
}

// Usage
const examQuestions = await generateCompleteExam({
  subject: 'Toán học',
  gradeLevel: 'high',
  totalQuestions: 30
});
```

### 2. Tạo đề theo chương trình học

```typescript
const syllabus = {
  "Toán 10": [
    "Mệnh đề và tập hợp",
    "Hàm số bậc nhất",
    "Hàm số bậc hai",
    "Phương trình và bất phương trình",
    "Hệ phương trình"
  ]
};

async function generateFromSyllabus(grade: string, questionsPerTopic: number) {
  const topics = syllabus[grade];
  const allQuestions = [];

  for (const topic of topics) {
    const questions = await generateQuestions({
      topic,
      difficulty: 0.5,
      count: questionsPerTopic,
      gradeLevel: "high",
      subject: "math"
    });
    allQuestions.push(...questions);
  }

  return allQuestions;
}
```

### 3. Tạo đề kiểm tra theo Bloom's Taxonomy

```typescript
const bloomLevels = {
  remember: 0.2,    // Nhớ, ghi nhớ
  understand: 0.4,  // Hiểu
  apply: 0.5,       // Vận dụng
  analyze: 0.7,     // Phân tích
  evaluate: 0.8,    // Đánh giá
  create: 0.9       // Sáng tạo
};

async function generateByBloomTaxonomy(topic: string) {
  const questions = [];

  for (const [level, difficulty] of Object.entries(bloomLevels)) {
    const qs = await generateQuestions({
      topic: `${topic} - ${level} level`,
      difficulty,
      count: 3,
      gradeLevel: "high"
    });
    questions.push(...qs);
  }

  return questions;
}
```

### 4. Batch Generation với Rate Limiting

```typescript
async function batchGenerate(topics: string[], questionsPerTopic: number) {
  const allQuestions = [];
  const delayBetweenRequests = 1000; // 1 second (60 requests/minute limit)

  for (const topic of topics) {
    const questions = await generateQuestions({
      topic,
      difficulty: 0.5,
      count: questionsPerTopic,
      gradeLevel: "high"
    });

    allQuestions.push(...questions);

    // Wait to respect rate limit
    await new Promise(resolve => setTimeout(resolve, delayBetweenRequests));
  }

  return allQuestions;
}

// Generate for 50 topics (takes ~1 minute)
const topics = [
  "Đạo hàm của hàm số",
  "Tích phân xác định",
  // ... 48 more topics
];

const questions = await batchGenerate(topics, 5); // 250 questions total
```

## Best Practices

### 1. Optimize API Usage

```typescript
// Good: Generate multiple questions per request
await generateQuestions({
  topic: "Toán học",
  count: 20  // 1 API call
});

// Bad: Generate one at a time
for (let i = 0; i < 20; i++) {
  await generateQuestions({
    topic: "Toán học",
    count: 1  // 20 API calls!
  });
}
```

### 2. Error Handling

```typescript
async function generateWithRetry(config: any, maxRetries = 3) {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await generateQuestions(config);
    } catch (error) {
      if (attempt === maxRetries) {
        throw error;
      }
      
      // Exponential backoff
      await new Promise(resolve => 
        setTimeout(resolve, 1000 * Math.pow(2, attempt))
      );
    }
  }
}
```

### 3. Caching Results

```typescript
const questionCache = new Map();

async function generateOrGetCached(config: any) {
  const cacheKey = JSON.stringify(config);
  
  if (questionCache.has(cacheKey)) {
    console.log('Using cached questions');
    return questionCache.get(cacheKey);
  }

  const questions = await generateQuestions(config);
  questionCache.set(cacheKey, questions);
  return questions;
}
```

### 4. Quality Validation

```typescript
function validateQuestion(question: any): boolean {
  // Check required fields
  if (!question.question_text || !question.options) {
    return false;
  }

  // Check options count
  if (question.options.length < 2 || question.options.length > 6) {
    return false;
  }

  // Check correct answer
  if (question.correct_answer < 0 || 
      question.correct_answer >= question.options.length) {
    return false;
  }

  // Check for duplicates
  const uniqueOptions = new Set(question.options);
  if (uniqueOptions.size !== question.options.length) {
    return false;
  }

  return true;
}

// Filter generated questions
const validQuestions = generatedQuestions.filter(validateQuestion);
```

## Rate Limits & Quotas

### Free Tier Limits

```
Gemini API Free Tier:
- 60 requests/minute
- 1,500 requests/day
- No credit card required

Calculations:
- 1 request = 1-20 questions
- 1,500 requests/day × 10 questions = 15,000 questions/day
- Enough for 200+ students (75 questions each)
```

### Monitoring Usage

```typescript
let requestCount = 0;
let requestWindow = Date.now();

async function generateWithRateLimit(config: any) {
  const now = Date.now();
  
  // Reset counter every minute
  if (now - requestWindow > 60000) {
    requestCount = 0;
    requestWindow = now;
  }

  // Check limit
  if (requestCount >= 60) {
    throw new Error('Rate limit exceeded. Wait 1 minute.');
  }

  requestCount++;
  return await generateQuestions(config);
}
```

## Troubleshooting

### "API key not configured"

**Solution**:
```bash
# Check .env file
cat .env | grep GEMINI

# Restart server
npm run dev
```

### "Rate limit exceeded"

**Solution**: Wait 1 minute or reduce requests

```typescript
// Add delay between requests
await new Promise(r => setTimeout(r, 1000));
```

### Câu hỏi không hay / không chính xác

**Solution**: Improve prompts, adjust difficulty

```typescript
// More specific topic
const better = {
  topic: "Phương trình bậc 2 - Công thức nghiệm và định lý Viète",
  // instead of just "Phương trình bậc 2"
};
```

## Summary

**Quick Start**:
1. ✅ Get FREE API key from Google AI Studio
2. ✅ Add to `.env`: `GEMINI_API_KEY=...`
3. ✅ Call API: `POST /api/questions/generate`
4. ✅ Done! Tạo được ngay câu hỏi

**Production Tips**:
- 🚀 Generate 10-20 questions per request
- 📊 Mix difficulty levels (30% easy, 50% medium, 20% hard)
- ⏱️ Respect rate limits (60/minute, 1500/day)
- ✅ Validate generated questions
- 💾 Cache frequently used questions

**Remember**: Gemini is FREE and works great for Vietnamese! Không cần training, chỉ cần API key là dùng được ngay!
