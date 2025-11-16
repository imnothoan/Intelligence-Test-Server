# Hướng Dẫn Setup Hoàn Chỉnh - Intelligence Test Platform
# Complete Setup Guide for Intelligence Test System

## 🎯 Tổng Quan / Overview

Hệ thống Intelligence Test Platform gồm 2 phần:
1. **Server** (Repository này) - Backend API với Supabase
2. **Client** (https://github.com/imnothoan/Intelligence-Test) - React frontend

## 📋 Yêu Cầu Hệ Thống

- Node.js 18+
- Tài khoản Supabase (miễn phí)
- Google Gemini API key (miễn phí)
- 2GB RAM tối thiểu
- Modern browser (Chrome, Firefox, Edge)

## 🚀 Setup Từ Đầu - 30 Phút

### Phần 1: Setup Server (15 phút)

#### Bước 1: Clone Server Repository

```bash
git clone https://github.com/imnothoan/Intelligence-Test-Server.git
cd Intelligence-Test-Server
npm install
```

#### Bước 2: Tạo Supabase Project

1. Truy cập https://supabase.com
2. Click "New Project"
3. Điền thông tin:
   - **Name**: intelligence-test
   - **Database Password**: Tạo password mạnh (lưu lại)
   - **Region**: Southeast Asia (Singapore)
4. Đợi 2-3 phút project khởi tạo

#### Bước 3: Lấy Supabase Credentials

Trong Supabase Dashboard:
1. Vào **Settings** → **API**
2. Copy 3 giá trị:
   - **Project URL** (VD: `https://xxxxx.supabase.co`)
   - **anon public** key
   - **service_role** key (⚠️ Giữ bí mật!)

#### Bước 4: Setup Database

1. Trong Supabase, vào **SQL Editor**
2. Click **New Query**
3. Copy toàn bộ nội dung file `supabase/migrations/001_initial_schema.sql`
4. Paste vào editor và click **Run**
5. Kiểm tra trong **Table Editor** - Phải có 7 tables:
   - users
   - classes
   - class_students
   - questions
   - exams
   - exam_assignments
   - exam_attempts

#### Bước 5: Lấy Gemini API Key (MIỄN PHÍ)

1. Truy cập https://makersuite.google.com/app/apikey
2. Đăng nhập Google
3. Click "Create API Key" → "Create API key in new project"
4. Copy API key (bắt đầu với `AIza...`)

#### Bước 6: Cấu Hình Environment

```bash
cp .env.example .env
nano .env  # or code .env
```

Điền vào `.env`:

```env
# Server
NODE_ENV=development
PORT=3000
API_PREFIX=/api

# Supabase (từ bước 3)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here

# JWT Secrets (generate mới với: openssl rand -base64 32)
JWT_SECRET=generated-secret-here-32-characters-minimum
JWT_REFRESH_SECRET=another-generated-secret-32-chars-min
JWT_EXPIRES_IN=1h
JWT_REFRESH_EXPIRES_IN=7d

# Gemini API (từ bước 5)
GEMINI_API_KEY=AIza...your-key-here

# CORS (URL của client, sẽ setup ở phần 2)
CORS_ORIGIN=http://localhost:5173
```

#### Bước 7: Start Server

```bash
npm run dev
```

Kết quả:
```
🚀 Intelligence Test Server started successfully!
📍 Server running on port 3000
🌍 Environment: development
🔗 API Base URL: http://localhost:3000/api
❤️  Health Check: http://localhost:3000/health
```

#### Bước 8: Verify Server

```bash
# Test health check
curl http://localhost:3000/health

# Kết quả mong đợi:
{
  "success": true,
  "message": "Intelligence Test Server is running",
  ...
}
```

✅ **Server setup hoàn tất!**

---

### Phần 2: Setup Client (15 phút)

#### Bước 1: Clone Client Repository

```bash
cd ..  # Ra khỏi server directory
git clone https://github.com/imnothoan/Intelligence-Test.git
cd Intelligence-Test
npm install
```

#### Bước 2: Cấu Hình Environment

```bash
cp .env.example .env
nano .env  # or code .env
```

Điền vào `.env`:

```env
# Backend Server URL (từ server setup)
VITE_API_BASE_URL=http://localhost:3000/api

# Google Gemini API (cùng key với server)
VITE_GEMINI_API_KEY=AIza...your-key-here

# Mode: false = client-server, true = standalone
VITE_DEV_MODE=false
```

#### Bước 3: Start Client

```bash
npm run dev
```

Kết quả:
```
VITE ready in 1234 ms

➜  Local:   http://localhost:5173/
➜  Network: use --host to expose
```

#### Bước 4: Verify Client

1. Mở browser: http://localhost:5173
2. Bạn sẽ thấy Login page
3. Click "Register" để tạo tài khoản

✅ **Client setup hoàn tất!**

---

## 🎓 Sử Dụng Hệ Thống

### Tạo Tài Khoản Giáo Viên

1. Mở http://localhost:5173
2. Click **Register**
3. Điền thông tin:
   - Email: teacher@test.com
   - Password: password123
   - Name: Giáo Viên Test
   - Role: **Instructor**
4. Click **Register**
5. Login với tài khoản vừa tạo

### Tạo Câu Hỏi với AI

1. Sau khi login, click **Question Bank**
2. Click **Generate with AI**
3. Điền form:
   - Topic: "Toán học - Phương trình bậc 2"
   - Difficulty: 0.5 (Medium)
   - Count: 10
   - Grade Level: High School
   - Subject: Math
4. Click **Generate**
5. Đợi 5-10 giây, câu hỏi sẽ được tạo tự động!

### Tạo Đề Thi

1. Click **Create Exam**
2. Điền thông tin:
   - Title: "Kiểm tra Toán 10"
   - Duration: 45 minutes
   - Enable CAT: ✅ (adaptive testing)
   - Enable Anti-Cheat: ✅ (camera monitoring)
3. Chọn câu hỏi từ Question Bank
4. Click **Create**

### Tạo Lớp Học

1. Click **Classes**
2. Click **Create Class**
3. Điền:
   - Name: "Lớp 10A1"
   - Description: "Lớp toán nâng cao"
4. Click **Create**
5. Thêm học sinh vào lớp

### Assign Đề Thi cho Lớp

1. Vào trang Exam
2. Click **Assign to Class**
3. Chọn lớp "10A1"
4. Click **Assign**

### Học Sinh Làm Bài

1. Logout, tạo tài khoản Student
2. Login với tài khoản student
3. Thấy exam đã được assign
4. Click **Start Exam**
5. Cho phép camera (nếu anti-cheat enabled)
6. Làm bài - CAT sẽ tự động điều chỉnh độ khó
7. Submit khi hoàn thành

### Giáo Viên Xem Kết Quả

1. Login với tài khoản instructor
2. Click **Monitor Exams** (real-time monitoring)
3. Click **Analytics** (xem kết quả chi tiết)
4. Export reports

---

## 🎯 Training Models (Tùy Chọn)

### CAT Model - Calibrate Độ Khó Câu Hỏi

**Khi nào**: Sau 3-6 tháng, có 100+ học sinh

**Cách làm**:
```bash
# Xem hướng dẫn chi tiết
cat docs/CAT_TRAINING.md

# Quick method: Manual calibration
# - Gán độ khó khi tạo câu hỏi
# - Easy: 0.0-0.3
# - Medium: 0.3-0.7
# - Hard: 0.7-1.0
```

### Anti-Cheat Model - Phát Hiện Gian Lận

**Khi nào**: Khi cần phát hiện hành vi cụ thể

**Cách làm**:
```bash
# Xem hướng dẫn chi tiết
cat docs/ANTICHEAT_TRAINING.md

# Default: Sử dụng BlazeFace (no training needed)
# Custom: Train model riêng với TensorFlow
```

### Question Generation - Tạo Đề Tự Động

**Đã hoạt động ngay**: Sử dụng Gemini API

**Cách sử dụng**:
```bash
# Xem hướng dẫn chi tiết và examples
cat docs/EXAM_GENERATION.md

# Tạo câu hỏi qua API hoặc UI
curl -X POST http://localhost:3000/api/questions/generate \
  -H "Authorization: Bearer TOKEN" \
  -d '{"topic": "Văn học", "count": 10}'
```

---

## 🔧 Troubleshooting

### Server không start

```bash
# Check Node.js version
node --version  # Phải >= 18

# Check port 3000 có bị chiếm
lsof -i :3000
# Nếu có process, kill nó hoặc đổi PORT trong .env

# Check .env file
cat .env | grep SUPABASE_URL
# Phải có đầy đủ credentials
```

### Client không connect được server

```bash
# Check server đang chạy
curl http://localhost:3000/health

# Check CORS trong server .env
# CORS_ORIGIN phải match với client URL

# Check client .env
cat .env | grep VITE_API_BASE_URL
# Phải là http://localhost:3000/api
```

### Gemini API không hoạt động

```bash
# Check API key
cat .env | grep GEMINI_API_KEY

# Test Gemini trực tiếp
curl -X POST http://localhost:3000/api/questions/generate \
  -H "Authorization: Bearer YOUR_JWT" \
  -H "Content-Type: application/json" \
  -d '{"topic": "test", "count": 1, "difficulty": 0.5, "type": "multiple-choice"}'
```

### Database errors

```sql
-- Trong Supabase SQL Editor, check tables:
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public';

-- Phải có 7 tables
-- Nếu thiếu, re-run migration file
```

---

## 📚 Tài Liệu Đầy Đủ

### Server Documentation
- [README.md](README.md) - Overview và quick start
- [CAT_TRAINING.md](docs/CAT_TRAINING.md) - Training CAT models
- [ANTICHEAT_TRAINING.md](docs/ANTICHEAT_TRAINING.md) - Anti-cheat camera
- [EXAM_GENERATION.md](docs/EXAM_GENERATION.md) - Gemini AI usage

### Client Documentation
Xem trong Intelligence-Test repository:
- README.md - Client setup
- QUICKSTART.vi.md - Hướng dẫn nhanh
- docs/vi/ - Tài liệu tiếng Việt

---

## 🚀 Deployment to Production

### Deploy Server (Railway - Recommended)

1. Tạo tài khoản tại https://railway.app
2. Click "New Project" → "Deploy from GitHub repo"
3. Chọn Intelligence-Test-Server repo
4. Add environment variables từ `.env`
5. Deploy!

Railway tự động:
- ✅ HTTPS
- ✅ Custom domain
- ✅ Auto-deploy khi push code

### Deploy Client (Vercel - Recommended)

1. Tạo tài khoản tại https://vercel.com
2. Import Intelligence-Test repo
3. Add environment variables
4. Deploy!

### Update CORS

Sau khi deploy, update `.env` của server:
```env
CORS_ORIGIN=https://your-client-domain.vercel.app
```

---

## 💡 Tips & Best Practices

### Security

✅ **DO**:
- Sử dụng strong passwords
- Generate JWT secrets mới (không dùng default)
- Enable HTTPS trong production
- Giữ service_role_key bí mật
- Enable Supabase RLS policies

❌ **DON'T**:
- Commit `.env` file vào git
- Share service_role_key
- Dùng HTTP trong production
- Disable rate limiting

### Performance

- Cache frequently used questions
- Use pagination cho large lists
- Optimize images (compress, lazy load)
- Enable Supabase database indexes

### Maintenance

- Backup database regularly
- Monitor API usage (Gemini limits)
- Update dependencies monthly
- Check logs for errors

---

## 🎉 Hoàn Tất!

Bây giờ bạn đã có:

✅ Server chạy với Supabase  
✅ Client kết nối với server  
✅ AI question generation với Gemini  
✅ CAT adaptive testing  
✅ Anti-cheat monitoring  
✅ Complete documentation  

**Hệ thống sẵn sàng sử dụng!**

Nếu cần hỗ trợ:
- 📖 Đọc documentation trong `/docs`
- 🐛 Mở issue trên GitHub
- 💬 Liên hệ qua GitHub profile

Chúc bạn thành công! 🚀
