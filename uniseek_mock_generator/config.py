# ==============================================================================
# UniSeek 兼职招聘平台 - Mock 数据生成器配置
# ==============================================================================
# 所有可配置参数均定义为模块级常量

# --- 批量写入大小 ---
# 每 1000 行 flush 一次 INSERT 语句
BATCH_SIZE = 1000

# --- 各表记录数目标 ---
USER_COUNT = 8000
REAL_NAME_AUTH_COUNT = 7000
ENTERPRISE_COUNT = 400
RESUME_COUNT = 7000
TASK_COUNT = 5000
TASK_APPLICATION_COUNT = 80000
NOTIFICATION_COUNT = 60000
CHAT_SESSION_COUNT = 25000
CHAT_MESSAGE_COUNT = 100000
COMPLAINT_COUNT = 300
OPERATION_LOG_COUNT = 25000
DAILY_STATISTICS_COUNT = 365

# --- 用户角色比例 ---
# Seeker（求职者）/ HR（企业招聘方）/ Admin（管理员）/ SuperAdmin（超级管理员）
SEEKER_RATIO = 0.9375       # 7500 / 8000
HR_RATIO = 0.05             # 400 / 8000
ADMIN_RATIO = 0.01225       # 98 / 8000
SUPER_ADMIN_RATIO = 0.00025  # 2 / 8000

# --- 管理员手机号保留区间 ---
ADMIN_PHONE_START = 13900000001
ADMIN_PHONE_END = 13900000299

# --- 默认密码 ---
DEFAULT_PASSWORD = "123456"
ADMIN_PASSWORD = "admin"

# --- 数据时间范围 ---
START_DATE = "2010-01-01"
END_DATE = "2026-07-15"

# --- 主要城市地区 ID（用于任务发布分布） ---
MAJOR_CITY_IDS = [
    110101, 110102, 110105, 110108,  # 北京
    310115, 310101,                  # 上海
    440305, 440306, 440303, 440304,  # 深圳
    320105, 320505,                  # 南京、苏州
    330105, 330106,                  # 杭州
    500101,                          # 重庆
    510108,                          # 成都
    420106,                          # 武汉
    430103,                          # 长沙
    210103,                          # 沈阳
    370202,                          # 青岛
]
