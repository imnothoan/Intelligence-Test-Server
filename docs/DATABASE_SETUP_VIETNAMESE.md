# Hướng Dẫn Thiết Lập Database - Intelligence Test Server

## Mục Lục
1. [Tổng Quan](#tổng-quan)
2. [Tạo Project Supabase](#tạo-project-supabase)
3. [Cấu Hình Database](#cấu-hình-database)
4. [Import Dữ Liệu Mẫu](#import-dữ-liệu-mẫu)
5. [Tạo Ngân Hàng Câu Hỏi](#tạo-ngân-hàng-câu-hỏi)
6. [Tối Ưu Hóa](#tối-ưu-hóa)

## Tổng Quan

Database của hệ thống sử dụng **Supabase** (PostgreSQL) với các bảng sau:
- **users**: Tài khoản người dùng (học sinh và giáo viên)
- **classes**: Lớp học  
- **class_students**: Quan hệ học sinh-lớp học
- **questions**: Ngân hàng câu hỏi
- **exams**: Đề thi
- **exam_assignments**: Phân công đề thi cho lớp
- **exam_attempts**: Lượt thi của học sinh

## Tạo Project Supabase

### Bước 1: Đăng Ký Tài Khoản
1. Truy cập [supabase.com](https://supabase.com)
2. Nhấn **"Start your project"**
3. Đăng nhập bằng GitHub hoặc email

### Bước 2: Tạo Project Mới
1. Nhấn **"New Project"**
2. Điền thông tin:
   - **Name**: `intelligence-test` (hoặc tên bạn muốn)
   - **Database Password**: Chọn mật khẩu mạnh (lưu lại!)
   - **Region**: Chọn gần nhất (ví dụ: Southeast Asia)
   - **Pricing Plan**: Chọn **Free** (0đ/tháng, đủ cho 10,000+ câu hỏi)
3. Nhấn **"Create new project"**
4. Đợi 2-3 phút để project khởi tạo

### Bước 3: Lấy Thông Tin Kết Nối
1. Vào **Settings** → **API**
2. Copy các thông tin sau:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public key**: Cho client
   - **service_role key**: Cho server (GIỮ BÍ MẬT!)

3. Lưu vào file `.env`:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here
```

## Cấu Hình Database

### Bước 1: Chạy Migration Schema
1. Trong Supabase dashboard, vào **SQL Editor**
2. Nhấn **"New Query"**
3. Copy nội dung file `supabase/migrations/001_initial_schema.sql`
4. Paste vào editor
5. Nhấn **"Run"** hoặc Ctrl+Enter
6. Kiểm tra thành công:
   - ✅ Thông báo "Success. No rows returned"
   - ✅ Vào **Table Editor**, thấy 7 bảng đã tạo

### Bước 2: Kiểm Tra Bảng
Vào **Table Editor**, bạn sẽ thấy:
- ✅ **users** (id, email, name, role, ...)
- ✅ **classes** (id, name, instructor_id, ...)
- ✅ **class_students** (class_id, student_id)
- ✅ **questions** (id, question_text, options, difficulty, ...)
- ✅ **exams** (id, title, question_ids, enable_cat, ...)
- ✅ **exam_assignments** (exam_id, class_id)
- ✅ **exam_attempts** (id, exam_id, student_id, responses, ...)

### Bước 3: Kiểm Tra Demo Accounts
1. Vào **Table Editor** → **users**
2. Bạn sẽ thấy 2 tài khoản demo:
   - **instructor@test.com** - Giáo viên
   - **student@test.com** - Học sinh
3. Mật khẩu mặc định: `demo123` (cần hash lại!)

## Import Dữ Liệu Mẫu

### Bước 1: Import Câu Hỏi Mẫu
1. Vào **SQL Editor**
2. Nhấn **"New Query"**
3. Copy nội dung file `supabase/seeds/002_sample_questions.sql`
4. Paste và nhấn **"Run"**
5. Kiểm tra:
   ```sql
   SELECT COUNT(*) FROM questions;
   -- Kết quả: 60+ câu hỏi
   
   SELECT topic, COUNT(*) as count 
   FROM questions 
   GROUP BY topic 
   ORDER BY topic;
   -- Xem phân bố theo chủ đề
   ```

### Bước 2: Xem Dữ Liệu Đã Import
```sql
-- Xem câu hỏi Toán cấp 1
SELECT question_text, difficulty, topic 
FROM questions 
WHERE topic = 'Math - Elementary'
ORDER BY difficulty;

-- Xem câu hỏi Khoa học THCS
SELECT question_text, difficulty 
FROM questions 
WHERE topic = 'Science - Middle School';

-- Xem câu hỏi Văn (tiếng Việt)
SELECT question_text, topic 
FROM questions 
WHERE topic LIKE 'Literature%';
```

## Tạo Ngân Hàng Câu Hỏi

### Cấu Trúc Câu Hỏi

Mỗi câu hỏi cần:
1. **type**: 'multiple-choice' hoặc 'essay'
2. **question_text**: Nội dung câu hỏi
3. **options**: JSON array các đáp án (chỉ cho multiple-choice)
4. **correct_answer**: Vị trí đáp án đúng (0-3 cho multiple-choice)
5. **difficulty**: Độ khó từ 0.0 (dễ nhất) đến 1.0 (khó nhất)
6. **topic**: Chủ đề (ví dụ: "Math - High School")
7. **explanation**: Giải thích đáp án
8. **created_by**: ID giáo viên tạo

### Thang Độ Khó (Difficulty Scale)

| Độ Khó | Cấp Độ | Mô Tả |
|--------|--------|-------|
| 0.0 - 0.2 | Rất dễ | Câu hỏi cơ bản, cấp 1-2 |
| 0.2 - 0.4 | Dễ | Cấp 3-5, THCS đầu cấp |
| 0.4 - 0.6 | Trung bình | THCS cao cấp, THPT đầu cấp |
| 0.6 - 0.8 | Khó | THPT, thi đại học |
| 0.8 - 1.0 | Rất khó | Đại học, chuyên sâu |

### Template Thêm Câu Hỏi

#### Câu Hỏi Trắc Nghiệm
```sql
INSERT INTO questions (
    type, 
    question_text, 
    options, 
    correct_answer, 
    difficulty, 
    topic, 
    explanation, 
    created_by
) VALUES (
    'multiple-choice',
    'Thủ đô của Việt Nam là gì?',
    '["Hồ Chí Minh", "Hà Nội", "Đà Nẵng", "Huế"]',
    '1',  -- Index 1 = "Hà Nội"
    0.15, -- Độ khó thấp
    'History - Elementary',
    'Hà Nội là thủ đô của Việt Nam từ năm 1010',
    'YOUR-INSTRUCTOR-UUID-HERE'
);
```

#### Câu Hỏi Tự Luận
```sql
INSERT INTO questions (
    type, 
    question_text, 
    difficulty, 
    topic, 
    explanation, 
    created_by
) VALUES (
    'essay',
    'Hãy mô tả tầm quan trọng của giáo dục trong xã hội hiện đại. (200-300 từ)',
    0.55,
    'Writing - Social Issues',
    'Đánh giá dựa trên: hiểu biết về vai trò giáo dục, lập luận mạch lạc, ví dụ cụ thể',
    'YOUR-INSTRUCTOR-UUID-HERE'
);
```

### Mẫu Câu Hỏi Theo Môn Học

#### Toán Học
```sql
-- Cấp 1 (Elementary)
INSERT INTO questions VALUES 
('multiple-choice', 'Tính 15 + 28 = ?', '["41", "42", "43", "44"]', '2', 0.18, 'Math - Elementary', '15 + 28 = 43', ...),
('multiple-choice', 'Hình vuông có mấy cạnh?', '["3", "4", "5", "6"]', '1', 0.12, 'Math - Elementary', 'Hình vuông có 4 cạnh bằng nhau', ...);

-- THCS (Middle School)
INSERT INTO questions VALUES
('multiple-choice', 'Giải phương trình: 3x - 7 = 8', '["x=3", "x=5", "x=7", "x=9"]', '1', 0.38, 'Math - Middle School', '3x = 15, x = 5', ...),
('multiple-choice', 'Tính diện tích hình tròn bán kính 5cm (π ≈ 3.14)', '["78.5", "31.4", "15.7", "25"]', '0', 0.42, 'Math - Middle School', 'S = πr² = 3.14 × 25 = 78.5 cm²', ...);

-- THPT (High School)
INSERT INTO questions VALUES
('multiple-choice', 'Đạo hàm của f(x) = 2x² + 3x - 1 là:', '["4x + 3", "2x + 3", "4x + 1", "2x + 1"]', '0', 0.58, 'Math - High School', 'f''(x) = 4x + 3', ...);
```

#### Khoa Học
```sql
-- Cấp 1
INSERT INTO questions VALUES
('multiple-choice', 'Loài nào sau đây là động vật có vú?', '["Cá heo", "Cá mập", "Cá hồi", "Cá voi"]', '0', 0.15, 'Science - Elementary', 'Cá heo là động vật có vú sống ở nước', ...);

-- THCS
INSERT INTO questions VALUES
('multiple-choice', 'Công thức hóa học của muối ăn là gì?', '["NaCl", "KCl", "CaCl₂", "MgCl₂"]', '0', 0.32, 'Science - Middle School', 'Muối ăn là Natri Clorua (NaCl)', ...);

-- THPT
INSERT INTO questions VALUES
('multiple-choice', 'Định luật thứ nhất của Newton phát biểu:', '["Vật giữ nguyên trạng thái chuyển động khi không có ngoại lực", "F = ma", "Lực tác dụng có lực phản tác dụng", "Năng lượng được bảo toàn"]', '0', 0.52, 'Science - High School', 'Định luật quán tính Newton', ...);
```

#### Văn Học
```sql
INSERT INTO questions VALUES
('multiple-choice', 'Tác giả "Tắt đèn" là ai?', '["Ngô Tất Tố", "Nam Cao", "Nguyễn Công Hoan", "Vũ Trọng Phụng"]', '0', 0.35, 'Literature - Middle School', '"Tắt đèn" là tiểu thuyết nổi tiếng của Ngô Tất Tố', ...),
('multiple-choice', '"Chiều tối" là thơ của tác giả nào?', '["Hồ Chí Minh", "Tố Hữu", "Xuân Diệu", "Huy Cận"]', '0', 0.42, 'Literature - High School', 'Bài thơ "Chiều tối" của Hồ Chí Minh', ...);
```

#### Lịch Sử
```sql
INSERT INTO questions VALUES
('multiple-choice', 'Ngày giải phóng miền Nam là ngày nào?', '["2/9/1945", "30/4/1975", "7/5/1954", "1/5/1975"]', '1', 0.20, 'History - Elementary', 'Ngày 30/4/1975 là ngày giải phóng hoàn toàn miền Nam', ...),
('multiple-choice', 'Cuộc khởi nghĩa nào đánh dấu bước ngoặt lịch sử Việt Nam?', '["Lam Sơn", "Hai Bà Trưng", "Tây Sơn", "Cách mạng Tháng Tám"]', '3', 0.48, 'History - High School', 'Cách mạng Tháng Tám 1945 giành chính quyền', ...);
```

### Script Tạo Hàng Loạt Câu Hỏi

```sql
-- Tạo nhiều câu hỏi Toán cấp 1 cùng lúc
DO $$
DECLARE
    instructor_id UUID;
BEGIN
    -- Lấy ID giáo viên
    SELECT id INTO instructor_id FROM users WHERE role = 'instructor' LIMIT 1;
    
    -- Tạo 10 câu hỏi cộng trừ cơ bản
    FOR i IN 1..10 LOOP
        INSERT INTO questions (type, question_text, options, correct_answer, difficulty, topic, created_by)
        VALUES (
            'multiple-choice',
            format('Tính %s + %s = ?', i * 5, i * 3),
            format('["%s", "%s", "%s", "%s"]', 
                i * 5 + i * 3 - 1,
                i * 5 + i * 3,
                i * 5 + i * 3 + 1,
                i * 5 + i * 3 + 2
            ),
            '1',
            0.15 + (i::decimal / 100),
            'Math - Elementary',
            instructor_id
        );
    END LOOP;
    
    RAISE NOTICE 'Đã tạo % câu hỏi', 10;
END $$;
```

## Tối Ưu Hóa

### Bước 1: Kiểm Tra Indexes
```sql
-- Xem các indexes hiện có
SELECT 
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
```

### Bước 2: Thêm Indexes Tùy Chỉnh
```sql
-- Index cho tìm kiếm câu hỏi theo nhiều tiêu chí
CREATE INDEX IF NOT EXISTS idx_questions_topic_difficulty 
ON questions(topic, difficulty);

-- Index cho các truy vấn CAT phức tạp
CREATE INDEX IF NOT EXISTS idx_questions_difficulty_type 
ON questions(difficulty, type);

-- Full-text search cho câu hỏi (nếu cần)
CREATE INDEX IF NOT EXISTS idx_questions_search 
ON questions USING gin(to_tsvector('english', question_text));
```

### Bước 3: Vacuum và Analyze
```sql
-- Tối ưu hóa database (chạy định kỳ)
VACUUM ANALYZE questions;
VACUUM ANALYZE exam_attempts;
```

### Bước 4: Monitoring Performance
```sql
-- Xem các queries chậm
SELECT 
    query,
    calls,
    total_time / 1000 as total_seconds,
    mean_time / 1000 as mean_seconds
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;

-- Xem kích thước bảng
SELECT
    table_name,
    pg_size_pretty(pg_total_relation_size(quote_ident(table_name))) as size
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY pg_total_relation_size(quote_ident(table_name)) DESC;
```

## Row Level Security (RLS)

### Hiện Trạng
RLS đã được enable trong migration. Các policy:
- Users có thể đọc/sửa dữ liệu của mình
- Instructors có quyền cao hơn với classes, exams
- Students chỉ xem được exams được assign

### Kiểm Tra RLS
```sql
-- Xem các policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
ORDER BY tablename, policyname;
```

### Disable RLS (Chỉ Để Test)
```sql
-- CẢNH BÁO: Chỉ dùng trong môi trường dev!
ALTER TABLE questions DISABLE ROW LEVEL SECURITY;
```

## Backup và Restore

### Backup Database
1. Vào **Database** → **Backups**
2. Nhấn **"Start a backup"**
3. Đặt tên backup: `backup-YYYY-MM-DD`
4. Backup sẽ lưu tự động (giới hạn 7 days trong free plan)

### Restore từ Backup
1. Vào **Database** → **Backups**
2. Chọn backup cần restore
3. Nhấn **"Restore"**
4. Xác nhận (SẼ GHI ĐÈ DỮ LIỆU HIỆN TẠI!)

### Export SQL
```bash
# Export toàn bộ database
pg_dump -h db.xxxxx.supabase.co \
    -U postgres \
    -d postgres \
    -F c \
    -f backup.dump

# Export chỉ bảng questions
pg_dump -h db.xxxxx.supabase.co \
    -U postgres \
    -d postgres \
    -t questions \
    -F c \
    -f questions_backup.dump
```

## Troubleshooting

### Lỗi: "relation already exists"
**Nguyên nhân**: Bảng đã tồn tại từ lần chạy trước

**Giải pháp**:
```sql
-- Xóa tất cả bảng (CẢNH BÁO: Mất hết dữ liệu!)
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
-- Sau đó chạy lại migration
```

### Lỗi: "permission denied"
**Nguyên nhân**: Dùng sai key hoặc RLS chặn

**Giải pháp**:
- Đảm bảo dùng `service_role` key cho server
- Kiểm tra RLS policies

### Lỗi: Cannot connect to database
**Nguyên nhân**: Sai URL hoặc credentials

**Giải pháp**:
1. Kiểm tra `.env`:
   - SUPABASE_URL đúng format
   - SUPABASE_SERVICE_ROLE_KEY đầy đủ
2. Test connection:
   ```bash
   curl -H "apikey: YOUR_ANON_KEY" \
        https://your-project.supabase.co/rest/v1/
   ```

## Kết Luận

Sau khi hoàn thành, bạn đã có:
- ✅ Database đầy đủ với 7 bảng
- ✅ 60+ câu hỏi mẫu đa dạng
- ✅ Indexes được tối ưu
- ✅ RLS policies bảo mật
- ✅ Backup tự động

**Lưu Ý Quan Trọng**:
- ⚠️ **GIỮ BÍ MẬT** service_role key
- ⚠️ Đổi mật khẩu demo accounts
- ⚠️ Backup thường xuyên
- ⚠️ Monitor usage để không vượt free tier

**Giới Hạn Free Tier**:
- Database: 500 MB
- Bandwidth: 5 GB/tháng
- API requests: Không giới hạn
- Row Level Security: ✅
- Realtime: ✅

**Nâng Cấp** (nếu cần):
- Pro Plan: $25/tháng
- Team Plan: $599/tháng
