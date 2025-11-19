# Hướng Dẫn Triển Khai Hoàn Chỉnh - Intelligence Test Server

## 🎯 Tổng Quan

Hướng dẫn này sẽ giúp bạn triển khai hoàn chỉnh hệ thống Intelligence Test Server từ đầu đến cuối, bao gồm:
- ✅ Cài đặt và cấu hình server
- ✅ Thiết lập database Supabase
- ✅ Import ngân hàng câu hỏi
- ✅ Cấu hình AI (Gemini)
- ✅ Deploy lên production
- ✅ Kiểm tra và testing

## 📋 Yêu Cầu Hệ Thống

### Phần Mềm Cần Thiết
- **Node.js**: 18.0 trở lên
- **npm**: 9.0 trở lên
- **Git**: Bất kỳ phiên bản nào

### Tài Khoản Cần Tạo (MIỄN PHÍ)
- [Supabase](https://supabase.com) - Database
- [Google AI Studio](https://makersuite.google.com) - Gemini API

## 🚀 Bước 1: Clone và Cài Đặt

### 1.1 Clone Repository
```bash
git clone https://github.com/imnothoan/Intelligence-Test-Server.git
cd Intelligence-Test-Server
```

### 1.2 Cài Đặt Dependencies
```bash
npm install
```

Kết quả mong đợi:
```
added 362 packages in 21s
```

### 1.3 Kiểm Tra Cài Đặt
```bash
# Kiểm tra Node.js version
node --version  # Phải >= v18.0.0

# Kiểm tra npm version
npm --version   # Phải >= 9.0.0

# Build để test
npm run build

# Kết quả: Không có lỗi, tạo folder dist/
```

## 🗄️ Bước 2: Thiết Lập Database (Supabase)

### 2.1 Tạo Project Supabase

1. Truy cập [supabase.com/dashboard](https://supabase.com/dashboard)
2. Đăng nhập (hoặc đăng ký nếu chưa có)
3. Click **"New Project"**
4. Điền thông tin:
   ```
   Name: intelligence-test
   Database Password: [Tạo mật khẩu mạnh - LƯU LẠI!]
   Region: Southeast Asia (Singapore)
   Pricing Plan: Free ($0/month)
   ```
5. Click **"Create new project"**
6. Đợi 2-3 phút để project khởi tạo

### 2.2 Lấy Credentials

1. Vào **Settings** → **API**
2. Copy các thông tin sau:

```
Project URL: https://xxxxxxxxxxxxx.supabase.co
anon public: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
service_role: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**⚠️ QUAN TRỌNG**: `service_role` key có full quyền truy cập, GIỮ BÍ MẬT!

### 2.3 Chạy Database Migration

1. Trong Supabase dashboard, vào **SQL Editor**
2. Click **"New Query"**
3. Copy toàn bộ nội dung file `supabase/migrations/001_initial_schema.sql`
4. Paste vào editor
5. Click **"Run"** (hoặc Ctrl+Enter)
6. Kết quả: "Success. No rows returned"

### 2.4 Kiểm Tra Tables

Vào **Table Editor**, bạn sẽ thấy 7 bảng:
- ✅ users
- ✅ classes
- ✅ class_students
- ✅ questions
- ✅ exams
- ✅ exam_assignments
- ✅ exam_attempts

### 2.5 Import Câu Hỏi Mẫu

1. Vào **SQL Editor** → **New Query**
2. Copy nội dung file `supabase/seeds/002_sample_questions.sql`
3. Paste và click **"Run"**
4. Kiểm tra:
   ```sql
   SELECT COUNT(*) FROM questions;
   -- Kết quả: 60+ câu hỏi
   ```

## 🔑 Bước 3: Cấu Hình Environment Variables

### 3.1 Tạo File .env

```bash
cp .env.example .env
```

### 3.2 Chỉnh Sửa .env

```env
# Server Configuration
NODE_ENV=development
PORT=3000
API_PREFIX=/api

# Supabase (từ Bước 2.2)
SUPABASE_URL=https://xxxxxxxxxxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGci...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGci...

# JWT Secrets (tạo mới!)
JWT_SECRET=your-super-secret-jwt-key-change-this
JWT_REFRESH_SECRET=your-super-secret-refresh-key-change-this
JWT_EXPIRES_IN=1h
JWT_REFRESH_EXPIRES_IN=7d

# Google Gemini API (Bước 4)
GEMINI_API_KEY=AIza...

# CORS (URL của client)
CORS_ORIGIN=http://localhost:5173

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# WebSocket Port (mặc định dùng chung với HTTP)
WS_PORT=3000

# Logging
LOG_LEVEL=info
```

### 3.3 Tạo JWT Secrets An Toàn

**Linux/Mac:**
```bash
# Generate JWT_SECRET
openssl rand -base64 32

# Generate JWT_REFRESH_SECRET
openssl rand -base64 32
```

**Windows (PowerShell):**
```powershell
# JWT_SECRET
[Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Minimum 0 -Maximum 256 }))

# JWT_REFRESH_SECRET
[Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Minimum 0 -Maximum 256 }))
```

Copy kết quả vào `.env`

## 🤖 Bước 4: Cấu Hình Gemini API (MIỄN PHÍ)

### 4.1 Lấy API Key

1. Truy cập [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Đăng nhập bằng tài khoản Google
3. Click **"Create API Key"**
4. Chọn **"Create API key in new project"**
5. Copy API key (bắt đầu với `AIza...`)

### 4.2 Thêm vào .env

```env
GEMINI_API_KEY=AIzaSy...your-key-here
```

### 4.3 Giới Hạn Free Tier

Gemini FREE tier:
- ✅ 60 requests/minute
- ✅ 1,500 requests/day
- ✅ Không cần thẻ tín dụng
- ✅ Đủ cho 100-200 học sinh/ngày

## 🧪 Bước 5: Test Server Local

### 5.1 Chạy Development Mode

```bash
npm run dev
```

Kết quả mong đợi:
```
🚀 Intelligence Test Server started successfully!
📍 Server running on port 3000
🌍 Environment: development
🔗 API Base URL: http://localhost:3000/api
❤️  Health Check: http://localhost:3000/health
🔌 WebSocket server initialized on /ws

📚 API Endpoints:
   - Auth: /api/auth
   - Questions: /api/questions
   - Exams: /api/exams
   - Classes: /api/classes
   - Attempts: /api/attempts
   - WebSocket: ws://localhost:3000/ws

✨ Ready to accept connections!
```

### 5.2 Test Health Check

**Browser:**
```
http://localhost:3000/health
```

**curl:**
```bash
curl http://localhost:3000/health
```

Kết quả:
```json
{
  "success": true,
  "message": "Intelligence Test Server is running",
  "timestamp": "2024-11-19T...",
  "environment": "development"
}
```

### 5.3 Test API Endpoints

```bash
# Test register
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test123!@#",
    "name": "Test User",
    "role": "instructor"
  }'

# Test login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test123!@#"
  }'

# Lưu token từ response, dùng cho các request sau
```

### 5.4 Test WebSocket

Sử dụng [Postman](https://www.postman.com/downloads/) hoặc [websocat](https://github.com/vi/websocat):

```bash
# Install websocat (Linux/Mac)
cargo install websocat

# Connect to WebSocket
websocat ws://localhost:3000/ws

# Gửi message (sau khi connect)
{"type":"auth","data":{"token":"YOUR_JWT_TOKEN"}}
```

## 🌐 Bước 6: Deploy Production

### Option 1: Railway (Khuyến Nghị - FREE)

#### 6.1 Chuẩn Bị
1. Push code lên GitHub (nếu chưa)
2. Tạo tài khoản [Railway.app](https://railway.app)

#### 6.2 Deploy
1. Trong Railway dashboard, click **"New Project"**
2. Chọn **"Deploy from GitHub repo"**
3. Chọn repository `Intelligence-Test-Server`
4. Railway tự động detect và deploy

#### 6.3 Cấu Hình Environment Variables
1. Vào project → **Variables**
2. Add tất cả biến từ `.env`:
   ```
   NODE_ENV=production
   PORT=3000
   SUPABASE_URL=...
   SUPABASE_ANON_KEY=...
   SUPABASE_SERVICE_ROLE_KEY=...
   JWT_SECRET=...
   JWT_REFRESH_SECRET=...
   GEMINI_API_KEY=...
   CORS_ORIGIN=https://your-client-domain.com
   ```

#### 6.4 Domain
- Railway tự động cấp subdomain: `your-app.up.railway.app`
- Hoặc add custom domain trong Settings

#### 6.5 Verify Deployment
```bash
curl https://your-app.up.railway.app/health
```

### Option 2: Render.com (FREE Alternative)

#### 6.2 Deploy
1. Tạo tài khoản [Render.com](https://render.com)
2. Click **"New"** → **"Web Service"**
3. Connect GitHub repository
4. Configure:
   ```
   Name: intelligence-test-server
   Environment: Node
   Build Command: npm install && npm run build
   Start Command: npm start
   ```

#### 6.3 Environment Variables
Add trong Render dashboard (giống Railway)

#### 6.4 Free Tier Limitations
- ⚠️ App sleep sau 15 phút không hoạt động
- ⚠️ Khởi động lại mất ~30 giây
- ✅ 750 giờ/tháng miễn phí

### Option 3: VPS (Ubuntu)

#### 6.1 Cài Đặt Node.js
```bash
# Update system
sudo apt update
sudo apt upgrade -y

# Install Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Verify
node --version
npm --version
```

#### 6.2 Clone và Setup
```bash
# Clone repo
cd /var/www
sudo git clone https://github.com/imnothoan/Intelligence-Test-Server.git
cd Intelligence-Test-Server

# Install dependencies
sudo npm install

# Build
sudo npm run build

# Create .env
sudo nano .env
# Paste nội dung từ Bước 3
```

#### 6.3 Install PM2
```bash
# Install PM2
sudo npm install -g pm2

# Start server
pm2 start dist/app.js --name intelligence-test-server

# Auto-start on reboot
pm2 startup
pm2 save

# Check status
pm2 status
pm2 logs intelligence-test-server
```

#### 6.4 Setup Nginx Reverse Proxy
```bash
# Install Nginx
sudo apt install -y nginx

# Create config
sudo nano /etc/nginx/sites-available/intelligence-test
```

Nội dung file:
```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # WebSocket support
    location /ws {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
    }
}
```

Enable site:
```bash
# Enable config
sudo ln -s /etc/nginx/sites-available/intelligence-test /etc/nginx/sites-enabled/

# Test config
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
```

#### 6.5 SSL với Let's Encrypt
```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Get certificate
sudo certbot --nginx -d your-domain.com

# Auto-renew (already configured)
sudo certbot renew --dry-run
```

## 🔐 Bước 7: Security Checklist

### 7.1 Production Environment Variables
- ✅ Đổi `JWT_SECRET` và `JWT_REFRESH_SECRET` thành random strings mạnh
- ✅ Đặt `NODE_ENV=production`
- ✅ Cập nhật `CORS_ORIGIN` thành domain thật của client
- ✅ **KHÔNG BAO GIỜ** commit `.env` vào Git

### 7.2 Supabase Security
1. Vào Supabase → **Authentication** → **Policies**
2. Kiểm tra Row Level Security (RLS) đã enable
3. Review các policies:
   - Users chỉ đọc/sửa dữ liệu của mình
   - Instructors có quyền với classes/exams
   - Students chỉ xem exams được assign

### 7.3 Rate Limiting
Đã cấu hình mặc định:
- ✅ 100 requests/15 phút (global)
- ✅ 5 login attempts/15 phút
- ✅ 3 password changes/giờ

### 7.4 Database Backup
1. Vào Supabase → **Database** → **Backups**
2. Enable automatic backups (free plan: 7 days retention)
3. Test restore procedure

### 7.5 Monitoring
```bash
# Check server logs
pm2 logs intelligence-test-server

# Monitor resources
pm2 monit

# Check Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

## 📊 Bước 8: Kiểm Tra Hoạt Động

### 8.1 Checklist Chức Năng

**Authentication:**
- [ ] Register account (instructor + student)
- [ ] Login thành công
- [ ] Refresh token hoạt động
- [ ] Logout thành công

**Questions:**
- [ ] List questions (có 60+ câu từ seed data)
- [ ] Filter by topic, difficulty
- [ ] Create new question (instructor)
- [ ] Generate với Gemini AI

**Exams:**
- [ ] Create exam
- [ ] Assign to class
- [ ] Start exam attempt (student)
- [ ] CAT algorithm chọn câu hỏi
- [ ] Submit answers
- [ ] Complete exam

**WebSocket:**
- [ ] Connect successful
- [ ] Receive real-time updates
- [ ] Anti-cheat warnings broadcast

**Analytics:**
- [ ] Exam statistics
- [ ] Question analytics
- [ ] Student performance

### 8.2 Performance Testing

```bash
# Install Apache Bench
sudo apt install apache2-utils

# Test health endpoint
ab -n 1000 -c 10 http://localhost:3000/health

# Kết quả mong đợi:
# Requests per second: 500-1000
# Time per request: 1-2ms
```

### 8.3 Load Testing (Optional)

```bash
# Install k6
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt update
sudo apt install k6

# Create test script
cat > load-test.js << 'EOF'
import http from 'k6/http';
import { check } from 'k6';

export let options = {
  stages: [
    { duration: '1m', target: 50 },  // Ramp up to 50 users
    { duration: '3m', target: 50 },  // Stay at 50 users
    { duration: '1m', target: 0 },   // Ramp down
  ],
};

export default function() {
  let res = http.get('http://localhost:3000/health');
  check(res, { 'status is 200': (r) => r.status === 200 });
}
EOF

# Run test
k6 run load-test.js
```

## 🐛 Troubleshooting

### Lỗi: "Cannot connect to database"
**Nguyên nhân**: Sai Supabase credentials

**Giải pháp**:
1. Kiểm tra `.env`:
   - `SUPABASE_URL` đúng format
   - `SUPABASE_SERVICE_ROLE_KEY` đầy đủ, không bị cắt
2. Test connection:
   ```bash
   curl -H "apikey: YOUR_ANON_KEY" \
        https://your-project.supabase.co/rest/v1/
   ```

### Lỗi: "Port 3000 already in use"
**Giải pháp**:
```bash
# Find process using port 3000
lsof -i :3000

# Kill process
kill -9 PID

# Hoặc đổi port trong .env
PORT=3001
```

### Lỗi: "Gemini API quota exceeded"
**Nguyên nhân**: Vượt quá 60 req/min hoặc 1500 req/day

**Giải pháp**:
1. Đợi 1 phút (nếu vượt rate limit/minute)
2. Đợi đến ngày mai (nếu vượt daily quota)
3. Implement caching cho AI responses

### WebSocket không kết nối
**Giải pháp**:
1. Kiểm tra client URL: `ws://` (không phải `wss://` nếu chưa SSL)
2. Kiểm tra firewall: Port 3000 phải open
3. Nginx: Đảm bảo có WebSocket config (Bước 6.4)

### Build lỗi TypeScript
**Giải pháp**:
```bash
# Clear cache
rm -rf node_modules dist
npm install
npm run build
```

## 📚 Tài Liệu Tham Khảo

### Tài Liệu Chính
- [README.md](README.md) - Overview và quick start
- [DATABASE_SETUP_VIETNAMESE.md](docs/DATABASE_SETUP_VIETNAMESE.md) - Chi tiết database
- [MODEL_TRAINING_VIETNAMESE.md](docs/MODEL_TRAINING_VIETNAMESE.md) - Train CAT & Anti-cheat
- [API_COMPATIBILITY_ANALYSIS.md](API_COMPATIBILITY_ANALYSIS.md) - API mapping

### External Resources
- [Supabase Docs](https://supabase.com/docs)
- [Google Gemini API](https://ai.google.dev/docs)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)
- [PM2 Documentation](https://pm2.keymetrics.io/docs/usage/quick-start/)

## 🎓 Training & Support

### Học Thêm
1. **CAT Algorithm**: Xem `docs/CAT_TRAINING.md`
2. **Anti-Cheat**: Xem `docs/ANTICHEAT_TRAINING.md`  
3. **Exam Generation**: Xem `docs/EXAM_GENERATION.md`
4. **Supabase**: Xem `docs/SUPABASE_SETUP.md`

### Hỗ Trợ
- 📧 GitHub Issues: [Report bugs](https://github.com/imnothoan/Intelligence-Test-Server/issues)
- 📖 Documentation: [Full docs](docs/)
- 💬 Community: [Discussions](https://github.com/imnothoan/Intelligence-Test-Server/discussions)

## ✅ Hoàn Thành!

Chúc mừng! Bạn đã hoàn thành việc triển khai Intelligence Test Server. 🎉

**Các bước tiếp theo:**
1. ✅ Deploy client application
2. ✅ Tạo classes và students
3. ✅ Tạo exams từ question bank
4. ✅ Test end-to-end flow
5. ✅ Monitor và optimize

**Cần giúp đỡ?** Mở issue trên GitHub!

---

**Phát triển bởi**: Intelligence Test Team  
**License**: MIT  
**Version**: 1.0.0  
**Ngày cập nhật**: November 2024
