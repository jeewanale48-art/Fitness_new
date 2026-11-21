-- FitTrack 2.0 additive migration. BACK UP YOUR DATABASE FIRST.
-- Select the existing FitTrack database in phpMyAdmin before importing.
DELIMITER $$
DROP PROCEDURE IF EXISTS ft_add_column$$
CREATE PROCEDURE ft_add_column(IN tbl VARCHAR(64), IN col VARCHAR(64), IN definition TEXT)
BEGIN
 IF NOT EXISTS (SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=tbl AND COLUMN_NAME=col) THEN
  SET @sql_text=CONCAT('ALTER TABLE `',tbl,'` ADD COLUMN `',col,'` ',definition);
  PREPARE stmt FROM @sql_text; EXECUTE stmt; DEALLOCATE PREPARE stmt;
 END IF;
END$$
DELIMITER ;
CALL ft_add_column('users','fitness_goal','VARCHAR(40) NULL DEFAULT ''general_fitness''');
CALL ft_add_column('users','dietary_preference','VARCHAR(40) NULL DEFAULT ''no_preference''');
CALL ft_add_column('users','food_allergies','VARCHAR(500) NULL');
CALL ft_add_column('users','available_days','TEXT NULL');
-- Include the new Expert label while preserving legacy Advanced values.
ALTER TABLE users MODIFY fitness_level ENUM('beginner','intermediate','advanced','expert') NOT NULL DEFAULT 'beginner';
CALL ft_add_column('users','subscription_plan','ENUM(''monthly'',''quarterly'',''yearly'') NULL DEFAULT NULL');
CALL ft_add_column('users','subscription_status','ENUM(''normal'',''pending'',''active'',''expired'') NOT NULL DEFAULT ''normal''');
CALL ft_add_column('users','subscription_expires_at','DATE NULL');
DROP PROCEDURE ft_add_column;

CREATE TABLE IF NOT EXISTS diet_plans (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, title VARCHAR(160) NOT NULL, description TEXT NULL,
 fitness_level ENUM('beginner','intermediate','expert') NOT NULL, access_type ENUM('free','premium') NOT NULL DEFAULT 'free',
 dietary_preference VARCHAR(40) NULL, guidance TEXT NULL, is_active TINYINT(1) NOT NULL DEFAULT 1,
 created_by BIGINT UNSIGNED NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT fk_diet_admin FOREIGN KEY(created_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS workout_templates (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, title VARCHAR(160) NOT NULL, description TEXT NULL,
 fitness_level ENUM('beginner','intermediate','expert') NOT NULL, access_type ENUM('free','premium') NOT NULL DEFAULT 'free',
 schedule_text TEXT NULL, guidance TEXT NULL, is_active TINYINT(1) NOT NULL DEFAULT 1,
 created_by BIGINT UNSIGNED NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT fk_workout_admin FOREIGN KEY(created_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS user_plan_assignments (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, user_id BIGINT UNSIGNED NOT NULL,
 diet_plan_id BIGINT UNSIGNED NULL, workout_template_id BIGINT UNSIGNED NULL,
 assigned_by BIGINT UNSIGNED NULL, notes TEXT NULL, starts_on DATE NULL, ends_on DATE NULL,
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
 FOREIGN KEY(diet_plan_id) REFERENCES diet_plans(id) ON DELETE SET NULL,
 FOREIGN KEY(workout_template_id) REFERENCES workout_templates(id) ON DELETE SET NULL,
 FOREIGN KEY(assigned_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS admin_suggestions (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, user_id BIGINT UNSIGNED NOT NULL,
 admin_id BIGINT UNSIGNED NULL, title VARCHAR(160) NOT NULL, suggestion TEXT NOT NULL,
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, is_read TINYINT(1) NOT NULL DEFAULT 0,
 FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
 FOREIGN KEY(admin_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS subscription_requests (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, user_id BIGINT UNSIGNED NOT NULL,
 plan ENUM('monthly','quarterly','yearly') NOT NULL, amount DECIMAL(10,2) NULL,
 payment_reference VARCHAR(120) NULL, proof_file VARCHAR(255) NULL,
 status ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
 admin_reason TEXT NULL, requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 reviewed_at DATETIME NULL, reviewed_by BIGINT UNSIGNED NULL,
 starts_on DATE NULL, expires_on DATE NULL,
 FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
 FOREIGN KEY(reviewed_by) REFERENCES users(id) ON DELETE SET NULL,
 INDEX idx_subscription_status(status,requested_at)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS notifications (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, user_id BIGINT UNSIGNED NOT NULL,
 title VARCHAR(160) NOT NULL, message TEXT NOT NULL, is_read TINYINT(1) NOT NULL DEFAULT 0,
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
 INDEX idx_notifications_user(user_id,is_read,created_at)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS coaches (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, name VARCHAR(120) NOT NULL,
 email VARCHAR(190) NULL, specialization VARCHAR(180) NOT NULL, bio TEXT NULL,
 experience_years TINYINT UNSIGNED NULL, fee DECIMAL(10,2) NULL, photo VARCHAR(255) NULL,
 is_active TINYINT(1) NOT NULL DEFAULT 1, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS coach_availability (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, coach_id BIGINT UNSIGNED NOT NULL,
 weekday TINYINT UNSIGNED NOT NULL, start_time TIME NOT NULL, end_time TIME NOT NULL,
 FOREIGN KEY(coach_id) REFERENCES coaches(id) ON DELETE CASCADE
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS coach_bookings (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, user_id BIGINT UNSIGNED NOT NULL,
 coach_id BIGINT UNSIGNED NOT NULL, session_start DATETIME NOT NULL,
 duration_minutes SMALLINT UNSIGNED NOT NULL DEFAULT 60,
 status ENUM('pending','approved','rejected','completed','cancelled') NOT NULL DEFAULT 'pending',
 user_message TEXT NULL, admin_message TEXT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 reviewed_at DATETIME NULL, reviewed_by BIGINT UNSIGNED NULL,
 FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
 FOREIGN KEY(coach_id) REFERENCES coaches(id) ON DELETE RESTRICT,
 FOREIGN KEY(reviewed_by) REFERENCES users(id) ON DELETE SET NULL,
 INDEX idx_coach_slot(coach_id,session_start,status)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS email_logs (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, user_id BIGINT UNSIGNED NULL,
 recipient VARCHAR(190) NOT NULL, subject VARCHAR(255) NOT NULL,
 status ENUM('sent','failed','not_configured') NOT NULL,
 error_message TEXT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS admin_notifications (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, title VARCHAR(160) NOT NULL,
 message TEXT NOT NULL, related_type VARCHAR(40) NULL, related_id BIGINT UNSIGNED NULL,
 is_read TINYINT(1) NOT NULL DEFAULT 0, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;
