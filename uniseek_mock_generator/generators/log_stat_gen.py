# ==============================================================================
# UniSeek 兼职招聘平台 - 操作日志与运营日报生成器
# ==============================================================================
# 生成 25,000 条操作日志（operation_log）和 365 条运营日报统计（daily_statistics）。
#
# operation_log 覆盖用户全生命周期操作类型，时间跨度为 2010-01-01 至 2026-07-15。
# daily_statistics 覆盖 2025-07-16 至 2026-07-15 共 365 天，数据呈增长趋势。
#
# 依赖：
#   - config: START_DATE, END_DATE, OPERATION_LOG_COUNT, DAILY_STATISTICS_COUNT
#   - datapool: OPERATION_TYPES
#   - sql_output: SQLWriter 批量写入器
# ==============================================================================

import datetime
import json
import random
from typing import Dict, List

from config import END_DATE, START_DATE
from sql_output import SQLWriter

# =============================================================================
# 常量定义
# =============================================================================

# 操作日志表列名（与 schema 中的 operation_log 表一致）
OPERATION_LOG_COLUMNS = [
    "id", "operator_id", "operation_type", "target_type",
    "target_id", "detail", "ip_address", "create_time",
]

# 运营日报表列名（与 schema 中的 daily_statistics 表一致）
DAILY_STATISTICS_COLUMNS = [
    "id", "stat_date", "new_user_count", "new_enterprise_count",
    "new_task_count", "new_resume_count", "new_delivery_count",
    "new_interview_count", "new_entry_count", "create_time",
]

# 时间范围
START_DT = datetime.datetime.strptime(START_DATE, "%Y-%m-%d")
END_DT = datetime.datetime.strptime(END_DATE, "%Y-%m-%d")
SPAN_SECONDS = int((END_DT - START_DT).total_seconds())

# 目标记录数
TARGET_LOG_COUNT = 25000
TARGET_DAILY_COUNT = 365

# =============================================================================
# 辅助函数
# =============================================================================


def _random_ip() -> str:
    """生成随机 IPv4 地址。"""
    return f"{random.randint(1, 255)}.{random.randint(0, 255)}.{random.randint(0, 255)}.{random.randint(1, 254)}"


def _format_dt(dt: datetime.datetime) -> str:
    """将 datetime 格式化为 MySQL 兼容的日期时间字符串。"""
    return dt.strftime("%Y-%m-%d %H:%M:%S")


def _random_datetime() -> datetime.datetime:
    """在 [START_DT, END_DT] 范围内均匀随机生成一个时间点。"""
    return START_DT + datetime.timedelta(seconds=random.randint(0, SPAN_SECONDS))


def _random_datetime_between(
    start: datetime.datetime,
    end: datetime.datetime,
) -> datetime.datetime:
    """在 [start, end] 闭区间内均匀随机生成一个时间点。"""
    diff = int((end - start).total_seconds())
    if diff <= 0:
        return start
    return start + datetime.timedelta(seconds=random.randint(0, diff))


def _generate_detail(op_type: str, target_id: int) -> str:
    """根据操作类型生成 detail 字段的 JSON 字符串。

    Args:
        op_type: 操作类型（如 REGISTER, APPLY, HIRE 等）
        target_id: 操作目标 ID（部分类型会嵌入到 detail 中）

    Returns:
        符合业务逻辑的 JSON 字符串（ensure_ascii=False）
    """
    if op_type == "REGISTER":
        return json.dumps({"registerType": "phone"}, ensure_ascii=False)
    elif op_type == "APPLY":
        return json.dumps({"taskId": target_id}, ensure_ascii=False)
    elif op_type == "HIRE":
        return json.dumps({"fromStatus": 1, "toStatus": 3}, ensure_ascii=False)
    elif op_type == "REJECT":
        return json.dumps({"fromStatus": 1, "toStatus": 4}, ensure_ascii=False)
    elif op_type in ("AUDIT_TASK", "AUDIT_ENTERPRISE"):
        return json.dumps({"fromStatus": 0, "toStatus": 1}, ensure_ascii=False)
    elif op_type == "COMPLETE":
        return json.dumps({"fromStatus": 3, "toStatus": 5}, ensure_ascii=False)
    else:
        return json.dumps({}, ensure_ascii=False)


def _pick_random_items(
    source_list: list,
    count: int,
    allow_duplicates: bool = False,
) -> list:
    """从列表中随机选取指定数量的元素。

    Args:
        source_list: 源列表
        count: 需要选取的数量
        allow_duplicates: 是否允许重复选取（默认为 False）

    Returns:
        选取的元素列表
    """
    if not source_list:
        return []

    if allow_duplicates:
        return [random.choice(source_list) for _ in range(count)]

    k = min(count, len(source_list))
    return random.sample(source_list, k)


# =============================================================================
# 操作日志生成器
# =============================================================================


def generate_operation_logs(
    writer: SQLWriter,
    all_user_ids: List[int],
    seeker_ids: List[int],
    hr_ids: List[int],
    admin_ids: List[int],
    application_info_list: List[Dict],
) -> List[int]:
    """生成操作日志数据并写入 SQL 文件。

    生成 25,000 条操作日志记录，覆盖用户生命周期中的各类操作。
    各操作类型的分布比例符合实际业务场景：
    - LOGIN（30%）：随机用户，随机时间
    - REGISTER（15%）：映射到用户注册行为
    - APPLY（10%）：来源于投递记录
    - HIRE（8%）：来源于已录用/已完成的投递（status=3 或 5）
    - REJECT（8%）：来源于已淘汰的投递（status=4）
    - SAVE_RESUME（8%）：随机求职者
    - TASK_PUBLISH（5%）：随机 HR 用户
    - AUDIT_TASK（5%）：管理员用户
    - REAL_NAME_AUTH（5%）：随机用户
    - AUDIT_ENTERPRISE（3%）：管理员用户
    - COMPLAINT（3%）：随机用户

    所有 detail 字段为有效的 JSON 字符串。
    IP 地址为随机生成的 IPv4 地址。

    Args:
        writer: SQLWriter 实例，用于写入 SQL 文件
        all_user_ids: 所有用户的 ID 列表（共 8,000 个）
        seeker_ids: 求职者角色的用户 ID 列表（共 7,500 个）
        hr_ids: HR 角色的用户 ID 列表（共 400 个）
        admin_ids: 管理员角色的用户 ID 列表（共 100 个）
        application_info_list: 投递信息列表（共 80,000 个），
            每个字典包含 app_id, task_id, applicant_id, status, hr_id, create_time

    Returns:
        operation_log_ids: 生成的操作日志 ID 列表（长度 25,000）
    """
    # ---- 预处理：按操作类型分组统计数据 ----
    target_total = TARGET_LOG_COUNT

    # 按百分比计算各类型记录数
    count_login = int(target_total * 0.30)
    count_register = int(target_total * 0.15)
    count_apply = int(target_total * 0.10)
    count_hire = int(target_total * 0.08)
    count_reject = int(target_total * 0.08)
    count_save_resume = int(target_total * 0.08)
    count_task_publish = int(target_total * 0.05)
    count_audit_task = int(target_total * 0.05)
    count_real_name_auth = int(target_total * 0.05)
    count_audit_enterprise = int(target_total * 0.03)
    count_complaint = int(target_total * 0.03)

    # 因取整可能不足，补到 target_total
    allocated = (
        count_login + count_register + count_apply + count_hire + count_reject
        + count_save_resume + count_task_publish + count_audit_task
        + count_real_name_auth + count_audit_enterprise + count_complaint
    )
    diff = target_total - allocated
    if diff > 0:
        # 将差值补到 LOGIN（占比最大）
        count_login += diff

    # ---- 从 application_info_list 中筛选 HIRE/REJECT 的候选记录 ----
    hire_apps = [a for a in application_info_list if a.get("status") in (3, 5)]
    reject_apps = [a for a in application_info_list if a.get("status") == 4]
    apply_apps = application_info_list  # APPLY 可用全部投递记录

    # 确保不会因候选不足而出错
    # 若候选不足，允许重复使用（带放回抽样）
    hire_allow_dup = len(hire_apps) < count_hire
    reject_allow_dup = len(reject_apps) < count_reject
    apply_allow_dup = len(apply_apps) < count_apply

    # ---- 开始写入 ----
    operation_log_ids: List[int] = []

    writer.write_comment(f"操作日志表（{target_total} 条记录）")
    writer.begin_insert("operation_log", OPERATION_LOG_COLUMNS)

    # --- 1. LOGIN 事件（30%）---
    for _ in range(count_login):
        operator_id = random.choice(all_user_ids)
        log_id = writer.next_id("operation_log")
        operation_log_ids.append(log_id)

        writer.add_row([
            log_id,
            operator_id,
            "LOGIN",                                    # operation_type
            "USER",                                      # target_type
            operator_id,                                 # target_id（登录的用户自身）
            json.dumps({}, ensure_ascii=False),          # detail
            _random_ip(),                                # ip_address
            _format_dt(_random_datetime()),               # create_time
        ])

    # --- 2. REGISTER 事件（15%）---
    register_users = _pick_random_items(all_user_ids, count_register, allow_duplicates=False)
    for operator_id in register_users:
        log_id = writer.next_id("operation_log")
        operation_log_ids.append(log_id)

        writer.add_row([
            log_id,
            operator_id,
            "REGISTER",                                  # operation_type
            "USER",                                      # target_type
            operator_id,                                 # target_id
            _generate_detail("REGISTER", operator_id),   # detail: {"registerType": "phone"}
            _random_ip(),                                # ip_address
            _format_dt(_random_datetime()),               # create_time
        ])

    # --- 3. APPLY 事件（10%）---
    apply_samples = _pick_random_items(apply_apps, count_apply, allow_duplicates=apply_allow_dup)
    for app in apply_samples:
        operator_id = app["applicant_id"]
        app_id = app["app_id"]
        task_id = app["task_id"]
        log_id = writer.next_id("operation_log")
        operation_log_ids.append(log_id)

        # 使用投递记录的 create_time 附近的时间
        app_create_time = app.get("create_time")
        if app_create_time:
            try:
                app_dt = datetime.datetime.strptime(
                    app_create_time, "%Y-%m-%d %H:%M:%S"
                )
                log_time = _random_datetime_between(
                    app_dt - datetime.timedelta(hours=1),
                    app_dt + datetime.timedelta(hours=1),
                )
            except (ValueError, TypeError):
                log_time = _random_datetime()
        else:
            log_time = _random_datetime()

        writer.add_row([
            log_id,
            operator_id,
            "APPLY",                                     # operation_type
            "APPLICATION",                               # target_type
            app_id,                                      # target_id
            _generate_detail("APPLY", task_id),          # detail: {"taskId": task_id}
            _random_ip(),                                # ip_address
            _format_dt(log_time),                         # create_time
        ])

    # --- 4. HIRE 事件（8%）---
    hire_samples = _pick_random_items(hire_apps, count_hire, allow_duplicates=hire_allow_dup)
    for app in hire_samples:
        operator_id = app.get("hr_id") or random.choice(hr_ids)
        app_id = app["app_id"]
        log_id = writer.next_id("operation_log")
        operation_log_ids.append(log_id)

        # HIRE 时间应在投递 create_time 之后
        app_create_time = app.get("create_time")
        if app_create_time:
            try:
                app_dt = datetime.datetime.strptime(
                    app_create_time, "%Y-%m-%d %H:%M:%S"
                )
                log_time = _random_datetime_between(app_dt, END_DT)
            except (ValueError, TypeError):
                log_time = _random_datetime()
        else:
            log_time = _random_datetime()

        writer.add_row([
            log_id,
            operator_id,
            "HIRE",                                      # operation_type
            "APPLICATION",                               # target_type
            app_id,                                      # target_id
            _generate_detail("HIRE", app_id),            # detail: {"fromStatus": 1, "toStatus": 3}
            _random_ip(),                                # ip_address
            _format_dt(log_time),                         # create_time
        ])

    # --- 5. REJECT 事件（8%）---
    reject_samples = _pick_random_items(reject_apps, count_reject, allow_duplicates=reject_allow_dup)
    for app in reject_samples:
        operator_id = app.get("hr_id") or random.choice(hr_ids)
        app_id = app["app_id"]
        log_id = writer.next_id("operation_log")
        operation_log_ids.append(log_id)

        # REJECT 时间应在投递 create_time 之后
        app_create_time = app.get("create_time")
        if app_create_time:
            try:
                app_dt = datetime.datetime.strptime(
                    app_create_time, "%Y-%m-%d %H:%M:%S"
                )
                log_time = _random_datetime_between(app_dt, END_DT)
            except (ValueError, TypeError):
                log_time = _random_datetime()
        else:
            log_time = _random_datetime()

        writer.add_row([
            log_id,
            operator_id,
            "REJECT",                                    # operation_type
            "APPLICATION",                               # target_type
            app_id,                                      # target_id
            _generate_detail("REJECT", app_id),          # detail: {"fromStatus": 1, "toStatus": 4}
            _random_ip(),                                # ip_address
            _format_dt(log_time),                         # create_time
        ])

    # --- 6. SAVE_RESUME 事件（8%）---
    save_resume_users = _pick_random_items(seeker_ids, count_save_resume, allow_duplicates=True)
    for operator_id in save_resume_users:
        log_id = writer.next_id("operation_log")
        operation_log_ids.append(log_id)

        writer.add_row([
            log_id,
            operator_id,
            "SAVE_RESUME",                               # operation_type
            "RESUME",                                    # target_type
            operator_id,                                 # target_id（简历 ID 与用户 ID 关联）
            json.dumps({}, ensure_ascii=False),          # detail
            _random_ip(),                                # ip_address
            _format_dt(_random_datetime()),               # create_time
        ])

    # --- 7. TASK_PUBLISH 事件（5%）---
    task_publish_hrs = _pick_random_items(hr_ids, count_task_publish, allow_duplicates=True)
    for operator_id in task_publish_hrs:
        log_id = writer.next_id("operation_log")
        operation_log_ids.append(log_id)

        writer.add_row([
            log_id,
            operator_id,
            "TASK_PUBLISH",                              # operation_type
            "TASK",                                      # target_type
            random.randint(1, 5000),                     # target_id（随机任务 ID）
            json.dumps({}, ensure_ascii=False),          # detail
            _random_ip(),                                # ip_address
            _format_dt(_random_datetime()),               # create_time
        ])

    # --- 8. AUDIT_TASK 事件（5%）---
    audit_task_admins = _pick_random_items(admin_ids, count_audit_task, allow_duplicates=True)
    for operator_id in audit_task_admins:
        log_id = writer.next_id("operation_log")
        operation_log_ids.append(log_id)

        writer.add_row([
            log_id,
            operator_id,
            "AUDIT_TASK",                                # operation_type
            "TASK",                                      # target_type
            random.randint(1, 5000),                     # target_id（随机任务 ID）
            _generate_detail("AUDIT_TASK", 0),           # detail: {"fromStatus": 0, "toStatus": 1}
            _random_ip(),                                # ip_address
            _format_dt(_random_datetime()),               # create_time
        ])

    # --- 9. REAL_NAME_AUTH 事件（5%）---
    auth_users = _pick_random_items(all_user_ids, count_real_name_auth, allow_duplicates=False)
    for operator_id in auth_users:
        log_id = writer.next_id("operation_log")
        operation_log_ids.append(log_id)

        writer.add_row([
            log_id,
            operator_id,
            "REAL_NAME_AUTH",                            # operation_type
            "USER",                                      # target_type
            operator_id,                                 # target_id
            json.dumps({"authType": "id_card"}, ensure_ascii=False),  # detail
            _random_ip(),                                # ip_address
            _format_dt(_random_datetime()),               # create_time
        ])

    # --- 10. AUDIT_ENTERPRISE 事件（3%）---
    audit_enterprise_admins = _pick_random_items(admin_ids, count_audit_enterprise, allow_duplicates=True)
    for operator_id in audit_enterprise_admins:
        log_id = writer.next_id("operation_log")
        operation_log_ids.append(log_id)

        writer.add_row([
            log_id,
            operator_id,
            "AUDIT_ENTERPRISE",                          # operation_type
            "ENTERPRISE",                                # target_type
            random.randint(1, 400),                      # target_id（随机企业 ID）
            _generate_detail("AUDIT_ENTERPRISE", 0),     # detail: {"fromStatus": 0, "toStatus": 1}
            _random_ip(),                                # ip_address
            _format_dt(_random_datetime()),               # create_time
        ])

    # --- 11. COMPLAINT 事件（3%）---
    complaint_users = _pick_random_items(all_user_ids, count_complaint, allow_duplicates=True)
    for operator_id in complaint_users:
        log_id = writer.next_id("operation_log")
        operation_log_ids.append(log_id)

        writer.add_row([
            log_id,
            operator_id,
            "COMPLAINT",                                 # operation_type
            "COMPLAINT",                                 # target_type
            random.randint(1, 300),                      # target_id（随机投诉 ID）
            json.dumps({}, ensure_ascii=False),          # detail
            _random_ip(),                                # ip_address
            _format_dt(_random_datetime()),               # create_time
        ])

    # ---- 最终断言验证 ----
    generated = len(operation_log_ids)
    assert generated == TARGET_LOG_COUNT, (
        f"操作日志记录数必须为 {TARGET_LOG_COUNT}，实际生成 {generated}"
    )

    return operation_log_ids


# =============================================================================
# 运营日报生成器
# =============================================================================


def generate_daily_statistics(writer: SQLWriter) -> List[int]:
    """生成运营日报统计数据并写入 SQL 文件。

    生成 365 条每日统计数据，日期范围为 2025-07-16 至 2026-07-15。
    各统计指标呈现增长趋势——较晚日期的均值高于较早日期。
    使用高斯分布生成每日计数，并确保所有数值非负。

    指标包括：
    - new_user_count: 新增用户数（基准均值 80）
    - new_enterprise_count: 新增认证企业数（基准均值 4）
    - new_task_count: 新增职位数（基准均值 25）
    - new_resume_count: 新增简历数（基准均值 40）
    - new_delivery_count: 新增投递数（基准均值 150）
    - new_interview_count: 新增面试数（基准均值 25）
    - new_entry_count: 新增入职数（基准均值 12）

    Args:
        writer: SQLWriter 实例，用于写入 SQL 文件

    Returns:
        statistics_ids: 生成的统计记录 ID 列表（长度 365）
    """
    start_date = datetime.date(2025, 7, 16)
    total_days = TARGET_DAILY_COUNT

    statistics_ids: List[int] = []

    writer.write_comment(f"运营日报统计表（{total_days} 条记录）")
    writer.begin_insert("daily_statistics", DAILY_STATISTICS_COLUMNS)

    for i in range(total_days):
        stat_date = start_date + datetime.timedelta(days=i)

        # 增长因子：随时间从 0.5 线性增长至 1.5
        progress = i / total_days  # 0.0 ~ 1.0
        growth = 0.5 + progress * 1.0  # 0.5 ~ 1.5

        # 各指标基准值 × 增长因子 + 高斯随机波动
        # 使用 random.gauss(mean, stddev) 生成正态分布随机数
        new_users = int(random.gauss(80, 20) * growth)
        new_enterprises = int(random.gauss(4, 2) * growth)
        new_tasks = int(random.gauss(25, 8) * growth)
        new_resumes = int(random.gauss(40, 12) * growth)
        new_deliveries = int(random.gauss(150, 40) * growth)
        new_interviews = int(random.gauss(25, 8) * growth)
        new_entries = int(random.gauss(12, 5) * growth)

        # 确保所有计数非负
        new_users = max(0, new_users)
        new_enterprises = max(0, new_enterprises)
        new_tasks = max(0, new_tasks)
        new_resumes = max(0, new_resumes)
        new_deliveries = max(0, new_deliveries)
        new_interviews = max(0, new_interviews)
        new_entries = max(0, new_entries)

        stat_id = writer.next_id("daily_statistics")
        statistics_ids.append(stat_id)

        # create_time 设为统计日期的当日午夜
        create_time = datetime.datetime.combine(stat_date, datetime.time(0, 0, 0))

        writer.add_row([
            stat_id,
            stat_date.isoformat(),     # stat_date（格式：YYYY-MM-DD）
            new_users,
            new_enterprises,
            new_tasks,
            new_resumes,
            new_deliveries,
            new_interviews,
            new_entries,
            _format_dt(create_time),   # create_time
        ])

    # ---- 最终断言验证 ----
    generated = len(statistics_ids)
    assert generated == TARGET_DAILY_COUNT, (
        f"运营日报记录数必须为 {TARGET_DAILY_COUNT}，实际生成 {generated}"
    )

    return statistics_ids
