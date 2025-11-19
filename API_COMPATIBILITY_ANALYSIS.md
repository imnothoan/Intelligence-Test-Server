# API Compatibility Analysis: Client vs Server

## Overview
This document analyzes the compatibility between the Intelligence Test Client and Server APIs, identifying mismatches and required implementations.

## Authentication API

### Client Expectations:
```typescript
POST /api/auth/login { email, password, role }
POST /api/auth/register { email, password, name, role }
POST /api/auth/refresh { refreshToken }
POST /api/auth/logout { refreshToken }
GET /api/auth/me
```

### Server Implementation:
```typescript
POST /api/auth/register ✅
POST /api/auth/login ✅
POST /api/auth/refresh ✅
GET /api/auth/profile ⚠️ (should be /me)
PUT /api/auth/profile ✅
PUT /api/auth/change-password ✅
POST /api/auth/logout ❌ MISSING
```

### Action Items:
- [ ] Add `/api/auth/me` endpoint (or alias `/profile` to `/me`)
- [ ] Add `/api/auth/logout` endpoint
- [ ] Verify refresh token flow matches client expectations

## User Management API

### Client Expectations:
```typescript
GET /api/users/:userId
GET /api/users (list all users - admin?)
PUT /api/users/:userId
DELETE /api/users/:userId
```

### Server Implementation:
```typescript
❌ No user management routes implemented
```

### Action Items:
- [ ] Decide if user management API is needed
- [ ] If yes, implement user CRUD endpoints

## Exam API

### Client Expectations:
```typescript
GET /api/exams (list all)
GET /api/exams/:id
POST /api/exams
PUT /api/exams/:id
DELETE /api/exams/:id
GET /api/exams/:examId/attempts (all attempts for exam)
POST /api/exams/:examId/attempts (start new attempt)
GET /api/exams/:examId/sessions/active
GET /api/exams/:examId/attempts/flagged
GET /api/exams/:examId/statistics
GET /api/exams/:examId/analytics/questions
GET /api/students/:studentId/available (available exams for student)
```

### Server Implementation:
```typescript
GET /api/exams ✅
GET /api/exams/:id ✅
POST /api/exams ✅
PUT /api/exams/:id ✅
DELETE /api/exams/:id ✅
POST /api/exams/assign ✅ (assign to class)
GET /api/attempts/exam/:examId ⚠️ (should be /exams/:examId/attempts)
POST /api/attempts/start ⚠️ (expects examId in body, not URL)
GET /api/exams/:examId/sessions/active ❌ MISSING
GET /api/exams/:examId/attempts/flagged ❌ MISSING
GET /api/exams/:examId/statistics ❌ MISSING
GET /api/exams/:examId/analytics/questions ❌ MISSING
GET /api/students/:studentId/available ❌ MISSING
```

### Action Items:
- [ ] Add nested attempt routes under /exams/:examId/attempts
- [ ] Add exam statistics endpoint
- [ ] Add question analytics endpoint
- [ ] Add active sessions endpoint
- [ ] Add flagged attempts endpoint
- [ ] Add available exams for student endpoint

## Class API

### Client Expectations:
```typescript
POST /api/classes
GET /api/classes/:id
PUT /api/classes/:id
DELETE /api/classes/:id
GET /api/classes/instructor/:instructorId
POST /api/classes/:classId/students { studentId }
DELETE /api/classes/:classId/students/:studentId
```

### Server Implementation:
```typescript
GET /api/classes ✅
GET /api/classes/:id ✅
POST /api/classes ✅
PUT /api/classes/:id ✅
DELETE /api/classes/:id ✅
GET /api/classes/:id/students ✅
GET /api/classes/:id/exams ✅
POST /api/classes/students ⚠️ (expects both classId and studentId in body)
DELETE /api/classes/:classId/students/:studentId ✅
GET /api/classes/instructor/:instructorId ❌ MISSING
```

### Action Items:
- [ ] Add endpoint to get classes by instructor
- [ ] Consider adjusting POST /classes/students to POST /classes/:classId/students

## Question Bank API

### Client Expectations:
```typescript
POST /api/questions
GET /api/questions/:id
PUT /api/questions/:id
DELETE /api/questions/:id
GET /api/questions/search?filters
```

### Server Implementation:
```typescript
GET /api/questions ✅ (with filters)
GET /api/questions/:id ✅
POST /api/questions ✅
POST /api/questions/generate ✅ (AI generation)
POST /api/questions/bulk-import ✅
POST /api/questions/by-ids ✅
PUT /api/questions/:id ✅
DELETE /api/questions/:id ✅
GET /api/questions/search ❌ (using GET /questions with query params instead)
```

### Action Items:
- [ ] Consider adding explicit /search endpoint or document that filters are on main endpoint

## Exam Attempt API

### Client Expectations:
```typescript
POST /api/exams/:examId/attempts (start)
GET /api/attempts/:id
PUT /api/attempts/:id
POST /api/attempts/:id/submit
GET /api/exams/:examId/attempts
GET /api/students/:studentId/attempts
POST /api/attempts/:attemptId/warnings
```

### Server Implementation:
```typescript
POST /api/attempts/start ⚠️ (expects examId in body)
GET /api/attempts/:attemptId/next-question ✅
POST /api/attempts/:attemptId/submit-answer ✅
POST /api/attempts/:attemptId/submit-warning ✅
POST /api/attempts/:attemptId/complete ✅
GET /api/attempts/:id ✅
GET /api/attempts/exam/:examId ⚠️
GET /api/attempts/student/:studentId ⚠️
PUT /api/attempts/:id ❌ MISSING
POST /api/attempts/:id/submit ❌ (using /complete instead)
```

### Action Items:
- [ ] Align attempt start endpoint with client expectations
- [ ] Align attempt listing endpoints
- [ ] Add update attempt endpoint if needed
- [ ] Document difference between submit and complete

## Anti-Cheat & Monitoring API

### Client Expectations:
```typescript
POST /api/attempts/:attemptId/warnings
GET /api/exams/:examId/sessions/active
GET /api/exams/:examId/attempts/flagged
```

### Server Implementation:
```typescript
POST /api/attempts/:attemptId/submit-warning ✅
GET /api/exams/:examId/sessions/active ❌ MISSING
GET /api/exams/:examId/attempts/flagged ❌ MISSING
```

### Action Items:
- [ ] Implement active sessions endpoint
- [ ] Implement flagged attempts endpoint

## Analytics API

### Client Expectations:
```typescript
GET /api/exams/:examId/statistics
GET /api/exams/:examId/analytics/questions
GET /api/students/:studentId/performance?timeRange
```

### Server Implementation:
```typescript
❌ No analytics endpoints implemented
```

### Action Items:
- [ ] Implement exam statistics endpoint
- [ ] Implement question analytics endpoint
- [ ] Implement student performance endpoint

## WebSocket API

### Client Expectations:
```typescript
ws://server/ws/monitoring/:examId
Messages:
  - auth
  - exam_started
  - exam_progress
  - exam_completed
  - cheat_warning
  - student_joined
  - student_left
  - answer_submitted
  - ping/pong
```

### Server Implementation:
```typescript
❌ No WebSocket implementation
```

### Action Items:
- [ ] Implement WebSocket server
- [ ] Add authentication middleware for WebSocket
- [ ] Implement real-time monitoring
- [ ] Implement cheat warning broadcasts
- [ ] Add heartbeat/ping-pong mechanism

## Health Check API

### Client Expectations:
```typescript
GET /api/health
```

### Server Implementation:
```typescript
GET /health ✅ (not under /api prefix)
```

### Action Items:
- [ ] Add /api/health endpoint or document correct path

## Summary of Missing Features

### Critical (Blocks Core Functionality):
1. WebSocket implementation for real-time monitoring
2. Exam attempt start endpoint alignment
3. Active sessions endpoint
4. Flagged attempts endpoint

### Important (Expected by Client):
1. Auth logout endpoint
2. Auth /me endpoint
3. Exam statistics endpoint
4. Question analytics endpoint
5. Student performance endpoint
6. Available exams for student endpoint
7. Classes by instructor endpoint

### Nice to Have:
1. Explicit /questions/search endpoint
2. User management endpoints (if needed)
3. Update attempt endpoint

## Recommendations

1. **Immediate Actions**:
   - Add missing authentication endpoints
   - Align attempt endpoint structure
   - Implement WebSocket server

2. **Short-term Actions**:
   - Add analytics endpoints
   - Add monitoring endpoints
   - Implement active session tracking

3. **Documentation**:
   - Create comprehensive API documentation
   - Document any intentional differences
   - Add API versioning strategy

4. **Testing**:
   - Create integration tests between client and server
   - Test all critical flows end-to-end
   - Add monitoring for API errors
