# ==============================================================================
# UniSeek 兼职招聘平台 - 用户数据生成器
# ==============================================================================
# 生成 8,000 条用户记录和 7,000 条实名认证记录。
# 用户角色分布：7,500 求职者 + 400 HR + 98 管理员 + 2 超级管理员
# 实名认证覆盖约 87% 的求职者和 HR。

import random
import datetime
from typing import Dict, List, Tuple

from faker import Faker

from config import (
    REAL_NAME_AUTH_COUNT,
    ADMIN_PHONE_START,
    ADMIN_PHONE_END,
    DEFAULT_PASSWORD,
    ADMIN_PASSWORD,
)
from crypto import generate_salt, encrypt_password
from sql_output import SQLWriter
from datapool import SURNAMES, MALE_GIVEN_NAMES, FEMALE_GIVEN_NAMES
from time_utils import weighted_random_time

# =============================================================================
# 常量定义
# =============================================================================

# 用户表列名
USER_COLUMNS = [
    "id", "phone", "email", "password", "salt", "nickname", "avatar_url",
    "role", "credit_score", "status", "last_login_time", "create_time", "update_time",
]

# 实名认证表列名
REAL_NAME_AUTH_COLUMNS = [
    "id", "user_id", "real_name", "id_card", "status", "auth_time",
    "create_time", "update_time",
]

# 有效手机号前缀（中国移动/联通/电信号段）
PHONE_PREFIXES = ["13", "15", "17", "18", "19"]

# 时间范围
START_DT = datetime.datetime(2010, 1, 1)
END_DT = datetime.datetime(2026, 7, 15)
SPAN_SECONDS = int((END_DT - START_DT).total_seconds())

# 角色常量
ROLE_SEEKER = 0
ROLE_HR = 1
ROLE_ADMIN = 9
ROLE_SUPER_ADMIN = 99

# 数量
ADMIN_COUNT = 98
SUPER_ADMIN_COUNT = 2
SEEKER_COUNT = 7500
HR_COUNT = 400
ADMIN_TOTAL = ADMIN_COUNT + SUPER_ADMIN_COUNT
REGULAR_TOTAL = SEEKER_COUNT + HR_COUNT

# =============================================================================
# 汉字转拼音映射表（覆盖 datapool 中所有姓氏和名字用字）
# =============================================================================

_CT2PY = {
    # ---- 姓氏 ----
    "王": "wang", "李": "li", "张": "zhang", "刘": "liu", "陈": "chen",
    "杨": "yang", "赵": "zhao", "黄": "huang", "周": "zhou", "吴": "wu",
    "徐": "xu", "孙": "sun", "马": "ma", "胡": "hu", "朱": "zhu",
    "郭": "guo", "何": "he", "罗": "luo", "高": "gao", "林": "lin",
    "梁": "liang", "宋": "song", "唐": "tang", "郑": "zheng", "谢": "xie",
    "韩": "han", "冯": "feng", "于": "yu", "董": "dong", "萧": "xiao",
    "程": "cheng", "曹": "cao", "袁": "yuan", "邓": "deng", "许": "xu",
    "傅": "fu", "沈": "shen", "曾": "zeng", "彭": "peng", "吕": "lv",
    "苏": "su", "卢": "lu", "蒋": "jiang", "蔡": "cai", "贾": "jia",
    "丁": "ding", "魏": "wei", "薛": "xue", "叶": "ye", "阎": "yan",
    "余": "yu", "潘": "pan", "杜": "du", "戴": "dai", "夏": "xia",
    "钟": "zhong", "汪": "wang", "田": "tian", "任": "ren", "姜": "jiang",
    "范": "fan", "方": "fang", "石": "shi", "姚": "yao", "谭": "tan",
    "廖": "liao", "邹": "zou", "熊": "xiong", "金": "jin", "陆": "lu",
    "郝": "hao", "孔": "kong", "白": "bai", "崔": "cui", "康": "kang",
    "毛": "mao", "邱": "qiu", "秦": "qin", "江": "jiang", "史": "shi",
    "顾": "gu", "侯": "hou", "邵": "shao", "孟": "meng", "龙": "long",
    "万": "wan", "段": "duan", "雷": "lei", "钱": "qian", "汤": "tang",
    "尹": "yin", "黎": "li", "易": "yi", "常": "chang", "武": "wu",
    "乔": "qiao", "贺": "he", "赖": "lai", "龚": "gong", "文": "wen",
    "卫": "wei", "庞": "pang", "施": "shi", "付": "fu", "甘": "gan",
    "阮": "ruan", "屈": "qu", "宁": "ning", "晏": "yan", "柯": "ke",
    "茅": "mao", "池": "chi", "卓": "zhuo", "梅": "mei", "翁": "weng",
    "仇": "qiu", "焦": "jiao", "卞": "bian", "冷": "leng", "藏": "zang",
    "巫": "wu", "敖": "ao", "幸": "xing", "郜": "gao", "鞠": "ju",
    "乜": "nie",
    # ---- 男性名字用字 ----
    "伟": "wei", "强": "qiang", "磊": "lei", "军": "jun", "勇": "yong",
    "杰": "jie", "涛": "tao", "明": "ming", "超": "chao", "波": "bo",
    "辉": "hui", "刚": "gang", "健": "jian", "飞": "fei", "鹏": "peng",
    "斌": "bin", "峰": "feng", "浩": "hao", "亮": "liang", "华": "hua",
    "志": "zhi", "国": "guo", "海": "hai", "俊": "jun", "豪": "hao",
    "翰": "han", "昊": "hao", "宇": "yu", "轩": "xuan", "博": "bo",
    "子": "zi", "涵": "han", "天": "tian", "佑": "you", "嘉": "jia",
    "懿": "yi", "瑞": "rui", "霖": "lin", "哲": "zhe", "泽": "ze",
    "思": "si", "远": "yuan", "瀚": "han", "睿": "rui", "渊": "yuan",
    "晟": "sheng", "修": "xiu", "昕": "xin", "恒": "heng", "景": "jing",
    "行": "xing", "柏": "bai", "然": "ran", "鸿": "hong", "煊": "xuan",
    "瑾": "jin", "瑜": "yu", "楷": "kai", "烨": "ye", "雨": "yu",
    "逸": "yi", "凡": "fan", "云": "yun", "熙": "xi", "晨": "chen",
    "奕": "yi", "辰": "chen", "铭": "ming", "弘": "hong", "楠": "nan",
    "乐": "le", "翊": "yi", "承": "cheng", "旭": "xu", "尧": "yao",
    "洋": "yang", "振": "zhen", "骞": "qian", "建": "jian", "航": "hang",
    "致": "zhi",
    # ---- 女性名字用字 ----
    "芳": "fang", "娟": "juan", "敏": "min", "静": "jing", "丽": "li",
    "艳": "yan", "燕": "yan", "霞": "xia", "秀": "xiu", "英": "ying",
    "美": "mei", "兰": "lan", "凤": "feng", "玉": "yu", "珍": "zhen",
    "桂": "gui", "淑": "shu", "琪": "qi", "欣": "xin", "怡": "yi",
    "诗": "shi", "桐": "tong", "萱": "xuan", "语": "yu", "嫣": "yan",
    "彤": "tong", "晓": "xiao", "梦": "meng", "雪": "xue", "婷": "ting",
    "晴": "qing", "梓": "zi", "紫": "zi", "雯": "wen", "心": "xin",
    "可": "ke", "雅": "ya", "琴": "qin", "若": "ruo", "曦": "xi",
    "芷": "zhi", "婉": "wan", "韵": "yun", "薇": "wei", "慧": "hui",
    "倩": "qian", "舒": "shu", "瑶": "yao", "羽": "yu", "馨": "xin",
    "艺": "yi", "婧": "jing", "颖": "ying", "惠": "hui", "茜": "xi",
    "凌": "ling", "蕊": "rui", "芸": "yun", "歆": "xin", "予": "yu",
    "沛": "pei", "珊": "shan", "洛": "luo", "沁": "qin", "芊": "qian",
    "玥": "yue", "希": "xi", "恩": "en", "衿": "jin", "玲": "ling",
    "琳": "lin", "儿": "er",
}

# =============================================================================
# Faker 实例（用于生成中国身份证号）
# =============================================================================

_fake = Faker("zh_CN")


# =============================================================================
# 辅助函数
# =============================================================================

def _name_to_pinyin(name: str) -> str:
    """将中文姓名转为拼音（用于邮箱前缀）。"""
    result = []
    for ch in name:
        py = _CT2PY.get(ch)
        if py:
            result.append(py)
    return "".join(result) if result else "user"


def _pick_surname() -> str:
    """从带权重的姓氏列表中随机选取一个姓氏。"""
    items, weights = zip(*SURNAMES)
    return random.choices(items, weights=weights, k=1)[0]


def random_name() -> str:
    """生成随机中文姓名（姓氏 + 名字，男女各半）。"""
    surname = _pick_surname()
    is_male = random.random() < 0.5
    given = random.choice(MALE_GIVEN_NAMES if is_male else FEMALE_GIVEN_NAMES)
    return surname + given


def random_create_time() -> datetime.datetime:
    """生成加权分布的用户注册时间。

    使用 weighted_random_time() 确保数据在 2010-2026 年间分布合理，
    近期数据更密集，以支持仪表盘趋势分析。
    """
    return weighted_random_time()


def random_regular_phone(used_phones: set) -> int:
    """生成不重复的普通用户手机号。

    格式：13x / 15x / 17x / 18x / 19x + 8 位数字，
    避开管理员保留区间 13900000001–13900000299。
    """
    while True:
        prefix = random.choice(PHONE_PREFIXES)
        third = str(random.randint(0, 9))
        remaining = "".join(str(random.randint(0, 9)) for _ in range(8))
        phone_str = prefix + third + remaining
        phone = int(phone_str)
        if ADMIN_PHONE_START <= phone <= ADMIN_PHONE_END:
            continue
        if phone in used_phones:
            continue
        used_phones.add(phone)
        return phone


def generate_email(nickname: str, used_emails: set) -> str:
    """生成唯一邮箱地址。

    格式：{拼音}{随机数字}@uniseek.com
    """
    base = _name_to_pinyin(nickname)
    if not base:
        base = "user"
    MAX_ATTEMPTS = 100000
    for _ in range(MAX_ATTEMPTS):
        suffix = random.randint(100, 99999)
        email = f"{base}{suffix}@uniseek.com"
        if email not in used_emails:
            used_emails.add(email)
            return email
    # 极端情况下的兜底：用计数器强制唯一
    email = f"{base}{len(used_emails) + 1}@uniseek.com"
    used_emails.add(email)
    return email


def random_credit_score() -> int:
    """生成信用分：95% 为 100，5% 为 60–99 之间的随机值。"""
    return 100 if random.random() < 0.95 else random.randint(60, 99)


def random_datetime_between(start: datetime.datetime, end: datetime.datetime) -> datetime.datetime:
    """在 [start, end] 之间随机生成一个时间点。"""
    diff = int((end - start).total_seconds())
    if diff <= 0:
        return start
    return start + datetime.timedelta(seconds=random.randint(0, diff))


def format_dt(dt: datetime.datetime) -> str:
    """将 datetime 格式化为 MySQL 兼容的字符串。"""
    return dt.strftime("%Y-%m-%d %H:%M:%S")


def build_password(role: int) -> Tuple[str, str]:
    """根据角色生成加密密码和盐值。"""
    plain = DEFAULT_PASSWORD if role in (ROLE_SEEKER, ROLE_HR) else ADMIN_PASSWORD
    salt = generate_salt()
    pwd = encrypt_password(plain, salt)
    return pwd, salt


# =============================================================================
# 主生成函数
# =============================================================================

def generate_users(writer: SQLWriter) -> Tuple[List[int], List[int], List[int], List[int]]:
    """生成用户数据和实名认证数据。

    Args:
        writer: SQLWriter 实例，用于输出 SQL

    Returns:
        (all_user_ids, seeker_ids, hr_ids, admin_ids) 四元组：
        - all_user_ids: 所有用户的 ID 列表
        - seeker_ids:   求职者角色 (role=0) 的用户 ID 列表
        - hr_ids:       HR 角色 (role=1) 的用户 ID 列表
        - admin_ids:    管理员角色 (role=9) + 超级管理员 (role=99) 的用户 ID 列表
    """
    # =========================================================================
    # 第一阶段：在内存中生成所有用户记录
    # =========================================================================

    used_phones: set = set()  # 记录已用的手机号
    used_emails: set = set()  # 记录已用的邮箱
    all_users: list = []      # 用户记录列表

    # --- 1a. 生成管理员用户（98 个管理员 + 2 个超级管理员）---
    # 管理员手机号从 13900000001 开始顺序分配
    next_admin_phone = ADMIN_PHONE_START

    for _ in range(ADMIN_COUNT):
        role = ROLE_ADMIN
        phone = next_admin_phone
        next_admin_phone += 1
        used_phones.add(phone)

        nickname = random_name()
        create_time = random_create_time()
        pwd, salt = build_password(role)

        user = {
            "phone": phone,
            "email": generate_email(nickname, used_emails),
            "password": pwd,
            "salt": salt,
            "nickname": nickname,
            "avatar_url": None,
            "role": role,
            "credit_score": random_credit_score(),
            "create_time": create_time,
            "update_time": create_time,
        }
        all_users.append(user)

    for _ in range(SUPER_ADMIN_COUNT):
        role = ROLE_SUPER_ADMIN
        phone = next_admin_phone
        next_admin_phone += 1
        used_phones.add(phone)

        nickname = random_name()
        create_time = random_create_time()
        pwd, salt = build_password(role)

        user = {
            "phone": phone,
            "email": generate_email(nickname, used_emails),
            "password": pwd,
            "salt": salt,
            "nickname": nickname,
            "avatar_url": None,
            "role": role,
            "credit_score": random_credit_score(),
            "create_time": create_time,
            "update_time": create_time,
        }
        all_users.append(user)

    # --- 1b. 生成普通用户（7,500 个求职者 + 400 个 HR）---
    # 先构建角色列表并打乱顺序
    regular_roles = [ROLE_SEEKER] * SEEKER_COUNT + [ROLE_HR] * HR_COUNT
    random.shuffle(regular_roles)

    for role in regular_roles:
        phone = random_regular_phone(used_phones)
        nickname = random_name()
        create_time = random_create_time()
        pwd, salt = build_password(role)

        user = {
            "phone": phone,
            "email": generate_email(nickname, used_emails),
            "password": pwd,
            "salt": salt,
            "nickname": nickname,
            "avatar_url": None,
            "role": role,
            "credit_score": random_credit_score(),
            "create_time": create_time,
            "update_time": create_time,
        }
        all_users.append(user)

    # =========================================================================
    # 第二阶段：按注册时间分配 status 和 last_login_time
    # =========================================================================
    # 最早注册的 2% 用户设为禁用状态，最早注册的 30% 用户从未登录过

    all_users.sort(key=lambda u: u["create_time"])
    total = len(all_users)

    disabled_count = int(total * 0.02)
    null_login_count = int(total * 0.3)

    for i in range(total):
        # status：最早 2% 禁用，其余正常
        all_users[i]["status"] = 0 if i < disabled_count else 1

        # last_login_time：最早 30% 从未登录，其余随机
        if i < null_login_count:
            all_users[i]["last_login_time"] = None
        else:
            all_users[i]["last_login_time"] = random_datetime_between(
                all_users[i]["create_time"], END_DT
            )

    # 打乱顺序后再写入 SQL，使输出分布更自然
    random.shuffle(all_users)

    # 确保 id=1 为超级管理员（role=99），id=2 为系统管理员（role=9）
    super_admin_idx = next(i for i, u in enumerate(all_users) if u["role"] == ROLE_SUPER_ADMIN)
    admin_idx = next(i for i, u in enumerate(all_users) if u["role"] == ROLE_ADMIN)

    sa = all_users[super_admin_idx]
    sa["phone"] = 13999999999
    sa["nickname"] = "超级管理员"
    pwd_123456, salt_123456 = encrypt_password("123456", "e417419cf2e5194657477ed259440d3e"), "e417419cf2e5194657477ed259440d3e"
    sa["password"] = pwd_123456
    sa["salt"] = salt_123456

    a = all_users[admin_idx]
    a["phone"] = 13999990001
    a["nickname"] = "系统管理员"
    pwd_123456_2, salt_123456_2 = encrypt_password("123456", "7973add9a398e87ab80e7f14c7bfdc1f"), "7973add9a398e87ab80e7f14c7bfdc1f"
    a["password"] = pwd_123456_2
    a["salt"] = salt_123456_2

    for idx in sorted([super_admin_idx, admin_idx], reverse=True):
        all_users.pop(idx)
    all_users.insert(0, a)
    all_users.insert(0, sa)

    # =========================================================================
    # 第三阶段：写入用户数据到 SQL
    # =========================================================================

    writer.write_comment(f"用户表（{total} 条记录）")
    writer.begin_insert("user", USER_COLUMNS)

    all_user_ids: List[int] = []
    seeker_ids: List[int] = []
    hr_ids: List[int] = []
    admin_ids: List[int] = []
    user_name_map: Dict[int, str] = {}

    # phone -> user_id 映射（用于实名认证阶段查找 uid）
    phone_to_uid: dict = {}

    for user in all_users:
        uid = writer.next_id("user")
        all_user_ids.append(uid)
        user_name_map[uid] = user["nickname"]
        phone_to_uid[user["phone"]] = uid

        role = user["role"]
        if role == ROLE_SEEKER:
            seeker_ids.append(uid)
        elif role == ROLE_HR:
            hr_ids.append(uid)
        else:
            admin_ids.append(uid)

        last_login = (
            format_dt(user["last_login_time"])
            if user["last_login_time"] is not None
            else None
        )

        writer.add_row([
            uid,
            user["phone"],
            user["email"],
            user["password"],
            user["salt"],
            user["nickname"],
            user["avatar_url"],  # NULL
            role,
            user["credit_score"],
            user["status"],
            last_login,
            format_dt(user["create_time"]),
            format_dt(user["update_time"]),
        ])

    # =========================================================================
    # 第四阶段：生成实名认证数据
    # =========================================================================
    # 从所有求职者和 HR 中随机选取约 7,000 人进行实名认证

    eligible_users = [
        u for u in all_users if u["role"] in (ROLE_SEEKER, ROLE_HR)
    ]
    selected_count = min(REAL_NAME_AUTH_COUNT, len(eligible_users))
    selected_users = random.sample(eligible_users, selected_count)

    writer.write_comment(f"实名认证表（{selected_count} 条记录）")
    writer.begin_insert("real_name_auth", REAL_NAME_AUTH_COLUMNS)

    for user in selected_users:
        auth_id = writer.next_id("real_name_auth")
        uid = phone_to_uid[user["phone"]]
        real_name = user["nickname"]
        id_card = _fake.ssn()

        # 95% 已认证，5% 待审核
        auth_status = 1 if random.random() < 0.95 else 0

        auth_time = (
            random_datetime_between(user["create_time"], END_DT)
            if auth_status == 1
            else None
        )

        writer.add_row([
            auth_id,
            uid,
            real_name,
            id_card,
            auth_status,
            format_dt(auth_time) if auth_time is not None else None,
            format_dt(user["create_time"]),
            format_dt(user["update_time"]),
        ])

    return (all_user_ids, seeker_ids, hr_ids, admin_ids, user_name_map)
