-- ========================================
-- 收藏职位表
-- 用户可收藏心仪的职位，方便后续查看
-- ========================================

CREATE TABLE IF NOT EXISTS `favorite` (
  `id`          BIGINT    NOT NULL AUTO_INCREMENT  COMMENT '收藏记录ID',
  `user_id`     BIGINT    NOT NULL                 COMMENT '用户ID',
  `task_id`     BIGINT    NOT NULL                 COMMENT '职位ID',
  `create_time` DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '收藏时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_task` (`user_id`, `task_id`) COMMENT '同一用户对同一职位只能收藏一次',
  KEY `idx_user_id` (`user_id`),
  KEY `idx_task_id` (`task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='收藏职位表';


UPDATE real_name_auth r
JOIN user u ON r.user_id = u.id
SET r.status = 1, r.auth_time = NOW(), r.update_time = NOW()
WHERE u.role = 1;

ALTER TABLE chat_session MODIFY COLUMN task_application_id BIGINT NULL;
