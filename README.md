# Intelligence Test Server 🎓

Backend API server for the Intelligence Test Platform - A modern, AI-powered intelligent exam platform with Computerized Adaptive Testing (CAT) and anti-cheat features.

[![TypeScript](https://img.shields.io/badge/TypeScript-5.7-blue)](https://www.typescriptlang.org/)
[![Node.js](https://img.shields.io/badge/Node.js-18+-green)](https://nodejs.org/)
[![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-brightgreen)](https://supabase.com/)
[![Express](https://img.shields.io/badge/Express-4.x-lightgrey)](https://expressjs.com/)

## 🌟 Features

### 🔐 Authentication & Authorization
- **JWT-based authentication** with access and refresh tokens
- **bcrypt password hashing** for security
- **Role-based access control** (Student/Instructor)
- Secure session management

### 📊 Adaptive Testing (CAT)
- **Item Response Theory (IRT)** 1-parameter logistic model
- **Maximum Likelihood Estimation (MLE)** for ability estimation
- **Fisher Information** for question selection
- Dynamic difficulty adjustment
- Precision-based stopping criteria

### 🤖 AI Integration
- **Google Gemini API** (FREE) for:
  - Question generation (multiple-choice & essay)
  - Essay grading with rubrics
  - Vietnamese language support
- Prompt engineering for different grade levels
- Subject-specific question templates

### 🛡️ Anti-Cheat System
- Real-time warning tracking
- Automatic flagging based on severity
- Support for multiple warning types:
  - No face detected
  - Multiple faces
  - Looking away
  - Tab switching

### 📚 Complete API
- User management
- Class management
- Question bank CRUD
- Exam creation and assignment
- Exam attempts with CAT
- Real-time monitoring (ready for WebSocket)

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│     Client (React Application)          │
└──────────────┬──────────────────────────┘
               │ HTTPS/REST API
               │ (JWT Authentication)
┌──────────────┴──────────────────────────┐
│    Express.js Server (This Repo)        │
│  ┌────────────────────────────────────┐ │
│  │      Controllers & Routes          │ │
│  │  Auth | Exam | Class | Question    │ │
│  └────────────────────────────────────┘ │
│  ┌────────────────────────────────────┐ │
│  │          Services                  │ │
│  │   Gemini AI | CAT Algorithm        │ │
│  └────────────────────────────────────┘ │
└──────────────┬──────────────────────────┘
               │ Supabase Client
┌──────────────┴──────────────────────────┐
│         Supabase (PostgreSQL)           │
│  Users | Exams | Classes | Questions    │
│         ExamAttempts | Warnings          │
└─────────────────────────────────────────┘
```

## 📋 Prerequisites

- **Node.js** 18+ and npm
- **Supabase Account** (Free tier)
- **Google Gemini API Key** (Free from Google AI Studio)

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/imnothoan/Intelligence-Test-Server.git
cd Intelligence-Test-Server
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Setup Supabase

#### Create a Supabase Project

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Click "New Project"
3. Fill in project details:
   - **Name**: intelligence-test
   - **Database Password**: Choose a strong password
   - **Region**: Select closest to you
4. Wait for project to be ready (2-3 minutes)

#### Get Supabase Credentials

1. In your project dashboard, go to **Settings** → **API**
2. Copy the following:
   - **Project URL** (looks like `https://xxxxx.supabase.co`)
   - **anon public** key
   - **service_role** key (keep this secret!)

#### Run Database Migration

1. In Supabase dashboard, go to **SQL Editor**
2. Click **New Query**
3. Copy the entire content of `supabase/migrations/001_initial_schema.sql`
4. Paste and click **Run**
5. Verify all tables are created in **Table Editor**

### 4. Get Gemini API Key (FREE)

1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Create API Key" → "Create API key in new project"
4. Copy the API key (starts with `AIza...`)

**Free tier limits**: 60 requests/minute, 1,500 requests/day

### 5. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` file:

```env
# Server
NODE_ENV=development
PORT=3000
API_PREFIX=/api

# Supabase (from step 3)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here

# JWT Secrets (generate with: openssl rand -base64 32)
JWT_SECRET=your-super-secret-jwt-key-change-this
JWT_REFRESH_SECRET=your-super-secret-refresh-key-change-this

# Google Gemini API (from step 4)
GEMINI_API_KEY=AIza...your-key-here

# CORS (client URL)
CORS_ORIGIN=http://localhost:5173
```

### 6. Run the Server

**Development mode (with auto-reload):**

```bash
npm run dev
```

**Production mode:**

```bash
npm run build
npm start
```

Server will start on http://localhost:3000

### 7. Verify Installation

Visit http://localhost:3000/health in your browser. You should see:

```json
{
  "success": true,
  "message": "Intelligence Test Server is running",
  "timestamp": "2024-11-15T15:00:00.000Z",
  "environment": "development"
}
```

## 📚 API Documentation

### Base URL

```
http://localhost:3000/api
```

### Authentication Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/register` | Register new user |
| POST | `/auth/login` | Login user |
| POST | `/auth/refresh` | Refresh access token |
| GET | `/auth/profile` | Get user profile |
| PUT | `/auth/profile` | Update profile |
| PUT | `/auth/change-password` | Change password |

### Question Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/questions` | List questions | ✅ |
| GET | `/questions/:id` | Get question | ✅ |
| POST | `/questions` | Create question | ✅ Instructor |
| POST | `/questions/generate` | Generate with AI | ✅ Instructor |
| POST | `/questions/bulk-import` | Bulk import | ✅ Instructor |
| PUT | `/questions/:id` | Update question | ✅ |
| DELETE | `/questions/:id` | Delete question | ✅ |

### Exam Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/exams` | List exams | ✅ |
| GET | `/exams/:id` | Get exam | ✅ |
| POST | `/exams` | Create exam | ✅ Instructor |
| POST | `/exams/assign` | Assign to class | ✅ Instructor |
| PUT | `/exams/:id` | Update exam | ✅ Instructor |
| DELETE | `/exams/:id` | Delete exam | ✅ Instructor |

### Class Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/classes` | List classes | ✅ |
| GET | `/classes/:id` | Get class | ✅ |
| GET | `/classes/:id/students` | Get students | ✅ |
| GET | `/classes/:id/exams` | Get exams | ✅ |
| POST | `/classes` | Create class | ✅ Instructor |
| POST | `/classes/students` | Add student | ✅ Instructor |
| DELETE | `/classes/:classId/students/:studentId` | Remove student | ✅ Instructor |

### Exam Attempt Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/attempts/start` | Start exam | ✅ Student |
| GET | `/attempts/:id/next-question` | Get next (CAT) | ✅ Student |
| POST | `/attempts/:id/submit-answer` | Submit answer | ✅ Student |
| POST | `/attempts/:id/submit-warning` | Anti-cheat warning | ✅ Student |
| POST | `/attempts/:id/complete` | Complete exam | ✅ Student |
| GET | `/attempts/:id` | Get attempt | ✅ |
| GET | `/attempts/exam/:examId` | List by exam | ✅ Instructor |

For detailed API documentation with request/response examples, see [docs/API.md](docs/API.md)

## 🧪 Testing

**Run tests:**

```bash
npm test
```

**Test with curl:**

```bash
# Health check
curl http://localhost:3000/health

# Register user
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "teacher@example.com",
    "password": "password123",
    "name": "John Teacher",
    "role": "instructor"
  }'
```

## 📖 Documentation

### Setup Guides
- [Supabase Setup Guide](docs/SUPABASE_SETUP.md) - Detailed Supabase configuration
- [Deployment Guide](docs/DEPLOYMENT.md) - Deploy to production
- [Environment Configuration](docs/ENVIRONMENT.md) - All environment variables

### Training Guides
- [CAT Model Training](docs/CAT_TRAINING.md) - Calibrate question difficulty
- [Anti-Cheat Model Training](docs/ANTICHEAT_TRAINING.md) - Computer vision model
- [Exam Generation Guide](docs/EXAM_GENERATION.md) - Use Gemini for questions

### Development
- [API Reference](docs/API.md) - Complete API documentation
- [Database Schema](docs/DATABASE.md) - Table structures and relationships
- [Architecture](docs/ARCHITECTURE.md) - System design and patterns

## 🔧 Development

### Project Structure

```
Intelligence-Test-Server/
├── src/
│   ├── config/           # Configuration (Supabase, env)
│   ├── controllers/      # Request handlers
│   ├── middleware/       # Auth, validation, error handling
│   ├── routes/           # API routes
│   ├── services/         # Business logic (CAT, Gemini)
│   ├── types/            # TypeScript types
│   └── app.ts            # Express app setup
├── supabase/
│   └── migrations/       # Database migrations
├── docs/                 # Documentation
├── .env.example          # Environment template
├── package.json
├── tsconfig.json
└── README.md
```

### Available Scripts

```bash
npm run dev      # Development with auto-reload
npm run build    # Build for production
npm start        # Run production build
npm test         # Run tests
npm run lint     # Lint code
npm run format   # Format with Prettier
```

## 🌍 Deployment

### Deploy to Railway (Recommended)

1. Create account at [Railway.app](https://railway.app)
2. Click "New Project" → "Deploy from GitHub repo"
3. Select this repository
4. Add environment variables from `.env`
5. Deploy!

Railway provides:
- ✅ Free tier: 500 hours/month
- ✅ Automatic HTTPS
- ✅ Easy database connection

### Deploy to Render

1. Create account at [Render.com](https://render.com)
2. Click "New" → "Web Service"
3. Connect GitHub repository
4. Configure:
   - **Build Command**: `npm install && npm run build`
   - **Start Command**: `npm start`
5. Add environment variables
6. Deploy!

### Deploy to VPS (Ubuntu)

```bash
# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Clone and setup
git clone https://github.com/imnothoan/Intelligence-Test-Server.git
cd Intelligence-Test-Server
npm install
npm run build

# Install PM2
npm install -g pm2

# Start with PM2
pm2 start dist/app.js --name intelligence-test-server
pm2 save
pm2 startup
```

See [Deployment Guide](docs/DEPLOYMENT.md) for details.

## 🔒 Security

### Best Practices

- ✅ Use strong JWT secrets (32+ characters)
- ✅ Enable HTTPS in production
- ✅ Keep service role key secret
- ✅ Use Row Level Security (RLS) in Supabase
- ✅ Rate limiting enabled by default
- ✅ Input validation with Joi schemas
- ✅ bcrypt for password hashing

### Environment Variables

**Never commit `.env` file to Git!**

For production:
- Generate strong secrets: `openssl rand -base64 32`
- Use environment-specific configurations
- Enable Supabase RLS policies
- Configure CORS for your domain

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

MIT License - see [LICENSE](LICENSE) file

## 👥 Authors

- [@imnothoan](https://github.com/imnothoan)

## 🙏 Acknowledgments

- [Supabase](https://supabase.com) - Database and authentication
- [Google Gemini](https://ai.google.dev/) - FREE AI API
- [Express.js](https://expressjs.com/) - Web framework
- Intelligence Test Community

## 📞 Support

- 📧 Email: See GitHub profile
- 🐛 Issues: [GitHub Issues](https://github.com/imnothoan/Intelligence-Test-Server/issues)
- 📖 Docs: [Documentation](docs/)

## 🗺️ Roadmap

- [ ] WebSocket real-time monitoring
- [ ] Advanced analytics dashboard
- [ ] Multi-language support
- [ ] Docker containerization
- [ ] Automated backups
- [ ] Performance monitoring
- [ ] Mobile API optimization

---

**Built with ❤️ for education**
