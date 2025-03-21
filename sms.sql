CREATE DATABASE CollegeSMS;
USE CollegeSMS;

-- Students Table
CREATE TABLE Students (
    student_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    dob DATE NOT NULL,
    gender ENUM('Male', 'Female', 'Other') NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(15) UNIQUE NOT NULL,
    address TEXT NOT NULL,
    admission_date DATE NOT NULL,
    INDEX idx_name (first_name, last_name)
);

-- Courses Table
CREATE TABLE Courses (
    course_id INT AUTO_INCREMENT PRIMARY KEY,
    course_name VARCHAR(100) NOT NULL UNIQUE,
    course_code VARCHAR(20) NOT NULL UNIQUE,
    credits INT NOT NULL CHECK (credits BETWEEN 1 AND 10)
);

-- Faculty Table
CREATE TABLE Faculty (
    faculty_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(15) UNIQUE NOT NULL,
    department VARCHAR(100) NOT NULL
);

-- Enrollments Table
CREATE TABLE Enrollments (
    enrollment_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT,
    course_id INT,
    enrollment_date DATE NOT NULL,
    CONSTRAINT fk_enroll_student FOREIGN KEY (student_id) REFERENCES Students(student_id) ON DELETE CASCADE,
    CONSTRAINT fk_enroll_course FOREIGN KEY (course_id) REFERENCES Courses(course_id) ON DELETE CASCADE,
    UNIQUE KEY unique_enrollment (student_id, course_id)
);

-- Attendance Table
CREATE TABLE Attendance (
    attendance_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT,
    course_id INT,
    date DATE NOT NULL,
    status ENUM('Present', 'Absent', 'Late') NOT NULL,
    CONSTRAINT fk_attendance_student FOREIGN KEY (student_id) REFERENCES Students(student_id) ON DELETE CASCADE,
    CONSTRAINT fk_attendance_course FOREIGN KEY (course_id) REFERENCES Courses(course_id) ON DELETE CASCADE
);

-- Exams Table
CREATE TABLE Exams (
    exam_id INT AUTO_INCREMENT PRIMARY KEY,
    course_id INT,
    exam_date DATE NOT NULL,
    total_marks INT NOT NULL CHECK (total_marks > 0),
    CONSTRAINT fk_exam_course FOREIGN KEY (course_id) REFERENCES Courses(course_id) ON DELETE CASCADE
);

-- Results Table
CREATE TABLE Results (
    result_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT,
    exam_id INT,
    marks_obtained INT NOT NULL CHECK (marks_obtained >= 0),
    grade VARCHAR(2) GENERATED ALWAYS AS (
        CASE
            WHEN marks_obtained >= 90 THEN 'A+'
            WHEN marks_obtained >= 80 THEN 'A'
            WHEN marks_obtained >= 70 THEN 'B'
            WHEN marks_obtained >= 60 THEN 'C'
            WHEN marks_obtained >= 50 THEN 'D'
            ELSE 'F'
        END
    ) STORED,
    CONSTRAINT fk_result_student FOREIGN KEY (student_id) REFERENCES Students(student_id) ON DELETE CASCADE,
    CONSTRAINT fk_result_exam FOREIGN KEY (exam_id) REFERENCES Exams(exam_id) ON DELETE CASCADE,
    UNIQUE KEY unique_result (student_id, exam_id)
);

-- Triggers
-- Prevent duplicate enrollments
DELIMITER $$
CREATE TRIGGER before_insert_enrollment
BEFORE INSERT ON Enrollments
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM Enrollments WHERE student_id = NEW.student_id AND course_id = NEW.course_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Student is already enrolled in this course';
    END IF;
END $$
DELIMITER ;

-- Auto-fill attendance when a student enrolls
DELIMITER $$
CREATE TRIGGER after_enrollment_insert
AFTER INSERT ON Enrollments
FOR EACH ROW
BEGIN
    INSERT INTO Attendance (student_id, course_id, date, status)
    VALUES (NEW.student_id, NEW.course_id, CURDATE(), 'Present');
END $$
DELIMITER ;

-- Set default admission_date
DELIMITER $$
CREATE TRIGGER before_insert_student
BEFORE INSERT ON Students
FOR EACH ROW
BEGIN
    IF NEW.admission_date IS NULL THEN
        SET NEW.admission_date = CURDATE();
    END IF;
END $$
DELIMITER ;

-- Set default enrollment_date
DELIMITER $$
CREATE TRIGGER before_insert_enrollment_date
BEFORE INSERT ON Enrollments
FOR EACH ROW
BEGIN
    IF NEW.enrollment_date IS NULL THEN
        SET NEW.enrollment_date = CURDATE();
    END IF;
END $$
DELIMITER ;

-- Indexing for Optimization
CREATE INDEX idx_student_email ON Students(email);
CREATE INDEX idx_student_phone ON Students(phone);
CREATE INDEX idx_course_code ON Courses(course_code);
CREATE INDEX idx_enrollment ON Enrollments(student_id, course_id);

INSERT INTO Students (first_name, last_name, dob, gender, email, phone, address, admission_date)
VALUES 
('John', 'Doe', '2000-05-15', 'Male', 'john.doe@example.com', '9800000001', 'Kathmandu', NULL),
('Alice', 'Smith', '1999-08-20', 'Female', 'alice.smith@example.com', '9800000002', 'Pokhara', NULL);

INSERT INTO Courses (course_name, course_code, credits)
VALUES 
('Database Systems', 'DB101', 4),
('Computer Networks', 'CN201', 3);

INSERT INTO Faculty (first_name, last_name, email, phone, department)
VALUES 
('Robert', 'Brown', 'robert.brown@example.com', '9800000003', 'Computer Science'),
('Sarah', 'Miller', 'sarah.miller@example.com', '9800000004', 'Information Technology');

INSERT INTO Enrollments (student_id, course_id, enrollment_date)
VALUES 
(1, 1, NULL), -- John Doe enrolls in Database Systems
(1, 2, NULL), -- John Doe enrolls in Computer Networks
(2, 1, NULL); -- Alice Smith enrolls in Database Systems

SELECT * FROM Attendance;

-- duplicate attendance
INSERT INTO Enrollments (student_id, course_id, enrollment_date)
VALUES (1, 1, NULL);
  
-- Test exam and results
INSERT INTO Exams (course_id, exam_date, total_marks)
VALUES (1, '2025-05-01', 100);

INSERT INTO Results (student_id, exam_id, marks_obtained)
VALUES (1, 1, 85);

SELECT * FROM Results;

-- Query Testing get all Students with Enrollment Details
SELECT s.student_id, s.first_name, s.last_name, c.course_name, e.enrollment_date
FROM Students s
JOIN Enrollments e ON s.student_id = e.student_id
JOIN Courses c ON e.course_id = c.course_id;
 -- attendance for specific 
SELECT a.date, a.status, c.course_name 
FROM Attendance a
JOIN Courses c ON a.course_id = c.course_id
WHERE a.student_id = 1;
 -- Performance Testing
 -- check if indexs are working by analysing queries
 
EXPLAIN SELECT * FROM Students WHERE email = 'john.doe@example.com';

-- Test Invalid Marks
INSERT INTO Results (student_id, exam_id, marks_obtained)
VALUES (1, 1, -10);
-- error due to CHECK (marks_obtained >= 0)
-- Test Deleting a Student
DELETE FROM Students WHERE student_id = 1;
-- Enrollment, attendance, and results should be deleted due to ON DELETE CASCADE.

