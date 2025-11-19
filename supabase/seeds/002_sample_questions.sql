-- Sample Questions Seed Data
-- Comprehensive question bank for Intelligence Test Platform
-- Covers Elementary, Middle School, High School, and University levels
-- Subjects: Math, Literature, Science, History, English

-- Note: Replace the instructor_id with actual instructor UUID from your database
-- or use the demo instructor ID from migration

-- Get or create demo instructor (if not exists from migration)
DO $$
DECLARE
    instructor_uuid UUID;
BEGIN
    -- Check if demo instructor exists
    SELECT id INTO instructor_uuid FROM users WHERE email = 'instructor@test.com' LIMIT 1;
    
    -- If not exists, create one
    IF instructor_uuid IS NULL THEN
        INSERT INTO users (email, password_hash, name, role)
        VALUES ('instructor@test.com', '$2b$10$rWVqX8xQZ5.QZ5.QZ5.QZ5.QZ5.QZ5.QZ5.QZ5.QZ5.QZ5.QZ5.QZ5.', 'Demo Instructor', 'instructor')
        RETURNING id INTO instructor_uuid;
    END IF;
    
    -- Store in temporary variable for use in inserts
    PERFORM set_config('app.instructor_id', instructor_uuid::text, false);
END $$;

-- ==========================================
-- MATHEMATICS QUESTIONS
-- ==========================================

-- Elementary Level Math (Grade 1-5)
INSERT INTO questions (type, question_text, options, correct_answer, difficulty, topic, explanation, created_by) VALUES
    ('multiple-choice', 'What is 5 + 7?', '["10", "11", "12", "13"]', '2', 0.15, 'Math - Elementary', 'Add the two numbers: 5 + 7 = 12', (SELECT current_setting('app.instructor_id')::uuid)),
    ('multiple-choice', 'How many sides does a triangle have?', '["2", "3", "4", "5"]', '1', 0.10, 'Math - Elementary', 'A triangle always has 3 sides.', (SELECT current_setting('app.instructor_id')::uuid)),
    ('multiple-choice', 'What is 8 × 3?', '["21", "24", "27", "30"]', '1', 0.20, 'Math - Elementary', 'Multiply 8 by 3: 8 × 3 = 24', (SELECT current_setting('app.instructor_id')::uuid)),
    ('multiple-choice', 'What is half of 20?', '["5", "10", "15", "20"]', '1', 0.18, 'Math - Elementary', 'Half of 20 is 20 ÷ 2 = 10', (SELECT current_setting('app.instructor_id')::uuid)),
    ('multiple-choice', 'Which number comes next: 2, 4, 6, 8, __?', '["9", "10", "11", "12"]', '1', 0.22, 'Math - Elementary', 'This is counting by 2s, so 8 + 2 = 10', (SELECT current_setting('app.instructor_id')::uuid));

-- Middle School Math (Grade 6-8)
INSERT INTO questions (type, question_text, options, correct_answer, difficulty, topic, explanation, created_by) VALUES
    ('multiple-choice', 'What is the value of x in the equation: 2x + 5 = 13?', '["3", "4", "5", "6"]', '1', 0.35, 'Math - Middle School', 'Solve for x: 2x = 13 - 5, 2x = 8, x = 4', (SELECT current_setting('app.instructor_id')::uuid)),
    ('multiple-choice', 'What is 15% of 200?', '["20", "25", "30", "35"]', '2', 0.40, 'Math - Middle School', 'Calculate: 200 × 0.15 = 30', (SELECT current_setting('app.instructor_id')::uuid)),
    ('multiple-choice', 'What is the area of a rectangle with length 8cm and width 5cm?', '["13 cm²", "26 cm²", "40 cm²", "80 cm²"]', '2', 0.32, 'Math - Middle School', 'Area = length × width = 8 × 5 = 40 cm²', (SELECT current_setting('app.instructor_id')::uuid)),
    ('multiple-choice', 'If a = 3 and b = 4, what is a² + b²?', '["7", "12", "25", "49"]', '2', 0.38, 'Math - Middle School', 'Calculate: 3² + 4² = 9 + 16 = 25', (SELECT current_setting('app.instructor_id')::uuid)),
    ('multiple-choice', 'What is the prime factorization of 24?', '["2 × 12", "2² × 6", "2³ × 3", "2 × 3 × 4"]', '2', 0.45, 'Math - Middle School', '24 = 2 × 2 × 2 × 3 = 2³ × 3', (SELECT current_setting('app.instructor_id')::uuid));

-- High School Math (Grade 9-12)
INSERT INTO questions (type, question_text, options, correct_answer, difficulty, topic, explanation, created_by) VALUES
    ('multiple-choice', 'Solve for x: x² - 5x + 6 = 0', '["x = 1 or x = 6", "x = 2 or x = 3", "x = -2 or x = -3", "x = 1 or x = -6"]', '1', 0.55, 'Math - High School', 'Factor: (x - 2)(x - 3) = 0, so x = 2 or x = 3', (SELECT current_setting('app.instructor_id')::uuid)),
    ('multiple-choice', 'What is the derivative of f(x) = x³?', '["x²", "2x²", "3x²", "3x"]', '2', 0.60, 'Math - High School', 'Using power rule: d/dx(x³) = 3x²', (SELECT current_setting('app.instructor_id')::uuid)),
    ('multiple-choice', 'What is sin(30°)?', '["1/2", "√2/2", "√3/2", "1"]', '0', 0.52, 'Math - High School', 'sin(30°) = 1/2', (SELECT current_setting('app.instructor_id')::uuid)),
    ('multiple-choice', 'What is the slope of the line y = 3x + 2?', '["2", "3", "5", "-3"]', '1', 0.48, 'Math - High School', 'In y = mx + b form, m is the slope. So slope = 3', (SELECT current_setting('app.instructor_id')::uuid)),
    ('multiple-choice', 'If log₂(x) = 5, what is x?', '["10", "16", "25", "32"]', '3', 0.62, 'Math - High School', 'log₂(x) = 5 means 2⁵ = x, so x = 32', (SELECT current_setting('app.instructor_id')::uuid));

-- University Level Math
INSERT INTO questions (type, question_text, options, correct_answer, difficulty, topic, explanation, created_by) VALUES
    ('multiple-choice', 'What is the limit of (sin x)/x as x approaches 0?', '["0", "1", "∞", "undefined"]', '1', 0.70, 'Math - University', 'This is a fundamental limit: lim(x→0) sin(x)/x = 1', (SELECT current_setting('app.instructor_id')::uuid)),
    ('multiple-choice', 'What is the integral of 1/x dx?', '["x²/2", "ln|x| + C", "1/x² + C", "-1/x + C"]', '1', 0.68, 'Math - University', '∫(1/x)dx = ln|x| + C', (SELECT current_setting('app.instructor_id')::uuid)),
    ('multiple-choice', 'Which of the following is an eigenvalue equation?', '["Ax = λx", "A + x = λ", "Ax = xλ", "A = λI"]', '0', 0.75, 'Math - University', 'Eigenvalue equation: Ax = λx where λ is eigenvalue', (SELECT current_setting('app.instructor_id')::uuid));

-- ==========================================
-- SCIENCE QUESTIONS
-- ==========================================

-- Elementary Science
INSERT INTO questions (type, question_text, options, correct_answer, difficulty, topic, explanation, created_by) VALUES
    ('multiple-choice', 'What do plants need to make food?', '["Water only", "Sunlight only", "Water, sunlight, and air", "Soil only"]', '2', 0.15, 'Science - Elementary', 'Plants need water, sunlight, and carbon dioxide from air for photosynthesis', (SELECT current_setting('app.instructor_id')::uuid)),
    ('multiple-choice', 'What is the center of our solar system?', '["Earth", "Moon", "Sun", "Jupiter"]', '2', 0.12, 'Science - Elementary', 'The Sun is at the center of our solar system', (SELECT current_setting('app.instructor_id')::uuid)),
    ('multiple-choice', 'What are the three states of matter?', '["Hot, cold, warm", "Solid, liquid, gas", "Big, small, tiny", "Fast, slow, still"]', '1', 0.18, 'Science - Elementary', 'Matter exists in three main states: solid, liquid, and gas', (SELECT current_setting('app.instructor_id')::uuid));

-- Middle School Science
INSERT INTO questions (type, question_text, options, correct_answer, difficulty, topic, explanation, created_by) VALUES
    ('multiple-choice', 'What is the chemical formula for water?', '["H₂O", "CO₂", "O₂", "H₂O₂"]', '0', 0.30, 'Science - Middle School', 'Water molecule consists of 2 hydrogen and 1 oxygen atom: H₂O', (SELECT current_setting('app.instructor_id')::uuid)),
    ('multiple-choice', 'What is the powerhouse of the cell?', '["Nucleus", "Mitochondria", "Chloroplast", "Ribosome"]', '1', 0.35, 'Science - Middle School', 'Mitochondria produce energy (ATP) for the cell', (SELECT current_setting('app.instructor_id')::uuid)),
    ('multiple-choice', 'What type of energy is stored in food?', '["Kinetic", "Potential", "Chemical", "Thermal"]', '2', 0.38, 'Science - Middle School', 'Food stores chemical energy in molecular bonds', (SELECT current_setting('app.instructor_id')::uuid));

-- High School Science
INSERT INTO questions (type, question_text, options, correct_answer, difficulty, topic, explanation, created_by) VALUES
    ('multiple-choice', 'What is Newton''s Second Law of Motion?', '["F = ma", "E = mc²", "v = d/t", "P = mv"]', '0', 0.50, 'Science - High School', 'Newton''s Second Law: Force = mass × acceleration', (SELECT current_setting('app.instructor_id')::uuid)),
    ('multiple-choice', 'What is the pH of a neutral solution?', '["0", "7", "14", "1"]', '1', 0.45, 'Science - High School', 'pH 7 is neutral (pure water)', (SELECT current_setting('app.instructor_id')::uuid)),
    ('multiple-choice', 'What is the process of cell division called?', '["Meiosis", "Mitosis", "Both A and B", "Osmosis"]', '2', 0.52, 'Science - High School', 'Both mitosis and meiosis are types of cell division', (SELECT current_setting('app.instructor_id')::uuid));

-- ==========================================
-- LITERATURE QUESTIONS (Vietnamese Context)
-- ==========================================

-- Elementary Literature
INSERT INTO questions (type, question_text, options, correct_answer, difficulty, topic, explanation, created_by) VALUES
    ('multiple-choice', 'Trong truyện "Sự tích Hồ Gươm", thanh gươm thần giúp ai?', '["Lê Lợi", "Trần Hưng Đạo", "Ngô Quyền", "Lý Thường Kiệt"]', '0', 0.20, 'Literature - Elementary', 'Thanh gươm thần giúp Lê Lợi đánh đuổi giặc Minh', (SELECT current_setting('app.instructor_id')::uuid)),
    ('multiple-choice', 'Câu thơ "Em yêu màu tím của hoa sim" là của tác giả nào?', '["Xuân Quỳnh", "Tố Hữu", "Thanh Hải", "Nguyễn Nhược Pháp"]', '2', 0.25, 'Literature - Elementary', 'Bài thơ "Hoa sim" của tác giả Thanh Hải', (SELECT current_setting('app.instructor_id')::uuid));

-- Middle School Literature  
INSERT INTO questions (type, question_text, options, correct_answer, difficulty, topic, explanation, created_by) VALUES
    ('multiple-choice', 'Tác phẩm "Chí Phèo" của Nam Cao thuộc thể loại nào?', '["Thơ", "Truyện ngắn", "Tiểu thuyết", "Kịch"]', '1', 0.35, 'Literature - Middle School', '"Chí Phèo" là truyện ngắn nổi tiếng của Nam Cao', (SELECT current_setting('app.instructor_id')::uuid)),
    ('multiple-choice', 'Ai là tác giả của "Truyện Kiều"?', '["Hồ Xuân Hương", "Nguyễn Du", "Nguyễn Trãi", "Nguyễn Bỉnh Khiêm"]', '1', 0.30, 'Literature - Middle School', 'Nguyễn Du là tác giả của "Đoạn trường tân thanh" (Truyện Kiều)', (SELECT current_setting('app.instructor_id')::uuid));

-- High School Literature
INSERT INTO questions (type, question_text, options, correct_answer, difficulty, topic, explanation, created_by) VALUES
    ('multiple-choice', 'Trong "Vợ chồng A Phủ", A Phủ là người dân tộc nào?', '["Thái", "Mông", "Tày", "Nùng"]', '1', 0.48, 'Literature - High School', 'A Phủ là người dân tộc Mông trong tác phẩm của Tô Hoài', (SELECT current_setting('app.instructor_id')::uuid)),
    ('multiple-choice', 'Thơ Đường luật có mấy câu?', '["4 câu", "6 câu", "8 câu", "10 câu"]', '2', 0.45, 'Literature - High School', 'Thơ Đường luật (Bát cú) có 8 câu', (SELECT current_setting('app.instructor_id')::uuid));

-- ==========================================
-- ENGLISH QUESTIONS
-- ==========================================

-- Elementary English
INSERT INTO questions (type, question_text, options, correct_answer, difficulty, topic, explanation, created_by) VALUES
    ('multiple-choice', 'Choose the correct spelling:', '["Aple", "Apple", "Apel", "Appel"]', '1', 0.15, 'English - Elementary', 'The correct spelling is "Apple"', (SELECT current_setting('app.instructor_id')::uuid)),
    ('multiple-choice', 'What is the opposite of "hot"?', '["Warm", "Cold", "Cool", "Freezing"]', '1', 0.12, 'English - Elementary', 'The opposite of hot is cold', (SELECT current_setting('app.instructor_id')::uuid)),
    ('multiple-choice', 'Which word is a verb?', '["Book", "Run", "Table", "Red"]', '1', 0.20, 'English - Elementary', '"Run" is an action word (verb)', (SELECT current_setting('app.instructor_id')::uuid));

-- Middle School English
INSERT INTO questions (type, question_text, options, correct_answer, difficulty, topic, explanation, created_by) VALUES
    ('multiple-choice', 'Choose the correct form: "She ___ to school every day."', '["go", "goes", "going", "gone"]', '1', 0.35, 'English - Middle School', 'With "she" (third person singular), use "goes"', (SELECT current_setting('app.instructor_id')::uuid)),
    ('multiple-choice', 'What is the past tense of "write"?', '["Writed", "Wrote", "Written", "Writing"]', '1', 0.32, 'English - Middle School', 'The past tense of "write" is "wrote"', (SELECT current_setting('app.instructor_id')::uuid)),
    ('multiple-choice', 'Identify the adjective: "The beautiful flower bloomed."', '["The", "Beautiful", "Flower", "Bloomed"]', '1', 0.38, 'English - Middle School', '"Beautiful" describes the flower, making it an adjective', (SELECT current_setting('app.instructor_id')::uuid));

-- High School English
INSERT INTO questions (type, question_text, options, correct_answer, difficulty, topic, explanation, created_by) VALUES
    ('multiple-choice', 'Which literary device is used: "The wind whispered through the trees"?', '["Metaphor", "Simile", "Personification", "Alliteration"]', '2', 0.50, 'English - High School', 'Giving human qualities (whisper) to wind is personification', (SELECT current_setting('app.instructor_id')::uuid)),
    ('multiple-choice', 'What is the main clause in: "When I arrived, they had left"?', '["When I arrived", "They had left", "I arrived", "Had left"]', '1', 0.52, 'English - High School', '"They had left" is the independent/main clause', (SELECT current_setting('app.instructor_id')::uuid)),
    ('multiple-choice', 'Choose the correct usage:', '["Less people", "Fewer people", "Lesser people", "Few people"]', '1', 0.48, 'English - High School', 'Use "fewer" with countable nouns like "people"', (SELECT current_setting('app.instructor_id')::uuid));

-- ==========================================
-- HISTORY QUESTIONS (Vietnamese History)
-- ==========================================

-- Elementary History
INSERT INTO questions (type, question_text, options, correct_answer, difficulty, topic, explanation, created_by) VALUES
    ('multiple-choice', 'Ai là vị vua đầu tiên của nước Việt Nam?', '["Lý Thái Tổ", "Đinh Tiên Hoàng", "Hùng Vương", "Lê Lợi"]', '2', 0.22, 'History - Elementary', 'Hùng Vương là vị vua đầu tiên, sáng lập nhà nước Văn Lang', (SELECT current_setting('app.instructor_id')::uuid)),
    ('multiple-choice', 'Ngày Quốc khánh Việt Nam là ngày nào?', '["30/4", "2/9", "19/5", "20/11"]', '1', 0.15, 'History - Elementary', 'Ngày Quốc khánh là 2/9/1945', (SELECT current_setting('app.instructor_id')::uuid));

-- Middle School History
INSERT INTO questions (type, question_text, options, correct_answer, difficulty, topic, explanation, created_by) VALUES
    ('multiple-choice', 'Trận chiến nào đánh dấu kết thúc ách thống trị của thực dân Pháp?', '["Điện Biên Phủ", "Bạch Đằng", "Chi Lăng", "Đống Đa"]', '0', 0.40, 'History - Middle School', 'Chiến thắng Điện Biên Phủ 1954 chấm dứt ách thống trị của Pháp', (SELECT current_setting('app.instructor_id')::uuid)),
    ('multiple-choice', 'Ai là người đã ba lần đánh thắng quân Mông Cổ?', '["Trần Hưng Đạo", "Ngô Quyền", "Lê Lợi", "Quang Trung"]', '0', 0.35, 'History - Middle School', 'Trần Hưng Đạo ba lần đánh thắng quân Nguyên - Mông', (SELECT current_setting('app.instructor_id')::uuid));

-- High School History
INSERT INTO questions (type, question_text, options, correct_answer, difficulty, topic, explanation, created_by) VALUES
    ('multiple-choice', 'Cách mạng tháng Tám thành công vào năm nào?', '["1944", "1945", "1946", "1954"]', '1', 0.45, 'History - High School', 'Cách mạng tháng Tám thành công năm 1945', (SELECT current_setting('app.instructor_id')::uuid)),
    ('multiple-choice', 'Chiến dịch nào mở đầu cho cuộc Tổng tiến công và nổi dậy năm 1975?', '["Tây Nguyên", "Hồ Chí Minh", "Xuân Lộc", "Huế - Đà Nẵng"]', '0', 0.52, 'History - High School', 'Chiến dịch Tây Nguyên (10-27/3/1975) mở đầu Tổng tiến công', (SELECT current_setting('app.instructor_id')::uuid));

-- ==========================================
-- ESSAY QUESTIONS (Mixed Topics)
-- ==========================================

INSERT INTO questions (type, question_text, options, correct_answer, difficulty, topic, explanation, created_by) VALUES
    ('essay', 'Describe your favorite hobby and explain why you enjoy it. (150-200 words)', NULL, NULL, 0.40, 'Writing - General', 'Evaluate based on clarity, organization, and explanation of personal interest', (SELECT current_setting('app.instructor_id')::uuid)),
    ('essay', 'Explain the importance of education in modern society. (200-300 words)', NULL, NULL, 0.55, 'Writing - Social Issues', 'Assess understanding of education''s role, coherent arguments, and examples', (SELECT current_setting('app.instructor_id')::uuid)),
    ('essay', 'Discuss the impact of technology on daily life. Include both positive and negative aspects. (250-350 words)', NULL, NULL, 0.60, 'Writing - Technology', 'Evaluate balanced perspective, specific examples, and critical thinking', (SELECT current_setting('app.instructor_id')::uuid)),
    ('essay', 'Write a short story about a memorable experience from your childhood. (200-250 words)', NULL, NULL, 0.45, 'Writing - Creative', 'Assess narrative structure, descriptive language, and emotional engagement', (SELECT current_setting('app.instructor_id')::uuid));

-- Add comments for documentation
COMMENT ON COLUMN questions.difficulty IS 'Difficulty level from 0.0 (easiest) to 1.0 (hardest) for CAT algorithm';
COMMENT ON COLUMN questions.topic IS 'Subject and grade level classification';

-- Summary output
DO $$
DECLARE
    question_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO question_count FROM questions;
    RAISE NOTICE 'Successfully inserted % questions across multiple subjects and grade levels', question_count;
END $$;
