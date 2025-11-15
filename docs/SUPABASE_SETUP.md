# Supabase Setup Guide - Intelligence Test Server
# Hướng Dẫn Thiết Lập Supabase Chi Tiết

## 📚 Table of Contents

- [Giới thiệu Supabase](#giới-thiệu-supabase)
- [Tại sao chọn Supabase?](#tại-sao-chọn-supabase)
- [Setup từ đầu](#setup-từ-đầu)
- [Database Schema](#database-schema)
- [Row Level Security (RLS)](#row-level-security-rls)
- [Performance Optimization](#performance-optimization)
- [Backup và Recovery](#backup-và-recovery)
- [Monitoring](#monitoring)

## Giới thiệu Supabase

**Supabase** là "Firebase alternative" mã nguồn mở, sử dụng PostgreSQL.

### Tính năng chính:
- 🗄️ **PostgreSQL Database** - SQL database mạnh mẽ
- 🔐 **Authentication** - Built-in auth (không dùng trong project này)
- 📦 **Storage** - File storage (không cần cho project này)
- 🔄 **Realtime** - WebSocket subscriptions
- 🛡️ **Row Level Security** - Fine-grained access control

## Tại sao chọn Supabase?

### ✅ Ưu điểm

**1. Miễn phí**
- 500MB database
- 50,000 monthly active users
- 2GB file storage (không cần)
- 2GB bandwidth

**2. PostgreSQL**
- SQL queries mạnh mẽ
- ACID transactions
- Advanced indexing
- JSON support (JSONB)
- Full-text search

**3. Easy to use**
- Dashboard trực quan
- SQL Editor
- Table Editor (GUI)
- API documentation tự động

**4. Scalability**
- Upgrade dễ dàng
- Horizontal scaling
- Connection pooling

### ❌ Hạn chế Free tier

- 500MB database (đủ cho 10,000+ questions)
- Pause sau 7 ngày không hoạt động (chỉ cần visit dashboard)
- 2 projects tối đa

### 💰 So sánh với alternatives

| Feature | Supabase Free | Firebase Free | MongoDB Atlas Free |
|---------|---------------|---------------|-------------------|
| Database | 500MB PostgreSQL | 1GB Firestore | 512MB MongoDB |
| Queries | Unlimited | 50K reads/day | Unlimited |
| API | REST + GraphQL | SDK only | REST |
| SQL | ✅ Yes | ❌ No | ❌ No |
| Price | Free forever | Free tier | Free tier |

## Setup từ đầu

### Bước 1: Tạo tài khoản

1. Truy cập https://supabase.com
2. Click **"Start your project"**
3. Sign up với:
   - GitHub (recommended)
   - Google
   - Email

### Bước 2: Tạo Organization

1. Sau khi login, click **"New organization"**
2. Name: "Intelligence Test" (hoặc tên bạn muốn)
3. Plan: **Free** (mặc định)
4. Click **Create organization**

### Bước 3: Tạo Project

1. Click **"New project"**
2. Điền thông tin:
   ```
   Name: intelligence-test-server
   Database Password: [Generate strong password]
   Region: Southeast Asia (Singapore) - Chọn gần nhất
   Pricing Plan: Free
   ```
3. Click **"Create new project"**
4. Đợi 2-3 phút (có progress bar)

### Bước 4: Lấy API Credentials

1. Sau khi project ready, vào **Settings** (⚙️ icon)
2. Click **API** trong sidebar
3. Copy 3 values:

**Project URL:**
```
https://xxxxxxxxxxxxx.supabase.co
```

**anon public key** (trong "Project API keys"):
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**service_role key** (trong "Project API keys"):
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

⚠️ **Warning**: `service_role` key có full admin access. KHÔNG share, KHÔNG commit vào git!

### Bước 5: Setup Database Schema

#### Option A: Sử dụng SQL Editor (Recommended)

1. Trong Supabase Dashboard, click **SQL Editor**
2. Click **New Query**
3. Copy toàn bộ nội dung từ:
   ```
   supabase/migrations/001_initial_schema.sql
   ```
4. Paste vào editor
5. Click **Run** (hoặc Ctrl+Enter)
6. Chờ vài giây, sẽ thấy "Success. No rows returned"

#### Option B: Sử dụng Supabase CLI (Advanced)

```bash
# Install Supabase CLI
npm install -g supabase

# Login
supabase login

# Link to your project
supabase link --project-ref YOUR_PROJECT_REF

# Run migrations
supabase db push
```

### Bước 6: Verify Tables

1. Click **Table Editor** trong sidebar
2. Bạn sẽ thấy 7 tables:
   - ✅ users
   - ✅ classes
   - ✅ class_students
   - ✅ questions
   - ✅ exams
   - ✅ exam_assignments
   - ✅ exam_attempts

3. Click vào mỗi table để xem structure

### Bước 7: Tạo Demo Data (Optional)

SQL đã tạo 2 demo users:
- `instructor@test.com` (Instructor)
- `student@test.com` (Student)

**Lưu ý**: Password hash trong migration là demo. Trong production, user phải register qua API.

## Database Schema

### Users Table

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('student', 'instructor')),
    avatar TEXT,
    bio TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Purpose**: Lưu thông tin user (students và instructors)

**Indexes**:
- `email` - Fast login lookup
- `role` - Filter by role

### Classes Table

```sql
CREATE TABLE classes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    instructor_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Purpose**: Lớp học do instructor tạo

**Relationships**:
- `instructor_id` → `users(id)` (CASCADE delete)

### Questions Table

```sql
CREATE TABLE questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type VARCHAR(20) NOT NULL CHECK (type IN ('multiple-choice', 'essay')),
    question_text TEXT NOT NULL,
    options JSONB,  -- Array of strings for MC
    correct_answer VARCHAR(255),  -- For MC
    difficulty DECIMAL(3, 2) NOT NULL CHECK (difficulty >= 0 AND difficulty <= 1),
    topic VARCHAR(255),
    explanation TEXT,
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Purpose**: Question bank với CAT difficulty parameters

**Special fields**:
- `difficulty`: 0.0-1.0 for CAT algorithm
- `options`: JSONB array cho multiple-choice
- `correct_answer`: Index (0,1,2,3) hoặc text

**Indexes**:
- `type`, `difficulty`, `topic` - Fast filtering
- `created_by` - Questions by instructor

### Exams Table

```sql
CREATE TABLE exams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    instructor_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    duration_minutes INTEGER NOT NULL CHECK (duration_minutes > 0),
    enable_cat BOOLEAN DEFAULT FALSE,
    enable_anti_cheat BOOLEAN DEFAULT FALSE,
    question_ids JSONB NOT NULL,  -- Array of UUIDs
    cat_settings JSONB,
    scheduled_start TIMESTAMP WITH TIME ZONE,
    scheduled_end TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Purpose**: Đề thi

**Special fields**:
- `question_ids`: JSONB array of question UUIDs
- `cat_settings`: CAT configuration (optional)
- `enable_cat`: Adaptive testing on/off
- `enable_anti_cheat`: Camera monitoring on/off

### Exam Attempts Table

```sql
CREATE TABLE exam_attempts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    exam_id UUID NOT NULL REFERENCES exams(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    score INTEGER CHECK (score >= 0 AND score <= 100),
    ability_estimate DECIMAL(5, 2),  -- CAT ability
    responses JSONB DEFAULT '[]'::JSONB,  -- Question responses
    anti_cheat_warnings JSONB DEFAULT '[]'::JSONB,  -- Warnings
    flagged BOOLEAN DEFAULT FALSE,
    status VARCHAR(20) NOT NULL DEFAULT 'in_progress',
    cat_state JSONB,  -- Current CAT state
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Purpose**: Student exam attempts với CAT state và anti-cheat

**Special fields**:
- `responses`: Array of `{question_id, answer, is_correct, time_spent_seconds}`
- `anti_cheat_warnings`: Array of `{timestamp, type, severity, details}`
- `cat_state`: Current CAT algorithm state
- `status`: 'in_progress', 'completed', 'abandoned'

**Indexes**:
- `exam_id`, `student_id` - Fast lookups
- `status`, `flagged` - Filter attempts

## Row Level Security (RLS)

### Tại sao RLS?

RLS (Row Level Security) là security layer trong PostgreSQL cho phép:
- Fine-grained access control
- User chỉ thấy data của mình
- Instructor chỉ thấy classes/exams của mình
- Tự động enforce bởi database

### Policies đã setup

#### Users Table

```sql
-- Users can read their own data
CREATE POLICY users_select_own ON users
    FOR SELECT
    USING (auth.uid() = id);

-- Instructors can read all users
CREATE POLICY users_select_instructor ON users
    FOR SELECT
    USING ((SELECT role FROM users WHERE id = auth.uid()) = 'instructor');
```

#### Classes Table

```sql
-- Instructors can manage their classes
-- Students can view classes they're in
CREATE POLICY classes_all_instructor ON classes
    FOR ALL
    USING (
        instructor_id = auth.uid() OR
        EXISTS (SELECT 1 FROM class_students 
                WHERE class_id = classes.id AND student_id = auth.uid())
    );
```

#### Exam Attempts

```sql
-- Students can manage their own attempts
CREATE POLICY exam_attempts_all_student ON exam_attempts
    FOR ALL
    USING (student_id = auth.uid());

-- Instructors can view attempts for their exams
CREATE POLICY exam_attempts_select_instructor ON exam_attempts
    FOR SELECT
    USING (
        EXISTS (SELECT 1 FROM exams 
                WHERE exams.id = exam_attempts.exam_id 
                AND exams.instructor_id = auth.uid())
    );
```

### Bypass RLS với Service Role

Server sử dụng `service_role` key để bypass RLS, thực hiện business logic phía server.

**Lý do**: 
- Server cần full access để implement complex logic
- RLS phức tạp cho relationships
- Performance tốt hơn

## Performance Optimization

### Indexes đã tạo

```sql
-- Users
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

-- Questions
CREATE INDEX idx_questions_type ON questions(type);
CREATE INDEX idx_questions_difficulty ON questions(difficulty);
CREATE INDEX idx_questions_topic ON questions(topic);

-- Exam Attempts
CREATE INDEX idx_exam_attempts_exam ON exam_attempts(exam_id);
CREATE INDEX idx_exam_attempts_student ON exam_attempts(student_id);
CREATE INDEX idx_exam_attempts_status ON exam_attempts(status);
```

### Query Optimization

#### Good queries

```sql
-- Use indexes
SELECT * FROM questions 
WHERE difficulty >= 0.5 AND difficulty <= 0.7
AND type = 'multiple-choice';

-- Use LIMIT
SELECT * FROM exam_attempts 
WHERE student_id = 'uuid' 
ORDER BY started_at DESC 
LIMIT 10;
```

#### Bad queries

```sql
-- Full table scan
SELECT * FROM questions WHERE topic LIKE '%math%';

-- No LIMIT on large table
SELECT * FROM exam_attempts;  -- Could return millions
```

### Connection Pooling

Supabase sử dụng Supavisor cho connection pooling:
- Session mode: Long-lived connections
- Transaction mode: Cho serverless
- Max 60 connections trên free tier

## Backup và Recovery

### Automatic Backups

Supabase Free tier:
- ❌ No automatic backups
- ✅ Point-in-time recovery: None

**Recommendation**: Manual backups

### Manual Backup

#### Option 1: SQL Dump

```bash
# Install PostgreSQL client
sudo apt-get install postgresql-client

# Backup
pg_dump -h db.xxxxx.supabase.co \
        -U postgres \
        -d postgres \
        -F c \
        -f backup_$(date +%Y%m%d).dump

# Restore
pg_restore -h db.xxxxx.supabase.co \
           -U postgres \
           -d postgres \
           backup_20241115.dump
```

#### Option 2: CSV Export

Trong SQL Editor:

```sql
-- Export questions
COPY questions TO '/tmp/questions.csv' CSV HEADER;

-- Export exam attempts
COPY exam_attempts TO '/tmp/attempts.csv' CSV HEADER;
```

### Backup Schedule

**Recommended**:
- Daily: Important data (exam_attempts, users)
- Weekly: Full database
- Before major updates

## Monitoring

### Database Size

```sql
-- Check database size
SELECT pg_size_pretty(pg_database_size('postgres'));

-- Check table sizes
SELECT 
    table_name,
    pg_size_pretty(pg_total_relation_size(quote_ident(table_name)))
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY pg_total_relation_size(quote_ident(table_name)) DESC;
```

### Active Connections

```sql
SELECT count(*) FROM pg_stat_activity;
```

### Slow Queries

Trong Dashboard → Logs → Postgres Logs

Filter: Queries taking > 1000ms

### Supabase Dashboard

Dashboard → Reports:
- Database usage
- API requests
- Bandwidth
- Active users

## Troubleshooting

### Connection errors

```
Error: connect ECONNREFUSED

Solution:
- Check SUPABASE_URL is correct
- Check internet connection
- Verify project is not paused
```

### RLS errors

```
Error: new row violates row-level security policy

Solution:
- Use service_role key (not anon key)
- Check RLS policies
- Disable RLS for development (not recommended)
```

### Migration errors

```
Error: relation "users" already exists

Solution:
- Tables already created
- Drop all tables first:
  DROP TABLE IF EXISTS exam_attempts CASCADE;
  DROP TABLE IF EXISTS exam_assignments CASCADE;
  ...
- Or create new project
```

## Best Practices

### Security

✅ **DO**:
- Use service_role key on server only
- Enable RLS in production
- Validate inputs
- Use parameterized queries

❌ **DON'T**:
- Expose service_role key to client
- Store passwords in plaintext
- Disable RLS without reason

### Performance

✅ **DO**:
- Use indexes for frequently queried columns
- Use LIMIT for pagination
- Cache frequently accessed data
- Use connection pooling

❌ **DON'T**:
- Query without indexes
- Fetch all rows without pagination
- Make too many small queries (use batch)

### Maintenance

- Monitor database size weekly
- Review slow queries
- Backup before major updates
- Update statistics: `ANALYZE;`

## Resources

- [Supabase Documentation](https://supabase.com/docs)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Supabase Discord](https://discord.supabase.com)

## Summary

**Setup checklist**:
- ✅ Create Supabase account
- ✅ Create project
- ✅ Get API credentials
- ✅ Run migration SQL
- ✅ Verify tables created
- ✅ Configure server `.env`
- ✅ Test connection

**Free tier limits**:
- 500MB database
- 50K monthly active users
- Unlimited API requests
- Pause after 7 days inactive

**Remember**: Supabase free tier đủ cho 10,000+ questions, 1,000+ students, và 100,000+ exam attempts!
