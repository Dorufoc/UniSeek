# ==============================================================================
# UniSeek 兼职招聘平台 - 简历数据生成器
# ==============================================================================
# 生成 7,000 条简历记录，每位求职者对应一条简历。
# 包含性别、出生日期、学历、学校、技能、工作经历等字段。
# 技能存储为 JSON 数组字符串，工作经历存储为 HTML 格式。
#
# 依赖：
#   - config: START_DATE, END_DATE
#   - datapool: 中文数据池（学校、技能、经历模板等）
#   - sql_output: SQLWriter 批量写入器
# ==============================================================================

import datetime
import json
import random
import re
from typing import Dict, List, Tuple

from config import START_DATE, END_DATE
from datapool import (
    COMPANY_PREFIXES,
    COMPANY_SUFFIXES,
    EXPERIENCE_TEMPLATES,
    JOB_TITLES_BY_CATEGORY,
    SKILLS_BY_CATEGORY,
)
from sql_output import SQLWriter
from time_utils import weighted_random_time

# =============================================================================
# 常量定义
# =============================================================================

# 简历表列名
RESUME_COLUMNS = [
    "id", "user_id", "gender", "birth_date", "education", "school",
    "skills", "experience", "attachment_url", "is_published",
    "create_time", "update_time",
]

# 中国高校/职业学校名单（50 所）
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

# 时间范围（用于生成 create_time）
START_DT = datetime.datetime.strptime(START_DATE, "%Y-%m-%d")
END_DT = datetime.datetime.strptime(END_DATE, "%Y-%m-%d")
SPAN_SECONDS = int((END_DT - START_DT).total_seconds())

# 项目名池（用于经历模板中的 {project} 占位符）
_PROJECTS = [
    "客户管理系统", "电商平台", "数据分析平台", "移动应用",
    "企业官网", "ERP系统", "CRM系统", "智能客服系统",
    "在线教育平台", "餐饮管理系统", "物流调度系统", "库存管理系统",
    "社交电商小程序", "企业数据中台", "智能推荐系统",
]

# 技术栈池（用于经历模板中的 {tech} 占位符）
_TECH_STACKS = [
    "Spring Boot + Vue", "Python + Django", "React + Node.js",
    "Java + MySQL", "Flask + MongoDB", "Spring Cloud + Vue",
    "Go + React", "PHP + Laravel", "Spring Boot + React",
    "Vue + Spring Boot + MySQL",
]

# 科目池（用于经历模板中的 {subject} 占位符）
_SUBJECTS = ["数学", "英语", "语文", "物理", "化学", "生物", "历史"]

# 教学法池（用于经历模板中的 {method} 占位符）
_METHODS = ["游戏化教学", "翻转课堂", "情景教学", "分层教学", "项目式学习"]

# 产品池（用于经历模板中的 {product} 占位符）
_PRODUCTS = [
    "软件产品", "日用品", "食品", "电子产品", "办公用品",
    "服装", "化妆品", "家居用品", "数码产品", "母婴用品",
]

# 设计风格池（用于经历模板中的 {style} 占位符）
_STYLES = ["中式", "欧式", "现代简约", "森系", "复古", "ins风", "轻奢", "工业风"]

# =============================================================================
# 辅助函数
# =============================================================================


def get_education(birth_year: int) -> str:
    """根据出生年份返回合适的学历。

    规则：
        - 2002–2005 年出生 → 大专 / 本科
        - 1997–2001 年出生 → 本科 / 硕士
        - 1985–1996 年出生 → 本科 / 硕士 / 博士
    """
    if birth_year >= 2002:
        return random.choice(["大专", "本科"])
    elif birth_year >= 1997:
        return random.choice(["本科", "硕士"])
    else:
        return random.choice(["本科", "硕士", "博士"])


def _generate_company_name() -> str:
    """生成随机公司名称。"""
    cat = random.choice(list(COMPANY_PREFIXES.keys()))
    prefix = random.choice(COMPANY_PREFIXES[cat])
    suffix = random.choice(COMPANY_SUFFIXES)
    return prefix + suffix


def _generate_position() -> str:
    """生成随机职位名称。"""
    cat = random.choice(list(JOB_TITLES_BY_CATEGORY.keys()))
    return random.choice(JOB_TITLES_BY_CATEGORY[cat])


def generate_skills() -> str:
    """生成技能 JSON 数组字符串。

    从 1-3 个技能分类中随机选取共 3-8 个技能，
    技能不重复，最终以 JSON 数组形式返回。
    """
    category_names = list(SKILLS_BY_CATEGORY.keys())
    selected_categories = random.sample(category_names, random.randint(1, 3))

    selected_skills: List[str] = []
    for cat in selected_categories:
        skills = SKILLS_BY_CATEGORY[cat]
        k = random.randint(1, min(4, len(skills)))
        selected_skills.extend(random.sample(skills, k))

    # 去重
    selected_skills = list(set(selected_skills))

    # 限制在 3-8 个技能
    if len(selected_skills) > 8:
        selected_skills = random.sample(selected_skills, random.randint(3, 8))
    elif len(selected_skills) < 3:
        # 从所有技能中补充到至少 3 个
        all_skills = list({
            s for skills in SKILLS_BY_CATEGORY.values() for s in skills
        })
        pool = [s for s in all_skills if s not in selected_skills]
        if pool:
            needed = 3 - len(selected_skills)
            selected_skills.extend(random.sample(pool, min(needed, len(pool))))

    return json.dumps(selected_skills, ensure_ascii=False)


def _format_template_placeholder(match: re.Match) -> str:
    """根据占位符名称返回对应的随机值。"""
    key = match.group(1)

    if key == "company":
        return _generate_company_name()
    elif key == "position":
        return _generate_position()
    elif key == "project":
        return random.choice(_PROJECTS)
    elif key == "tech":
        return random.choice(_TECH_STACKS)
    elif key == "subject":
        return random.choice(_SUBJECTS)
    elif key == "method":
        return random.choice(_METHODS)
    elif key == "product":
        return random.choice(_PRODUCTS)
    elif key == "style":
        return random.choice(_STYLES)
    elif key == "num":
        return str(random.randint(10, 500))
    elif key == "num2":
        return str(random.randint(10, 200))
    elif key == "num3":
        return str(random.randint(5, 100))
    elif key == "num4":
        return str(random.randint(5, 100))
    elif key == "num5":
        return str(random.randint(5, 100))
    else:
        return str(random.randint(10, 999))


def generate_experience() -> str:
    """生成 HTML 格式的工作经历。

    从 datapool.EXPERIENCE_TEMPLATES 中随机选取一个模板，
    使用正则替换所有 {placeholder} 为随机生成的值。
    返回完整的 HTML 字符串。
    """
    cat = random.choice(list(EXPERIENCE_TEMPLATES.keys()))
    template = random.choice(EXPERIENCE_TEMPLATES[cat])
    experience = re.sub(r'\{(\w+)\}', _format_template_placeholder, template)
    return experience


def random_create_time() -> datetime.datetime:
    """生成加权分布的简历创建时间。

    使用 weighted_random_time() 确保数据分布合理，近期更密集。
    """
    return weighted_random_time()


def format_dt(dt: datetime.datetime) -> str:
    """将 datetime 格式化为 MySQL 兼容的日期时间字符串。"""
    return dt.strftime("%Y-%m-%d %H:%M:%S")


def generate_resumes(
    writer: SQLWriter,
    seeker_ids: List[int],
) -> Tuple[List[int], Dict[int, int]]:
    """生成简历数据并写入 SQL 文件。

    从 7,500 个求职者 ID 中随机选取 7,000 个，
    为每位求职者生成一条简历记录。

    Args:
        writer: SQLWriter 实例，用于批量写入 SQL 文件
        seeker_ids: 求职者用户 ID 列表（共 7,500 个）

    Returns:
        (resume_ids, resume_id_map) 二元组：
        - resume_ids: 生成的简历 ID 列表（7,000 个）
        - resume_id_map: 用户 ID → 简历 ID 的映射字典
    """
    # 从 7,500 个求职者中随机选取 7,000 个
    selected_users = random.sample(seeker_ids, 7000)

    writer.write_comment(f"简历表（{len(selected_users)} 条记录）")
    writer.begin_insert("resume", RESUME_COLUMNS)

    resume_ids: List[int] = []

    for user_id in selected_users:
        resume_id = writer.next_id("resume")
        resume_ids.append(resume_id)

        # --- 性别 ---
        gender = random.randint(0, 1)

        # --- 出生日期（1985–2005 年）---
        birth_year = random.randint(1985, 2005)
        birth_month = random.randint(1, 12)
        birth_day = random.randint(1, 28)
        birth_date = datetime.date(birth_year, birth_month, birth_day)

        # --- 学历（根据出生年份匹配）---
        education = get_education(birth_year)

        # --- 学校 ---
        school = random.choice(SCHOOLS)

        # --- 技能（JSON 数组字符串）---
        skills = generate_skills()

        # --- 工作经历（HTML 格式）---
        experience = generate_experience()

        # --- 附件 URL（20% 概率有值）---
        attachment_url = (
            f"https://cdn.uniseek.com/resumes/{user_id}.pdf"
            if random.random() < 0.2
            else None
        )

        # --- 发布状态（60% 已发布）---
        is_published = 1 if random.random() < 0.6 else 0

        # --- 创建时间 / 更新时间 ---
        create_time = random_create_time()
        max_update_offset = int((END_DT - create_time).total_seconds())
        if max_update_offset > 0:
            update_offset = random.randint(0, max_update_offset)
        else:
            update_offset = 0
        update_time = create_time + datetime.timedelta(seconds=update_offset)

        writer.add_row([
            resume_id,
            user_id,
            gender,
            str(birth_date),       # MySQL DATE 格式：YYYY-MM-DD
            education,
            school,
            skills,                 # JSON 数组字符串
            experience,             # HTML 字符串
            attachment_url,         # 可能为 NULL
            is_published,
            format_dt(create_time),
            format_dt(update_time),
        ])

    # 构建用户 ID → 简历 ID 的映射（用于下游生成器）
    resume_id_map: Dict[int, int] = {
        selected_users[i]: resume_ids[i] for i in range(len(resume_ids))
    }
    return resume_ids, resume_id_map
