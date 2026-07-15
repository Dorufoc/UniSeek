# ==============================================================================
# UniSeek 兼职招聘平台 - 企业数据生成器
# ==============================================================================
# 生成 400 条企业记录，每个 HR 用户对应一条企业记录（一对一关系）。
# 包含企业名称、统一社会信用代码、行业、地区、审核状态、公司简介等信息。

import random
import datetime
from typing import Dict, List, Tuple

from config import END_DATE, MAJOR_CITY_IDS
from sql_output import SQLWriter
from datapool import COMPANY_PREFIXES, COMPANY_SUFFIXES, COMPANY_DESCRIPTIONS

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

# 100+ 区县级地区 ID 列表（含去重，MAJOR_CITY_IDS 在前）
EXTRA_REGION_IDS = [
    # 北京全部区县
    110101, 110102, 110105, 110106, 110107, 110108, 110109,
    110111, 110112, 110113, 110114, 110115, 110116, 110117,
    # 上海全部区县
    310101, 310104, 310105, 310106, 310107, 310109, 310110,
    310112, 310113, 310114, 310115, 310116, 310117, 310118, 310120,
    # 广州
    440103, 440104, 440105, 440106, 440111, 440112, 440113,
    440114, 440115, 440116, 440117, 440118,
    # 深圳
    440303, 440304, 440305, 440306, 440307, 440308, 440309, 440310,
    # 南京
    320102, 320104, 320105, 320106, 320111, 320113, 320114,
    320115, 320116, 320117, 320118,
    # 苏州
    320505, 320506, 320507, 320508, 320509, 320581, 320582,
    320583, 320585,
    # 杭州
    330102, 330103, 330105, 330106, 330108, 330109, 330110,
    330111, 330112, 330113, 330182, 330183, 330185,
    # 成都
    510104, 510105, 510106, 510107, 510108, 510112, 510113,
    510114, 510115, 510116, 510117, 510118, 510181, 510182,
    510183, 510184,
    # 武汉
    420102, 420103, 420104, 420105, 420106, 420111, 420112,
    420113, 420114, 420115, 420116, 420117,
    # 重庆
    500101, 500102, 500103, 500104, 500105, 500106, 500107,
    500108, 500109, 500110, 500111, 500112, 500113, 500114,
    500115, 500116, 500117, 500118, 500119, 500120,
    # 长沙
    430102, 430103, 430104, 430105, 430111, 430112, 430121,
    430181, 430182,
    # 天津
    120101, 120102, 120103, 120104, 120105, 120106, 120110,
    120111, 120112, 120113, 120114, 120115, 120116, 120117,
    120118, 120119,
    # 沈阳
    210102, 210103, 210104, 210105, 210106, 210111, 210112,
    210113, 210114,
    # 青岛
    370202, 370203, 370205, 370211, 370212, 370213, 370214,
    370281, 370282, 370283, 370285,
    # 福州
    350102, 350103, 350104, 350105, 350111, 350112, 350121,
    350181, 350182,
    # 厦门
    350203, 350205, 350206, 350211, 350212, 350213,
    # 珠海
    440402, 440403, 440404,
    # 惠州
    441302, 441303, 441304, 441322, 441323, 441324,
    # 东莞
    441901, 441902, 441903,
    # 中山
    442000, 442001,
    # 哈尔滨
    230102, 230103, 230104, 230108, 230109, 230110, 230111,
    230112, 230113, 230123, 230124, 230125, 230126, 230127,
    230128, 230129,
    # 长春
    220102, 220103, 220104, 220105, 220106, 220112, 220122,
    220182, 220183,
    # 大连
    210202, 210203, 210204, 210211, 210212, 210213, 210214,
    210224, 210281, 210282, 210283,
    # 石家庄
    130102, 130104, 130105, 130107, 130108, 130109, 130110,
    130111, 130121, 130123, 130181, 130182, 130183, 130184,
    130185,
    # 郑州
    410102, 410103, 410104, 410105, 410106, 410107, 410108,
    410122, 410181, 410182, 410183, 410184, 410185,
    # 南宁
    450102, 450103, 450105, 450107, 450108, 450109, 450110,
    450111, 450112, 450113, 450114, 450115, 450123, 450124,
    450125, 450126, 450127,
    # 昆明
    530102, 530103, 530111, 530112, 530113, 530114, 530115,
    530124, 530125, 530126, 530127, 530128, 530129, 530181,
    # 西安
    610102, 610103, 610104, 610111, 610112, 610113, 610114,
    610115, 610116, 610117, 610118, 610122, 610124, 610125,
    610126,
    # 兰州
    620102, 620103, 620104, 620105, 620111, 620112, 620121,
    620122, 620123,
    # 南昌
    360102, 360103, 360104, 360111, 360112, 360113, 360121,
    360122, 360123, 360124, 360125, 360126,
    # 合肥
    340102, 340103, 340104, 340111, 340121, 340122, 340123,
    340124, 340181,
    # 太原
    140105, 140106, 140107, 140108, 140109, 140110, 140121,
    140122, 140123, 140181,
    # 呼和浩特
    150102, 150103, 150104, 150105, 150121, 150122, 150123,
    150124, 150125,
    # 海口
    460105, 460106, 460107, 460108,
    # 无锡
    320213, 320214, 320281, 320282,
    # 宁波
    330201, 330203, 330205, 330206, 330211, 330212, 330213,
    330225, 330226, 330281, 330282, 330283,
]

# 去重合并全量地区 ID 列表（MAJOR_CITY_IDS 在前，避免重复）
_ALL_REGION_IDS_SET = set(MAJOR_CITY_IDS)
ALL_REGION_IDS = list(MAJOR_CITY_IDS) + [
    r for r in EXTRA_REGION_IDS if r not in _ALL_REGION_IDS_SET
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
    """选取地区 ID。

    60% 概率从主要城市（MAJOR_CITY_IDS）中选取，
    40% 概率从全量 100+ 区县级 ID 列表中选取。

    Returns:
        地区 ID
    """
    if random.random() < 0.6:
        return random.choice(MAJOR_CITY_IDS)
    else:
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

def generate_enterprises(writer: SQLWriter, hr_ids: List[int]) -> Tuple[List[int], Dict[int, int]]:
    """生成企业数据并写入 SQL 文件。

    每个 HR 用户对应一条企业记录（一对一关系），
    共 len(hr_ids) 条记录。

    企业数据包含：名称、信用代码、行业、地区、审核状态、简介等。

    Args:
        writer: SQLWriter 实例，用于输出 SQL
        hr_ids: HR 用户 ID 列表（长度 400）

    Returns:
        (enterprise_ids, hr_enterprise_map) 二元组：
        - enterprise_ids: 企业 ID 列表，顺序与 hr_ids 一一对应
        - hr_enterprise_map: HR 用户 ID → 企业 ID 的映射字典
    """
    total = len(hr_ids)
    used_credit_codes: set = set()
    enterprise_ids: List[int] = []

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

        # 8. 创建时间（使用 beta 分布确保偏向中后期，与用户注册时间分布相容）
        t = random.betavariate(2, 3)
        create_time = START_DT + datetime.timedelta(
            seconds=int(SPAN_SECONDS * t)
        )
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

    # 构建 HR 用户 ID → 企业 ID 的映射（用于下游生成器）
    hr_enterprise_map: Dict[int, int] = {
        hr_id: eid for hr_id, eid in zip(hr_ids, enterprise_ids)
    }
    return enterprise_ids, hr_enterprise_map
