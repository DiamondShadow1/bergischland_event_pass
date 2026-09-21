CREATE TABLE IF NOT EXISTS `bergischland_event_pass` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(255) NOT NULL,
    `coins` INT NOT NULL DEFAULT 0,
    `pass_level` INT NOT NULL DEFAULT 1,
    `experience` INT NOT NULL DEFAULT 0,
    `completed_tasks` JSON NULL,
    `daily_rewards` JSON NULL,
    `claim_status` JSON NULL,
    `achievements` JSON NULL,
    `total_progress` INT NOT NULL DEFAULT 0,
    `event_name` VARCHAR(100) NOT NULL DEFAULT 'Bergischland Event',
    `current_event` VARCHAR(100) NOT NULL DEFAULT 'bergischland_monthly',
    `daily_day` INT NOT NULL DEFAULT 1,
    `daily_claimed` TINYINT(1) NOT NULL DEFAULT 0,
    `daily_claimed_at` BIGINT NOT NULL DEFAULT 0,
    `job_name` VARCHAR(100) NULL,
    `job_seconds` INT NOT NULL DEFAULT 0,
    `job_last_check` BIGINT NOT NULL DEFAULT 0,
    `last_seen` BIGINT NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_identifier` (`identifier`),
    KEY `idx_current_event` (`current_event`),
    KEY `idx_last_seen` (`last_seen`),
    KEY `idx_daily_day` (`daily_day`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `bergischland_event_pass` (
    `identifier`, `coins`, `pass_level`, `experience`, `completed_tasks`, `daily_rewards`, `claim_status`, `achievements`,
    `total_progress`, `event_name`, `current_event`, `daily_day`, `daily_claimed`, `daily_claimed_at`, `last_seen`
)
VALUES (
    'template', 0, 1, 0, '[]', '[]', '{}', '[]', 0, 'Bergischland Event', 'bergischland_monthly', 1, 0, 0, UNIX_TIMESTAMP()
)
ON DUPLICATE KEY UPDATE `identifier` = `identifier`;
