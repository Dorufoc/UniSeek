# ==============================================================================
# UniSeek 兼职招聘平台 - 通知/聊天/投诉数据生成器
# ==============================================================================
# 生成 60,000 条通知、25,000 条聊天会话、100,000 条聊天消息、300 条投诉。
# 所有数据均通过投递事件驱动生成，外键关联完整有效。
#
# 依赖：
#   - config: 各表记录数目标及时间范围
#   - datapool: 通知模板、聊天消息模板、投诉内容模板
#   - sql_output: SQLWriter 批量写入器
# ==============================================================================

import datetime
import random
from typing import Dict, List

from config import (
    CHAT_MESSAGE_COUNT,
    CHAT_SESSION_COUNT,
    COMPLAINT_COUNT,
    END_DATE,
    NOTIFICATION_COUNT,
    START_DATE,
)
from datapool import (
    CHAT_MESSAGES_HR,
    CHAT_MESSAGES_SEEKER,
    COMPLAINT_CONTENT,
    NOTIFICATION_TEMPLATES,
)
from sql_output import SQLWriter

# =============================================================================
# 常量定义
# =============================================================================

# 通知表列名（与 uniseek_schema.sql 完全对应）
NOTIFICATION_COLUMNS = [
    "id", "receiver_id", "sender_id", "title", "content",
    "type", "is_read", "biz_id", "create_time",
]

# 聊天会话表列名
CHAT_SESSION_COLUMNS = [
    "id", "task_application_id", "employer_id", "seeker_id",
    "last_message", "last_message_time", "status",
    "create_time", "update_time",
]

# 聊天消息表列名
CHAT_MESSAGE_COLUMNS = [
    "id", "session_id", "sender_id", "message_type",
    "content", "is_read", "send_time",
]

# 投诉表列名
COMPLAINT_COLUMNS = [
    "id", "complainant_id", "target_type", "target_id",
    "type", "content", "status", "handler_id", "handle_result",
    "create_time", "update_time",
]

# 通知标题映射（与 schema 中 type 枚举一致）
NOTIFICATION_TITLES = {
    0: "系统通知",
    1: "面试邀请",
    2: "录用通知",
    3: "淘汰通知",
}

# 时间范围
START_DT = datetime.datetime.strptime(START_DATE, "%Y-%m-%d")
END_DT = datetime.datetime.strptime(END_DATE, "%Y-%m-%d")
SPAN_SECONDS = int((END_DT - START_DT).total_seconds())

# 占位数据（用于模板格式化，避免重复硬编码）
_CITIES = [
    "北京", "上海", "广州", "深圳", "杭州", "成都",
    "武汉", "南京", "重庆", "西安",
]
_DISTRICTS = [
    "朝阳区", "浦东新区", "天河区", "南山区", "西湖区",
    "高新区", "洪山区", "鼓楼区", "渝中区", "雁塔区",
]
_STREETS = [
    "长安街", "南京路", "中山大道", "深南大道", "西湖路",
    "天府大道", "珞喻路", "湖南路", "嘉陵江路", "科技路",
]
_COMPANY_NAMES = [
    "科创大厦", "商务中心", "时代广场", "国际金融中心",
    "软件园", "创业园", "总部基地", "科技园", "产业园", "创新中心",
]
_CATEGORIES = [
    "餐饮", "物流", "IT互联网", "教育培训", "设计创作",
    "家政服务", "美容美发", "销售贸易", "广告传媒",
]

# 投诉处理结果池（用于 status=2 已结案时填充）
_HANDLE_RESULTS = [
    "已处理完毕",
    "投诉已核实并处理",
    "已与双方沟通达成和解",
    "已对相关方进行警告处理",
    "经核查情况属实，已按平台规则处理",
    "已协调双方达成一致意见",
    "已要求企业整改并回复处理结果",
    "投诉不成立，已告知投诉人",
    "已转交相关部门进一步处理",
]


# =============================================================================
# 辅助函数
# =============================================================================


def _format_dt(dt: datetime.datetime) -> str:
    """将 datetime 格式化为 MySQL 兼容的日期时间字符串（精确到秒）。"""
    return dt.strftime("%Y-%m-%d %H:%M:%S")


def _random_datetime_between(
    start: datetime.datetime,
    end: datetime.datetime,
) -> datetime.datetime:
    """在 [start, end] 闭区间内均匀随机生成一个时间点。"""
    diff = int((end - start).total_seconds())
    if diff <= 0:
        return start
    return start + datetime.timedelta(seconds=random.randint(0, diff))


def _safe_format(template: str, **kwargs) -> str:
    """安全格式化模板字符串，仅替换已知占位符，未知占位符保留原样。

    Args:
        template: 含 {placeholder} 占位符的模板字符串
        **kwargs: 占位符名称到值的映射

    Returns:
        替换后的字符串
    """
    result = template
    for key, value in kwargs.items():
        result = result.replace("{" + key + "}", str(value))
    return result


# =============================================================================
# 1. 通知生成器
# =============================================================================


def generate_notifications(
    writer: SQLWriter,
    application_info_list: List[dict],
    hr_ids: List[int],
) -> List[int]:
    """生成 60,000 条通知数据并写入 SQL 文件。

    从投递事件驱动业务通知生成，不足 60,000 条时用纯系统通知填充。
    类型映射（5 种业务事件 → 4 种通知类型）：
    - type=0（系统通知 55%）：投递成功提醒→HR，系统消息
    - type=1（面试邀请 20%）：当投递状态为 1 或 2 时发送给求职者
    - type=2（录用通知 10%）：当投递状态为 3 或 5 时发送给求职者
    - type=3（淘汰通知 15%）：当投递状态为 4 时发送给求职者

    业务规则：
    - 所有投递：50% 概率向 HR 发送系统通知
    - 状态 1/2（待面试/面试通过）：70% 概率向求职者发送面试邀请
    - 状态 3/5（已录用/已完成）：80% 概率向求职者发送录用通知
    - 状态 4（已淘汰）：80% 概率向求职者发送淘汰通知

    Args:
        writer: SQLWriter 实例，用于写入 SQL 文件
        application_info_list: 投递信息列表，每项含 app_id, task_id,
                               applicant_id, status, hr_id, create_time
        hr_ids: HR 用户 ID 列表

    Returns:
        生成的通知 ID 列表（长度 60,000）
    """
    notification_ids: List[int] = []

    writer.write_comment(f"消息通知表（{NOTIFICATION_COUNT} 条记录）")
    writer.begin_insert("notification", NOTIFICATION_COLUMNS)

    # ---- 第一阶段：从投递事件驱动生成通知 ----
    for app in application_info_list:
        if len(notification_ids) >= NOTIFICATION_COUNT:
            break

        app_id = app["app_id"]
        seeker_id = app["applicant_id"]
        status = app["status"]
        hr_id = app["hr_id"]

        create_time_str = app["create_time"]
        create_time = datetime.datetime.strptime(
            create_time_str, "%Y-%m-%d %H:%M:%S",
        )

        # ---- 规则 1：所有投递 → 50% 向 HR 发送系统通知 ----
        if random.random() < 0.50 and hr_id is not None:
            if len(notification_ids) >= NOTIFICATION_COUNT:
                break
            nid = writer.next_id("notification")
            notification_ids.append(nid)

            writer.add_row([
                nid,
                hr_id,                                              # receiver_id
                seeker_id,                                          # sender_id = 求职者
                "新投递提醒",                                         # title
                f"求职者已投递岗位（投递编号：{app_id}），请及时登录平台处理。",  # content
                0,                                                  # type=系统通知
                0 if random.random() < 0.4 else 1,                  # is_read
                app_id,                                             # biz_id = 投递记录ID
                _format_dt(create_time),                            # create_time
            ])

        # ---- 规则 2：状态 1/2 → 70% 向求职者发送面试邀请 ----
        if status in (1, 2) and random.random() < 0.70:
            if len(notification_ids) >= NOTIFICATION_COUNT:
                break
            nid = writer.next_id("notification")
            notification_ids.append(nid)

            template = random.choice(NOTIFICATION_TEMPLATES[1])
            interview_time = create_time + datetime.timedelta(
                days=random.randint(1, 7),
                hours=random.randint(9, 18),
            )
            content = _safe_format(
                template,
                seeker_name=f"求职者",
                company="招聘企业",
                position="兼职岗位",
                time=_format_dt(interview_time),
                location=f"{random.choice(_CITIES)}{random.choice(_DISTRICTS)}{random.choice(_STREETS)}",
                interviewer="HR",
                phone="400-888-0000",
                minutes=str(random.randint(20, 60)),
            )
            writer.add_row([
                nid,
                seeker_id,                                   # receiver_id = 求职者
                hr_id,                                       # sender_id = HR
                NOTIFICATION_TITLES[1],                      # title = 面试邀请
                content,
                1,                                           # type=面试邀请
                0,                                           # is_read=未读
                app_id,
                _format_dt(create_time + datetime.timedelta(
                    minutes=random.randint(1, 120),
                )),
            ])

        # ---- 规则 3：状态 3/5 → 80% 向求职者发送录用通知 ----
        elif status in (3, 5) and random.random() < 0.80:
            if len(notification_ids) >= NOTIFICATION_COUNT:
                break
            nid = writer.next_id("notification")
            notification_ids.append(nid)

            template = random.choice(NOTIFICATION_TEMPLATES[2])
            onboard_time = create_time + datetime.timedelta(
                days=random.randint(1, 14),
            )
            content = _safe_format(
                template,
                seeker_name=f"求职者",
                company="招聘企业",
                position="兼职岗位",
                time=_format_dt(onboard_time),
                location=f"{random.choice(_CITIES)}{random.choice(_DISTRICTS)}",
                salary=str(random.randint(2000, 8000)),
                total=str(random.randint(30000, 100000)),
            )
            writer.add_row([
                nid,
                seeker_id,
                hr_id,
                NOTIFICATION_TITLES[2],                      # title = 录用通知
                content,
                2,                                           # type=录用通知
                0,
                app_id,
                _format_dt(create_time + datetime.timedelta(
                    hours=random.randint(1, 48),
                )),
            ])

        # ---- 规则 4：状态 4 → 80% 向求职者发送淘汰通知 ----
        elif status == 4 and random.random() < 0.80:
            if len(notification_ids) >= NOTIFICATION_COUNT:
                break
            nid = writer.next_id("notification")
            notification_ids.append(nid)

            template = random.choice(NOTIFICATION_TEMPLATES[3])
            content = _safe_format(
                template,
                seeker_name=f"求职者",
                company="招聘企业",
                position="兼职岗位",
            )
            writer.add_row([
                nid,
                seeker_id,
                hr_id,
                NOTIFICATION_TITLES[3],                      # title = 淘汰通知
                content,
                3,                                           # type=淘汰通知
                0,
                app_id,
                _format_dt(create_time + datetime.timedelta(
                    hours=random.randint(1, 72),
                )),
            ])

    # ---- 第二阶段：用纯系统通知填充至目标数量 ----
    remaining = NOTIFICATION_COUNT - len(notification_ids)
    if remaining > 0:
        # 构建接收者池：从 application_info_list 中提取所有用户 ID
        receiver_pool: List[int] = list(set(
            [app["applicant_id"] for app in application_info_list]
            + [app["hr_id"] for app in application_info_list if app["hr_id"] is not None]
            + hr_ids
        ))

        for _ in range(remaining):
            nid = writer.next_id("notification")
            notification_ids.append(nid)

            template = random.choice(NOTIFICATION_TEMPLATES[0])
            content = _safe_format(
                template,
                category=random.choice(_CATEGORIES),
                num=str(random.randint(3, 20)),
                nums=str(random.randint(10, 200)),
                time="22:00",
                time2="06:00",
            )
            writer.add_row([
                nid,
                random.choice(receiver_pool),                # receiver_id
                None,                                         # sender_id = NULL（系统）
                NOTIFICATION_TITLES[0],                      # title = 系统通知
                content,
                0,                                           # type=系统通知
                0 if random.random() < 0.3 else 1,            # is_read
                None,                                         # biz_id = NULL
                _format_dt(_random_datetime_between(START_DT, END_DT)),
            ])

    generated = len(notification_ids)
    assert generated == NOTIFICATION_COUNT, (
        f"通知记录数必须为 {NOTIFICATION_COUNT}，实际生成 {generated}"
    )

    return notification_ids


# =============================================================================
# 2. 聊天会话生成器
# =============================================================================


def generate_chat_sessions(
    writer: SQLWriter,
    application_info_list: List[dict],
) -> List[dict]:
    """生成 25,000 条聊天会话数据并写入 SQL 文件。

    从投递状态 >= 1（HR 已处理）的投递中随机选取 25,000 个，
    为每个投递创建一个一对一聊天会话。

    Args:
        writer: SQLWriter 实例，用于写入 SQL 文件
        application_info_list: 投递信息列表

    Returns:
        session_info_list: 会话信息列表，每项含 session_id,
                          task_application_id, employer_id, seeker_id, create_time
    """
    # 筛选 HR 已处理的投递（status >= 1 且有 HR 分配）
    eligible_apps = [
        app for app in application_info_list
        if app["status"] >= 1 and app["hr_id"] is not None
    ]

    sample_size = min(CHAT_SESSION_COUNT, len(eligible_apps))
    selected_apps = random.sample(eligible_apps, sample_size)

    session_info_list: List[dict] = []

    writer.write_comment(
        f"聊天会话表（{sample_size} 条记录，目标 {CHAT_SESSION_COUNT}）",
    )
    writer.begin_insert("chat_session", CHAT_SESSION_COLUMNS)

    for app in selected_apps:
        sid = writer.next_id("chat_session")
        app_id = app["app_id"]
        employer_id = app["hr_id"]
        seeker_id = app["applicant_id"]

        create_time_str = app["create_time"]
        create_time = datetime.datetime.strptime(
            create_time_str, "%Y-%m-%d %H:%M:%S",
        )
        update_time = create_time + datetime.timedelta(
            minutes=random.randint(5, 120),
        )

        # 会话状态：90% 活跃(0)，10% 已关闭(1)
        status = 0 if random.random() < 0.9 else 1

        writer.add_row([
            sid,
            app_id,                                              # task_application_id
            employer_id,                                         # employer_id = HR
            seeker_id,                                           # seeker_id
            "您好，很高兴与您沟通。",                                # last_message 占位
            _format_dt(update_time),                             # last_message_time
            status,
            _format_dt(create_time),
            _format_dt(update_time),
        ])

        session_info_list.append({
            "session_id": sid,
            "task_application_id": app_id,
            "employer_id": employer_id,
            "seeker_id": seeker_id,
            "create_time": _format_dt(create_time),
        })

    generated = len(session_info_list)
    assert generated == sample_size, (
        f"会话记录数必须为 {sample_size}，实际生成 {generated}"
    )

    return session_info_list


# =============================================================================
# 3. 聊天消息生成器
# =============================================================================


def generate_chat_messages(
    writer: SQLWriter,
    session_info_list: List[dict],
    user_names: Dict[int, str],
) -> List[int]:
    """生成 100,000 条聊天消息数据并写入 SQL 文件。

    每个会话生成 2-6 条消息（平均约 4 条），
    首条消息由求职者发送，之后交替发送。
    is_read：前 60% 的消息已读，后 40% 未读。

    Args:
        writer: SQLWriter 实例，用于写入 SQL 文件
        session_info_list: 会话信息列表（由 generate_chat_sessions 返回）
        user_names: 用户 ID → 用户昵称的映射字典

    Returns:
        生成的消息 ID 列表（长度 100,000）
    """
    message_ids: List[int] = []
    target_count = CHAT_MESSAGE_COUNT

    writer.write_comment(f"聊天消息表（目标 {target_count} 条记录）")
    writer.begin_insert("chat_message", CHAT_MESSAGE_COLUMNS)

    # 确定性地分配消息数量，确保总数精确等于目标值
    session_count = len(session_info_list)
    base_msgs = target_count // session_count if session_count > 0 else 0
    extra_msgs = target_count % session_count

    for idx, session_info in enumerate(session_info_list):
        if len(message_ids) >= target_count:
            break

        session_id = session_info["session_id"]
        employer_id = session_info["employer_id"]
        seeker_id = session_info["seeker_id"]

        create_time_str = session_info["create_time"]
        session_time = datetime.datetime.strptime(
            create_time_str, "%Y-%m-%d %H:%M:%S",
        )

        # 每个会话生成 base_msgs 条消息，前 extra_msgs 个会话多 1 条
        num_messages = base_msgs + (1 if idx < extra_msgs else 0)

        # 发送顺序：求职者先发（i%2==0），HR 后发（i%2==1）
        sender_cycle = [seeker_id, employer_id]
        current_time = session_time

        for i in range(num_messages):
            mid = writer.next_id("chat_message")
            message_ids.append(mid)

            sender_id = sender_cycle[i % 2]
            is_hr = (sender_id == employer_id)

            # 选取对应角色的消息模板并格式化
            if is_hr:
                template = random.choice(CHAT_MESSAGES_HR)
                content = _safe_format(
                    template,
                    salary=str(random.randint(100, 500)),
                    location=f"{random.choice(_CITIES)}{random.choice(_DISTRICTS)}",
                    content="日常运营工作",
                    hours=str(random.randint(4, 10)),
                    position="兼职岗位",
                    time=f"{random.randint(9, 18)}:00",
                    day=str(random.randint(1, 3)),
                    month=str(random.randint(1, 6)),
                    industry=random.choice(_CATEGORIES),
                    position2="其他岗位",
                )
            else:
                template = random.choice(CHAT_MESSAGES_SEEKER)
                content = _safe_format(
                    template,
                    position="兼职岗位",
                    nums=str(random.randint(1, 5)),
                    num=str(random.randint(2, 12)),
                    company=random.choice(_COMPANY_NAMES),
                    age=str(random.randint(18, 35)),
                    gender="男" if random.random() < 0.5 else "女",
                    location=f"{random.choice(_CITIES)}{random.choice(_DISTRICTS)}",
                    time=f"{random.randint(9, 18)}:00",
                    time2=f"{random.randint(18, 22)}:00",
                    day="周一",
                )

            # 消息时间按发送顺序递增
            current_time += datetime.timedelta(
                minutes=random.randint(1, 30),
            )

            # is_read：前 60% 已读(1)，后 40% 未读(0)
            read_threshold = int(num_messages * 0.6)
            is_read = 1 if i < read_threshold else 0

            writer.add_row([
                mid,
                session_id,
                sender_id,
                0,                              # message_type=0（文本）
                content,
                is_read,
                _format_dt(current_time),
            ])

    generated = len(message_ids)
    assert generated == target_count, (
        f"消息记录数必须为 {target_count}，实际生成 {generated}"
    )

    return message_ids


# =============================================================================
# 4. 投诉生成器
# =============================================================================


def generate_complaints(
    writer: SQLWriter,
    all_user_ids: List[int],
    enterprise_ids: List[int],
    admin_ids: List[int],
) -> List[int]:
    """生成 300 条投诉数据并写入 SQL 文件。

    分布规则：
    - target_type：70% 企业(1)，30% 用户(2)
    - status：50% 待处理(0)，20% 处理中(1)，30% 已结案(2)
    - handler_id：仅对处理中和已结案的投诉设置

    Args:
        writer: SQLWriter 实例，用于写入 SQL 文件
        all_user_ids: 所有用户 ID 列表
        enterprise_ids: 企业 ID 列表
        admin_ids: 管理员用户 ID 列表（用于 handler_id）

    Returns:
        生成的投诉 ID 列表（长度 300）
    """
    complaint_ids: List[int] = []

    writer.write_comment(f"投诉表（{COMPLAINT_COUNT} 条记录）")
    writer.begin_insert("complaint", COMPLAINT_COLUMNS)

    for _ in range(COMPLAINT_COUNT):
        cid = writer.next_id("complaint")

        # ---- 投诉人：从所有用户中随机选取 ----
        complainant_id = random.choice(all_user_ids)

        # ---- 被投诉对象：70% 企业，30% 用户 ----
        if random.random() < 0.70:
            target_type = 1
            target_id = random.choice(enterprise_ids)
        else:
            target_type = 2
            target_id = random.choice(all_user_ids)

        # ---- 投诉类型（1-5 随机）----
        complaint_type = random.randint(1, 5)

        # ---- 投诉内容 ----
        template = random.choice(COMPLAINT_CONTENT)
        content = _safe_format(
            template,
            min=str(random.randint(50, 300)),
            real=str(random.randint(30, 150)),
            min_s=str(random.randint(10, 60)),
            day=str(random.randint(3, 60)),
            hours=str(random.randint(10, 16)),
        )

        # ---- 处理状态分布 ----
        status_rand = random.random()
        if status_rand < 0.50:
            status = 0    # 待处理
        elif status_rand < 0.70:
            status = 1    # 处理中
        else:
            status = 2    # 已结案

        # ---- 处理人：处理中和已结案时设置 ----
        handler_id = None
        handle_result = None
        if status >= 1 and admin_ids:
            handler_id = random.choice(admin_ids)
        if status == 2:
            handle_result = random.choice(_HANDLE_RESULTS)

        # ---- 时间 ----
        create_time = _random_datetime_between(START_DT, END_DT)
        update_time = create_time
        if status >= 1:
            update_time = _random_datetime_between(create_time, END_DT)

        writer.add_row([
            cid,
            complainant_id,
            target_type,
            target_id,
            complaint_type,
            content,
            status,
            handler_id,
            handle_result,
            _format_dt(create_time),
            _format_dt(update_time),
        ])

        complaint_ids.append(cid)

    generated = len(complaint_ids)
    assert generated == COMPLAINT_COUNT, (
        f"投诉记录数必须为 {COMPLAINT_COUNT}，实际生成 {generated}"
    )

    return complaint_ids


# =============================================================================
# 5. 总编排函数
# =============================================================================


def generate_notifications_chat_complaints(
    writer: SQLWriter,
    application_info_list: List[dict],
    hr_ids: List[int],
    all_user_ids: List[int],
    admin_ids: List[int],
    enterprise_ids: List[int],
    user_names: Dict[int, str],
) -> dict:
    """编排所有通知/聊天/投诉生成器。

    依次生成通知、聊天会话、聊天消息和投诉数据，
    并将聊天会话信息传递给消息生成器。

    Args:
        writer: SQLWriter 实例
        application_info_list: 投递信息列表
        hr_ids: HR 用户 ID 列表
        all_user_ids: 所有用户 ID 列表
        admin_ids: 管理员用户 ID 列表
        enterprise_ids: 企业 ID 列表
        user_names: 用户 ID → 用户昵称的映射字典

    Returns:
        dict 包含所有生成记录的 ID：
        {
            "notification_ids": List[int],
            "session_info_list": List[dict],
            "message_ids": List[int],
            "complaint_ids": List[int],
        }
    """
    # 1. 生成通知
    notification_ids = generate_notifications(
        writer, application_info_list, hr_ids,
    )

    # 2. 生成聊天会话（返回会话信息供消息生成器使用）
    session_info_list = generate_chat_sessions(
        writer, application_info_list,
    )

    # 3. 生成聊天消息（依赖会话信息）
    message_ids = generate_chat_messages(
        writer, session_info_list, user_names,
    )

    # 4. 生成投诉
    complaint_ids = generate_complaints(
        writer, all_user_ids, enterprise_ids, admin_ids,
    )

    return {
        "notification_ids": notification_ids,
        "session_info_list": session_info_list,
        "message_ids": message_ids,
        "complaint_ids": complaint_ids,
    }
