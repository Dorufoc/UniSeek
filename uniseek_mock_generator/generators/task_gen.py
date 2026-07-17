# ==============================================================================
# UniSeek 兼职招聘平台 - 职位/岗位数据生成器
# ==============================================================================
# 生成 5000 条岗位（task）记录，分布在 400 家企业中。
# 每个岗位包含分类、薪资、地区、描述、标签等完整信息。
# 职位描述使用纯文本格式，标签使用 JSON 数组格式。

import random
import datetime
import json
from typing import List, Dict, Tuple

from config import END_DATE, START_DATE, ALL_REGION_IDS
from sql_output import SQLWriter
from datapool import JOB_TITLES_BY_CATEGORY, JOB_DESCRIPTION_TEMPLATES, SKILLS_BY_CATEGORY
from time_utils import weighted_random_time

# =============================================================================
# 常量定义
# =============================================================================

# 任务表列名
TASK_COLUMNS = [
    "id", "enterprise_id", "category_id", "region_id", "title",
    "description", "salary_min", "salary_max", "salary_unit",
    "job_type", "total_quota", "remaining_quota", "address",
    "tag", "longitude", "latitude", "status", "version",
    "deadline", "audit_time", "create_time", "update_time",
]

# 分类加权分布（ category_id → 权重）
CATEGORY_DISTRIBUTION: Dict[int, float] = {
    16: 0.06, 17: 0.04, 18: 0.04, 19: 0.03, 20: 0.02,  # 餐饮
    21: 0.04, 22: 0.05, 23: 0.02, 24: 0.02,              # 家教
    25: 0.05, 26: 0.05, 27: 0.03,                        # 物流
    28: 0.03, 29: 0.03, 30: 0.03,                        # 设计
    31: 0.03, 32: 0.03, 33: 0.02,                        # 促销
    34: 0.02, 35: 0.02, 36: 0.02,                        # 客服
    37: 0.02, 38: 0.01, 39: 0.02,                        # 文案
    40: 0.03, 41: 0.03, 42: 0.02,                        # 技术
    43: 0.02, 44: 0.01, 45: 0.01,                        # 翻译
    46: 0.02, 47: 0.02, 48: 0.01,                        # 美容
    49: 0.02, 50: 0.02, 51: 0.01,                        # 家政
    52: 0.02, 53: 0.02, 54: 0.01,                        # 教育
    55: 0.02, 56: 0.02, 57: 0.01,                        # 活动
    58: 0.01, 59: 0.01, 60: 0.01,                        # 摄影
    61: 0.03, 62: 0.01,                                    # 其他
}

# 时间范围
END_DT = datetime.datetime.strptime(END_DATE, "%Y-%m-%d")
START_DT = datetime.datetime.strptime(START_DATE, "%Y-%m-%d")
SPAN_SECONDS = int((END_DT - START_DT).total_seconds())

# =============================================================================
# 分类映射（category_id → parent_id → datapool 键名）
# =============================================================================

# category_id → parent_id 映射
CATEGORY_TO_PARENT: Dict[int, int] = {
    16: 1, 17: 1, 18: 1, 19: 1, 20: 1,   # 餐饮服务
    21: 2, 22: 2, 23: 2, 24: 2,           # 家教辅导
    25: 3, 26: 3, 27: 3,                  # 快递物流
    28: 6, 29: 6, 30: 6,                  # 设计创作
    31: 4, 32: 4, 33: 4,                  # 促销导购
    34: 5, 35: 5, 36: 5,                  # 话务客服
    37: 7, 38: 7, 39: 7,                  # 文案写作
    40: 8, 41: 8, 42: 8,                  # 技术支持
    43: 9, 44: 9, 45: 9,                  # 翻译校对
    46: 10, 47: 10, 48: 10,               # 美容美发
    49: 11, 50: 11, 51: 11,               # 家政保洁
    52: 12, 53: 12, 54: 12,               # 教育培训
    55: 13, 56: 13, 57: 13,               # 活动策划
    58: 14, 59: 14, 60: 14,               # 摄影摄像
    61: 15, 62: 15,                        # 其他
}

# parent_id → datapool 键名
PARENT_ID_TO_POOL_KEY: Dict[int, str] = {
    1: "餐饮服务",
    2: "家教辅导",
    3: "快递物流",
    4: "促销导购",
    5: "话务客服",
    6: "设计创作",
    7: "文案写作",
    8: "技术支持",
    9: "翻译校对",
    10: "美容美发",
    11: "家政保洁",
    12: "教育培训",
    13: "活动策划",
    14: "摄影摄像",
    15: None,  # 其他 - 没有直接映射
}

# 企业行业 → 允许的父分类 ID 映射（与 category 表顶级分类 ID 对应）
INDUSTRY_TO_PARENT_IDS: Dict[str, List[int]] = {
    "餐饮服务": [1],
    "家教辅导": [2],
    "快递物流": [3],
    "促销导购": [4],
    "话务客服": [5],
    "设计创作": [6],
    "文案写作": [7],
    "技术支持": [8],
    "翻译校对": [9],
    "美容美发": [10],
    "家政保洁": [11],
    "教育培训": [12],
    "活动策划": [13],
    "摄影摄像": [14],
    "其他": [15],
}

# 父分类 ID → 子分类 ID 列表（由 CATEGORY_TO_PARENT 逆向构建）
PARENT_TO_CHILD_IDS: Dict[int, List[int]] = {}
for child_id, parent_id in CATEGORY_TO_PARENT.items():
    PARENT_TO_CHILD_IDS.setdefault(parent_id, []).append(child_id)


# 其他分类的 fallback 池键名
FALLBACK_POOL_KEYS = [
    "餐饮服务", "家教辅导", "快递物流", "促销导购", "话务客服",
    "设计创作", "文案写作", "技术支持", "翻译校对", "美容美发",
    "家政保洁", "教育培训", "活动策划", "摄影摄像",
]

# category_id → parent_name 缓存
_CATEGORY_POOL_CACHE: Dict[int, str] = {}


def _get_pool_key(category_id: int) -> str:
    """根据 category_id 获取 datapool 键名。

    Args:
        category_id: 分类 ID（16-62）

    Returns:
        datapool 中的分类键名
    """
    if category_id not in _CATEGORY_POOL_CACHE:
        parent_id = CATEGORY_TO_PARENT.get(category_id, 15)
        key = PARENT_ID_TO_POOL_KEY.get(parent_id)
        if key is None:
            key = random.choice(FALLBACK_POOL_KEYS)
        _CATEGORY_POOL_CACHE[category_id] = key
    return _CATEGORY_POOL_CACHE[category_id]


# =============================================================================
# 职位标题前缀
# =============================================================================

TITLE_PREFIXES = ["急招", "高薪", "知名企业", ""]

# =============================================================================
# 薪资范围表（按分类和薪资单位）
# =============================================================================

# salary_unit: 0=日结, 1=时薪, 2=月结
# 返回值: (salary_min, salary_max)


def get_salary_range(category_id: int, salary_unit: int):
    """根据分类和薪资单位返回薪资范围。

    Args:
        category_id: 分类 ID
        salary_unit: 薪资单位（0=日结, 1=时薪, 2=月结）

    Returns:
        (salary_min, salary_max) 二元组
    """
    parent_id = CATEGORY_TO_PARENT.get(category_id, 15)

    if salary_unit == 0:  # 日结
        if parent_id == 1:          # 餐饮服务
            return (100, 300)
        elif parent_id == 2:        # 家教辅导
            return (150, 500)
        elif parent_id == 3:        # 快递物流
            return (150, 350)
        elif parent_id in (4, 5):   # 促销导购 / 话务客服
            return (100, 250)
        elif parent_id in (6, 7):   # 设计创作 / 文案写作
            return (200, 600)
        elif parent_id == 8:        # 技术支持
            return (200, 800)
        elif parent_id == 9:        # 翻译校对
            return (200, 500)
        elif parent_id == 10:       # 美容美发
            return (150, 400)
        elif parent_id == 11:       # 家政保洁
            return (100, 300)
        elif parent_id in (12, 13): # 教育培训 / 活动策划
            return (150, 400)
        elif parent_id == 14:       # 摄影摄像
            return (200, 600)
        else:                       # 其他
            return (100, 400)
    elif salary_unit == 1:  # 时薪
        if parent_id == 1:          # 餐饮服务
            return (15, 35)
        elif parent_id == 2:        # 家教辅导
            return (50, 200)
        elif parent_id == 3:        # 快递物流
            return (18, 40)
        elif parent_id in (4, 5):   # 促销导购 / 话务客服
            return (15, 30)
        elif parent_id in (6, 7):   # 设计创作 / 文案写作
            return (30, 100)
        elif parent_id == 8:        # 技术支持
            return (30, 150)
        elif parent_id == 9:        # 翻译校对
            return (30, 80)
        elif parent_id == 10:       # 美容美发
            return (20, 60)
        elif parent_id == 11:       # 家政保洁
            return (15, 40)
        elif parent_id in (12, 13): # 教育培训 / 活动策划
            return (20, 60)
        elif parent_id == 14:       # 摄影摄像
            return (30, 100)
        else:                       # 其他
            return (15, 50)
    else:  # 月结
        if parent_id == 1:          # 餐饮服务
            return (3000, 8000)
        elif parent_id == 2:        # 家教辅导
            return (4000, 12000)
        elif parent_id == 3:        # 快递物流
            return (4000, 10000)
        elif parent_id in (4, 5):   # 促销导购 / 话务客服
            return (3000, 7000)
        elif parent_id in (6, 7):   # 设计创作 / 文案写作
            return (5000, 15000)
        elif parent_id == 8:        # 技术支持
            return (6000, 20000)
        elif parent_id == 9:        # 翻译校对
            return (5000, 12000)
        elif parent_id == 10:       # 美容美发
            return (4000, 10000)
        elif parent_id == 11:       # 家政保洁
            return (3000, 8000)
        elif parent_id in (12, 13): # 教育培训 / 活动策划
            return (4000, 10000)
        elif parent_id == 14:       # 摄影摄像
            return (5000, 15000)
        else:                       # 其他
            return (3000, 8000)


# =============================================================================
# 职位标签池（按分类）
# =============================================================================

TAGS_BY_CATEGORY: Dict[str, List[str]] = {
    "餐饮服务": ["包吃", "包住", "环境好", "工作餐", "交通便利", "就近分配", "无需经验", "培训上岗", "周末", "轮班"],
    "家教辅导": ["一对一", "周末", "时间灵活", "在校生优先", "专业培训", "就近安排", "双休", "市区"],
    "快递物流": ["包住", "就近分配", "加班补贴", "夜班", "无需经验", "全职", "兼职", "月结"],
    "促销导购": ["周末", "日结", "时间灵活", "在校生优先", "无需经验", "培训", "市区", "商场"],
    "话务客服": ["坐班", "培训", "环境好", "双休", "五险一金", "全职", "兼职", "下午班"],
    "设计创作": ["远程", "时间灵活", "创意", "在校生优先", "周末", "项目制", "作品优先"],
    "文案写作": ["远程", "时间灵活", "在校生优先", "创意", "周末", "稿费", "自媒体"],
    "技术支持": ["五险一金", "双休", "全职", "项目奖", "年终奖", "培训", "晋升快"],
    "翻译校对": ["远程", "时间灵活", "在校生优先", "兼职", "专业培训", "按件计酬"],
    "美容美发": ["包吃", "包住", "培训", "环境好", "学徒", "晋升快", "就近分配"],
    "家政保洁": ["包住", "就近分配", "时间灵活", "无需经验", "培训上岗", "日结", "兼职"],
    "教育培训": ["双休", "五险一金", "寒暑假", "稳定", "晋升快", "培训", "环境好"],
    "活动策划": ["周末", "兼职", "在校生优先", "时间灵活", "项目制", "市区"],
    "摄影摄像": ["项目制", "时间灵活", "在校生优先", "周末", "作品优先", "自带设备"],
}

FALLBACK_TAGS = ["兼职", "全职", "急招", "周末", "时间灵活", "无需经验"]

# =============================================================================
# 职位职责、要求、福利池（用于填充描述模板）
# =============================================================================

RESPONSIBILITIES_BY_CATEGORY: Dict[str, List[str]] = {
    "餐饮服务": [
        "负责餐厅日常客户接待与点餐服务",
        "协助厨房进行食材清洗、切配等准备工作",
        "维护餐厅就餐环境及厨房卫生清洁",
        "负责外卖订单的打包、核对与出餐",
        "协助收银员进行结账和收银工作",
        "负责餐具清洗消毒和餐厅物料整理",
        "协助厨师完成菜品的制作和摆盘",
        "负责前厅客人的引导和座位安排",
        "参与餐厅库存盘点及物料补充工作",
        "负责饮品制作和吧台日常管理",
    ],
    "家教辅导": [
        "负责学生课后作业的辅导和批改",
        "针对学生学习薄弱环节进行专项强化",
        "制定个性化学习计划并监督执行",
        "协助学生预习复习各学科知识点",
        "培养学生良好的学习习惯和方法",
        "定期与家长沟通学生学习进展情况",
        "准备教学材料和课后练习题目",
        "辅导学生完成课外读物和拓展练习",
        "指导学生的艺术类课程和专业训练",
        "协助学生备考各类考试和竞赛",
    ],
    "快递物流": [
        "负责包裹的分拣、扫描和归类上架",
        "按照配送路线完成区域内快递派送",
        "协助装卸货物并进行数量核对",
        "负责仓库货物出入库登记和整理",
        "处理快递异常件和客户咨询",
        "配合完成每日库存盘点和数据录入",
        "负责包裹的打包、贴单和装车",
        "协助调度员完成车辆配载和路线规划",
        "使用PDA设备完成包裹扫描和签收",
        "负责退货件的处理和重新入库",
    ],
    "促销导购": [
        "负责卖场商品的陈列展示和补货",
        "主动向顾客介绍产品特点和促销活动",
        "协助完成促销活动的现场布置和执行",
        "维护卖场环境卫生和商品整洁",
        "协助收银和顾客咨询服务",
        "参与试吃推广和产品体验活动",
        "收集顾客反馈和竞品信息",
        "协助完成库存盘点和商品调拨",
        "引导顾客办理会员卡和积分兑换",
        "配合完成节假日促销活动执行",
    ],
    "话务客服": [
        "接听客户来电，解答产品咨询和疑问",
        "处理在线客服平台的客户咨询和投诉",
        "记录客户反馈并跟进问题处理进度",
        "协助客户完成订单查询和售后申请",
        "按照服务标准完成客户满意度回访",
        "整理客户常见问题并更新知识库",
        "协助处理退换货和退款申请",
        "引导客户完成线上操作流程",
        "配合团队完成客服工单的闭环处理",
        "参与客服质量监控和话术优化",
    ],
    "设计创作": [
        "负责品牌视觉设计和宣传物料的创作",
        "完成电商详情页和主图的设计制作",
        "参与UI界面设计和交互原型制作",
        "负责插画绘制和图形创意设计",
        "协助完成包装设计和印刷跟单工作",
        "完成海报、传单等平面设计任务",
        "参与品牌VI系统的设计和维护",
        "负责社交媒体图片和短视频制作",
        "协助完成展览展示的视觉设计",
        "参与创意方案讨论和视觉呈现",
    ],
    "文案写作": [
        "负责公众号文章的内容策划和撰写",
        "撰写品牌营销文案和产品推广软文",
        "完成短视频脚本和创意策划方案",
        "负责社交媒体平台的内容创作和运营",
        "撰写新闻稿件和品牌故事",
        "协助完成活动文案和宣传资料",
        "参与社群内容规划和话题策划",
        "负责SEO优化文案和网站内容更新",
        "完成产品详情页文案和卖点提炼",
        "协助竞品分析和市场调研报告撰写",
    ],
    "技术支持": [
        "负责公司系统的日常运维和故障处理",
        "参与功能模块的开发和代码编写",
        "协助完成软件测试和Bug跟踪修复",
        "负责数据库的日常维护和性能优化",
        "参与技术方案讨论和文档编写",
        "协助客户解决技术问题和疑问",
        "参与系统部署和上线工作",
        "负责代码审查和单元测试编写",
        "协助完成技术调研和原型验证",
        "参与团队技术分享和能力提升",
    ],
    "翻译校对": [
        "负责中英文文件和资料的互译工作",
        "协助完成本地化项目的翻译和审校",
        "参与字幕翻译和视频内容本地化",
        "负责技术文档和产品说明的翻译",
        "协助完成会议口译和商务沟通翻译",
        "参与术语库建设和翻译质量把控",
        "负责合同和法务文件的翻译校对",
        "协助完成多语种排版和文件整理",
        "参与翻译项目的进度管理和质量审核",
        "负责客户沟通和需求确认中的翻译支持",
    ],
    "美容美发": [
        "负责客户面部护理和皮肤管理服务",
        "完成美甲美睫和手足护理项目",
        "负责发型设计和染烫技术服务",
        "协助客户进行妆容设计和化妆造型",
        "负责SPA理疗和身体护理服务",
        "维护美容工具和设备的清洁消毒",
        "协助客户进行产品选择和护理方案制定",
        "参与门店日常运营和环境维护",
        "负责客户预约管理和服务记录",
        "参与技术培训和美业技能提升",
    ],
    "家政保洁": [
        "负责家庭日常保洁和深度清洁服务",
        "完成擦窗、除螨和家电清洗服务",
        "协助客户进行衣物整理和收纳归位",
        "负责开荒保洁和甲醛治理服务",
        "参与月嫂护理和新生儿照护服务",
        "协助老人陪护和病患看护服务",
        "负责日常地面清洁和垃圾分类处理",
        "完成厨房和卫生间的深度清洁消毒",
        "协助客户进行搬家前后的清洁整理",
        "参与家居消毒和除虫除害服务",
    ],
    "教育培训": [
        "负责学员的课程咨询和学习规划服务",
        "协助完成教学管理和课堂秩序维护",
        "参与课程研发和教学课件制作",
        "负责学员考勤管理和学习进度跟踪",
        "协助组织课外活动和家长沟通会",
        "参与招生宣传和市场推广活动",
        "负责教学场地管理和教学设备维护",
        "协助完成学员档案管理和数据统计",
        "参与教研活动和教学质量评估",
        "负责在线教育平台的运营支持",
    ],
    "活动策划": [
        "负责活动方案的策划和创意构思",
        "协助完成活动现场的布置和执行",
        "参与活动物料的采购和管理工作",
        "负责活动流程的把控和现场协调",
        "协助完成嘉宾邀请和接待工作",
        "参与活动宣传物料的设计和制作",
        "负责活动预算的制定和成本控制",
        "协助完成活动总结和效果评估",
        "参与供应商对接和场地勘测工作",
        "负责活动应急预案的制定和执行",
    ],
    "摄影摄像": [
        "负责拍摄各类商业摄影和活动记录",
        "协助完成视频拍摄和现场灯光布置",
        "参与后期修图和照片调色处理",
        "负责视频剪辑和影视后期制作",
        "协助完成产品拍摄和场景搭建",
        "参与航拍和特殊角度拍摄任务",
        "负责摄影器材的维护和管理",
        "协助客户进行选片和成品交付",
        "参与拍摄方案讨论和创意策划",
        "负责拍摄素材的整理和归档存储",
    ],
}

REQUIREMENTS_BY_CATEGORY: Dict[str, List[str]] = {
    "餐饮服务": [
        "年满18周岁，身体健康，持有健康证",
        "有餐饮服务经验者优先考虑",
        "服务意识强，具备良好的沟通能力",
        "能适应轮班制工作安排",
        "工作认真负责，注重食品卫生安全",
        "吃苦耐劳，能适应快节奏工作环境",
        "具备团队协作精神",
        "有相关岗位工作经验者优先",
    ],
    "家教辅导": [
        "本科及以上学历，相关专业优先",
        "有教学或家教经验者优先",
        "表达能力强，善于与学生沟通",
        "有耐心和责任心，热爱教育事业",
        "熟悉中小学教材和考试大纲",
        "持有教师资格证者优先考虑",
        "具备良好的时间管理能力",
        "能长期稳定任教者优先",
    ],
    "快递物流": [
        "身体健康，能适应体力劳动",
        "熟悉当地交通路线和小区分布",
        "有快递或物流行业经验者优先",
        "能适应早班和轮班工作制",
        "吃苦耐劳，能承受一定工作压力",
        "具备基本的数字计算和识字能力",
        "持有相关驾照或操作证书者优先",
        "工作细致认真，有责任心",
    ],
    "促销导购": [
        "形象气质佳，性格开朗活泼",
        "有销售或导购经验者优先",
        "沟通表达能力强，有亲和力",
        "能适应商场排班和周末工作",
        "具备一定的产品陈列知识",
        "工作积极主动，有服务意识",
        "具备团队合作精神",
        "学生兼职和有经验者均可",
    ],
    "话务客服": [
        "普通话标准，声音甜美",
        "有客服工作经验者优先",
        "打字速度每分钟50字以上",
        "具备良好的情绪管理能力",
        "能适应倒班和周末工作安排",
        "具备良好的沟通和应变能力",
        "熟练使用办公软件和CRM系统",
        "工作耐心细致，有服务意识",
    ],
    "设计创作": [
        "美术或设计相关专业毕业",
        "熟练使用Photoshop、Illustrator等设计软件",
        "有良好的审美能力和创意构思能力",
        "有相关设计工作经验者优先",
        "具备良好的沟通和理解能力",
        "能独立完成设计项目",
        "简历请附上个人作品集",
        "有较强的学习能力和创新精神",
    ],
    "文案写作": [
        "中文、新闻或广告相关专业优先",
        "有较强的文字功底和写作能力",
        "熟悉社交媒体平台和内容风格",
        "有新媒体运营或文案经验者优先",
        "具备良好的创意和策划能力",
        "能独立完成选题和内容创作",
        "了解SEO基本知识者优先",
        "有责任心，能按时完成稿件",
    ],
    "技术支持": [
        "计算机相关专业本科及以上学历",
        "熟悉一种或多种编程语言",
        "有良好的逻辑思维和问题解决能力",
        "有相关项目开发经验者优先",
        "具备团队协作和沟通能力",
        "学习能力强，能快速掌握新技术",
        "了解数据库和操作系统基本知识",
        "有开源项目贡献者优先考虑",
    ],
    "翻译校对": [
        "外语专业本科及以上学历",
        "持有相关语言等级证书（专八/CATTI等）",
        "有翻译或本地化经验者优先",
        "具备良好的中文表达和文字功底",
        "熟练使用CAT工具者优先",
        "有较强的责任心和细节把控能力",
        "能在规定时间内保质保量完成任务",
        "具备良好的沟通和团队协作能力",
    ],
    "美容美发": [
        "美容美发相关专业或培训经历",
        "有美容美发行业从业经验者优先",
        "持有相关职业资格证书者优先",
        "具备良好的客户服务意识",
        "热爱美业，有学习提升的意愿",
        "沟通能力好，有亲和力",
        "能适应排班和周末工作安排",
        "有团队合作精神",
    ],
    "家政保洁": [
        "身体健康，无传染性疾病",
        "有家政服务经验者优先",
        "工作细致认真，有责任心",
        "具备良好的服务态度和沟通能力",
        "能熟练使用各类清洁工具和设备",
        "持有相关家政服务证书者优先",
        "能适应灵活的工作时间安排",
        "吃苦耐劳，诚实守信",
    ],
    "教育培训": [
        "教育相关专业本科及以上学历",
        "有教育行业工作经验者优先",
        "性格开朗，有亲和力和感染力",
        "具备良好的沟通和表达能力",
        "热爱教育事业，有责任心",
        "持有教师资格证者优先考虑",
        "具备良好的团队合作精神",
        "有课程销售或咨询经验者优先",
    ],
    "活动策划": [
        "有活动策划或执行经验者优先",
        "具备良好的创意策划能力",
        "有较强的组织协调和统筹能力",
        "能适应灵活的工作时间安排",
        "具备良好的沟通和应变能力",
        "有责任心，能承受工作压力",
        "熟练使用办公软件",
        "有大型活动执行经验者优先",
    ],
    "摄影摄像": [
        "摄影或影视相关专业优先",
        "有摄影摄像工作经验者优先",
        "熟练使用各类摄影器材和后期软件",
        "有良好的构图能力和审美水平",
        "自带设备者优先考虑",
        "具备良好的沟通和协作能力",
        "能适应不同拍摄场景和灵活时间",
        "提交简历请附上个人作品集",
    ],
}

BENEFITS = [
    "五险一金",
    "带薪培训",
    "节日福利",
    "绩效奖金",
    "年终奖金",
    "员工聚餐",
    "定期团建",
    "晋升空间大",
    "节假日双倍工资",
    "交通补贴",
    "餐饮补贴",
    "住房补贴",
    "全勤奖励",
    "生日福利",
    "年假带薪",
    "免费体检",
    "员工折扣",
    "季度旅游",
    "下午茶福利",
    "弹性工作时间",
]

# =============================================================================
# 地址生成相关
# =============================================================================

DISTRICT_NAMES = [
    "朝阳区", "浦东新区", "南山区", "建邺区", "西湖区",
    "天河区", "洪山区", "高新区", "武侯区", "沈河区",
    "鼓楼区", "海淀区", "福田区", "渝中区", "锦江区",
]

STREET_NAMES = [
    "建国路", "科技园路", "中山路", "人民路", "建设大道",
    "高新路", "商务大道", "创业路", "创新路", "发展路",
    "长江路", "解放路", "繁华大道", "商业街", "金融街",
    "文化路", "学府路", "工业路", "滨江路", "湖滨路",
]

# =============================================================================
# 地理坐标映射（region_id 前四位 → (城市名, 经度, 纬度)）
# =============================================================================

CITY_COORDS: Dict[int, tuple] = {
    1101: ("北京", 116.4074, 39.9042),
    3101: ("上海", 121.4737, 31.2304),
    4403: ("深圳", 114.0579, 22.5431),
    4401: ("广州", 113.2644, 23.1291),
    3201: ("南京", 118.7969, 32.0603),
    3205: ("苏州", 120.5842, 31.2974),
    3301: ("杭州", 120.1551, 30.2741),
    5001: ("重庆", 106.5494, 29.5647),
    5101: ("成都", 104.0665, 30.5728),
    4201: ("武汉", 114.3054, 30.5931),
    4301: ("长沙", 112.9388, 28.2282),
    2101: ("沈阳", 123.4328, 41.8086),
    3702: ("青岛", 120.3826, 36.0671),
    1201: ("天津", 117.1956, 39.1252),
    3502: ("厦门", 118.0894, 24.4798),
    3501: ("福州", 119.2965, 26.0745),
    4404: ("珠海", 113.5767, 22.2708),
    6101: ("西安", 108.9402, 34.3416),
    4101: ("郑州", 113.6254, 34.7466),
    3302: ("宁波", 121.5440, 29.8683),
    3202: ("无锡", 120.3119, 31.4901),
    2301: ("哈尔滨", 126.5350, 45.8038),
    2201: ("长春", 125.3265, 43.8961),
    2102: ("大连", 121.6150, 38.9140),
    1301: ("石家庄", 114.5149, 38.0428),
    3601: ("南昌", 115.8582, 28.6829),
    3401: ("合肥", 117.2272, 31.8206),
    1401: ("太原", 112.5489, 37.8706),
    1501: ("呼和浩特", 111.7510, 40.8424),
    4601: ("海口", 110.1999, 20.0440),
    4501: ("南宁", 108.3661, 22.8174),
    5301: ("昆明", 102.8338, 24.8719),
    6201: ("兰州", 103.8343, 36.0611),
    4419: ("东莞", 113.7518, 23.0207),
    4420: ("中山", 113.3928, 22.5176),
    4413: ("惠州", 114.4168, 23.1115),
}

DEFAULT_COORDS = (116.4074, 39.9042)  # 北京作为默认


def _get_city_coords(region_id: int) -> tuple:
    """根据 region_id 获取城市坐标。

    Args:
        region_id: 地区 ID

    Returns:
        (城市名, 经度, 纬度) 三元组，或 (None, 默认经度, 默认纬度)
    """
    prefix = region_id // 100
    if prefix in CITY_COORDS:
        return CITY_COORDS[prefix]
    return (None, DEFAULT_COORDS[0], DEFAULT_COORDS[1])


# =============================================================================
# 辅助函数
# =============================================================================


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


def _pick_category_id(allowed_parent_ids: List[int] = None) -> int:
    """根据 CATEGORY_DISTRIBUTION 加权随机选取分类 ID。

    若指定 allowed_parent_ids，则只从属于这些父分类的子分类中选取。

    Args:
        allowed_parent_ids: 允许的父分类 ID 列表（为 None 时不限制）

    Returns:
        分类 ID（16-62）
    """
    cat_ids = list(CATEGORY_DISTRIBUTION.keys())
    if allowed_parent_ids:
        allowed_child_ids = set()
        for pid in allowed_parent_ids:
            allowed_child_ids.update(PARENT_TO_CHILD_IDS.get(pid, []))
        cat_ids = [cid for cid in cat_ids if cid in allowed_child_ids]
        if not cat_ids:
            cat_ids = list(CATEGORY_DISTRIBUTION.keys())
    weights = [CATEGORY_DISTRIBUTION[cid] for cid in cat_ids]
    return random.choices(cat_ids, weights=weights, k=1)[0]


def _pick_title(category_id: int) -> str:
    """根据分类 ID 生成职位标题。

    Args:
        category_id: 分类 ID

    Returns:
        职位标题字符串
    """
    pool_key = _get_pool_key(category_id)
    titles = JOB_TITLES_BY_CATEGORY.get(pool_key, ["兼职人员"])
    title = random.choice(titles)

    # 部分标题添加前缀（15% 概率）
    if random.random() < 0.15:
        prefix = random.choice(TITLE_PREFIXES)
        if prefix:
            title = prefix + title

    return title


def _generate_description(category_id: int) -> str:
    """使用 datapool 模板生成职位描述（纯文本格式）。"""
    pool_key = _get_pool_key(category_id)
    template = random.choice(JOB_DESCRIPTION_TEMPLATES)

    # 获取职责、要求池
    responsibilities = RESPONSIBILITIES_BY_CATEGORY.get(pool_key, RESPONSIBILITIES_BY_CATEGORY["餐饮服务"])
    requirements = REQUIREMENTS_BY_CATEGORY.get(pool_key, REQUIREMENTS_BY_CATEGORY["餐饮服务"])

    # 随机选取 3 条职责、3 条要求、3 条福利
    r1, r2, r3 = random.sample(responsibilities, min(3, len(responsibilities)))
    req1, req2, req3 = random.sample(requirements, min(3, len(requirements)))
    b1, b2, b3 = random.sample(BENEFITS, min(3, len(BENEFITS)))

    # 薪资范围显示
    salary_min, salary_max = get_salary_range(category_id, 2)  # 月薪作为参考
    salary_range = f"{salary_min}-{salary_max}"

    # 其他占位符
    city_name = random.choice(DISTRICT_NAMES).replace("区", "")
    district_name = random.choice(DISTRICT_NAMES)
    age_min = random.randint(16, 20)
    age_max = random.randint(35, 55)
    education = random.choice(["高中", "中专", "大专", "本科"])
    job_type_str = random.choice(["全职", "兼职", "实习"])
    target = random.choice(["应届毕业生", "在校大学生", "社会人士", "无需经验者"])
    work_time = random.choice(["9:00-18:00", "10:00-19:00", "8:30-17:30", "弹性工作制"])
    rest_day = str(random.randint(1, 2))
    platform = "UniSeek"
    industry = pool_key
    company = "本公司"
    num = str(random.randint(3, 20))
    area = random.choice(["网站开发", "市场推广", "客户服务", "教育培训", "设计创意"])

    placeholders = {
        "{responsibility1}": r1,
        "{responsibility2}": r2,
        "{responsibility3}": r3,
        "{requirement1}": req1,
        "{requirement2}": req2,
        "{requirement3}": req3,
        "{benefit1}": b1,
        "{benefit2}": b2,
        "{benefit3}": b3,
        "{salary_range}": salary_range,
        "{position}": random.choice(JOB_TITLES_BY_CATEGORY.get(pool_key, ["人员"])),
        "{city}": city_name,
        "{district}": district_name,
        "{company}": company,
        "{type}": job_type_str,
        "{num}": num,
        "{age}": str(random.randint(age_min, age_max)),
        "{age_min}": str(age_min),
        "{age_max}": str(age_max),
        "{education}": education,
        "{work_time}": work_time,
        "{rest_day}": rest_day,
        "{platform}": platform,
        "{industry}": industry,
        "{target}": target,
        "{area}": area,
        "{total}": str(random.randint(4000, 15000)),
    }

    result = template
    for key, value in placeholders.items():
        result = result.replace(key, value)

    return result


def _generate_tag(category_id: int) -> str:
    """根据分类生成职位标签（JSON 数组格式）。

    Args:
        category_id: 分类 ID

    Returns:
        JSON 数组字符串，如 '["兼职","周末","包吃"]'
    """
    pool_key = _get_pool_key(category_id)
    tag_pool = TAGS_BY_CATEGORY.get(pool_key, FALLBACK_TAGS)
    k = random.randint(2, 4)
    tags = random.sample(tag_pool, min(k, len(tag_pool)))
    return json.dumps(tags, ensure_ascii=False)


def _generate_address(region_id: int) -> str:
    """根据地区 ID 生成工作地址。

    Args:
        region_id: 地区 ID

    Returns:
        地址字符串
    """
    district = random.choice(DISTRICT_NAMES)
    street = random.choice(STREET_NAMES)
    number = random.randint(1, 999)
    return f"{district}{street}{number}号"


def _generate_coordinates(region_id: int) -> tuple:
    """根据地区 ID 生成坐标。

    50% 概率返回 (经度, 纬度)，50% 概率返回 (None, None)。

    Args:
        region_id: 地区 ID

    Returns:
        (经度, 纬度) 或 (None, None)
    """
    if random.random() < 0.5:
        return (None, None)

    _, base_lng, base_lat = _get_city_coords(region_id)
    # 添加随机偏移（约 ±0.05 度 ≈ ±5km）
    lng = base_lng + random.uniform(-0.05, 0.05)
    lat = base_lat + random.uniform(-0.05, 0.05)
    return (lng, lat)


def _pick_region_id() -> int:
    """从 ALL_REGION_IDS 中随机选取地区 ID。

    ALL_REGION_IDS 在 config.py 中定义，包含约 160 个加权区县级地区 ID，
    覆盖全国 34 个省级行政区，权重由出现次数体现。

    Returns:
        地区 ID
    """
    return random.choice(ALL_REGION_IDS)


def _pick_status() -> tuple:
    """随机选取岗位状态。

    分布：
    - 1（招聘中）: 50%
    - 0（待审核）: 15%
    - 2（已满员）: 12%
    - 3（已过期）: 13%
    - 4（已下架）: 10%

    Returns:
        status 值
    """
    r = random.random()
    if r < 0.50:
        return 1  # 招聘中
    elif r < 0.65:
        return 0  # 待审核
    elif r < 0.77:
        return 2  # 已满员
    elif r < 0.90:
        return 3  # 已过期
    else:
        return 4  # 已下架


def _generate_total_quota() -> int:
    """随机生成招聘总人数。

    分布：
    - 30%: 3-5 人
    - 40%: 5-15 人
    - 30%: 15-50 人

    Returns:
        招聘总人数
    """
    r = random.random()
    if r < 0.30:
        return random.randint(3, 5)
    elif r < 0.70:
        return random.randint(5, 15)
    else:
        return random.randint(15, 50)


def _generate_create_time(skew_recent: bool = True) -> datetime.datetime:
    """生成创建时间。

    使用 weighted_random_time() 确保数据分布合理，近期更密集。

    Args:
        skew_recent: 参数保留以兼容调用方（实际分布由 weighted_random_time 决定）

    Returns:
        随机的创建时间
    """
    return weighted_random_time()


# =============================================================================
# 主生成函数
# =============================================================================

def generate_tasks(
    writer: SQLWriter,
    enterprise_ids: List[int],
    hr_enterprise_map: Dict[int, int],
    enterprise_industry_map: Dict[int, str] = None,
    enterprise_audit_map: Dict[int, int] = None,
) -> Tuple[List[int], Dict[int, int]]:
    """生成岗位数据并写入 SQL 文件。

    生成 5000 条岗位（task）记录，分布在已认证的企业中。
    每个岗位包含完整的分类、薪资、地区、描述、标签等信息。

    职责、要求和福利使用预定义的分类池填充到纯文本描述模板中。
    标签使用 JSON 数组字符串格式。
    薪资范围基于分类和薪资单位合理分配。

    Args:
        writer: SQLWriter 实例，用于输出 SQL
        enterprise_ids: 企业 ID 列表
        hr_enterprise_map: HR 用户 ID → 企业 ID 映射（仅用于参考）
        enterprise_industry_map: 企业 ID → 行业名称映射（用于分类匹配）
        enterprise_audit_map: 企业 ID → 审核状态映射（仅过滤已认证企业）

    Returns:
        (task_ids, task_enterprise_map) 二元组：
        - task_ids: 生成的岗位 ID 列表
        - task_enterprise_map: 岗位 ID → 企业 ID 的映射字典
    """
    total_tasks = 5000
    task_ids: List[int] = []
    task_enterprise_map: Dict[int, int] = {}

    # ---- 过滤：只保留已认证的企业 ----
    if enterprise_audit_map:
        enterprise_ids = [eid for eid in enterprise_ids if enterprise_audit_map.get(eid) == 1]

    if not enterprise_ids:
        raise RuntimeError("没有已认证的企业，无法生成岗位数据")

    enterprise_count = len(enterprise_ids)

    # =====================================================================
    # 1. 分配各企业的岗位数量（平均分布，每家企业 12-13 个）
    # =====================================================================
    shuffled_ids = list(enterprise_ids)
    random.shuffle(shuffled_ids)

    base_count = total_tasks // enterprise_count  # 12
    extra_count = total_tasks % enterprise_count  # 200

    # 前 200 家企业 13 个，后 200 家企业 12 个
    enterprise_task_counts = [base_count] * enterprise_count
    for i in range(extra_count):
        enterprise_task_counts[i] += 1

    # 展开为企业 ID 列表
    task_enterprises: List[int] = []
    for eid, count in zip(shuffled_ids, enterprise_task_counts):
        task_enterprises.extend([eid] * count)

    assert len(task_enterprises) == total_tasks, f"岗位数量必须等于 {total_tasks}"

    writer.write_comment(f"岗位表（{total_tasks} 条记录，来自 {enterprise_count} 家已认证企业）")
    writer.begin_insert("task", TASK_COLUMNS)

    for i in range(total_tasks):
        tid = writer.next_id("task")
        task_ids.append(tid)

        enterprise_id = task_enterprises[i]
        task_enterprise_map[tid] = enterprise_id

        # -----------------------------------------------------------------
        # 2. 选取分类（根据企业行业限制可选的分类范围）
        # -----------------------------------------------------------------
        allowed_parents = None
        if enterprise_industry_map:
            industry = enterprise_industry_map.get(enterprise_id)
            allowed_parents = INDUSTRY_TO_PARENT_IDS.get(industry) if industry else None
        category_id = _pick_category_id(allowed_parents)
        pool_key = _get_pool_key(category_id)

        # -----------------------------------------------------------------
        # 3. 生成标题
        # -----------------------------------------------------------------
        title = _pick_title(category_id)

        # -----------------------------------------------------------------
        # 4. 生成描述
        # -----------------------------------------------------------------
        description = _generate_description(category_id)

        # -----------------------------------------------------------------
        # 5. 生成薪资
        # -----------------------------------------------------------------
        salary_unit = random.choices([0, 1, 2], weights=[0.40, 0.25, 0.35], k=1)[0]
        salary_min, salary_max = get_salary_range(category_id, salary_unit)

        # -----------------------------------------------------------------
        # 6. 岗位类型
        # -----------------------------------------------------------------
        job_type = random.choices([1, 2, 3], weights=[0.25, 0.55, 0.20], k=1)[0]

        # -----------------------------------------------------------------
        # 7. 招聘配额
        # -----------------------------------------------------------------
        total_quota = _generate_total_quota()
        remaining_quota = total_quota  # 初始值等于总配额

        # -----------------------------------------------------------------
        # 8. 地区和地址
        # -----------------------------------------------------------------
        region_id = _pick_region_id()
        address = _generate_address(region_id)

        # -----------------------------------------------------------------
        # 9. 标签
        # -----------------------------------------------------------------
        tag = _generate_tag(category_id)

        # -----------------------------------------------------------------
        # 10. 坐标
        # -----------------------------------------------------------------
        lng, lat = _generate_coordinates(region_id)

        # -----------------------------------------------------------------
        # 11. 状态
        # -----------------------------------------------------------------
        status = _pick_status()

        # -----------------------------------------------------------------
        # 12. 时间信息
        # -----------------------------------------------------------------
        version = 0

        create_time = _generate_create_time(skew_recent=True)
        update_time = create_time

        # 根据状态生成 deadline
        if status in (1, 0):  # 招聘中或待审核 → 未来截止
            deadline = create_time + datetime.timedelta(
                days=random.randint(15, 60)
            )
        elif status == 3:  # 已过期 → 已过截止
            deadline = create_time + datetime.timedelta(
                days=random.randint(1, 10)
            )
        else:  # 已满员或已下架 → 可设 NULL 或短期限
            if random.random() < 0.5:
                deadline = create_time + datetime.timedelta(
                    days=random.randint(5, 30)
                )
            else:
                deadline = None

        # 根据状态生成 audit_time
        if status == 1:  # 招聘中 → 有审核时间
            audit_time = create_time + datetime.timedelta(
                days=random.randint(0, 7),
                hours=random.randint(0, 23),
                minutes=random.randint(0, 59),
            )
        else:
            audit_time = None

        # -----------------------------------------------------------------
        # 13. 写入行
        # -----------------------------------------------------------------
        writer.add_row([
            tid,                     # id
            enterprise_id,           # enterprise_id
            category_id,             # category_id
            region_id,               # region_id
            title,                   # title
            description,             # description
            salary_min,              # salary_min
            salary_max,              # salary_max
            salary_unit,             # salary_unit
            job_type,                # job_type
            total_quota,             # total_quota
            remaining_quota,         # remaining_quota
            address,                 # address
            tag,                     # tag
            lng,                     # longitude
            lat,                     # latitude
            status,                  # status
            version,                 # version
            _format_dt(deadline),    # deadline
            _format_dt(audit_time),  # audit_time
            _format_dt(create_time), # create_time
            _format_dt(update_time), # update_time
        ])

    return task_ids, task_enterprise_map
