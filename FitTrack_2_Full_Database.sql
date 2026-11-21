-- FitTrack 2.0 COMPLETE DATABASE
-- This file creates a fresh database. It is intended for a NEW installation.
-- Database name: FitTrack2 (update config/database.php to use this name)
-- Do not import this over a database containing data you need to keep.

CREATE DATABASE IF NOT EXISTS `FitTrack2`
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `FitTrack2`;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS admin_notifications;
DROP TABLE IF EXISTS email_logs;
DROP TABLE IF EXISTS coach_bookings;
DROP TABLE IF EXISTS coach_availability;
DROP TABLE IF EXISTS coaches;
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS subscription_requests;
DROP TABLE IF EXISTS admin_suggestions;
DROP TABLE IF EXISTS user_plan_assignments;
DROP TABLE IF EXISTS workout_templates;
DROP TABLE IF EXISTS diet_plans;
DROP TABLE IF EXISTS food_logs;
DROP TABLE IF EXISTS water_logs;
DROP TABLE IF EXISTS body_measurements;
DROP TABLE IF EXISTS fitness_goals;
DROP TABLE IF EXISTS workout_sets;
DROP TABLE IF EXISTS workout_sessions;
DROP TABLE IF EXISTS plan_exercises;
DROP TABLE IF EXISTS workout_plans;
DROP TABLE IF EXISTS exercises;
DROP TABLE IF EXISTS users;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE users (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(190) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('user','admin') NOT NULL DEFAULT 'user',
  age TINYINT UNSIGNED NULL,
  gender ENUM('male','female','other','prefer_not_to_say') NULL,
  height_cm DECIMAL(5,2) NULL,
  weight_kg DECIMAL(6,2) NULL,
  fitness_level ENUM('beginner','intermediate','advanced','expert') NOT NULL DEFAULT 'beginner',
  fitness_goal VARCHAR(40) NULL DEFAULT 'general_fitness',
  dietary_preference VARCHAR(40) NULL DEFAULT 'no_preference',
  food_allergies VARCHAR(500) NULL,
  available_days TEXT NULL,
  subscription_plan ENUM('monthly','quarterly','yearly') NULL DEFAULT NULL,
  subscription_status ENUM('normal','pending','active','expired') NOT NULL DEFAULT 'normal',
  subscription_expires_at DATE NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE exercises (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  category VARCHAR(50) NOT NULL,
  muscle_group VARCHAR(100) NULL,
  instructions TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE workout_plans (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(150) NOT NULL,
  description TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_workout_plans_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE plan_exercises (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  plan_id BIGINT UNSIGNED NOT NULL,
  exercise_id BIGINT UNSIGNED NOT NULL,
  planned_sets INT UNSIGNED NULL,
  planned_reps INT UNSIGNED NULL,
  sort_order INT UNSIGNED NOT NULL DEFAULT 0,
  CONSTRAINT fk_plan_exercises_plan FOREIGN KEY (plan_id) REFERENCES workout_plans(id) ON DELETE CASCADE,
  CONSTRAINT fk_plan_exercises_exercise FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE workout_sessions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  plan_id BIGINT UNSIGNED NULL,
  session_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  duration_minutes INT UNSIGNED NULL,
  notes TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_sessions_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_sessions_plan FOREIGN KEY (plan_id) REFERENCES workout_plans(id) ON DELETE SET NULL,
  INDEX idx_sessions_user_date (user_id, session_date)
) ENGINE=InnoDB;

CREATE TABLE workout_sets (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  session_id BIGINT UNSIGNED NOT NULL,
  exercise_id BIGINT UNSIGNED NOT NULL,
  set_number INT UNSIGNED NOT NULL,
  repetitions INT UNSIGNED NULL,
  weight_kg DECIMAL(7,2) NULL,
  duration_seconds INT UNSIGNED NULL,
  distance_km DECIMAL(8,3) NULL,
  CONSTRAINT fk_sets_session FOREIGN KEY (session_id) REFERENCES workout_sessions(id) ON DELETE CASCADE,
  CONSTRAINT fk_sets_exercise FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE fitness_goals (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(150) NOT NULL,
  goal_type ENUM('target_weight','workout_frequency','workout_minutes','other') NOT NULL DEFAULT 'other',
  starting_value DECIMAL(10,2) NULL,
  target_value DECIMAL(10,2) NOT NULL,
  unit VARCHAR(30) NULL,
  start_date DATE NOT NULL,
  deadline DATE NULL,
  status ENUM('active','completed','cancelled') NOT NULL DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_goals_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE body_measurements (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  recorded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  weight_kg DECIMAL(6,2) NULL,
  body_fat_percent DECIMAL(5,2) NULL,
  waist_cm DECIMAL(6,2) NULL,
  notes TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_measurements_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_measurements_user_date (user_id, recorded_at)
) ENGINE=InnoDB;

CREATE TABLE water_logs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  log_date DATE NOT NULL,
  amount_ml INT UNSIGNED NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_water_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_water_user_date (user_id, log_date)
) ENGINE=InnoDB;

CREATE TABLE food_logs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  meal_name VARCHAR(150) NOT NULL,
  meal_type ENUM('breakfast','lunch','dinner','snack') NOT NULL DEFAULT 'snack',
  calories DECIMAL(8,2) NULL,
  protein_g DECIMAL(7,2) NULL,
  carbohydrates_g DECIMAL(7,2) NULL,
  fat_g DECIMAL(7,2) NULL,
  logged_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_food_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_food_user_date (user_id, logged_at)
) ENGINE=InnoDB;

CREATE TABLE diet_plans (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(160) NOT NULL,
  description TEXT NULL,
  fitness_level ENUM('beginner','intermediate','advanced','expert') NOT NULL,
  access_type ENUM('free','premium') NOT NULL DEFAULT 'free',
  dietary_preference VARCHAR(40) NULL,
  guidance TEXT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_by BIGINT UNSIGNED NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_diet_admin FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE workout_templates (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(160) NOT NULL,
  description TEXT NULL,
  fitness_level ENUM('beginner','intermediate','advanced','expert') NOT NULL,
  access_type ENUM('free','premium') NOT NULL DEFAULT 'free',
  schedule_text TEXT NULL,
  guidance TEXT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_by BIGINT UNSIGNED NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_template_admin FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE user_plan_assignments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  diet_plan_id BIGINT UNSIGNED NULL,
  workout_template_id BIGINT UNSIGNED NULL,
  assigned_by BIGINT UNSIGNED NULL,
  notes TEXT NULL,
  starts_on DATE NULL,
  ends_on DATE NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_assignment_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_assignment_diet FOREIGN KEY (diet_plan_id) REFERENCES diet_plans(id) ON DELETE SET NULL,
  CONSTRAINT fk_assignment_template FOREIGN KEY (workout_template_id) REFERENCES workout_templates(id) ON DELETE SET NULL,
  CONSTRAINT fk_assignment_admin FOREIGN KEY (assigned_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE admin_suggestions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  admin_id BIGINT UNSIGNED NULL,
  title VARCHAR(160) NOT NULL,
  suggestion TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  is_read TINYINT(1) NOT NULL DEFAULT 0,
  CONSTRAINT fk_suggestion_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_suggestion_admin FOREIGN KEY (admin_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE subscription_requests (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  plan ENUM('monthly','quarterly','yearly') NOT NULL,
  amount DECIMAL(10,2) NULL,
  payment_reference VARCHAR(120) NULL,
  proof_file VARCHAR(255) NULL,
  status ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  admin_reason TEXT NULL,
  requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  reviewed_at DATETIME NULL,
  reviewed_by BIGINT UNSIGNED NULL,
  starts_on DATE NULL,
  expires_on DATE NULL,
  CONSTRAINT fk_subscription_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_subscription_reviewer FOREIGN KEY (reviewed_by) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_subscription_status (status, requested_at)
) ENGINE=InnoDB;

CREATE TABLE notifications (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(160) NOT NULL,
  message TEXT NOT NULL,
  is_read TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_notification_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_notifications_user (user_id, is_read, created_at)
) ENGINE=InnoDB;

CREATE TABLE coaches (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  email VARCHAR(190) NULL,
  specialization VARCHAR(180) NOT NULL,
  bio TEXT NULL,
  experience_years TINYINT UNSIGNED NULL,
  fee DECIMAL(10,2) NULL,
  photo VARCHAR(255) NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE coach_availability (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  coach_id BIGINT UNSIGNED NOT NULL,
  weekday TINYINT UNSIGNED NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  CONSTRAINT fk_availability_coach FOREIGN KEY (coach_id) REFERENCES coaches(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE coach_bookings (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  coach_id BIGINT UNSIGNED NOT NULL,
  session_start DATETIME NOT NULL,
  duration_minutes SMALLINT UNSIGNED NOT NULL DEFAULT 60,
  status ENUM('pending','approved','rejected','completed','cancelled') NOT NULL DEFAULT 'pending',
  user_message TEXT NULL,
  admin_message TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  reviewed_at DATETIME NULL,
  reviewed_by BIGINT UNSIGNED NULL,
  CONSTRAINT fk_booking_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_booking_coach FOREIGN KEY (coach_id) REFERENCES coaches(id) ON DELETE RESTRICT,
  CONSTRAINT fk_booking_reviewer FOREIGN KEY (reviewed_by) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_coach_slot (coach_id, session_start, status)
) ENGINE=InnoDB;

CREATE TABLE email_logs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NULL,
  recipient VARCHAR(190) NOT NULL,
  subject VARCHAR(255) NOT NULL,
  status ENUM('sent','failed','not_configured') NOT NULL,
  error_message TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_email_log_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE admin_notifications (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(160) NOT NULL,
  message TEXT NOT NULL,
  related_type VARCHAR(40) NULL,
  related_id BIGINT UNSIGNED NULL,
  is_read TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO exercises (name, category, muscle_group, instructions) VALUES
('Push-up', 'Strength', 'Chest', 'Keep the body straight and lower with control.'),
('Bodyweight squat', 'Strength', 'Legs', 'Keep the feet stable and lower to a comfortable depth.'),
('Plank', 'Strength', 'Core', 'Keep the body aligned and brace the core.'),
('Walking', 'Cardio', 'Full body', 'Walk at a comfortable, steady pace.'),
('Running', 'Cardio', 'Full body', 'Choose a pace appropriate to your fitness level.'),
('Cycling', 'Cardio', 'Legs', 'Maintain a comfortable cadence and safe posture.'),
('Hamstring stretch', 'Flexibility', 'Hamstrings', 'Stretch gently without bouncing.');

-- New users start with subscription_status='normal' (Free/Normal plan).
-- Premium access is granted only after an administrator approves a subscription request.
