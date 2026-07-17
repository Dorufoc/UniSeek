# ==============================================================================
# UniSeek 兼职招聘平台 - 企业数据生成器
# ==============================================================================
# 生成 400 条企业记录，每个 HR 用户对应一条企业记录（一对一关系）。
# 包含企业名称、统一社会信用代码、行业、地区、审核状态、公司简介等信息。

import random
import datetime
from typing import Dict, List, Tuple

from config import END_DATE, ALL_REGION_IDS
from sql_output import SQLWriter
from datapool import COMPANY_PREFIXES, COMPANY_SUFFIXES, COMPANY_DESCRIPTIONS
from time_utils import weighted_random_time

# =============================================================================
# 常量定义
# =============================================================================

# 企业表列名
ENTERPRISE_COLUMNS = [
    "id", "user_id", "company_name", "credit_code", "license_img_url",
    "industry", "region_id", "description", "audit_status",
    "audit_time", "create_time", "update_time",
]

# 行业加权分布（短名称，用于选择前缀池）
INDUSTRIES_WEIGHTED: List[Tuple[str, float]] = [
    ("餐饮", 0.20),
    ("物流", 0.12),
    ("IT", 0.15),
    ("教育", 0.12),
    ("设计", 0.10),
    ("家政", 0.08),
    ("美容", 0.08),
    ("其他", 0.15),
]

# 短名称 → datapool 前缀池键名映射
SHORT_TO_PREFIX_KEY = {
    "餐饮": "餐饮",
    "物流": "物流",
    "IT": "IT互联网",
    "教育": "教育培训",
    "设计": "设计创作",
    "家政": "家政服务",
    "美容": "美容美发",
    "其他": "其他",
}

# 短名称 → 数据库行业名称映射
SHORT_TO_DB_INDUSTRY = {
    "餐饮": "餐饮服务",
    "物流": "物流快递",
    "IT": "IT互联网",
    "教育": "教育培训",
    "设计": "设计创意",
    "家政": "家政服务",
    "美容": "美容美发",
    "其他": "其他",
}

# 信用代码基（9 位：登记机关代码 + 行政区划 + 组织类别）
CREDIT_CODE_BASE = "91440101M"

# 时间范围
END_DT = datetime.datetime.strptime(END_DATE, "%Y-%m-%d")
START_DT = datetime.datetime(2010, 1, 1)
SPAN_SECONDS = int((END_DT - START_DT).total_seconds())

# 城市名称列表（用于公司简介模板）
CITIES = [
    "北京", "上海", "广州", "深圳", "杭州", "南京", "苏州", "成都",
    "武汉", "重庆", "长沙", "天津", "西安", "郑州", "青岛", "沈阳",
    "大连", "宁波", "厦门", "福州", "合肥", "昆明", "贵阳", "南宁",
    "哈尔滨", "长春", "石家庄", "太原", "南昌", "兰州", "乌鲁木齐",
    "呼和浩特", "海口", "银川", "西宁", "佛山", "东莞",
    "无锡", "常州", "温州", "绍兴", "嘉兴", "泉州", "烟台", "珠海",
]

# 创始人姓氏池
FOUNDER_SURNAMES = [
    "张", "王", "李", "刘", "陈", "杨", "黄", "吴", "周", "赵",
    "孙", "马", "朱", "徐", "胡", "郭", "林", "何", "高", "罗",
]

# 企业文化标语池
MOTTOES = [
    "诚信为本，服务至上", "品质第一，客户为先", "创新驱动，追求卓越",
    "专业专注，用心服务", "共创价值，共享未来", "以诚取信，以质取胜",
    "客户第一，员工第二", "务实创新，合作共赢", "精益求精，止于至善",
    "科技引领，服务社会", "以人为本，以德为先", "匠心精神，品质服务",
]

# 高校名称池
UNIVERSITIES = [
    "北京大学", "清华大学", "复旦大学", "上海交通大学", "浙江大学",
    "南京大学", "武汉大学", "华中科技大学", "中山大学", "四川大学",
    "西安交通大学", "哈尔滨工业大学", "北京理工大学", "同济大学",
]

# 知名企业客户池
FAMOUS_CLIENTS = [
    "腾讯", "阿里巴巴", "百度", "华为", "京东", "小米", "美团",
    "字节跳动", "网易", "拼多多", "比亚迪", "格力", "海尔",
]

# 产品/服务名称池
PRODUCTS = [
    "餐饮配送", "物流运输", "技术服务", "教育咨询", "设计服务",
    "家政服务", "美容护理", "贸易服务", "广告策划", "咨询服务",
]

# 区域后缀池
DISTRICTS = [
    "东城区", "朝阳区", "浦东新区", "南山区", "西湖区",
    "高新区", "天府新区", "洪山区", "建邺区", "工业园区",
]

# 设计风格池
STYLES = [
    "现代简约", "新中式", "田园自然", "轻奢风格", "极简主义",
    "复古风格", "北欧风格", "日式风格", "工业风格",
]




# =============================================================================
# 辅助函数
# =============================================================================

def _pick_industry() -> Tuple[str, str]:
    """根据 INDUSTRIES_WEIGHTED 加权随机选取行业。

    Returns:
        (短名称, 数据库行业名称) 二元组
    """
    items, weights = zip(*INDUSTRIES_WEIGHTED)
    short_name = random.choices(items, weights=weights, k=1)[0]
    db_name = SHORT_TO_DB_INDUSTRY[short_name]
    return short_name, db_name


def _generate_company_name(short_name: str) -> str:
    """根据行业短名称生成公司名称。

    从对应行业前缀池中随机选取前缀，拼接随机后缀。

    Args:
        short_name: 行业短名称（如 "餐饮"、"IT"）

    Returns:
        完整的公司名称（如 "味美滋餐饮管理有限公司"）
    """
    prefix_key = SHORT_TO_PREFIX_KEY[short_name]
    prefixes = COMPANY_PREFIXES[prefix_key]
    prefix = random.choice(prefixes)
    suffix = random.choice(COMPANY_SUFFIXES)
    return prefix + suffix


def _generate_credit_code(used_codes: set) -> str:
    """生成唯一的 18 位统一社会信用代码。

    格式：9 位基码（CREDIT_CODE_BASE）+ 9 位随机字母数字

    Args:
        used_codes: 已使用的信用代码集合，用于避免重复

    Returns:
        18 位唯一信用代码字符串
    """
    chars = "ABCDEFGHJKLMNPQRSTUVWXYZ0123456789"
    while True:
        suffix = "".join(random.choice(chars) for _ in range(9))
        code = CREDIT_CODE_BASE + suffix
        if code not in used_codes:
            used_codes.add(code)
            return code


def _pick_region_id() -> int:
    """从 ALL_REGION_IDS 中随机选取地区 ID。

    ALL_REGION_IDS 在 config.py 中定义，包含约 160 个加权区县级地区 ID，
    覆盖全国 34 个省级行政区，权重由出现次数体现。

    Returns:
        地区 ID
    """
    return random.choice(ALL_REGION_IDS)


def _random_audit_status() -> Tuple[int, datetime.datetime]:
    """随机生成审核状态和审核时间。

    分布：
    - 80% 已认证（status=1），附带随机审核时间
    - 15% 待审核（status=0），审核时间为 NULL
    - 5% 已拒绝（status=2），审核时间为 NULL

    Returns:
        (状态码, 审核时间或 None)
    """
    r = random.random()
    if r < 0.80:
        status = 1
        audit_time = _random_datetime_between(START_DT, END_DT)
        return status, audit_time
    elif r < 0.95:
        return 0, None
    else:
        return 2, None


def _random_datetime_between(
    start: datetime.datetime,
    end: datetime.datetime,
) -> datetime.datetime:
    """在 [start, end] 之间均匀随机生成一个时间点。

    Args:
        start: 起始时间
        end: 结束时间

    Returns:
        随机时间点
    """
    diff = int((end - start).total_seconds())
    if diff <= 0:
        return start
    return start + datetime.timedelta(seconds=random.randint(0, diff))


def _format_dt(dt) -> str:
    """将 datetime 格式化为 MySQL 兼容的时间字符串。

    Args:
        dt: datetime 对象或 None

    Returns:
        格式化字符串或 None
    """
    if dt is None:
        return None
    return dt.strftime("%Y-%m-%d %H:%M:%S")


def _generate_description(company_name: str, short_industry: str) -> str:
    """使用 datapool 中的 COMPANY_DESCRIPTIONS 模板生成公司简介。

    随机选取一个模板，并用公司相关信息填充其中的占位符。

    Args:
        company_name: 企业名称
        short_industry: 行业短名称

    Returns:
        填充后的公司简介文本
    """
    template = random.choice(COMPANY_DESCRIPTIONS)
    db_industry = SHORT_TO_DB_INDUSTRY.get(short_industry, "其他")
    district = random.choice(DISTRICTS)

    placeholders = {
        "{company}": company_name,
        "{year}": str(random.randint(2000, 2023)),
        "{year2}": str(random.randint(2, 15)),
        "{city}": random.choice(CITIES),
        "{district}": district,
        "{num}": str(random.randint(10, 999)),
        "{num2}": str(random.randint(100, 9999)),
        "{num3}": str(random.randint(10000, 999999)),
        "{num4}": str(random.randint(5, 95)),
        "{industry}": db_industry,
        "{capital}": str(random.randint(50, 5000)),
        "{area}": str(random.randint(100, 5000)),
        "{age}": str(random.randint(22, 45)),
        "{founder}": random.choice(FOUNDER_SURNAMES) + "先生",
        "{revenue}": str(random.randint(100, 10000)),
        "{value}": str(random.randint(500, 50000)),
        "{univ}": random.choice(UNIVERSITIES),
        "{product}": random.choice(PRODUCTS),
        "{client1}": random.choice(FAMOUS_CLIENTS),
        "{client2}": random.choice(FAMOUS_CLIENTS),
        "{motto}": random.choice(MOTTOES),
        "{style}": random.choice(STYLES),
    }

    result = template
    for key, value in placeholders.items():
        result = result.replace(key, value)
    return result


# =============================================================================
# 主生成函数
# =============================================================================

def generate_enterprises(
    writer: SQLWriter, hr_ids: List[int],
) -> Tuple[List[int], Dict[int, int], Dict[int, str], Dict[int, int]]:
    """生成企业数据并写入 SQL 文件。

    每个 HR 用户对应一条企业记录（一对一关系），
    共 len(hr_ids) 条记录。

    企业数据包含：名称、信用代码、行业、地区、审核状态、简介等。

    Args:
        writer: SQLWriter 实例，用于输出 SQL
        hr_ids: HR 用户 ID 列表（长度 400）

    Returns:
        (enterprise_ids, hr_enterprise_map, enterprise_industry_map, enterprise_audit_map) 四元组：
        - enterprise_ids: 企业 ID 列表，顺序与 hr_ids 一一对应
        - hr_enterprise_map: HR 用户 ID → 企业 ID 的映射字典
        - enterprise_industry_map: 企业 ID → 行业名称的映射字典
        - enterprise_audit_map: 企业 ID → 审核状态（0/1/2）的映射字典
    """
    total = len(hr_ids)
    used_credit_codes: set = set()
    enterprise_ids: List[int] = []
    enterprise_industry_map: Dict[int, str] = {}
    enterprise_audit_map: Dict[int, int] = {}

    writer.write_comment(f"企业表（{total} 条记录）")
    writer.begin_insert("enterprise", ENTERPRISE_COLUMNS)

    for user_id in hr_ids:
        eid = writer.next_id("enterprise")
        enterprise_ids.append(eid)

        # 1. 选取行业
        short_industry, db_industry = _pick_industry()

        # 2. 生成企业名称
        company_name = _generate_company_name(short_industry)

        # 3. 生成唯一信用代码
        credit_code = _generate_credit_code(used_credit_codes)

        # 4. 许可证图片 URL（示例链接）
        license_img_url = f"https://cdn.uniseek.com/license/{credit_code}.jpg"

        # 5. 选取地区
        region_id = _pick_region_id()

        # 6. 生成公司简介
        description = _generate_description(company_name, short_industry)

        # 7. 审核状态（80% 通过、15% 待审、5% 拒绝）
        audit_status, audit_time = _random_audit_status()

        # 8. 创建时间（使用加权分布确保数据分布合理，支持趋势分析）
        create_time = weighted_random_time()
        update_time = create_time

        writer.add_row([
            eid,
            user_id,
            company_name,
            credit_code,
            license_img_url,
            db_industry,
            region_id,
            description,
            audit_status,
            _format_dt(audit_time),
            _format_dt(create_time),
            _format_dt(update_time),
        ])

        enterprise_industry_map[eid] = db_industry
        enterprise_audit_map[eid] = audit_status

    # 构建 HR 用户 ID → 企业 ID 的映射（用于下游生成器）
    hr_enterprise_map: Dict[int, int] = {
        hr_id: eid for hr_id, eid in zip(hr_ids, enterprise_ids)
    }
    return enterprise_ids, hr_enterprise_map, enterprise_industry_map, enterprise_audit_map
