# Student-Management-System-
Ysma euta sms ko code xa jun chai sql ma lekhiyeko xa for college DBMS project.

ksari banako padnalai:
Here's a detailed explanation of each part of your MySQL schema and why it's implemented this way:

--Database Creation

CREATE DATABASE CollegeSMS;
USE CollegeSMS;

##Creates the database CollegeSMS.
Selects it for use, so all subsequent table operations apply to it.

--Students Table
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

##Stores student details.
AUTO_INCREMENT ensures student_id is unique.
ENUM restricts gender to allowed values.
UNIQUE ensures email and phone don’t duplicate.
Index on first_name, last_name for faster searches.

--Courses Table
CREATE TABLE Courses (
    course_id INT AUTO_INCREMENT PRIMARY KEY,
    course_name VARCHAR(100) NOT NULL UNIQUE,
    course_code VARCHAR(20) NOT NULL UNIQUE,
    credits INT NOT NULL CHECK (credits BETWEEN 1 AND 10)
);

##Stores course details.
UNIQUE course_name and course_code prevent duplication.
CHECK (credits BETWEEN 1 AND 10) ensures credits are valid.

--Faculty Table
CREATE TABLE Faculty (
    faculty_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(15) UNIQUE NOT NULL,
    department VARCHAR(100) NOT NULL
);

##Stores faculty details.
Unique email and phone prevent duplication.

--Enrollments Table
CREATE TABLE Enrollments (
    enrollment_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT,
    course_id INT,
    enrollment_date DATE NOT NULL,
    CONSTRAINT fk_enroll_student FOREIGN KEY (student_id) REFERENCES Students(student_id) ON DELETE CASCADE,
    CONSTRAINT fk_enroll_course FOREIGN KEY (course_id) REFERENCES Courses(course_id) ON DELETE CASCADE,
    UNIQUE KEY unique_enrollment (student_id, course_id)
);

##Stores which students enroll in which courses.
Foreign keys enforce referential integrity.
ON DELETE CASCADE deletes enrollments if a student or course is removed.
Unique constraint prevents duplicate enrollments.

--Attendance Table
CREATE TABLE Attendance (
    attendance_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT,
    course_id INT,
    date DATE NOT NULL,
    status ENUM('Present', 'Absent', 'Late') NOT NULL,
    CONSTRAINT fk_attendance_student FOREIGN KEY (student_id) REFERENCES Students(student_id) ON DELETE CASCADE,
    CONSTRAINT fk_attendance_course FOREIGN KEY (course_id) REFERENCES Courses(course_id) ON DELETE CASCADE
);

##Tracks student attendance.
Foreign keys ensure students and courses exist.
ENUM for status limits values to valid options.

--Exams Table
CREATE TABLE Exams (
    exam_id INT AUTO_INCREMENT PRIMARY KEY,
    course_id INT,
    exam_date DATE NOT NULL,
    total_marks INT NOT NULL CHECK (total_marks > 0),
    CONSTRAINT fk_exam_course FOREIGN KEY (course_id) REFERENCES Courses(course_id) ON DELETE CASCADE
);

##Stores exam details.
Foreign key on course_id ensures the course exists.
Check constraint ensures total_marks is positive.

--Results Table
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

##Stores exam results.
Auto-calculated grade based on marks_obtained.
Unique constraint ensures no duplicate results for a student-exam pair.

--Triggers
Prevent Duplicate Enrollments
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

##Prevents duplicate enrollments by checking if the student is already enrolled in the course.

--Auto-fill Attendance on Enrollment
DELIMITER $$
CREATE TRIGGER after_enrollment_insert
AFTER INSERT ON Enrollments
FOR EACH ROW
BEGIN
    INSERT INTO Attendance (student_id, course_id, date, status)
    VALUES (NEW.student_id, NEW.course_id, CURDATE(), 'Present');
END $$
DELIMITER ;

##Automatically marks attendance when a student enrolls.

--Set Default Admission Date
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

##Ensures admission_date defaults to today’s date if not provided.

--Set Default Enrollment Date
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

##Ensures enrollment_date defaults to today if not provided.

--Indexes for Optimization

CREATE INDEX idx_student_email ON Students(email);
CREATE INDEX idx_student_phone ON Students(phone);
CREATE INDEX idx_course_code ON Courses(course_code);
CREATE INDEX idx_enrollment ON Enrollments(student_id, course_id);
Speeds up queries on frequently searched fields.

--Final Notes
This schema is: ✔ Optimized with indexing.
✔ Ensures data integrity via constraints and foreign keys.
✔ Prevents duplication with unique keys and triggers.
✔ Automates tasks like setting default dates and tracking attendance.
