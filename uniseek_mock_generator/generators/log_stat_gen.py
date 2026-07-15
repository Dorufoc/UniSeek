# ==============================================================================
# UniSeek 兼职招聘平台 - 操作日志与运营日报生成器
# ==============================================================================
# 生成 25,000 条操作日志（operation_log）和 365 条运营日报统计（daily_statistics）。
#
# operation_log 使用真实的 15 种后端 OperationType 常量，覆盖用户全生命周期，
# 时间跨度为 2010-01-01 至 2026-07-15。detail 字段模拟 AOP 拦截方法参数序列化，
# IP 地址混合内网与公网范围，create_time 与关联业务实体时间对齐。
#
# daily_statistics 覆盖 2025-07-16 至 2026-07-15 共 365 天，数据呈增长趋势。
#
# 依赖：
#   - config: START_DATE, END_DATE, OPERATION_LOG_COUNT, DAILY_STATISTICS_COUNT
#   - datapool: JOB_TITLES_BY_CATEGORY
#   - sql_output: SQLWriter 批量写入器
# ==============================================================================

import datetime
import json
import random
from typing import Dict, List

from config import END_DATE, START_DATE
from sql_output import SQLWriter
from time_utils import weighted_random_time

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

# ---- 操作类型分布（共 15 种，对应后端 OperationType.java 常量） ----
# 格式：(operation_type, target_type, count, 描述)
# 总数 = 25000，LOGIN 占比最高（24%），符合登录高频的业务特征
OPERATION_DISTRIBUTION = [
    ("USER_LOGIN",          "USER",        6500,  "26% - 高频登录（含取整补足）"),
    ("USER_REGISTER",       "USER",        3000,  "12% - 注册"),
    ("APPLICATION_DELIVER",  "APPLICATION", 3000,  "12% - 投递"),
    ("APPLICATION_INTERVIEW","APPLICATION", 2000,  "8% - 邀请面试"),
    ("APPLICATION_HIRE",     "APPLICATION", 1500,  "6% - 录用"),
    ("APPLICATION_REJECT",   "APPLICATION", 2000,  "8% - 淘汰"),
    ("APPLICATION_COMPLETE", "APPLICATION", 1000,  "4% - 完成兼职"),
    ("APPLICATION_PENDING",  "APPLICATION",  800,  "3.2% - 待入职"),
    ("TASK_PUBLISH",        "TASK",        1500,  "6% - 发布岗位"),
    ("TASK_AUDIT",          "TASK",        1200,  "4.8% - 审核岗位"),
    ("TASK_OFFLINE",        "TASK",         500,  "2% - 下架岗位"),
    ("ENTERPRISE_SUBMIT",   "ENTERPRISE",   400,  "1.6% - 提交企业认证"),
    ("ENTERPRISE_AUDIT",    "ENTERPRISE",   300,  "1.2% - 审核企业"),
    ("REAL_NAME_AUTH",      "USER",        1000,  "4% - 实名认证"),
    ("COMPLAINT_HANDLE",    "COMPLAINT",    300,  "1.2% - 处理投诉"),
]

# IP 地址生成常量
# 内网 IP 前缀（模拟内部办公/API 调用来源）
PRIVATE_PREFIXES = ["10.", "172.", "192.168."]
# 公网 IP 前缀（模拟外部用户来源）
PUBLIC_PREFIXES = [
    "58.", "61.", "101.", "103.", "106.", "113.", "114.", "116.",
    "120.", "121.", "123.", "124.", "125.", "180.", "182.", "183.",
    "202.", "210.", "211.", "218.", "219.", "220.", "221.", "222.", "223.",
]


# =============================================================================
# 辅助函数
# =============================================================================


def _random_ip() -> str:
    """生成符合真实后端来源的 IPv4 地址。

    70% 为内网 IP（模拟内部 API / 办公室网络调用），
    30% 为公网 IP（模拟外部用户通过互联网访问）。
    """
    if random.random() < 0.7:
        # 内网 IP
        selector = random.random()
        if selector < 0.50:
            # 10.x.x.x （大型内网）
            return f"10.{random.randint(0, 255)}.{random.randint(0, 255)}.{random.randint(1, 254)}"
        elif selector < 0.85:
            # 192.168.x.x （小型局域网）
            return f"192.168.{random.randint(0, 255)}.{random.randint(1, 254)}"
        else:
            # 172.16.x.x - 172.31.x.x （中型内网）
            return f"172.{random.randint(16, 31)}.{random.randint(0, 255)}.{random.randint(1, 254)}"
    else:
        # 公网 IP
        prefix = random.choice(PUBLIC_PREFIXES)
        return f"{prefix}{random.randint(0, 255)}.{random.randint(0, 255)}.{random.randint(1, 254)}"


def _format_dt(dt: datetime.datetime) -> str:
    """将 datetime 格式化为 MySQL 兼容的日期时间字符串。"""
    return dt.strftime("%Y-%m-%d %H:%M:%S")


def _random_datetime() -> datetime.datetime:
    """在 [START_DT, END_DT] 范围内生成加权随机时间点。

    使用 weighted_random_time() 确保数据分布合理，近期更密集。
    """
    return weighted_random_time()


def _random_datetime_between(
    start: datetime.datetime,
    end: datetime.datetime,
) -> datetime.datetime:
    """在 [start, end] 闭区间内均匀随机生成一个时间点。"""
    diff = int((end - start).total_seconds())
    if diff <= 0:
        return start
    return start + datetime.timedelta(seconds=random.randint(0, diff))


def _generate_detail(op_type: str, target_id: int, related_info: dict = None) -> str:
    """根据操作类型生成 detail 字段的 JSON 字符串（模拟 AOP 拦截方法参数序列化）。

    后端使用 @OperationLog 注解 + AOP 切面在方法执行后拦截，
    通过 ObjectMapper.writeValueAsString(detailMap) 将所有方法参数
    序列化为 JSON 字符串。

    Args:
        op_type: 操作类型（15 种 OperationType 常量之一）
        target_id: 操作目标实体 ID
        related_info: 额外的业务上下文信息（如任务标题、公司名称、面试时间等）

    Returns:
        符合 AOP 序列化行为的 JSON 字符串（ensure_ascii=False）
    """
    if related_info is None:
        related_info = {}

    if op_type == "USER_REGISTER":
        # 注册接口参数：phone, role
        return json.dumps({
            "phone": related_info.get("phone", ""),
            "role": related_info.get("role", 0),
        }, ensure_ascii=False)

    elif op_type == "USER_LOGIN":
        # 登录接口无额外参数（token 在 request 中）
        return json.dumps({}, ensure_ascii=False)

    elif op_type == "ENTERPRISE_SUBMIT":
        # 企业提交接口参数：companyName
        return json.dumps({
            "companyName": related_info.get("company_name", ""),
        }, ensure_ascii=False)

    elif op_type == "ENTERPRISE_AUDIT":
        # 企业审核接口参数：id, auditStatus, fromStatus, toStatus
        return json.dumps({
            "id": target_id,
            "auditStatus": related_info.get("audit_status", 1),
            "fromStatus": related_info.get("from_status", 0),
            "toStatus": related_info.get("to_status", 1),
        }, ensure_ascii=False)

    elif op_type == "TASK_PUBLISH":
        # 岗位发布接口参数：title, enterpriseId
        return json.dumps({
            "title": related_info.get("title", ""),
            "enterpriseId": related_info.get("enterprise_id", 0),
        }, ensure_ascii=False)

    elif op_type == "TASK_AUDIT":
        # 岗位审核接口参数：id, status, fromStatus, toStatus
        return json.dumps({
            "id": target_id,
            "status": related_info.get("status", 1),
            "fromStatus": related_info.get("from_status", 0),
            "toStatus": related_info.get("to_status", 1),
        }, ensure_ascii=False)

    elif op_type == "TASK_OFFLINE":
        # 岗位下架接口参数：id, fromStatus, toStatus
        return json.dumps({
            "id": target_id,
            "fromStatus": related_info.get("from_status", 1),
            "toStatus": related_info.get("to_status", 4),
        }, ensure_ascii=False)

    elif op_type == "APPLICATION_DELIVER":
        # 投递接口参数：taskId, applicantId
        return json.dumps({
            "taskId": related_info.get("task_id", 0),
            "applicantId": related_info.get("applicant_id", 0),
        }, ensure_ascii=False)

    elif op_type == "APPLICATION_INTERVIEW":
        # 安排面试接口参数：id, interviewTime, fromStatus, toStatus
        return json.dumps({
            "id": target_id,
            "interviewTime": related_info.get("interview_time", ""),
            "fromStatus": related_info.get("from_status", 0),
            "toStatus": related_info.get("to_status", 1),
        }, ensure_ascii=False)

    elif op_type == "APPLICATION_PENDING":
        # 待入职操作参数：id, fromStatus, toStatus
        return json.dumps({
            "id": target_id,
            "fromStatus": related_info.get("from_status", 1),
            "toStatus": related_info.get("to_status", 2),
        }, ensure_ascii=False)

    elif op_type == "APPLICATION_HIRE":
        # 录用操作参数：id, fromStatus, toStatus
        return json.dumps({
            "id": target_id,
            "fromStatus": related_info.get("from_status", 2),
            "toStatus": related_info.get("to_status", 3),
        }, ensure_ascii=False)

    elif op_type == "APPLICATION_REJECT":
        # 淘汰操作参数：id, reason, fromStatus, toStatus
        return json.dumps({
            "id": target_id,
            "reason": related_info.get("reason", ""),
            "fromStatus": related_info.get("from_status", 1),
            "toStatus": related_info.get("to_status", 4),
        }, ensure_ascii=False)

    elif op_type == "APPLICATION_COMPLETE":
        # 完成兼职操作参数：id, fromStatus, toStatus
        return json.dumps({
            "id": target_id,
            "fromStatus": related_info.get("from_status", 3),
            "toStatus": related_info.get("to_status", 5),
        }, ensure_ascii=False)

    elif op_type == "REAL_NAME_AUTH":
        # 实名认证接口参数：userId, authType, status
        return json.dumps({
            "userId": target_id,
            "authType": related_info.get("auth_type", "id_card"),
            "status": related_info.get("status", 1),
        }, ensure_ascii=False)

    elif op_type == "COMPLAINT_HANDLE":
        # 投诉处理接口参数：id, fromStatus, toStatus
        return json.dumps({
            "id": target_id,
            "fromStatus": related_info.get("from_status", 0),
            "toStatus": related_info.get("to_status", 2),
        }, ensure_ascii=False)

    else:
        return json.dumps({}, ensure_ascii=False)


def _pick_random_items(
    source_list: list,
    count: int,
    allow_duplicates: bool = False,
) -> list:
    """从列表中随机选取指定数量的元素。"""
    if not source_list:
        return []
    if allow_duplicates:
        return [random.choice(source_list) for _ in range(count)]
    k = min(count, len(source_list))
    return random.sample(source_list, k)


# =============================================================================
# 拒绝原因池（用于 APPLICATION_REJECT 的 detail）
# =============================================================================

REJECT_REASON_POOL = [
    "简历与岗位要求不匹配",
    "工作经验不足",
    "面试表现未达到预期",
    "已招到更合适的人选",
    "岗位已停止招聘",
    "薪资期望超出范围",
    "到岗时间无法满足要求",
    "技能与岗位需求不符",
    "学历要求未达标",
    "沟通能力未通过评估",
    "距离通勤时间过长",
    "无法适应排班安排",
]

# =============================================================================
# 职位标题池（用于 TASK_PUBLISH 的 detail）
# =============================================================================

TASK_TITLE_POOL = [
    "餐厅服务员", "后厨帮工", "送餐员", "咖啡师", "调酒师",
    "小学数学家教", "初中英语家教", "高中物理家教", "钢琴陪练",
    "快递分拣员", "配送员", "仓库管理员", "打包员",
    "平面设计师", "UI设计师", "插画师", "美工",
    "导购员", "促销员", "地推推广", "试吃员",
    "电话客服", "在线客服", "售后客服",
    "新媒体文案", "内容编辑", "软文写手",
    "Java开发工程师", "前端开发工程师", "测试工程师", "运维工程师",
    "英语翻译", "日语翻译",
    "美容师", "美甲师", "化妆师", "发型师",
    "保洁员", "钟点工", "月嫂",
    "课程顾问", "学习规划师", "教务管理",
    "活动策划师", "婚礼策划",
    "摄影师", "摄像师", "视频剪辑",
    "销售代表", "业务员",
    "行政助理", "前台接待", "文员",
    "会计", "出纳",
    "电焊工", "电工", "装配工",
    "货车司机", "小车司机",
    "保安员", "门卫", "监控员",
    "兼职模特", "会展礼仪", "手工制作",
    "APP推广", "社群运营", "数据标注员",
]

# =============================================================================
# 公司/企业名称池（用于 ENTERPRISE_SUBMIT 的 detail）
# =============================================================================

COMPANY_NAME_POOL = [
    "味美滋餐饮管理有限公司", "飞速达物流有限公司", "智汇科技有限公司",
    "启航教育咨询有限公司", "创艺空间设计有限公司", "安心家政服务有限公司",
    "美丽传说美容有限公司", "华贸贸易有限公司", "盛世传媒有限公司",
    "博雅教育培训学校", "云创信息技术有限公司", "好味道餐饮有限公司",
    "顺风速物流有限公司", "天工智能科技有限公司", "卓越教育咨询有限公司",
    "灵感设计工作室", "温馨家园家政有限公司", "靓丽人生美容有限公司",
    "鼎盛贸易有限公司", "创想广告有限公司",
]


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
    task_ids: List[int],
    enterprise_ids: List[int],
) -> List[int]:
    """生成操作日志数据并写入 SQL 文件。

    生成 25,000 条操作日志记录，覆盖后端 15 种 OperationType 常量。
    各操作类型的分布模拟真实业务场景：LOGIN 最高频，业务操作按生命周期排列。
    detail 字段模拟 AOP 切面对方法参数的 JSON 序列化行为。
    IP 地址混用内网（70%）与公网（30%）范围。
    create_time 与关联业务实体的时间对齐（如投递日志 ≈ 投递记录的 create_time）。

    Args:
        writer: SQLWriter 实例，用于写入 SQL 文件
        all_user_ids: 所有用户的 ID 列表（共 8,000 个）
        seeker_ids: 求职者角色的用户 ID 列表（共 7,500 个）
        hr_ids: HR 角色的用户 ID 列表（共 400 个）
        admin_ids: 管理员角色的用户 ID 列表（共 100 个）
        application_info_list: 投递信息列表（共 80,000 个），
            每个字典包含 app_id, task_id, applicant_id, status, hr_id,
            create_time, interview_time
        task_ids: 岗位 ID 列表（共 5,000 个）
        enterprise_ids: 企业 ID 列表（共 400 个）

    Returns:
        operation_log_ids: 生成的操作日志 ID 列表（长度 25,000）
    """
    operation_log_ids: List[int] = []

    writer.write_comment(f"操作日志表（{TARGET_LOG_COUNT} 条记录）")
    writer.begin_insert("operation_log", OPERATION_LOG_COLUMNS)

    # =========================================================================
    # 辅助函数：生成一条操作日志并写入
    # =========================================================================

    def _write_log(
        operator_id: int,
        op_type: str,
        target_type: str,
        target_id: int,
        detail: str,
        create_time: datetime.datetime,
    ) -> int:
        log_id = writer.next_id("operation_log")
        operation_log_ids.append(log_id)
        writer.add_row([
            log_id,
            operator_id,
            op_type,
            target_type,
            target_id,
            detail,
            _random_ip(),
            _format_dt(create_time),
        ])
        return log_id

    # =========================================================================
    # 1. USER_LOGIN（6,500 条 — 26%）
    #    用户登录是最频繁的操作，随机选择用户，时间广泛分布
    #    多出的 500 条用于补足取整差额，使总数达到 25,000
    # =========================================================================
    for _ in range(6500):
        _write_log(
            operator_id=random.choice(all_user_ids),
            op_type="USER_LOGIN",
            target_type="USER",
            target_id=random.choice(all_user_ids),
            detail=_generate_detail("USER_LOGIN", 0),
            create_time=_random_datetime(),
        )

    # =========================================================================
    # 2. USER_REGISTER（3,000 条 — 12%）
    #    对应每个用户的注册时刻，从用户池不重复选取
    # =========================================================================
    register_users = _pick_random_items(all_user_ids, 3000, allow_duplicates=False)
    for operator_id in register_users:
        _write_log(
            operator_id=operator_id,
            op_type="USER_REGISTER",
            target_type="USER",
            target_id=operator_id,
            detail=_generate_detail("USER_REGISTER", operator_id, {
                "phone": f"1{random.choice(['3','5','7','8','9'])}{random.randint(0,9)}{''.join(str(random.randint(0,9)) for _ in range(8))}",
                "role": random.choice([0, 1]),
            }),
            create_time=_random_datetime(),
        )

    # =========================================================================
    # 3. APPLICATION_DELIVER（3,000 条 — 12%）
    #    对应求职者投递简历的时刻，从所有投递记录中选取
    # =========================================================================
    deliver_samples = _pick_random_items(
        application_info_list, 3000, allow_duplicates=True,
    )
    for app in deliver_samples:
        operator_id = app["applicant_id"]
        task_id = app["task_id"]
        app_id = app["app_id"]

        # 投递日志时间 ≈ 投递记录的 create_time
        app_create_time = app.get("create_time")
        if app_create_time:
            try:
                app_dt = datetime.datetime.strptime(app_create_time, "%Y-%m-%d %H:%M:%S")
                log_time = _random_datetime_between(
                    app_dt - datetime.timedelta(minutes=5),
                    app_dt + datetime.timedelta(minutes=30),
                )
            except (ValueError, TypeError):
                log_time = _random_datetime()
        else:
            log_time = _random_datetime()

        _write_log(
            operator_id=operator_id,
            op_type="APPLICATION_DELIVER",
            target_type="APPLICATION",
            target_id=app_id,
            detail=_generate_detail("APPLICATION_DELIVER", app_id, {
                "task_id": task_id,
                "applicant_id": operator_id,
            }),
            create_time=log_time,
        )

    # =========================================================================
    # 4. APPLICATION_INTERVIEW（2,000 条 — 8%）
    #    对应 HR 邀请面试，优先从 status=1（待面试）的投递中选取
    # =========================================================================
    interview_apps = [a for a in application_info_list if a.get("status") == 1]
    if len(interview_apps) < 2000:
        # 候选不足时补充 status >= 1 的记录
        supplement = [a for a in application_info_list if a.get("status", 0) >= 1]
        interview_apps.extend(supplement)
    interview_samples = _pick_random_items(
        interview_apps, 2000, allow_duplicates=True,
    )
    for app in interview_samples:
        operator_id = app.get("hr_id") or random.choice(hr_ids)
        app_id = app["app_id"]
        interview_time = app.get("interview_time")

        # 面试日志时间 ≈ 投递 create_time 之后，interview_time 附近
        app_create_time = app.get("create_time")
        if app_create_time and interview_time:
            try:
                app_dt = datetime.datetime.strptime(app_create_time, "%Y-%m-%d %H:%M:%S")
                iv_dt = datetime.datetime.strptime(interview_time, "%Y-%m-%d %H:%M:%S")
                log_time = _random_datetime_between(app_dt, iv_dt)
            except (ValueError, TypeError):
                log_time = _random_datetime()
        elif app_create_time:
            try:
                app_dt = datetime.datetime.strptime(app_create_time, "%Y-%m-%d %H:%M:%S")
                log_time = _random_datetime_between(app_dt, END_DT)
            except (ValueError, TypeError):
                log_time = _random_datetime()
        else:
            log_time = _random_datetime()

        _write_log(
            operator_id=operator_id,
            op_type="APPLICATION_INTERVIEW",
            target_type="APPLICATION",
            target_id=app_id,
            detail=_generate_detail("APPLICATION_INTERVIEW", app_id, {
                "interview_time": interview_time or _format_dt(log_time),
                "from_status": 0,
                "to_status": 1,
            }),
            create_time=log_time,
        )

    # =========================================================================
    # 5. APPLICATION_HIRE（1,500 条 — 6%）
    #    对应 HR 录用操作，从 status=3（已录用）或 status=5（已完成）中选取
    # =========================================================================
    hire_apps = [a for a in application_info_list if a.get("status") in (3, 5)]
    hire_samples = _pick_random_items(hire_apps, 1500, allow_duplicates=len(hire_apps) < 1500)
    for app in hire_samples:
        operator_id = app.get("hr_id") or random.choice(hr_ids)
        app_id = app["app_id"]

        app_create_time = app.get("create_time")
        if app_create_time:
            try:
                app_dt = datetime.datetime.strptime(app_create_time, "%Y-%m-%d %H:%M:%S")
                log_time = _random_datetime_between(app_dt, END_DT)
            except (ValueError, TypeError):
                log_time = _random_datetime()
        else:
            log_time = _random_datetime()

        _write_log(
            operator_id=operator_id,
            op_type="APPLICATION_HIRE",
            target_type="APPLICATION",
            target_id=app_id,
            detail=_generate_detail("APPLICATION_HIRE", app_id, {
                "from_status": 2,
                "to_status": 3,
            }),
            create_time=log_time,
        )

    # =========================================================================
    # 6. APPLICATION_REJECT（2,000 条 — 8%）
    #    对应 HR 淘汰操作，从 status=4（已淘汰）中选取
    # =========================================================================
    reject_apps = [a for a in application_info_list if a.get("status") == 4]
    reject_samples = _pick_random_items(reject_apps, 2000, allow_duplicates=len(reject_apps) < 2000)
    for app in reject_samples:
        operator_id = app.get("hr_id") or random.choice(hr_ids)
        app_id = app["app_id"]

        app_create_time = app.get("create_time")
        if app_create_time:
            try:
                app_dt = datetime.datetime.strptime(app_create_time, "%Y-%m-%d %H:%M:%S")
                log_time = _random_datetime_between(app_dt, END_DT)
            except (ValueError, TypeError):
                log_time = _random_datetime()
        else:
            log_time = _random_datetime()

        _write_log(
            operator_id=operator_id,
            op_type="APPLICATION_REJECT",
            target_type="APPLICATION",
            target_id=app_id,
            detail=_generate_detail("APPLICATION_REJECT", app_id, {
                "reason": random.choice(REJECT_REASON_POOL),
                "from_status": 1,
                "to_status": 4,
            }),
            create_time=log_time,
        )

    # =========================================================================
    # 7. APPLICATION_COMPLETE（1,000 条 — 4%）
    #    对应兼职完成操作，从 status=5（已完成）中选取
    # =========================================================================
    complete_apps = [a for a in application_info_list if a.get("status") == 5]
    complete_samples = _pick_random_items(complete_apps, 1000, allow_duplicates=len(complete_apps) < 1000)
    for app in complete_samples:
        operator_id = app.get("hr_id") or random.choice(hr_ids)
        app_id = app["app_id"]

        app_create_time = app.get("create_time")
        if app_create_time:
            try:
                app_dt = datetime.datetime.strptime(app_create_time, "%Y-%m-%d %H:%M:%S")
                log_time = _random_datetime_between(app_dt, END_DT)
            except (ValueError, TypeError):
                log_time = _random_datetime()
        else:
            log_time = _random_datetime()

        _write_log(
            operator_id=operator_id,
            op_type="APPLICATION_COMPLETE",
            target_type="APPLICATION",
            target_id=app_id,
            detail=_generate_detail("APPLICATION_COMPLETE", app_id, {
                "from_status": 3,
                "to_status": 5,
            }),
            create_time=log_time,
        )

    # =========================================================================
    # 8. APPLICATION_PENDING（800 条 — 3.2%）
    #    对应面试通过/待入职状态变更，从 status=2（面试通过）中选取
    # =========================================================================
    pending_apps = [a for a in application_info_list if a.get("status") == 2]
    pending_samples = _pick_random_items(pending_apps, 800, allow_duplicates=len(pending_apps) < 800)
    for app in pending_samples:
        operator_id = app.get("hr_id") or random.choice(hr_ids)
        app_id = app["app_id"]

        app_create_time = app.get("create_time")
        if app_create_time:
            try:
                app_dt = datetime.datetime.strptime(app_create_time, "%Y-%m-%d %H:%M:%S")
                log_time = _random_datetime_between(app_dt, END_DT)
            except (ValueError, TypeError):
                log_time = _random_datetime()
        else:
            log_time = _random_datetime()

        _write_log(
            operator_id=operator_id,
            op_type="APPLICATION_PENDING",
            target_type="APPLICATION",
            target_id=app_id,
            detail=_generate_detail("APPLICATION_PENDING", app_id, {
                "from_status": 1,
                "to_status": 2,
            }),
            create_time=log_time,
        )

    # =========================================================================
    # 9. TASK_PUBLISH（1,500 条 — 6%）
    #    对应 HR 发布岗位，从岗位 ID 列表中选取
    # =========================================================================
    pub_tasks = _pick_random_items(task_ids, 1500, allow_duplicates=True)
    hr_task_pool = list(set(hr_ids))
    for task_id in pub_tasks:
        operator_id = random.choice(hr_task_pool)
        enterprise_id = random.choice(enterprise_ids)

        _write_log(
            operator_id=operator_id,
            op_type="TASK_PUBLISH",
            target_type="TASK",
            target_id=task_id,
            detail=_generate_detail("TASK_PUBLISH", task_id, {
                "title": random.choice(TASK_TITLE_POOL),
                "enterprise_id": enterprise_id,
            }),
            create_time=_random_datetime(),
        )

    # =========================================================================
    # 10. TASK_AUDIT（1,200 条 — 4.8%）
    #     对应管理员审核岗位
    # =========================================================================
    audit_task_admins = _pick_random_items(admin_ids, 1200, allow_duplicates=True)
    for operator_id in audit_task_admins:
        task_id = random.choice(task_ids)
        _write_log(
            operator_id=operator_id,
            op_type="TASK_AUDIT",
            target_type="TASK",
            target_id=task_id,
            detail=_generate_detail("TASK_AUDIT", task_id, {
                "status": 1,
                "from_status": 0,
                "to_status": 1,
            }),
            create_time=_random_datetime(),
        )

    # =========================================================================
    # 11. TASK_OFFLINE（500 条 — 2%）
    #     对应管理员或 HR 下架岗位
    # =========================================================================
    offline_tasks = _pick_random_items(task_ids, 500, allow_duplicates=True)
    offline_operators = admin_ids + hr_ids
    for task_id in offline_tasks:
        operator_id = random.choice(offline_operators)
        _write_log(
            operator_id=operator_id,
            op_type="TASK_OFFLINE",
            target_type="TASK",
            target_id=task_id,
            detail=_generate_detail("TASK_OFFLINE", task_id, {
                "from_status": 1,
                "to_status": 4,
            }),
            create_time=_random_datetime(),
        )

    # =========================================================================
    # 12. ENTERPRISE_SUBMIT（400 条 — 1.6%）
    #     对应 HR 提交企业认证资料
    # =========================================================================
    submit_enterprises = _pick_random_items(enterprise_ids, 400, allow_duplicates=True)
    for eid in submit_enterprises:
        operator_id = random.choice(hr_ids)
        company_name = random.choice(COMPANY_NAME_POOL)
        _write_log(
            operator_id=operator_id,
            op_type="ENTERPRISE_SUBMIT",
            target_type="ENTERPRISE",
            target_id=eid,
            detail=_generate_detail("ENTERPRISE_SUBMIT", eid, {
                "company_name": company_name,
            }),
            create_time=_random_datetime(),
        )

    # =========================================================================
    # 13. ENTERPRISE_AUDIT（300 条 — 1.2%）
    #     对应管理员审核企业认证
    # =========================================================================
    audit_enterprise_admins = _pick_random_items(admin_ids, 300, allow_duplicates=True)
    for operator_id in audit_enterprise_admins:
        eid = random.choice(enterprise_ids)
        _write_log(
            operator_id=operator_id,
            op_type="ENTERPRISE_AUDIT",
            target_type="ENTERPRISE",
            target_id=eid,
            detail=_generate_detail("ENTERPRISE_AUDIT", eid, {
                "audit_status": 1,
                "from_status": 0,
                "to_status": 1,
            }),
            create_time=_random_datetime(),
        )

    # =========================================================================
    # 14. REAL_NAME_AUTH（1,000 条 — 4%）
    #     对应普通用户进行实名认证
    # =========================================================================
    auth_users = _pick_random_items(all_user_ids, 1000, allow_duplicates=False)
    for operator_id in auth_users:
        _write_log(
            operator_id=operator_id,
            op_type="REAL_NAME_AUTH",
            target_type="USER",
            target_id=operator_id,
            detail=_generate_detail("REAL_NAME_AUTH", operator_id, {
                "auth_type": "id_card",
                "status": 1,
            }),
            create_time=_random_datetime(),
        )

    # =========================================================================
    # 15. COMPLAINT_HANDLE（300 条 — 1.2%）
    #     对应管理员处理投诉
    # =========================================================================
    complaint_admins = _pick_random_items(admin_ids, 300, allow_duplicates=True)
    for idx, operator_id in enumerate(complaint_admins, start=1):
        _write_log(
            operator_id=operator_id,
            op_type="COMPLAINT_HANDLE",
            target_type="COMPLAINT",
            target_id=idx,  # complaint 表共 300 条，ID 从 1 开始
            detail=_generate_detail("COMPLAINT_HANDLE", idx, {
                "from_status": 0,
                "to_status": 2,
            }),
            create_time=_random_datetime(),
        )

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
