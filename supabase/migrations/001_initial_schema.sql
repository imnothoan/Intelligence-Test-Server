-- Intelligence Test Server - Supabase Database Schema
-- This migration creates all necessary tables for the Intelligence Test Platform

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE IF NOT EXISTS users (
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

-- Create index on email for faster lookups
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

-- Classes table
CREATE TABLE IF NOT EXISTS classes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    instructor_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_classes_instructor ON classes(instructor_id);

-- Class students (many-to-many relationship)
CREATE TABLE IF NOT EXISTS class_students (
    class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (class_id, student_id)
);

CREATE INDEX idx_class_students_class ON class_students(class_id);
CREATE INDEX idx_class_students_student ON class_students(student_id);

-- Questions table
CREATE TABLE IF NOT EXISTS questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type VARCHAR(20) NOT NULL CHECK (type IN ('multiple-choice', 'essay')),
    question_text TEXT NOT NULL,
    options JSONB, -- Array of strings for multiple-choice
    correct_answer VARCHAR(255), -- For multiple-choice
    difficulty DECIMAL(3, 2) NOT NULL CHECK (difficulty >= 0 AND difficulty <= 1),
    topic VARCHAR(255),
    explanation TEXT,
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_questions_type ON questions(type);
CREATE INDEX idx_questions_difficulty ON questions(difficulty);
CREATE INDEX idx_questions_topic ON questions(topic);
CREATE INDEX idx_questions_created_by ON questions(created_by);

-- Exams table
CREATE TABLE IF NOT EXISTS exams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    instructor_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    duration_minutes INTEGER NOT NULL CHECK (duration_minutes > 0),
    enable_cat BOOLEAN DEFAULT FALSE,
    enable_anti_cheat BOOLEAN DEFAULT FALSE,
    question_ids JSONB NOT NULL, -- Array of UUIDs
    cat_settings JSONB, -- {initial_ability, precision_threshold, min_questions, max_questions}
    scheduled_start TIMESTAMP WITH TIME ZONE,
    scheduled_end TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_exams_instructor ON exams(instructor_id);
CREATE INDEX idx_exams_scheduled_start ON exams(scheduled_start);

-- Exam assignments (exams assigned to classes)
CREATE TABLE IF NOT EXISTS exam_assignments (
    exam_id UUID NOT NULL REFERENCES exams(id) ON DELETE CASCADE,
    class_id UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (exam_id, class_id)
);

CREATE INDEX idx_exam_assignments_exam ON exam_assignments(exam_id);
CREATE INDEX idx_exam_assignments_class ON exam_assignments(class_id);

-- Exam attempts table
CREATE TABLE IF NOT EXISTS exam_attempts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    exam_id UUID NOT NULL REFERENCES exams(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    score INTEGER CHECK (score >= 0 AND score <= 100),
    ability_estimate DECIMAL(5, 2), -- For CAT
    responses JSONB DEFAULT '[]'::JSONB, -- Array of {question_id, answer, is_correct, time_spent_seconds, answered_at}
    anti_cheat_warnings JSONB DEFAULT '[]'::JSONB, -- Array of {timestamp, type, severity, details}
    flagged BOOLEAN DEFAULT FALSE,
    status VARCHAR(20) NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed', 'abandoned')),
    cat_state JSONB, -- Current CAT state
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_exam_attempts_exam ON exam_attempts(exam_id);
CREATE INDEX idx_exam_attempts_student ON exam_attempts(student_id);
CREATE INDEX idx_exam_attempts_status ON exam_attempts(status);
CREATE INDEX idx_exam_attempts_flagged ON exam_attempts(flagged);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updating updated_at
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_classes_updated_at
    BEFORE UPDATE ON classes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_questions_updated_at
    BEFORE UPDATE ON questions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_exams_updated_at
    BEFORE UPDATE ON exams
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_exam_attempts_updated_at
    BEFORE UPDATE ON exam_attempts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Row Level Security (RLS) Policies
-- Note: Enable RLS for production. For now, using service role key for server operations.

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_students ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE exams ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_attempts ENABLE ROW LEVEL SECURITY;

-- Users can read their own data
CREATE POLICY users_select_own ON users
    FOR SELECT
    USING (auth.uid() = id OR 'authenticated' IN (SELECT role FROM users WHERE id = auth.uid()));

-- Instructors can read all users
CREATE POLICY users_select_instructor ON users
    FOR SELECT
    USING (
        (SELECT role FROM users WHERE id = auth.uid()) = 'instructor'
    );

-- Users can update their own profile
CREATE POLICY users_update_own ON users
    FOR UPDATE
    USING (auth.uid() = id);

-- Classes: Instructors can do everything with their classes
CREATE POLICY classes_all_instructor ON classes
    FOR ALL
    USING (
        instructor_id = auth.uid() OR
        EXISTS (SELECT 1 FROM class_students WHERE class_id = classes.id AND student_id = auth.uid())
    );

-- Questions: Creators can manage their questions
CREATE POLICY questions_all_creator ON questions
    FOR ALL
    USING (created_by = auth.uid());

-- Questions: Everyone can read
CREATE POLICY questions_select_all ON questions
    FOR SELECT
    USING (true);

-- Exams: Instructors can manage their exams
CREATE POLICY exams_all_instructor ON exams
    FOR ALL
    USING (instructor_id = auth.uid());

-- Students can read exams assigned to their classes
CREATE POLICY exams_select_student ON exams
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM exam_assignments ea
            JOIN class_students cs ON ea.class_id = cs.class_id
            WHERE ea.exam_id = exams.id AND cs.student_id = auth.uid()
        )
    );

-- Exam attempts: Students can manage their own attempts
CREATE POLICY exam_attempts_all_student ON exam_attempts
    FOR ALL
    USING (student_id = auth.uid());

-- Instructors can view attempts for their exams
CREATE POLICY exam_attempts_select_instructor ON exam_attempts
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM exams
            WHERE exams.id = exam_attempts.exam_id AND exams.instructor_id = auth.uid()
        )
    );

-- Insert some demo data (optional - comment out for production)
-- Demo instructor
INSERT INTO users (id, email, password_hash, name, role) VALUES
    ('00000000-0000-0000-0000-000000000001', 'instructor@test.com', '$2b$10$rWVqX8xQZ5.QZ5.QZ5.QZ5.QZ5.QZ5.QZ5.QZ5.QZ5.QZ5.QZ5.QZ5.', 'Demo Instructor', 'instructor')
ON CONFLICT (email) DO NOTHING;

-- Demo student
INSERT INTO users (id, email, password_hash, name, role) VALUES
    ('00000000-0000-0000-0000-000000000002', 'student@test.com', '$2b$10$rWVqX8xQZ5.QZ5.QZ5.QZ5.QZ5.QZ5.QZ5.QZ5.QZ5.QZ5.QZ5.QZ5.', 'Demo Student', 'student')
ON CONFLICT (email) DO NOTHING;

COMMENT ON TABLE users IS 'User accounts (students and instructors)';
COMMENT ON TABLE classes IS 'Classes created by instructors';
COMMENT ON TABLE class_students IS 'Many-to-many relationship between classes and students';
COMMENT ON TABLE questions IS 'Question bank with difficulty parameters for CAT';
COMMENT ON TABLE exams IS 'Exams created by instructors';
COMMENT ON TABLE exam_assignments IS 'Exams assigned to classes';
COMMENT ON TABLE exam_attempts IS 'Student exam attempts with CAT state and anti-cheat warnings';
