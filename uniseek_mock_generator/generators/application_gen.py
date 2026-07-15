# ==============================================================================
# UniSeek 兼职招聘平台 - 岗位投递数据生成器
# ==============================================================================
# 生成 80,000 条岗位投递（task_application）记录，
# 覆盖 7,500 个求职者对 5,000 个岗位的投递行为。
# 每名求职者平均投递 10-11 个岗位。
# 投递状态采用统计分布模型（非状态机），各状态比例符合招聘业务场景。
#
# 依赖：
#   - config: START_DATE, END_DATE
#   - datapool: 中文数据池（教育、学校、技能、面试地点、拒绝原因等）
#   - sql_output: SQLWriter 批量写入器
# ==============================================================================

import datetime
import json
import random
from typing import Dict, List, Tuple

from config import END_DATE, START_DATE
from sql_output import SQLWriter
from datapool import (
    EDUCATION_LEVELS,
    INTERVIEW_LOCATIONS,
    REJECT_REASONS,
    SURNAMES,
    MALE_GIVEN_NAMES,
    FEMALE_GIVEN_NAMES,
    SKILLS_BY_CATEGORY,
)
from time_utils import weighted_random_time

# =============================================================================
# 常量定义
# =============================================================================

# 投递表列名
APPLICATION_COLUMNS = [
    "id", "task_id", "applicant_id", "resume_snapshot",
    "attachment_url", "status", "hr_id", "interview_time",
    "interview_location", "reject_reason", "hr_note",
    "version", "create_time", "update_time",
]

# 状态分布（统计模型，非状态机）
# 每组为 (status_code, weight)
# 0=已投递  1=待面试  2=面试通过  3=已录用  4=已淘汰  5=已完成
STATUS_DISTRIBUTION: List[Tuple[int, float]] = [
    (0, 0.30),   # 已投递 —— HR 尚未处理
    (1, 0.15),   # 待面试 —— 已安排面试
    (2, 0.08),   # 面试通过 —— 面试已过，等待录用
    (3, 0.15),   # 已录用 —— 已发 Offer
    (4, 0.20),   # 已淘汰 —— 未通过
    (5, 0.12),   # 已完成 —— 兼职工作已完成
]

# 中国高校/职业学校名单（与 resume_gen 保持一致）
SCHOOLS = [
    "北京大学", "清华大学", "复旦大学", "上海交通大学", "浙江大学",
    "南京大学", "武汉大学", "华中科技大学", "中山大学", "西安交通大学",
    "哈尔滨工业大学", "北京理工大学", "北京航空航天大学", "同济大学",
    "南开大学", "天津大学", "厦门大学", "四川大学", "吉林大学",
    "兰州大学", "山东大学", "中国科学技术大学", "中南大学", "湖南大学",
    "华南理工大学", "大连理工大学", "重庆大学", "电子科技大学",
    "北京邮电大学", "北京科技大学", "北京交通大学", "北京外国语大学",
    "中央美术学院", "中国传媒大学", "上海大学", "华东师范大学",
    "上海外国语大学", "上海财经大学", "南京理工大学", "南京航空航天大学",
    "苏州大学", "郑州大学", "南昌大学", "云南大学", "广西大学",
    "深圳职业技术学院", "广州番禺职业技术学院", "武汉职业技术学院",
    "长沙民政职业技术学院", "北京工业职业技术学院",
]

# 面试地点占位数据
CITIES = ["北京", "上海", "广州", "深圳", "杭州", "成都", "武汉", "南京", "重庆", "西安"]
DISTRICTS = ["朝阳区", "浦东新区", "天河区", "南山区", "西湖区", "高新区", "洪山区", "鼓楼区", "渝中区", "雁塔区"]
STREETS = ["长安街", "南京路", "中山大道", "深南大道", "西湖路", "天府大道", "珞喻路", "湖南路", "嘉陵江路", "科技路"]
COMPANY_NAMES = ["科创大厦", "商务中心", "时代广场", "国际金融中心", "软件园", "创业园", "总部基地", "科技园", "产业园", "创新中心"]
FLOORS = [str(i) for i in range(2, 30)]
ROOMS = [f"{i}0{i}" for i in range(1, 10)]

# HR 备注池（按状态分类）
HR_NOTES: Dict[int, List[str]] = {
    1: ["已安排面试，请准时参加", "安排面试", "请准时参加面试", "面试邀请已发出", "请携带简历参加面试"],
    2: ["面试通过，待入职确认", "面试表现优秀，等待入职", "面试通过，进入录用流程", "面试合格，等待薪资确认"],
    3: ["已录用，等待入职", "录用通过，已发Offer", "录用审批完成", "录用确认，安排入职"],
    4: ["不合适，建议转投其他岗位", "经评估不匹配", "简历与岗位要求不符", "已招到更合适人选", "岗位已满"],
    5: ["已完成工作，表现良好", "已完成结算", "工作完成，双方满意", "任务已完成验收"],
}

# 时间范围
START_DT = datetime.datetime.strptime(START_DATE, "%Y-%m-%d")
END_DT = datetime.datetime.strptime(END_DATE, "%Y-%m-%d")
SPAN_SECONDS = int((END_DT - START_DT).total_seconds())

TARGET_APPLICATION_COUNT = 80000


# =============================================================================
# 辅助函数
# =============================================================================


def _random_name() -> str:
    """按姓氏权重生成随机中文姓名。"""
    surnames_pool = [s for s, w in SURNAMES]
    weights = [w for s, w in SURNAMES]
    surname = random.choices(surnames_pool, weights=weights, k=1)[0]
    given_name_pool = random.choice([MALE_GIVEN_NAMES, FEMALE_GIVEN_NAMES])
    given_name = random.choice(given_name_pool)
    return surname + given_name


def _random_skills(count: int = 4) -> List[str]:
    """从全量技能池中随机采样指定数量的技能。"""
    all_skills = list({s for skills in SKILLS_BY_CATEGORY.values() for s in skills})
    k = min(count, len(all_skills))
    return random.sample(all_skills, k)


def generate_resume_snapshot() -> str:
    """生成简历快照 JSON 字符串。

    模拟求职者在投递时刻的简历信息快照，包含姓名、性别、
    出生日期、学历、学校、技能列表和经历描述。

    Returns:
        简历快照 JSON 字符串（ensure_ascii=False）
    """
    name = _random_name()
    gender = random.randint(0, 1)
    birth_year = random.randint(1985, 2005)
    birth_month = random.randint(1, 12)
    birth_day = random.randint(1, 28)
    birth_date = f"{birth_year:04d}-{birth_month:02d}-{birth_day:02d}"
    education = random.choice(EDUCATION_LEVELS)
    school = random.choice(SCHOOLS)
    skills = json.dumps(_random_skills(4), ensure_ascii=False)

    # 随机选取一段经历描述
    experience_templates = [
        "<p>曾在多家企业担任相关职位，积累了丰富的行业经验。"
        "具备良好的团队协作能力和沟通能力，能快速适应新环境。</p>",
        "<p>工作认真负责，善于学习新知识，不断提升专业技能。"
        "有较强的执行力和抗压能力，能按时保质完成工作任务。</p>",
        "<p>熟悉行业规范和操作流程，具备独立处理问题的能力。"
        "在工作中注重细节，追求卓越的工作品质。</p>",
        "<p>拥有多年的行业从业经验，熟悉各类办公软件和常用工具。"
        "善于与客户沟通，能够准确把握客户需求。</p>",
        "<p>具备扎实的专业基础和丰富的实践经验。"
        "乐于接受挑战，能在快节奏的工作环境中保持高效产出。</p>",
        "<p>毕业于知名高校相关专业，理论基础扎实。"
        "在校期间多次参与社会实践项目，积累了宝贵的工作经验。</p>",
    ]
    experience = random.choice(experience_templates)

    snapshot = {
        "realName": name,
        "gender": gender,
        "birthDate": birth_date,
        "education": education,
        "school": school,
        "skills": skills,
        "experience": experience,
    }
    return json.dumps(snapshot, ensure_ascii=False)


def _random_interview_location() -> str:
    """使用 datapool 中的面试地点模板生成随机面试地点字符串。"""
    template = random.choice(INTERVIEW_LOCATIONS)
    city = random.choice(CITIES)
    district = random.choice(DISTRICTS)
    street = random.choice(STREETS)
    company = random.choice(COMPANY_NAMES)
    floor = random.choice(FLOORS)
    room = random.choice(ROOMS)
    return template.format(
        city=city, district=district, street=street,
        company=company, building=company, floor=floor, room=room,
    )


def _format_dt(dt: datetime.datetime) -> str:
    """将 datetime 格式化为 MySQL 兼容的日期时间字符串。"""
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


def _random_future_datetime(create_time: datetime.datetime) -> datetime.datetime:
    """生成一个相对于 create_time 的未来时间（1-30 天后）。"""
    days = random.randint(1, 30)
    hours = random.randint(9, 18)
    minutes = random.randint(0, 59)
    return create_time + datetime.timedelta(days=days, hours=hours, minutes=minutes)


def _random_past_datetime(create_time: datetime.datetime) -> datetime.datetime:
    """生成一个介于 create_time 和 END_DT 之间的过去时间。"""
    return _random_datetime_between(create_time, END_DT)


def _pick_status() -> int:
    """按 STATUS_DISTRIBUTION 加权随机选取投递状态。"""
    statuses, weights = zip(*STATUS_DISTRIBUTION)
    return random.choices(statuses, weights=weights, k=1)[0]


def _build_enterprise_hr_map(
    hr_enterprise_map: Dict[int, int],
) -> Dict[int, List[int]]:
    """构建企业 ID → HR 用户 ID 列表的反向映射。

    Args:
        hr_enterprise_map: HR 用户 ID → 企业 ID 的映射

    Returns:
        企业 ID → HR 用户 ID 列表的映射
    """
    enterprise_hr_map: Dict[int, List[int]] = {}
    for hr_id, enterprise_id in hr_enterprise_map.items():
        enterprise_hr_map.setdefault(enterprise_id, []).append(hr_id)
    return enterprise_hr_map


def _build_application_record(
    app_id: int,
    task_id: int,
    applicant_id: int,
) -> dict:
    """构建单条投递记录的所有字段（写入 SQL 用）。

    Args:
        app_id: 投递记录自增 ID
        task_id: 岗位 ID
        applicant_id: 求职者用户 ID

    Returns:
        包含所有 APPLICATION_COLUMNS 字段值的字典
    """
    # 按统计模型选取状态
    status = _pick_status()

    # 生成创建时间（使用加权分布确保数据分布合理，支持趋势分析）
    create_time = weighted_random_time()
    update_time = create_time

    # 简历快照
    resume_snapshot = generate_resume_snapshot()

    # 附件 URL（15% 概率有值）
    attachment_url = (
        f"https://cdn.uniseek.com/resumes/{applicant_id}.pdf"
        if random.random() < 0.15
        else None
    )

    return {
        "id": app_id,
        "task_id": task_id,
        "applicant_id": applicant_id,
        "resume_snapshot": resume_snapshot,
        "attachment_url": attachment_url,
        "status": status,
        "hr_id": None,
        "interview_time": None,
        "interview_location": None,
        "reject_reason": None,
        "hr_note": None,
        "version": 0,
        "create_time": create_time,
        "update_time": update_time,
    }


def _populate_status_fields(
    record: dict,
    enterprise_hr_map: Dict[int, List[int]],
) -> None:
    """根据投递状态填充 HR 信息、面试时间、拒绝原因等条件字段。

    规则：
    - status >= 1 时，为该投递分配一个随机 HR
    - status == 1 时，填充未来的面试时间和地点
    - status in (2, 3, 5) 时，填充过去的面试时间和地点
    - status == 4 时，填充拒绝原因
    - status == 5 时，填充已完成备注

    Args:
        record: 投递记录字典（会被原地修改）
        enterprise_hr_map: 企业 ID → HR 用户 ID 列表的映射
    """
    status = record["status"]
    create_time = record["create_time"]

    # status >= 1 表示 HR 已处理过该投递
    if status >= 1 and enterprise_hr_map:
        enterprise_id = random.choice(list(enterprise_hr_map.keys()))
        record["hr_id"] = random.choice(enterprise_hr_map[enterprise_id])

    if status == 1:  # 待面试
        record["interview_time"] = _random_future_datetime(create_time)
        record["interview_location"] = _random_interview_location()
        record["hr_note"] = random.choice(HR_NOTES[1])

    elif status == 2:  # 面试通过
        record["interview_time"] = _random_past_datetime(create_time)
        record["interview_location"] = _random_interview_location()
        record["hr_note"] = random.choice(HR_NOTES[2])

    elif status == 3:  # 已录用
        record["interview_time"] = _random_past_datetime(create_time)
        record["interview_location"] = _random_interview_location()
        record["hr_note"] = random.choice(HR_NOTES[3])

    elif status == 4:  # 已淘汰
        record["reject_reason"] = random.choice(REJECT_REASONS)
        record["hr_note"] = random.choice(HR_NOTES[4])

    elif status == 5:  # 已完成
        record["interview_time"] = _random_past_datetime(create_time)
        record["interview_location"] = _random_interview_location()
        record["hr_note"] = random.choice(HR_NOTES[5])


def _record_to_row(record: dict) -> list:
    """将投递记录字典转换为 SQL 行值列表（按 APPLICATION_COLUMNS 顺序）。

    Args:
        record: 投递记录字典

    Returns:
        与 APPLICATION_COLUMNS 对应的值列表
    """
    return [
        record["id"],
        record["task_id"],
        record["applicant_id"],
        record["resume_snapshot"],
        record["attachment_url"],
        record["status"],
        record["hr_id"],
        _format_dt(record["interview_time"]) if record["interview_time"] is not None else None,
        record["interview_location"],
        record["reject_reason"],
        record["hr_note"],
        record["version"],
        _format_dt(record["create_time"]),
        _format_dt(record["update_time"]),
    ]


def _build_info(record: dict) -> dict:
    """从投递记录中提取下游生成器所需的摘要信息。

    Args:
        record: 投递记录字典

    Returns:
        包含下游所需字段的字典
    """
    return {
        "app_id": record["id"],
        "task_id": record["task_id"],
        "applicant_id": record["applicant_id"],
        "status": record["status"],
        "hr_id": record["hr_id"],
        "create_time": _format_dt(record["create_time"]),
        "interview_time": (
            _format_dt(record["interview_time"])
            if record["interview_time"] is not None
            else None
        ),
    }


# =============================================================================
# 主生成函数
# =============================================================================


def generate_applications(
    writer: SQLWriter,
    seeker_ids: List[int],
    task_ids: List[int],
    hr_enterprise_map: Dict[int, int],
    resume_id_map: Dict[int, int],
) -> Tuple[List[int], List[dict]]:
    """生成岗位投递数据并写入 SQL 文件。

    生成 80,000 条投递记录，覆盖 7,500 个求职者向 5,000 个岗位的投递行为。
    每名求职者平均投递约 10-11 个岗位，所有 (task_id, applicant_id) 对唯一。
    投递状态按统计分布模型分配（非状态机）。

    简历快照（resume_snapshot）为 JSON 字符串，包含投递时刻的简历信息。
    各状态的条件字段按业务规则填充（面试时间、面试地点、拒绝原因等）。

    Args:
        writer: SQLWriter 实例，用于写入 SQL 文件
        seeker_ids: 求职者用户 ID 列表（共 7,500 个）
        task_ids: 岗位 ID 列表（共 5,000 个）
        hr_enterprise_map: HR 用户 ID → 企业 ID 映射（字典长度 400）
        resume_id_map: 用户 ID → 简历 ID 映射（用于简历引用，当前保留备用）

    Returns:
        (application_ids, application_info_list)
        - application_ids: 生成的投递记录 ID 列表（长度 80,000）
        - application_info_list: 投递信息列表（长度 80,000），
          每个字典包含下游 notification_gen 和 chat_gen 所需的字段：
          app_id, task_id, applicant_id, status, hr_id, create_time, interview_time
    """
    # ---- 构建反向映射：企业 ID → HR 用户 ID 列表 ----
    enterprise_hr_map_rev = _build_enterprise_hr_map(hr_enterprise_map)

    # ---- 初始化 ----
    used_pairs: set = set()  # 用于保证 (task_id, applicant_id) 唯一
    application_ids: List[int] = []
    application_info_list: List[dict] = []

    writer.write_comment(f"投递表（{TARGET_APPLICATION_COUNT} 条记录）")
    writer.begin_insert("task_application", APPLICATION_COLUMNS)

    # ---- 第一阶段：按求职者分配投递 ----
    # 每名求职者投递 8-14 个岗位
    # 7,500 人 × 10.67 ≈ 80,000，自然接近目标
    for seeker_id in seeker_ids:
        if len(application_ids) >= TARGET_APPLICATION_COUNT:
            break

        # 每名求职者投递 8-14 个岗位
        num_apps = random.randint(8, 14)

        # 过滤出该求职者尚未投递的岗位
        available_tasks = [
            t for t in task_ids if (t, seeker_id) not in used_pairs
        ]
        if not available_tasks:
            continue

        actual_count = min(num_apps, len(available_tasks))
        chosen_tasks = random.sample(available_tasks, actual_count)

        for task_id in chosen_tasks:
            if len(application_ids) >= TARGET_APPLICATION_COUNT:
                break

            used_pairs.add((task_id, seeker_id))

            # 构建记录
            app_id = writer.next_id("task_application")
            record = _build_application_record(app_id, task_id, seeker_id)

            # 根据状态填充条件字段
            _populate_status_fields(record, enterprise_hr_map_rev)

            # 写入 SQL
            writer.add_row(_record_to_row(record))

            # 收集返回信息
            application_ids.append(app_id)
            application_info_list.append(_build_info(record))

    # ---- 第二阶段：若不足 80,000 条，补充投递 ----
    # 理论上 7,500 × 10.67 ≈ 80,000，但随机性可能导致略少，
    # 此处补充到目标值
    while len(application_ids) < TARGET_APPLICATION_COUNT:
        seeker_id = random.choice(seeker_ids)
        available_tasks = [
            t for t in task_ids if (t, seeker_id) not in used_pairs
        ]
        if not available_tasks:
            # 该求职者已投递所有岗位，换一个
            continue

        task_id = random.choice(available_tasks)
        used_pairs.add((task_id, seeker_id))

        app_id = writer.next_id("task_application")
        record = _build_application_record(app_id, task_id, seeker_id)
        _populate_status_fields(record, enterprise_hr_map_rev)

        writer.add_row(_record_to_row(record))

        application_ids.append(app_id)
        application_info_list.append(_build_info(record))

    # ---- 最终断言验证 ----
    generated = len(application_ids)
    assert generated == TARGET_APPLICATION_COUNT, (
        f"投递记录数必须为 {TARGET_APPLICATION_COUNT}，实际生成 {generated}"
    )
    assert len(used_pairs) == generated, (
        f"唯一投递对数 ({len(used_pairs)}) 与记录数 ({generated}) 不一致"
    )

    return application_ids, application_info_list
