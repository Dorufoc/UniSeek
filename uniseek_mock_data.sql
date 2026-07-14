-- ====================================================================
-- UniSeek 兼职招聘平台 - 测试模拟数据填充脚本
-- 版本: V1.0
-- 创建日期: 2026-07-14
-- 说明: 包含 14 张业务表的完整测试模拟数据
-- 使用: mysql -u root -p uniseek < uniseek_mock_data.sql
--       或在已选择 uniseek 数据库后执行: source uniseek_mock_data.sql
-- 前置条件: 需先执行 uniseek_schema.sql 完成建表
-- 注意: 脚本可重复执行，每次执行会先清空所有数据再重新插入
-- ====================================================================

SET FOREIGN_KEY_CHECKS = 0;
SET NAMES utf8mb4;
START TRANSACTION;

-- ====================================================================
-- 1. user - 用户表（26 条）
--    超级管理员 1 条（role=99），管理员 1 条（role=9），企业 HR 8 条（role=1），求职者 16 条（role=0）
--    密码: '85455c805d1a6d3f0ed396658acec8a1'
--    盐值: a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6
-- ====================================================================

DELETE FROM `user`;

INSERT INTO `user` (`id`, `phone`, `email`, `password`, `salt`, `nickname`, `avatar_url`, `role`, `credit_score`, `status`, `last_login_time`, `create_time`, `update_time`) VALUES
-- 管理员 1 条
(1,  '13900000001', 'admin@uniseek.com',       '85455c805d1a6d3f0ed396658acec8a1', 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6', '系统管理员', NULL, 9, 100, 1, DATE_SUB(NOW(), INTERVAL 1 HOUR),  DATE_SUB(NOW(), INTERVAL 28 DAY),  NOW()),

-- 企业 HR 8 条（role=1）
(2,  '13900000011', 'li_hr_canyin@uniseek.com',  '85455c805d1a6d3f0ed396658acec8a1', 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6', '李 HR-餐饮',  NULL, 1, 100, 1, DATE_SUB(NOW(), INTERVAL 2 HOUR),  DATE_SUB(NOW(), INTERVAL 26 DAY),  NOW()),
(3,  '13900000012', 'wang_hr_wuliu@uniseek.com',  '85455c805d1a6d3f0ed396658acec8a1', 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6', '王 HR-物流',  NULL, 1, 100, 1, DATE_SUB(NOW(), INTERVAL 5 HOUR),  DATE_SUB(NOW(), INTERVAL 25 DAY),  NOW()),
(4,  '13900000013', 'zhang_hr_jishu@uniseek.com', '85455c805d1a6d3f0ed396658acec8a1', 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6', '张 HR-技术',  NULL, 1, 100, 1, DATE_SUB(NOW(), INTERVAL 3 HOUR),  DATE_SUB(NOW(), INTERVAL 24 DAY),  NOW()),
(5,  '13900000014', 'liu_hr_jiaoyu@uniseek.com',  '85455c805d1a6d3f0ed396658acec8a1', 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6', '刘 HR-教育',  NULL, 1, 100, 1, DATE_SUB(NOW(), INTERVAL 1 DAY),   DATE_SUB(NOW(), INTERVAL 22 DAY),  NOW()),
(6,  '13900000015', 'chen_hr_sheji@uniseek.com',  '85455c805d1a6d3f0ed396658acec8a1', 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6', '陈 HR-设计',  NULL, 1, 100, 1, DATE_SUB(NOW(), INTERVAL 8 HOUR),  DATE_SUB(NOW(), INTERVAL 20 DAY),  NOW()),
(7,  '13900000016', 'zhao_hr_jiazheng@uniseek.com', '85455c805d1a6d3f0ed396658acec8a1', 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6', '赵 HR-家政',  NULL, 1, 100, 1, DATE_SUB(NOW(), INTERVAL 12 HOUR), DATE_SUB(NOW(), INTERVAL 18 DAY),  NOW()),
(8,  '13900000017', 'sun_hr_meirong@uniseek.com', '85455c805d1a6d3f0ed396658acec8a1', 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6', '孙 HR-美容',  NULL, 1, 100, 1, DATE_SUB(NOW(), INTERVAL 1 DAY),   DATE_SUB(NOW(), INTERVAL 16 DAY),  NOW()),
(9,  '13900000018', 'zhou_hr_qita@uniseek.com',   '85455c805d1a6d3f0ed396658acec8a1', 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6', '周 HR-其他',  NULL, 1, 100, 1, DATE_SUB(NOW(), INTERVAL 2 DAY),   DATE_SUB(NOW(), INTERVAL 14 DAY),  NOW()),

-- 求职者 16 条（role=0）
(10, '13900000101', 'zhangxiaomang@uniseek.com',  '85455c805d1a6d3f0ed396658acec8a1', 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6', '张小芒', NULL, 0, 100, 1, DATE_SUB(NOW(), INTERVAL 3 DAY),   DATE_SUB(NOW(), INTERVAL 27 DAY),  NOW()),
(11, '13900000102', 'lixiaoming@uniseek.com',     '85455c805d1a6d3f0ed396658acec8a1', 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6', '李小明', NULL, 0, 100, 1, DATE_SUB(NOW(), INTERVAL 5 DAY),   DATE_SUB(NOW(), INTERVAL 26 DAY),  NOW()),
(12, '13900000103', 'wangdali@uniseek.com',       '85455c805d1a6d3f0ed396658acec8a1', 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6', '王大力', NULL, 0, 100, 1, DATE_SUB(NOW(), INTERVAL 7 DAY),   DATE_SUB(NOW(), INTERVAL 25 DAY),  NOW()),
(13, '13900000104', 'zhaoxiaoyan@uniseek.com',    '85455c805d1a6d3f0ed396658acec8a1', 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6', '赵晓燕', NULL, 0, 100, 1, DATE_SUB(NOW(), INTERVAL 4 DAY),   DATE_SUB(NOW(), INTERVAL 24 DAY),  NOW()),
(14, '13900000105', 'liuzhiqiang@uniseek.com',    '85455c805d1a6d3f0ed396658acec8a1', 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6', '刘志强', NULL, 0, 100, 1, DATE_SUB(NOW(), INTERVAL 10 DAY),  DATE_SUB(NOW(), INTERVAL 23 DAY),  NOW()),
(15, '13900000106', 'chensiyu@uniseek.com',       '85455c805d1a6d3f0ed396658acec8a1', 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6', '陈思雨', NULL, 0, 100, 1, DATE_SUB(NOW(), INTERVAL 6 DAY),   DATE_SUB(NOW(), INTERVAL 22 DAY),  NOW()),
(16, '13900000107', 'yanghaoyu@uniseek.com',      '85455c805d1a6d3f0ed396658acec8a1', 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6', '杨浩宇', NULL, 0, 100, 1, DATE_SUB(NOW(), INTERVAL 8 DAY),   DATE_SUB(NOW(), INTERVAL 21 DAY),  NOW()),
(17, '13900000108', 'zhoumeiling@uniseek.com',    '85455c805d1a6d3f0ed396658acec8a1', 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6', '周美玲', NULL, 0, 100, 1, DATE_SUB(NOW(), INTERVAL 9 DAY),   DATE_SUB(NOW(), INTERVAL 20 DAY),  NOW()),
(18, '13900000109', 'wuhaotian@uniseek.com',      '85455c805d1a6d3f0ed396658acec8a1', 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6', '吴昊天', NULL, 0, 100, 1, DATE_SUB(NOW(), INTERVAL 12 DAY),  DATE_SUB(NOW(), INTERVAL 19 DAY),  NOW()),
(19, '13900000110', 'zhengyawei@uniseek.com',     '85455c805d1a6d3f0ed396658acec8a1', 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6', '郑雅文', NULL, 0, 100, 1, DATE_SUB(NOW(), INTERVAL 2 DAY),   DATE_SUB(NOW(), INTERVAL 18 DAY),  NOW()),
(20, '13900000111', 'sunpengfei@uniseek.com',     '85455c805d1a6d3f0ed396658acec8a1', 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6', '孙鹏飞', NULL, 0, 100, 1, NULL,                              DATE_SUB(NOW(), INTERVAL 17 DAY),  NOW()),
(21, '13900000112', 'linjingyi@uniseek.com',      '85455c805d1a6d3f0ed396658acec8a1', 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6', '林静怡', NULL, 0, 100, 1, DATE_SUB(NOW(), INTERVAL 1 DAY),   DATE_SUB(NOW(), INTERVAL 16 DAY),  NOW()),
(22, '13900000113', 'huangjunjie@uniseek.com',    '85455c805d1a6d3f0ed396658acec8a1', 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6', '黄俊杰', NULL, 0, 100, 1, DATE_SUB(NOW(), INTERVAL 11 DAY),  DATE_SUB(NOW(), INTERVAL 15 DAY),  NOW()),
(23, '13900000114', 'heyutong@uniseek.com',       '85455c805d1a6d3f0ed396658acec8a1', 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6', '何雨桐', NULL, 0, 100, 1, DATE_SUB(NOW(), INTERVAL 6 DAY),   DATE_SUB(NOW(), INTERVAL 14 DAY),  NOW()),
(24, '13900000115', 'maxiaofeng@uniseek.com',     '85455c805d1a6d3f0ed396658acec8a1', 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6', '马晓峰', NULL, 0, 100, 1, NULL,                              DATE_SUB(NOW(), INTERVAL 13 DAY),  NOW()),
(25, '13900000116', 'tangyuyan@uniseek.com',      '85455c805d1a6d3f0ed396658acec8a1', 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6', '唐语嫣', NULL, 0, 100, 1, DATE_SUB(NOW(), INTERVAL 3 DAY),   DATE_SUB(NOW(), INTERVAL 12 DAY),  NOW()),
-- 超级管理员 1 条（role=99）
(26, '13999999999', 'superadmin@uniseek.com', '85455c805d1a6d3f0ed396658acec8a1', 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6', '超级管理员', NULL, 99, 100, 1, NOW(), DATE_SUB(NOW(), INTERVAL 1 DAY), NOW());

-- ====================================================================
-- 2. real_name_auth - 实名认证表（24 条）
--    每位 HR（user_id 2-9）和求职者（user_id 10-25）各 1 条
--    身份证号格式: 110101（北京东城区）+ 出生日期 + 顺序码 + 校验码
--    real_name 与 user.nickname 对应
-- ====================================================================

DELETE FROM `real_name_auth`;

INSERT INTO `real_name_auth` (`id`, `user_id`, `real_name`, `id_card`, `status`, `auth_time`, `create_time`, `update_time`) VALUES
-- HR 实名认证 8 条
(1,  2,  '李 HR-餐饮', '110101198503122332', 1, DATE_SUB(NOW(), INTERVAL 25 DAY), DATE_SUB(NOW(), INTERVAL 26 DAY), NOW()),
(2,  3,  '王 HR-物流', '110101199007234512', 1, DATE_SUB(NOW(), INTERVAL 24 DAY), DATE_SUB(NOW(), INTERVAL 25 DAY), NOW()),
(3,  4,  '张 HR-技术', '110101198812054378', 1, DATE_SUB(NOW(), INTERVAL 23 DAY), DATE_SUB(NOW(), INTERVAL 24 DAY), NOW()),
(4,  5,  '刘 HR-教育', '110101199103187654', 1, DATE_SUB(NOW(), INTERVAL 21 DAY), DATE_SUB(NOW(), INTERVAL 22 DAY), NOW()),
(5,  6,  '陈 HR-设计', '110101199205209876', 1, DATE_SUB(NOW(), INTERVAL 19 DAY), DATE_SUB(NOW(), INTERVAL 20 DAY), NOW()),
(6,  7,  '赵 HR-家政', '110101198710113456', 1, DATE_SUB(NOW(), INTERVAL 17 DAY), DATE_SUB(NOW(), INTERVAL 18 DAY), NOW()),
(7,  8,  '孙 HR-美容', '110101199409157890', 1, DATE_SUB(NOW(), INTERVAL 15 DAY), DATE_SUB(NOW(), INTERVAL 16 DAY), NOW()),
(8,  9,  '周 HR-其他', '110101198610285678', 1, DATE_SUB(NOW(), INTERVAL 13 DAY), DATE_SUB(NOW(), INTERVAL 14 DAY), NOW()),

-- 求职者实名认证 16 条
(9,  10, '张小芒', '110101199805123456', 1, DATE_SUB(NOW(), INTERVAL 26 DAY), DATE_SUB(NOW(), INTERVAL 27 DAY), NOW()),
(10, 11, '李小明', '110101199608231234', 1, DATE_SUB(NOW(), INTERVAL 25 DAY), DATE_SUB(NOW(), INTERVAL 26 DAY), NOW()),
(11, 12, '王大力', '110101199503177890', 1, DATE_SUB(NOW(), INTERVAL 24 DAY), DATE_SUB(NOW(), INTERVAL 25 DAY), NOW()),
(12, 13, '赵晓燕', '110101200011083456', 1, DATE_SUB(NOW(), INTERVAL 23 DAY), DATE_SUB(NOW(), INTERVAL 24 DAY), NOW()),
(13, 14, '刘志强', '110101199707011234', 1, DATE_SUB(NOW(), INTERVAL 22 DAY), DATE_SUB(NOW(), INTERVAL 23 DAY), NOW()),
(14, 15, '陈思雨', '110101199902145678', 1, DATE_SUB(NOW(), INTERVAL 21 DAY), DATE_SUB(NOW(), INTERVAL 22 DAY), NOW()),
(15, 16, '杨浩宇', '110101199409209012', 1, DATE_SUB(NOW(), INTERVAL 20 DAY), DATE_SUB(NOW(), INTERVAL 21 DAY), NOW()),
(16, 17, '周美玲', '110101200106303456', 1, DATE_SUB(NOW(), INTERVAL 19 DAY), DATE_SUB(NOW(), INTERVAL 20 DAY), NOW()),
(17, 18, '吴昊天', '110101199312057890', 1, DATE_SUB(NOW(), INTERVAL 18 DAY), DATE_SUB(NOW(), INTERVAL 19 DAY), NOW()),
(18, 19, '郑雅文', '110101199804181234', 1, DATE_SUB(NOW(), INTERVAL 17 DAY), DATE_SUB(NOW(), INTERVAL 18 DAY), NOW()),
(19, 20, '孙鹏飞', '110101199610105678', 1, DATE_SUB(NOW(), INTERVAL 16 DAY), DATE_SUB(NOW(), INTERVAL 17 DAY), NOW()),
(20, 21, '林静怡', '110101200201259012', 1, DATE_SUB(NOW(), INTERVAL 15 DAY), DATE_SUB(NOW(), INTERVAL 16 DAY), NOW()),
(21, 22, '黄俊杰', '110101199708153456', 1, DATE_SUB(NOW(), INTERVAL 14 DAY), DATE_SUB(NOW(), INTERVAL 15 DAY), NOW()),
(22, 23, '何雨桐', '110101200007077890', 1, DATE_SUB(NOW(), INTERVAL 13 DAY), DATE_SUB(NOW(), INTERVAL 14 DAY), NOW()),
(23, 24, '马晓峰', '110101199511301234', 1, DATE_SUB(NOW(), INTERVAL 12 DAY), DATE_SUB(NOW(), INTERVAL 13 DAY), NOW()),
(24, 25, '唐语嫣', '110101199909095678', 1, DATE_SUB(NOW(), INTERVAL 11 DAY), DATE_SUB(NOW(), INTERVAL 12 DAY), NOW());

-- ====================================================================
-- 3. enterprise - 企业信息表（8 条）
--    每位 HR 对应 1 家企业
--    region_id 引用已有区县级 region 数据
--    audit_status: 5 家已认证(1), 2 家待审(0), 1 家驳回(2)
-- ====================================================================

DELETE FROM `enterprise`;

INSERT INTO `enterprise` (`id`, `user_id`, `company_name`, `credit_code`, `license_img_url`, `industry`, `region_id`, `description`, `audit_status`, `audit_time`, `create_time`, `update_time`) VALUES
(1, 2, '味美滋餐饮管理有限公司',       '91440101MA5A1234567ABCDE', 'https://cdn.uniseek.com/licenses/1.jpg', '餐饮',     110105, '味美滋餐饮专注于中式快餐连锁经营，在北京拥有 20 余家门店，致力于为顾客提供健康美味的餐饮体验。', 1, DATE_SUB(NOW(), INTERVAL 25 DAY), DATE_SUB(NOW(), INTERVAL 26 DAY), NOW()),
(2, 3, '飞速达物流配送有限公司',       '91440300MA5B2345678EFGH', 'https://cdn.uniseek.com/licenses/2.jpg', '物流',     310115, '飞速达物流是一家专业的城市配送服务商，覆盖上海及周边地区，拥有完善的仓储物流体系。',             1, DATE_SUB(NOW(), INTERVAL 24 DAY), DATE_SUB(NOW(), INTERVAL 25 DAY), NOW()),
(3, 4, '智汇科技有限公司',             '91440300MA5C3456789IJKL', 'https://cdn.uniseek.com/licenses/3.jpg', 'IT',       440305, '智汇科技致力于为企业提供数字化转型解决方案，核心团队来自知名互联网公司。',                     1, DATE_SUB(NOW(), INTERVAL 23 DAY), DATE_SUB(NOW(), INTERVAL 24 DAY), NOW()),
(4, 5, '启航教育培训有限公司',         '91320105MA5D4567890MNOP', 'https://cdn.uniseek.com/licenses/4.jpg', '教育培训', 320105, '启航教育专注于 K12 课外辅导和职业技能培训，秉承因材施教的理念，帮助学员实现自我提升。',       1, DATE_SUB(NOW(), INTERVAL 21 DAY), DATE_SUB(NOW(), INTERVAL 22 DAY), NOW()),
(5, 6, '创艺空间设计有限公司',         '91330105MA5E5678901QRST', 'https://cdn.uniseek.com/licenses/5.jpg', '设计',     330105, '创艺空间是一家综合性设计公司，业务涵盖平面设计、UI/UX 设计、品牌设计等领域。',             1, DATE_SUB(NOW(), INTERVAL 19 DAY), DATE_SUB(NOW(), INTERVAL 20 DAY), NOW()),
(6, 7, '安心家政服务有限公司',         '91510108MA5F6789012UVWX', 'https://cdn.uniseek.com/licenses/6.jpg', '家政',     510108, '安心家政提供专业的家庭保洁、月嫂、老人陪护等家政服务，所有人员均持证上岗。',                 0, NULL,                               DATE_SUB(NOW(), INTERVAL 18 DAY), NOW()),
(7, 8, '美丽传说美容有限公司',         '91420106MA5G7890123YZAB', 'https://cdn.uniseek.com/licenses/7.jpg', '美容',     420106, '美丽传说美容会所是一家高端美容服务机构，提供美容护肤、美体塑形、美甲美睫等一站式服务。',   0, NULL,                               DATE_SUB(NOW(), INTERVAL 16 DAY), NOW()),
(8, 9, '万象综合服务有限公司',         '91430103MA5H8901234CDEF', 'https://cdn.uniseek.com/licenses/8.jpg', '其他',     430103, '万象综合服务涵盖活动策划、礼仪接待、展会服务等多领域，为客户提供优质的综合性服务解决方案。', 2, NULL,                               DATE_SUB(NOW(), INTERVAL 14 DAY), NOW());

-- ====================================================================
-- 4. resume - 在线简历表（16 条）
--    每位求职者（user_id 10-25）各 1 份简历
--    skills 为 JSON 数组格式字符串
--    experience 为富文本 HTML 格式
--    attachment_url 均为 NULL
-- ====================================================================

DELETE FROM `resume`;

INSERT INTO `resume` (`id`, `user_id`, `gender`, `birth_date`, `education`, `school`, `skills`, `experience`, `attachment_url`, `create_time`, `update_time`) VALUES
(1,  10, 0, '1998-05-12', '本科', '北京大学',
  '["Java","Spring Boot","MySQL","Redis","Git"]',
  '<p>曾在某互联网公司担任 Java 后端开发实习生，负责公司核心业务系统的 API 开发与维护，参与了千万级数据量的查询优化项目，将接口响应时间缩短 40%。</p>',
  NULL, DATE_SUB(NOW(), INTERVAL 27 DAY), NOW()),

(2,  11, 0, '1996-08-23', '本科', '北京理工大学',
  '["Python","Django","PostgreSQL","Docker","Linux"]',
  '<p>在科技创业公司担任 Python 后端开发，独立设计并实现了基于 Django 的在线教育平台后端架构，支持日均 10 万 + 用户访问。</p>',
  NULL, DATE_SUB(NOW(), INTERVAL 26 DAY), NOW()),

(3,  12, 0, '1995-03-17', '大专', '深圳职业技术学院',
  '["仓储管理","配送调度","WMS系统","Excel","数据分析"]',
  '<p>在大型物流公司担任仓储主管 2 年，负责仓库日常运营管理与配送调度优化，通过流程改进将出库效率提升了 25%。</p>',
  NULL, DATE_SUB(NOW(), INTERVAL 25 DAY), NOW()),

(4,  13, 1, '2000-11-08', '本科', '上海交通大学',
  '["Photoshop","UI设计","Figma","Sketch","Axure RP"]',
  '<p>在设计公司担任 UI 设计实习生，参与多个移动端 App 和 Web 端产品的界面设计工作，熟悉设计规范与交互流程。</p>',
  NULL, DATE_SUB(NOW(), INTERVAL 24 DAY), NOW()),

(5,  14, 0, '1997-07-01', '硕士', '浙江大学',
  '["数据分析","Python","机器学习","SQL","Tableau"]',
  '<p>在数据分析公司实习期间，利用 Python 和机器学习算法为电商客户构建用户画像模型，帮助客户将转化率提升了 15%。</p>',
  NULL, DATE_SUB(NOW(), INTERVAL 23 DAY), NOW()),

(6,  15, 1, '1999-02-14', '本科', '南京大学',
  '["文案策划","微信公众号运营","PS","短视频剪辑","活动策划"]',
  '<p>在传媒公司担任文案策划实习生，负责企业微信公众号的日常运营与内容创作，累计产出爆款文章 10 余篇，单篇最高阅读量 5 万 +。</p>',
  NULL, DATE_SUB(NOW(), INTERVAL 22 DAY), NOW()),

(7,  16, 0, '1994-09-20', '本科', '华中科技大学',
  '["Android开发","Kotlin","Java","Jetpack","Android Studio"]',
  '<p>在移动互联网公司担任 Android 开发工程师，主导了公司核心产品的 Android 端架构升级，提升了应用稳定性和用户体验。</p>',
  NULL, DATE_SUB(NOW(), INTERVAL 21 DAY), NOW()),

(8,  17, 1, '2001-06-30', '大专', '广州番禺职业技术学院',
  '["美容护理","化妆造型","皮肤管理","美甲","客户沟通"]',
  '<p>在高端美容会所实习期间，系统学习了皮肤护理和化妆造型技术，服务客户满意度达 98%，被评为优秀实习生。</p>',
  NULL, DATE_SUB(NOW(), INTERVAL 20 DAY), NOW()),

(9,  18, 0, '1993-12-05', '本科', '西安电子科技大学',
  '["前端开发","Vue.js","JavaScript","TypeScript","Element UI"]',
  '<p>在互联网公司担任前端开发工程师，负责公司管理后台系统的前端开发，使用 Vue.js 框架实现了复杂的数据可视化大屏。</p>',
  NULL, DATE_SUB(NOW(), INTERVAL 19 DAY), NOW()),

(10, 19, 1, '1998-04-18', '本科', '厦门大学',
  '["英语翻译","CAT工具","口译","日语","中文写作"]',
  '<p>在外贸公司担任英语翻译实习生，负责商务文件的中英互译及外宾接待口译工作，累计翻译文档 30 万余字。</p>',
  NULL, DATE_SUB(NOW(), INTERVAL 18 DAY), NOW()),

(11, 20, 0, '1996-10-10', '大专', '武汉职业技术学院',
  '["餐饮管理","客户服务","团队协作","食品安全","收银系统"]',
  '<p>在连锁餐饮企业从服务员做起，后升任前厅主管，负责门店日常运营与员工排班管理，积累了丰富的餐饮行业经验。</p>',
  NULL, DATE_SUB(NOW(), INTERVAL 17 DAY), NOW()),

(12, 21, 1, '2002-01-25', '本科', '四川大学',
  '["会计核算","用友软件","Excel","税务申报","财务分析"]',
  '<p>在会计师事务所实习期间，协助完成多家企业的年度财务报表审计工作，熟悉企业会计核算流程与税务申报规范。</p>',
  NULL, DATE_SUB(NOW(), INTERVAL 16 DAY), NOW()),

(13, 22, 0, '1997-08-15', '硕士', '哈尔滨工业大学',
  '["嵌入式开发","C++","RTOS","STM32","Linux驱动"]',
  '<p>在智能硬件公司担任嵌入式开发实习生，参与了物联网网关设备的嵌入式软件开发，负责底层驱动调试与通信协议实现。</p>',
  NULL, DATE_SUB(NOW(), INTERVAL 15 DAY), NOW()),

(14, 23, 1, '2000-07-07', '本科', '中山大学',
  '["视频剪辑","Premiere Pro","After Effects","Final Cut Pro","摄影"]',
  '<p>在影视制作公司实习期间，参与多个短视频和宣传片项目的后期剪辑与特效制作，熟悉全流程制作规范。</p>',
  NULL, DATE_SUB(NOW(), INTERVAL 14 DAY), NOW()),

(15, 24, 0, '1995-11-30', '本科', '大连理工大学',
  '["机械设计","AutoCAD","SolidWorks","工艺设计","工程制图"]',
  '<p>在机械制造企业担任助理工程师，负责机械零部件的图纸设计与工艺文件编制，参与了两条自动化产线的改造项目。</p>',
  NULL, DATE_SUB(NOW(), INTERVAL 13 DAY), NOW()),

(16, 25, 1, '1999-09-09', '大专', '湖南女子学院',
  '["礼仪接待","茶艺","会务服务","沟通协调","应急处理"]',
  '<p>在高端商务会所担任礼仪接待实习生，负责贵宾接待与大型会议的服务保障工作，获得客户多次书面表扬。</p>',
  NULL, DATE_SUB(NOW(), INTERVAL 12 DAY), NOW());

-- ====================================================================
-- 5. task - 职位/岗位表（20 条）
--     分布在 8 家企业下，覆盖多种分类与状态
-- ====================================================================

DELETE FROM `task`;

INSERT INTO `task` (`id`, `enterprise_id`, `category_id`, `region_id`, `title`, `description`, `salary_min`, `salary_max`, `salary_unit`, `job_type`, `total_quota`, `remaining_quota`, `address`, `tag`, `longitude`, `latitude`, `status`, `version`, `deadline`, `audit_time`, `create_time`, `update_time`) VALUES
-- Enterprise 1: 味美滋餐饮（朝阳区） - 3 条
(1, 1, 16, 110105, '周末餐厅服务员',
 '<p>味美滋餐饮朝阳门店诚聘周末服务员，负责餐厅日常接待、点餐、上菜及卫生维护工作。要求：服务意识强，有餐饮行业经验者优先。包三餐，待遇优厚。</p>',
 120.00, 180.00, 0, 2, 8, 5, '北京市朝阳区建国路88号味美滋大厦B1层', '["兼职","周末","包吃"]', 116.4605000, 39.9087000, 1, 0, DATE_ADD(NOW(), INTERVAL 30 DAY), DATE_SUB(NOW(), INTERVAL 10 DAY), DATE_SUB(NOW(), INTERVAL 15 DAY), NOW()),

(2, 1, 17, 110105, '后厨帮工',
 '<p>味美滋餐饮后厨招聘帮工，负责食材清洗、切配、餐具清洗及厨房卫生维护。要求：吃苦耐劳，有后厨经验优先。月休4天，包食宿。</p>',
 3500.00, 5000.00, 2, 1, 5, 3, '北京市朝阳区望京西路12号味美滋后厨中心', '["全职","包吃住","五险"]', 116.4802000, 39.9928000, 1, 0, DATE_ADD(NOW(), INTERVAL 45 DAY), DATE_SUB(NOW(), INTERVAL 8 DAY), DATE_SUB(NOW(), INTERVAL 13 DAY), NOW()),

(3, 1, 19, 110105, '餐厅收银员',
 '<p>味美滋餐饮招聘收银员，负责门店收银、账单核对、发票开具及每日营收报表汇总。要求：熟练操作收银系统，细心负责。</p>',
 4000.00, 5500.00, 2, 1, 4, 0, '北京市朝阳区朝阳大悦城B2层味美滋', '["全职","五险","收银"]', 116.4984000, 39.9201000, 2, 0, DATE_ADD(NOW(), INTERVAL 20 DAY), DATE_SUB(NOW(), INTERVAL 6 DAY), DATE_SUB(NOW(), INTERVAL 14 DAY), NOW()),

-- Enterprise 2: 飞速达物流（浦东新区） - 3 条
(4, 2, 26, 310115, '外卖配送员',
 '<p>飞速达物流诚聘外卖配送员，负责浦东新区范围内的餐品配送服务。工作时间灵活，可按天接单。要求：自备电动车，熟悉浦东路况，年满18周岁。</p>',
 150.00, 300.00, 0, 2, 20, 12, '上海市浦东新区陆家嘴环路958号配送站', '["兼职","日结","自备车辆"]', 121.5058000, 31.2421000, 1, 0, DATE_ADD(NOW(), INTERVAL 60 DAY), DATE_SUB(NOW(), INTERVAL 12 DAY), DATE_SUB(NOW(), INTERVAL 15 DAY), NOW()),

(5, 2, 25, 310115, '快递分拣员',
 '<p>飞速达物流招聘快递分拣员，负责快递包裹的分拣、扫描、打包工作。晚班作业，时薪制，适合兼职学生。提供夜宵。</p>',
 20.00, 30.00, 1, 2, 15, 8, '上海市浦东新区川沙路5889号分拣中心', '["兼职","夜班","时薪"]', 121.6984000, 31.1878000, 1, 0, DATE_ADD(NOW(), INTERVAL 25 DAY), DATE_SUB(NOW(), INTERVAL 7 DAY), DATE_SUB(NOW(), INTERVAL 12 DAY), NOW()),

(6, 2, 27, 310115, '仓库管理员',
 '<p>飞速达物流诚聘仓库管理员，负责仓库货物的入库登记、库存盘点、出库核对及仓库5S管理。要求：有仓储管理经验，熟悉WMS系统者优先。</p>',
 5000.00, 7000.00, 2, 1, 3, 0, '上海市浦东新区外高桥保税区仓库A区', '["全职","五险一金","仓库管理"]', 121.6084000, 31.3518000, 3, 0, DATE_SUB(NOW(), INTERVAL 5 DAY), DATE_SUB(NOW(), INTERVAL 15 DAY), DATE_SUB(NOW(), INTERVAL 18 DAY), NOW()),

-- Enterprise 3: 智汇科技（南山区） - 2 条
(7, 3, 41, 440305, '软件测试实习生',
 '<p>智汇科技招聘软件测试实习生，参与公司核心产品的功能测试、接口测试和自动化测试脚本编写。要求：计算机相关专业，熟悉测试流程，了解Selenium或Postman等工具。</p>',
 3000.00, 4500.00, 2, 3, 5, 5, '深圳市南山区科技园南区智汇大厦12楼', '["实习","软件测试","双休"]', 113.9521000, 22.5371000, 1, 0, DATE_ADD(NOW(), INTERVAL 40 DAY), DATE_SUB(NOW(), INTERVAL 9 DAY), DATE_SUB(NOW(), INTERVAL 12 DAY), NOW()),

(8, 3, 42, 440305, '技术助理',
 '<p>智汇科技诚聘技术助理，协助技术总监进行项目进度跟踪、技术文档整理、会议安排及跨部门沟通协调。要求：理工科背景，熟练使用Office办公软件，具备良好的沟通能力。</p>',
 6000.00, 8000.00, 2, 1, 3, 3, '深圳市南山区科技园南区智汇大厦12楼', '["全职","五险一金","技术助理"]', 113.9521000, 22.5371000, 0, 0, DATE_ADD(NOW(), INTERVAL 30 DAY), NULL, DATE_SUB(NOW(), INTERVAL 3 DAY), NOW()),

-- Enterprise 4: 启航教育（姑苏区） - 3 条
(9, 4, 22, 320508, '初中数学家教',
 '<p>启航教育招聘初中数学家教老师，负责初一至初三学生的数学辅导，小班制教学（每班6-8人）。要求：数学功底扎实，有家教或教学经验者优先，师范类专业更佳。</p>',
 50.00, 80.00, 1, 2, 6, 4, '苏州市姑苏区观前街188号启航教育3楼', '["兼职","家教","周末"]', 120.6325000, 31.2982000, 1, 0, DATE_ADD(NOW(), INTERVAL 35 DAY), DATE_SUB(NOW(), INTERVAL 11 DAY), DATE_SUB(NOW(), INTERVAL 14 DAY), NOW()),

(10, 4, 21, 320508, '小学陪读老师',
 '<p>启航教育招聘小学陪读老师，负责小学生课后作业辅导、阅读陪伴及兴趣培养。工作时间：周一至周五下午16:00-19:00。要求：有耐心，喜欢孩子，教育相关专业优先。</p>',
 25.00, 40.00, 1, 2, 8, 6, '苏州市姑苏区十全街256号启航教育分部', '["兼职","陪读","小学"]', 120.6410000, 31.2915000, 1, 0, DATE_ADD(NOW(), INTERVAL 20 DAY), DATE_SUB(NOW(), INTERVAL 5 DAY), DATE_SUB(NOW(), INTERVAL 10 DAY), NOW()),

(11, 4, 22, 320508, '高中英语家教',
 '<p>启航教育诚聘高中英语家教，负责高一至高三学生英语辅导，重点提升阅读理解和写作能力。要求：英语专业八级或同等水平，有高考英语辅导经验优先。</p>',
 60.00, 100.00, 1, 2, 4, 3, '苏州市姑苏区干将东路333号启航教育总部', '["兼职","家教","英语"]', 120.6490000, 31.3015000, 1, 0, DATE_ADD(NOW(), INTERVAL 30 DAY), DATE_SUB(NOW(), INTERVAL 3 DAY), DATE_SUB(NOW(), INTERVAL 13 DAY), NOW()),

-- Enterprise 5: 创艺空间设计（宝安区） - 3 条
(12, 5, 28, 440306, '平面设计师',
 '<p>创艺空间招聘平面设计师，负责企业品牌视觉设计、宣传物料设计（海报、画册、展架等）及社交媒体视觉内容制作。要求：精通PS/AI，有2年以上设计经验。</p>',
 7000.00, 10000.00, 2, 1, 3, 2, '深圳市宝安区宝安中心区创业一路1008号设计大厦5层', '["全职","五险一金","平面设计"]', 113.8830000, 22.5549000, 1, 0, DATE_ADD(NOW(), INTERVAL 30 DAY), DATE_SUB(NOW(), INTERVAL 4 DAY), DATE_SUB(NOW(), INTERVAL 10 DAY), NOW()),

(13, 5, 29, 440306, 'UI设计实习生',
 '<p>创艺空间招募UI设计实习生，参与移动端App和Web端产品的UI界面设计，协助设计师完成图标绘制、切图标注等工作。要求：熟悉Figma或Sketch，有作品集。</p>',
 2000.00, 3000.00, 2, 3, 4, 0, '深圳市宝安区宝安中心区创业一路1008号设计大厦5层', '["实习","UI设计","双休"]', 113.8830000, 22.5549000, 2, 0, DATE_ADD(NOW(), INTERVAL 15 DAY), DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 14 DAY), NOW()),

(14, 5, 30, 440306, '短视频剪辑',
 '<p>创艺空间诚聘短视频剪辑师，负责抖音/小红书等平台的短视频剪辑、特效添加及字幕制作。可兼职按单结算。要求：熟练使用Premiere Pro或剪映，有创意有网感。</p>',
 100.00, 300.00, 0, 2, 5, 3, '深圳市宝安区西乡街道创意产业园C栋203', '["兼职","日结","视频剪辑"]', 113.8720000, 22.5788000, 1, 0, DATE_ADD(NOW(), INTERVAL 45 DAY), DATE_SUB(NOW(), INTERVAL 6 DAY), DATE_SUB(NOW(), INTERVAL 11 DAY), NOW()),

-- Enterprise 6: 安心家政（朝阳区） - 2 条
(15, 6, 61, 110105, '家庭保洁员',
 '<p>安心家政诚聘家庭保洁员，负责家庭日常保洁、深度清洁及擦窗服务。按单计酬，时间灵活。要求：有保洁经验优先，自备交通工具，服务意识强。</p>',
 30.00, 50.00, 1, 2, 10, 7, '北京市朝阳区和平街10号安心家政服务中心', '["兼职","时薪","保洁"]', 116.4180000, 39.9605000, 1, 0, DATE_ADD(NOW(), INTERVAL 60 DAY), DATE_SUB(NOW(), INTERVAL 5 DAY), DATE_SUB(NOW(), INTERVAL 10 DAY), NOW()),

(16, 6, 61, 110105, '家政服务人员',
 '<p>安心家政招聘全职家政服务人员，提供家庭保洁、衣物整理、简单烹饪等综合家政服务。公司提供专业培训，月休4天。要求：身体健康，品行端正，有责任心。</p>',
 4500.00, 6000.00, 2, 1, 5, 5, '北京市朝阳区和平街10号安心家政服务中心', '["全职","培训","五险"]', 116.4180000, 39.9605000, 0, 0, DATE_ADD(NOW(), INTERVAL 30 DAY), NULL, DATE_SUB(NOW(), INTERVAL 2 DAY), NOW()),

-- Enterprise 7: 美丽传说美容（南山区） - 2 条
(17, 7, 31, 440305, '美容导购员',
 '<p>美丽传说美容会所招聘美容导购员，负责店内美容产品介绍、体验引导及客户维护。要求：形象气质佳，有美容或销售经验优先，无经验可带薪培训。</p>',
 5000.00, 8000.00, 2, 1, 5, 3, '深圳市南山区后海路888号美丽传说1层', '["全职","五险","导购"]', 113.9417000, 22.5212000, 1, 0, DATE_ADD(NOW(), INTERVAL 25 DAY), DATE_SUB(NOW(), INTERVAL 3 DAY), DATE_SUB(NOW(), INTERVAL 8 DAY), NOW()),

(18, 7, 32, 440305, '护肤品促销员',
 '<p>美丽传说美容会所招聘护肤品促销员，在南山各大商场进行品牌护肤品推广促销活动。按天结算，周末为主。要求：性格开朗，表达能力强，有促销经验优先。</p>',
 130.00, 200.00, 0, 2, 8, 8, '深圳市南山区海岸城购物中心B1层', '["兼职","日结","促销"]', 113.9372000, 22.5115000, 4, 0, DATE_ADD(NOW(), INTERVAL 10 DAY), DATE_SUB(NOW(), INTERVAL 1 DAY), DATE_SUB(NOW(), INTERVAL 8 DAY), NOW()),

-- Enterprise 8: 万象综合服务（朝阳区） - 2 条
(19, 8, 37, 110105, '公众号文案编辑',
 '<p>万象综合服务招聘公众号文案编辑，负责企业微信公众号的内容策划、文章撰写及排版发布。要求：文字功底扎实，熟悉公众号后台操作，有新媒体运营经验优先。</p>',
 4000.00, 6000.00, 2, 2, 3, 0, '北京市朝阳区东三环中路39号万象中心8层', '["兼职","月结","文案"]', 116.4625000, 39.9080000, 2, 0, DATE_ADD(NOW(), INTERVAL 15 DAY), DATE_SUB(NOW(), INTERVAL 4 DAY), DATE_SUB(NOW(), INTERVAL 12 DAY), NOW()),

(20, 8, 61, 110105, '展会礼仪接待',
 '<p>万象综合服务诚聘展会礼仪接待人员，负责展会期间的来宾接待、签到引导、资料发放等工作。形象端庄，沟通能力强，有礼仪经验优先。</p>',
 180.00, 350.00, 0, 2, 6, 0, '北京市朝阳区国家会议中心E3馆', '["兼职","日结","礼仪"]', 116.3875000, 39.9958000, 3, 0, DATE_SUB(NOW(), INTERVAL 7 DAY), DATE_SUB(NOW(), INTERVAL 15 DAY), DATE_SUB(NOW(), INTERVAL 15 DAY), NOW());

-- ====================================================================
-- 6. task_application - 投递报名表（50 条）
--     覆盖所有投递状态，确保无重复（uk_task_applicant）
-- ====================================================================

DELETE FROM `task_application`;

INSERT INTO `task_application` (`id`, `task_id`, `applicant_id`, `resume_snapshot`, `attachment_url`, `status`, `hr_id`, `interview_time`, `interview_location`, `reject_reason`, `hr_note`, `version`, `create_time`, `update_time`) VALUES
-- 求职者 10 张小芒（3 条投递 + 1 条额外）
(1, 1, 10,
 '{"realName":"张小芒","gender":0,"birthDate":"1998-05-12","education":"本科","school":"北京大学","skills":"[\"Java\",\"Spring Boot\",\"MySQL\"]","experience":"<p>曾在某互联网公司担任 Java 后端开发实习生。</p>"}',
 NULL, 3, 2, NULL, NULL, NULL, '技术基础扎实，适合后端岗位', 0, DATE_SUB(NOW(), INTERVAL 8 DAY), NOW()),
(2, 4, 10,
 '{"realName":"张小芒","gender":0,"birthDate":"1998-05-12","education":"本科","school":"北京大学","skills":"[\"Java\",\"Spring Boot\",\"MySQL\"]","experience":"<p>曾在某互联网公司担任 Java 后端开发实习生。</p>"}',
 NULL, 0, NULL, NULL, NULL, NULL, NULL, 0, DATE_SUB(NOW(), INTERVAL 3 DAY), NOW()),
(3, 7, 10,
 '{"realName":"张小芒","gender":0,"birthDate":"1998-05-12","education":"本科","school":"北京大学","skills":"[\"Java\",\"Spring Boot\",\"MySQL\"]","experience":"<p>曾在某互联网公司担任 Java 后端开发实习生。</p>"}',
 NULL, 1, 4, DATE_ADD(NOW(), INTERVAL 5 DAY), '深圳市南山区科技园南区智汇大厦12楼会议室', NULL, '已安排面试', 0, DATE_SUB(NOW(), INTERVAL 6 DAY), NOW()),
(4, 12, 10,
 '{"realName":"张小芒","gender":0,"birthDate":"1998-05-12","education":"本科","school":"北京大学","skills":"[\"Java\",\"Spring Boot\",\"MySQL\"]","experience":"<p>曾在某互联网公司担任 Java 后端开发实习生。</p>"}',
 NULL, 0, NULL, NULL, NULL, NULL, NULL, 0, DATE_SUB(NOW(), INTERVAL 2 DAY), NOW()),

-- 求职者 11 李小明（3 条投递）
(5, 4, 11,
 '{"realName":"李小明","gender":0,"birthDate":"1996-08-23","education":"本科","school":"北京理工大学","skills":"[\"Python\",\"Django\",\"PostgreSQL\"]","experience":"<p>在科技创业公司担任 Python 后端开发。</p>"}',
 NULL, 1, 3, DATE_ADD(NOW(), INTERVAL 3 DAY), '上海市浦东新区陆家嘴环路958号配送站2楼办公室', NULL, '沟通良好，安排配送岗面试', 0, DATE_SUB(NOW(), INTERVAL 7 DAY), NOW()),
(6, 5, 11,
 '{"realName":"李小明","gender":0,"birthDate":"1996-08-23","education":"本科","school":"北京理工大学","skills":"[\"Python\",\"Django\",\"PostgreSQL\"]","experience":"<p>在科技创业公司担任 Python 后端开发。</p>"}',
 NULL, 2, 3, NULL, NULL, NULL, '面试通过，待入职确认', 0, DATE_SUB(NOW(), INTERVAL 5 DAY), NOW()),
(7, 7, 11,
 '{"realName":"李小明","gender":0,"birthDate":"1996-08-23","education":"本科","school":"北京理工大学","skills":"[\"Python\",\"Django\",\"PostgreSQL\"]","experience":"<p>在科技创业公司担任 Python 后端开发。</p>"}',
 NULL, 4, 4, NULL, NULL, '编程能力尚可但缺乏测试相关经验', '建议转投开发岗位', 0, DATE_SUB(NOW(), INTERVAL 4 DAY), NOW()),

-- 求职者 12 王大力（3 条投递）
(8, 4, 12,
 '{"realName":"王大力","gender":0,"birthDate":"1995-03-17","education":"大专","school":"深圳职业技术学院","skills":"[\"仓储管理\",\"配送调度\",\"WMS系统\"]","experience":"<p>在大型物流公司担任仓储主管2年。</p>"}',
 NULL, 3, 3, NULL, NULL, NULL, '物流经验丰富，直接录用', 0, DATE_SUB(NOW(), INTERVAL 9 DAY), NOW()),
(9, 5, 12,
 '{"realName":"王大力","gender":0,"birthDate":"1995-03-17","education":"大专","school":"深圳职业技术学院","skills":"[\"仓储管理\",\"配送调度\",\"WMS系统\"]","experience":"<p>在大型物流公司担任仓储主管2年。</p>"}',
 NULL, 1, 3, DATE_ADD(NOW(), INTERVAL 4 DAY), '上海市浦东新区川沙路5889号分拣中心办公室', NULL, '安排分拣岗位试岗', 0, DATE_SUB(NOW(), INTERVAL 6 DAY), NOW()),
(10, 6, 12,
 '{"realName":"王大力","gender":0,"birthDate":"1995-03-17","education":"大专","school":"深圳职业技术学院","skills":"[\"仓储管理\",\"配送调度\",\"WMS系统\"]","experience":"<p>在大型物流公司担任仓储主管2年。</p>"}',
 NULL, 4, 3, NULL, NULL, '岗位已满员，暂无法安排', '可推荐其他仓库岗位', 0, DATE_SUB(NOW(), INTERVAL 10 DAY), NOW()),

-- 求职者 13 赵晓燕（4 条投递）
(11, 12, 13,
 '{"realName":"赵晓燕","gender":1,"birthDate":"2000-11-08","education":"本科","school":"上海交通大学","skills":"[\"Photoshop\",\"UI设计\",\"Figma\"]","experience":"<p>在设计公司担任 UI 设计实习生。</p>"}',
 NULL, 2, 6, NULL, NULL, NULL, '设计能力突出，通过面试', 0, DATE_SUB(NOW(), INTERVAL 5 DAY), NOW()),
(12, 13, 13,
 '{"realName":"赵晓燕","gender":1,"birthDate":"2000-11-08","education":"本科","school":"上海交通大学","skills":"[\"Photoshop\",\"UI设计\",\"Figma\"]","experience":"<p>在设计公司担任 UI 设计实习生。</p>"}',
 NULL, 0, NULL, NULL, NULL, NULL, NULL, 0, DATE_SUB(NOW(), INTERVAL 3 DAY), NOW()),
(13, 14, 13,
 '{"realName":"赵晓燕","gender":1,"birthDate":"2000-11-08","education":"本科","school":"上海交通大学","skills":"[\"Photoshop\",\"UI设计\",\"Figma\"]","experience":"<p>在设计公司担任 UI 设计实习生。</p>"}',
 NULL, 3, 6, NULL, NULL, NULL, '已录用为短视频剪辑岗', 0, DATE_SUB(NOW(), INTERVAL 7 DAY), NOW()),
(14, 7, 13,
 '{"realName":"赵晓燕","gender":1,"birthDate":"2000-11-08","education":"本科","school":"上海交通大学","skills":"[\"Photoshop\",\"UI设计\",\"Figma\"]","experience":"<p>在设计公司担任 UI 设计实习生。</p>"}',
 NULL, 3, 4, NULL, NULL, NULL, '已录用为测试实习生', 0, DATE_SUB(NOW(), INTERVAL 4 DAY), NOW()),

-- 求职者 14 刘志强（3 条投递）
(15, 1, 14,
 '{"realName":"刘志强","gender":0,"birthDate":"1997-07-01","education":"硕士","school":"浙江大学","skills":"[\"数据分析\",\"Python\",\"机器学习\"]","experience":"<p>在数据分析公司实习，使用Python分析电商数据。</p>"}',
 NULL, 4, 2, NULL, NULL, '学历过高，担心稳定性', NULL, 0, DATE_SUB(NOW(), INTERVAL 5 DAY), NOW()),
(16, 7, 14,
 '{"realName":"刘志强","gender":0,"birthDate":"1997-07-01","education":"硕士","school":"浙江大学","skills":"[\"数据分析\",\"Python\",\"机器学习\"]","experience":"<p>在数据分析公司实习，使用Python分析电商数据。</p>"}',
 NULL, 5, 4, NULL, NULL, NULL, '已完成测试实习，表现优秀', 0, DATE_SUB(NOW(), INTERVAL 12 DAY), NOW()),
(17, 8, 14,
 '{"realName":"刘志强","gender":0,"birthDate":"1997-07-01","education":"硕士","school":"浙江大学","skills":"[\"数据分析\",\"Python\",\"机器学习\"]","experience":"<p>在数据分析公司实习，使用Python分析电商数据。</p>"}',
 NULL, 1, 4, DATE_ADD(NOW(), INTERVAL 6 DAY), '深圳市南山区科技园南区智汇大厦8楼会议室', NULL, '安排技术助理面试', 0, DATE_SUB(NOW(), INTERVAL 2 DAY), NOW()),

-- 求职者 15 陈思雨（4 条投递）
(18, 9, 15,
 '{"realName":"陈思雨","gender":1,"birthDate":"1999-02-14","education":"本科","school":"南京大学","skills":"[\"文案策划\",\"公众号运营\",\"PS\"]","experience":"<p>在传媒公司担任文案策划实习生。</p>"}',
 NULL, 3, 5, NULL, NULL, NULL, '文案功底强，录用为数学助教', 0, DATE_SUB(NOW(), INTERVAL 8 DAY), NOW()),
(19, 10, 15,
 '{"realName":"陈思雨","gender":1,"birthDate":"1999-02-14","education":"本科","school":"南京大学","skills":"[\"文案策划\",\"公众号运营\",\"PS\"]","experience":"<p>在传媒公司担任文案策划实习生。</p>"}',
 NULL, 1, 5, DATE_ADD(NOW(), INTERVAL 2 DAY), '苏州市姑苏区十全街256号启航教育分部', NULL, '安排陪读面试', 0, DATE_SUB(NOW(), INTERVAL 4 DAY), NOW()),
(20, 14, 15,
 '{"realName":"陈思雨","gender":1,"birthDate":"1999-02-14","education":"本科","school":"南京大学","skills":"[\"文案策划\",\"公众号运营\",\"PS\"]","experience":"<p>在传媒公司担任文案策划实习生。</p>"}',
 NULL, 0, NULL, NULL, NULL, NULL, NULL, 0, DATE_SUB(NOW(), INTERVAL 1 DAY), NOW()),
(21, 19, 15,
 '{"realName":"陈思雨","gender":1,"birthDate":"1999-02-14","education":"本科","school":"南京大学","skills":"[\"文案策划\",\"公众号运营\",\"PS\"]","experience":"<p>在传媒公司担任文案策划实习生。</p>"}',
 NULL, 4, 9, NULL, NULL, '岗位已满员', '可考虑下次招聘', 0, DATE_SUB(NOW(), INTERVAL 6 DAY), NOW()),

-- 求职者 16 杨浩宇（3 条投递）
(22, 7, 16,
 '{"realName":"杨浩宇","gender":0,"birthDate":"1994-09-20","education":"本科","school":"华中科技大学","skills":"[\"Android开发\",\"Kotlin\",\"Java\"]","experience":"<p>在移动互联网公司担任 Android 开发工程师。</p>"}',
 NULL, 5, 4, NULL, NULL, NULL, '已完成测试实习，代码质量高', 0, DATE_SUB(NOW(), INTERVAL 14 DAY), NOW()),
(23, 8, 16,
 '{"realName":"杨浩宇","gender":0,"birthDate":"1994-09-20","education":"本科","school":"华中科技大学","skills":"[\"Android开发\",\"Kotlin\",\"Java\"]","experience":"<p>在移动互联网公司担任 Android 开发工程师。</p>"}',
 NULL, 0, NULL, NULL, NULL, NULL, NULL, 0, DATE_SUB(NOW(), INTERVAL 2 DAY), NOW()),
(24, 12, 16,
 '{"realName":"杨浩宇","gender":0,"birthDate":"1994-09-20","education":"本科","school":"华中科技大学","skills":"[\"Android开发\",\"Kotlin\",\"Java\"]","experience":"<p>在移动互联网公司担任 Android 开发工程师。</p>"}',
 NULL, 0, NULL, NULL, NULL, NULL, NULL, 0, DATE_SUB(NOW(), INTERVAL 1 DAY), NOW()),

-- 求职者 17 周美玲（3 条投递）
(25, 15, 17,
 '{"realName":"周美玲","gender":1,"birthDate":"2001-06-30","education":"大专","school":"广州番禺职业技术学院","skills":"[\"美容护理\",\"化妆造型\",\"皮肤管理\"]","experience":"<p>在高端美容会所实习，服务客户满意度98%。</p>"}',
 NULL, 2, 7, NULL, NULL, NULL, '面试通过，适合家政岗位', 0, DATE_SUB(NOW(), INTERVAL 4 DAY), NOW()),
(26, 17, 17,
 '{"realName":"周美玲","gender":1,"birthDate":"2001-06-30","education":"大专","school":"广州番禺职业技术学院","skills":"[\"美容护理\",\"化妆造型\",\"皮肤管理\"]","experience":"<p>在高端美容会所实习，服务客户满意度98%。</p>"}',
 NULL, 3, 8, NULL, NULL, NULL, '美容经验丰富，录用为导购', 0, DATE_SUB(NOW(), INTERVAL 6 DAY), NOW()),
(27, 18, 17,
 '{"realName":"周美玲","gender":1,"birthDate":"2001-06-30","education":"大专","school":"广州番禺职业技术学院","skills":"[\"美容护理\",\"化妆造型\",\"皮肤管理\"]","experience":"<p>在高端美容会所实习，服务客户满意度98%。</p>"}',
 NULL, 0, NULL, NULL, NULL, NULL, NULL, 0, DATE_SUB(NOW(), INTERVAL 3 DAY), NOW()),

-- 求职者 18 吴昊天（3 条投递）
(28, 5, 18,
 '{"realName":"吴昊天","gender":0,"birthDate":"1993-12-05","education":"本科","school":"西安电子科技大学","skills":"[\"前端开发\",\"Vue.js\",\"JavaScript\"]","experience":"<p>在互联网公司担任前端开发工程师。</p>"}',
 NULL, 1, 3, DATE_ADD(NOW(), INTERVAL 5 DAY), '上海市浦东新区川沙路5889号分拣中心2楼', NULL, '安排面试', 0, DATE_SUB(NOW(), INTERVAL 3 DAY), NOW()),
(29, 7, 18,
 '{"realName":"吴昊天","gender":0,"birthDate":"1993-12-05","education":"本科","school":"西安电子科技大学","skills":"[\"前端开发\",\"Vue.js\",\"JavaScript\"]","experience":"<p>在互联网公司担任前端开发工程师。</p>"}',
 NULL, 5, 4, NULL, NULL, NULL, '完成测试实习，转投开发岗', 0, DATE_SUB(NOW(), INTERVAL 13 DAY), NOW()),
(30, 8, 18,
 '{"realName":"吴昊天","gender":0,"birthDate":"1993-12-05","education":"本科","school":"西安电子科技大学","skills":"[\"前端开发\",\"Vue.js\",\"JavaScript\"]","experience":"<p>在互联网公司担任前端开发工程师。</p>"}',
 NULL, 0, NULL, NULL, NULL, NULL, NULL, 0, DATE_SUB(NOW(), INTERVAL 1 DAY), NOW()),

-- 求职者 19 郑雅文（3 条投递）
(31, 9, 19,
 '{"realName":"郑雅文","gender":1,"birthDate":"1998-04-18","education":"本科","school":"厦门大学","skills":"[\"英语翻译\",\"CAT工具\",\"日语\"]","experience":"<p>在外贸公司担任英语翻译实习生。</p>"}',
 NULL, 0, NULL, NULL, NULL, NULL, NULL, 0, DATE_SUB(NOW(), INTERVAL 4 DAY), NOW()),
(32, 10, 19,
 '{"realName":"郑雅文","gender":1,"birthDate":"1998-04-18","education":"本科","school":"厦门大学","skills":"[\"英语翻译\",\"CAT工具\",\"日语\"]","experience":"<p>在外贸公司担任英语翻译实习生。</p>"}',
 NULL, 2, 5, NULL, NULL, NULL, '英语能力优秀，通过面试', 0, DATE_SUB(NOW(), INTERVAL 3 DAY), NOW()),
(33, 8, 19,
 '{"realName":"郑雅文","gender":1,"birthDate":"1998-04-18","education":"本科","school":"厦门大学","skills":"[\"英语翻译\",\"CAT工具\",\"日语\"]","experience":"<p>在外贸公司担任英语翻译实习生。</p>"}',
 NULL, 3, 4, NULL, NULL, NULL, '录用为技术助理', 0, DATE_SUB(NOW(), INTERVAL 5 DAY), NOW()),

-- 求职者 20 孙鹏飞（3 条投递）
(34, 1, 20,
 '{"realName":"孙鹏飞","gender":0,"birthDate":"1996-10-10","education":"大专","school":"武汉职业技术学院","skills":"[\"餐饮管理\",\"客户服务\",\"收银系统\"]","experience":"<p>在连锁餐饮企业从服务员做起，后升任前厅主管。</p>"}',
 NULL, 0, NULL, NULL, NULL, NULL, NULL, 0, DATE_SUB(NOW(), INTERVAL 2 DAY), NOW()),
(35, 2, 20,
 '{"realName":"孙鹏飞","gender":0,"birthDate":"1996-10-10","education":"大专","school":"武汉职业技术学院","skills":"[\"餐饮管理\",\"客户服务\",\"收银系统\"]","experience":"<p>在连锁餐饮企业从服务员做起，后升任前厅主管。</p>"}',
 NULL, 3, 2, NULL, NULL, NULL, '餐饮经验丰富，录用为后厨帮工', 0, DATE_SUB(NOW(), INTERVAL 7 DAY), NOW()),
(36, 3, 20,
 '{"realName":"孙鹏飞","gender":0,"birthDate":"1996-10-10","education":"大专","school":"武汉职业技术学院","skills":"[\"餐饮管理\",\"客户服务\",\"收银系统\"]","experience":"<p>在连锁餐饮企业从服务员做起，后升任前厅主管。</p>"}',
 NULL, 4, 2, NULL, NULL, '收银岗位已满员', NULL, 0, DATE_SUB(NOW(), INTERVAL 6 DAY), NOW()),

-- 求职者 21 林静怡（3 条投递）
(37, 1, 21,
 '{"realName":"林静怡","gender":1,"birthDate":"2002-01-25","education":"本科","school":"四川大学","skills":"[\"会计核算\",\"用友软件\",\"Excel\"]","experience":"<p>在会计师事务所实习，完成多家企业审计工作。</p>"}',
 NULL, 1, 2, DATE_ADD(NOW(), INTERVAL 3 DAY), '北京市朝阳区建国路88号味美滋大厦HR办公室', NULL, '安排服务员面试', 0, DATE_SUB(NOW(), INTERVAL 4 DAY), NOW()),
(38, 2, 21,
 '{"realName":"林静怡","gender":1,"birthDate":"2002-01-25","education":"本科","school":"四川大学","skills":"[\"会计核算\",\"用友软件\",\"Excel\"]","experience":"<p>在会计师事务所实习，完成多家企业审计工作。</p>"}',
 NULL, 0, NULL, NULL, NULL, NULL, NULL, 0, DATE_SUB(NOW(), INTERVAL 1 DAY), NOW()),
(39, 8, 21,
 '{"realName":"林静怡","gender":1,"birthDate":"2002-01-25","education":"本科","school":"四川大学","skills":"[\"会计核算\",\"用友软件\",\"Excel\"]","experience":"<p>在会计师事务所实习，完成多家企业审计工作。</p>"}',
 NULL, 1, 4, DATE_ADD(NOW(), INTERVAL 7 DAY), '深圳市南山区科技园南区智汇大厦8楼会议室', NULL, '安排技术助理面试', 0, DATE_SUB(NOW(), INTERVAL 2 DAY), NOW()),

-- 求职者 22 黄俊杰（3 条投递）
(40, 5, 22,
 '{"realName":"黄俊杰","gender":0,"birthDate":"1997-08-15","education":"硕士","school":"哈尔滨工业大学","skills":"[\"嵌入式开发\",\"C++\",\"RTOS\"]","experience":"<p>在智能硬件公司担任嵌入式开发实习生。</p>"}',
 NULL, 1, 3, DATE_ADD(NOW(), INTERVAL 6 DAY), '上海市浦东新区川沙路5889号分拣中心办公室', NULL, '转岗面试分拣员', 0, DATE_SUB(NOW(), INTERVAL 3 DAY), NOW()),
(41, 7, 22,
 '{"realName":"黄俊杰","gender":0,"birthDate":"1997-08-15","education":"硕士","school":"哈尔滨工业大学","skills":"[\"嵌入式开发\",\"C++\",\"RTOS\"]","experience":"<p>在智能硬件公司担任嵌入式开发实习生。</p>"}',
 NULL, 5, 4, NULL, NULL, NULL, '完成测试实习，返回学校', 0, DATE_SUB(NOW(), INTERVAL 15 DAY), NOW()),

-- 求职者 23 何雨桐（3 条投递）
(42, 12, 23,
 '{"realName":"何雨桐","gender":1,"birthDate":"2000-07-07","education":"本科","school":"中山大学","skills":"[\"视频剪辑\",\"Premiere Pro\",\"After Effects\"]","experience":"<p>在影视制作公司实习，参与多个视频项目后期。</p>"}',
 NULL, 0, NULL, NULL, NULL, NULL, NULL, 0, DATE_SUB(NOW(), INTERVAL 3 DAY), NOW()),
(43, 13, 23,
 '{"realName":"何雨桐","gender":1,"birthDate":"2000-07-07","education":"本科","school":"中山大学","skills":"[\"视频剪辑\",\"Premiere Pro\",\"After Effects\"]","experience":"<p>在影视制作公司实习，参与多个视频项目后期。</p>"}',
 NULL, 4, 6, NULL, NULL, 'UI设计经验不足，不符合要求', '可关注平面设计岗位', 0, DATE_SUB(NOW(), INTERVAL 5 DAY), NOW()),
(44, 14, 23,
 '{"realName":"何雨桐","gender":1,"birthDate":"2000-07-07","education":"本科","school":"中山大学","skills":"[\"视频剪辑\",\"Premiere Pro\",\"After Effects\"]","experience":"<p>在影视制作公司实习，参与多个视频项目后期。</p>"}',
 NULL, 2, 6, NULL, NULL, NULL, '视频剪辑面试通过', 0, DATE_SUB(NOW(), INTERVAL 4 DAY), NOW()),

-- 求职者 24 马晓峰（3 条投递）
(45, 1, 24,
 '{"realName":"马晓峰","gender":0,"birthDate":"1995-11-30","education":"本科","school":"大连理工大学","skills":"[\"机械设计\",\"AutoCAD\",\"SolidWorks\"]","experience":"<p>在机械制造企业担任助理工程师。</p>"}',
 NULL, 0, NULL, NULL, NULL, NULL, NULL, 0, DATE_SUB(NOW(), INTERVAL 2 DAY), NOW()),
(46, 2, 24,
 '{"realName":"马晓峰","gender":0,"birthDate":"1995-11-30","education":"本科","school":"大连理工大学","skills":"[\"机械设计\",\"AutoCAD\",\"SolidWorks\"]","experience":"<p>在机械制造企业担任助理工程师。</p>"}',
 NULL, 1, 2, DATE_ADD(NOW(), INTERVAL 4 DAY), '北京市朝阳区望京西路12号味美滋后厨中心', NULL, '安排后厨帮工面试', 0, DATE_SUB(NOW(), INTERVAL 3 DAY), NOW()),
(47, 15, 24,
 '{"realName":"马晓峰","gender":0,"birthDate":"1995-11-30","education":"本科","school":"大连理工大学","skills":"[\"机械设计\",\"AutoCAD\",\"SolidWorks\"]","experience":"<p>在机械制造企业担任助理工程师。</p>"}',
 NULL, 0, NULL, NULL, NULL, NULL, NULL, 0, DATE_SUB(NOW(), INTERVAL 1 DAY), NOW()),

-- 求职者 25 唐语嫣（3 条投递）
(48, 16, 25,
 '{"realName":"唐语嫣","gender":1,"birthDate":"1999-09-09","education":"大专","school":"湖南女子学院","skills":"[\"礼仪接待\",\"茶艺\",\"会务服务\"]","experience":"<p>在高端商务会所担任礼仪接待实习生。</p>"}',
 NULL, 0, NULL, NULL, NULL, NULL, NULL, 0, DATE_SUB(NOW(), INTERVAL 2 DAY), NOW()),
(49, 17, 25,
 '{"realName":"唐语嫣","gender":1,"birthDate":"1999-09-09","education":"大专","school":"湖南女子学院","skills":"[\"礼仪接待\",\"茶艺\",\"会务服务\"]","experience":"<p>在高端商务会所担任礼仪接待实习生。</p>"}',
 NULL, 5, 8, NULL, NULL, NULL, '完成美容导购工作，表现优秀', 0, DATE_SUB(NOW(), INTERVAL 10 DAY), NOW()),
(50, 20, 25,
 '{"realName":"唐语嫣","gender":1,"birthDate":"1999-09-09","education":"大专","school":"湖南女子学院","skills":"[\"礼仪接待\",\"茶艺\",\"会务服务\"]","experience":"<p>在高端商务会所担任礼仪接待实习生。</p>"}',
 NULL, 4, 9, NULL, NULL, '展会已结束，岗位取消', '下次有合适岗位优先联系', 0, DATE_SUB(NOW(), INTERVAL 8 DAY), NOW());

-- ====================================================================
-- 7. 更新 task.remaining_quota（根据已录用和已完成投递扣减名额）
-- ====================================================================

-- 已录用（status=3）扣减
UPDATE `task` SET `remaining_quota` = `remaining_quota` - 1 WHERE `id` = 1;  -- 张小芒→周末餐厅服务员
UPDATE `task` SET `remaining_quota` = `remaining_quota` - 1 WHERE `id` = 2;  -- 孙鹏飞→后厨帮工
UPDATE `task` SET `remaining_quota` = `remaining_quota` - 1 WHERE `id` = 4;  -- 王大力→外卖配送员
UPDATE `task` SET `remaining_quota` = `remaining_quota` - 1 WHERE `id` = 7;  -- 赵晓燕→软件测试实习生
UPDATE `task` SET `remaining_quota` = `remaining_quota` - 1 WHERE `id` = 8;  -- 郑雅文→技术助理
UPDATE `task` SET `remaining_quota` = `remaining_quota` - 1 WHERE `id` = 9;  -- 陈思雨→初中数学家教
UPDATE `task` SET `remaining_quota` = `remaining_quota` - 1 WHERE `id` = 14; -- 赵晓燕→短视频剪辑
UPDATE `task` SET `remaining_quota` = `remaining_quota` - 1 WHERE `id` = 17; -- 周美玲→美容导购员

-- 已完成（status=5，从已录用流转来，额外扣减）
UPDATE `task` SET `remaining_quota` = `remaining_quota` - 1 WHERE `id` = 7;  -- 刘志强→软件测试实习生（已完成）
UPDATE `task` SET `remaining_quota` = `remaining_quota` - 1 WHERE `id` = 7;  -- 杨浩宇→软件测试实习生（已完成）
UPDATE `task` SET `remaining_quota` = `remaining_quota` - 1 WHERE `id` = 7;  -- 吴昊天→软件测试实习生（已完成）
UPDATE `task` SET `remaining_quota` = `remaining_quota` - 1 WHERE `id` = 7;  -- 黄俊杰→软件测试实习生（已完成）
UPDATE `task` SET `remaining_quota` = `remaining_quota` - 1 WHERE `id` = 17; -- 唐语嫣→美容导购员（已完成）

-- 若 remaining_quota 降到 0，将岗位状态更新为已满员
UPDATE `task` SET `status` = 2 WHERE `id` = 7 AND `remaining_quota` = 0;

-- ====================================================================
-- 8. notification - 消息通知表（30 条）
--     类型：0-系统通知, 1-面试邀请, 2-录用通知, 3-淘汰通知
--     is_read: 约一半已读(1)、一半未读(0)
-- ====================================================================

DELETE FROM `notification`;

INSERT INTO `notification` (`id`, `receiver_id`, `sender_id`, `title`, `content`, `type`, `is_read`, `biz_id`, `create_time`) VALUES
-- type=0: 系统通知 8 条（sender_id=NULL）
(1,  10, NULL, '欢迎注册 UniSeek 平台',
 '欢迎您注册UniSeek兼职招聘平台，完善简历后即可投递心仪岗位，祝您早日找到满意的工作！',
 0, 1, NULL, DATE_SUB(NOW(), INTERVAL 27 DAY)),
(2,  11, NULL, '新增物流配送类岗位',
 '平台新增了物流配送类兼职岗位，薪资丰厚、时间灵活，快来看看有没有适合您的吧！',
 0, 0, NULL, DATE_SUB(NOW(), INTERVAL 25 DAY)),
(3,  12, NULL, '简历完善度提醒',
 '您的简历完善度已达到90%，完整度越高越容易被企业HR发现，继续保持哦！',
 0, 1, NULL, DATE_SUB(NOW(), INTERVAL 23 DAY)),
(4,  13, NULL, '设计类岗位专区上线',
 '平台上线了设计类岗位专区，汇集UI设计、平面设计、视频剪辑等优质岗位，推荐您查看。',
 0, 0, NULL, DATE_SUB(NOW(), INTERVAL 21 DAY)),
(5,  14, NULL, '简历更新提醒',
 '系统检测到您的简历可能已过期，建议补充最新工作经历和技能，以提高求职成功率。',
 0, 1, NULL, DATE_SUB(NOW(), INTERVAL 19 DAY)),
(6,  15, NULL, '您已多日未登录',
 '您已连续多日未登录平台，近期有新的教育类兼职岗位上线，快来看看吧！',
 0, 0, NULL, DATE_SUB(NOW(), INTERVAL 17 DAY)),
(7,  17, NULL, '实名认证优惠活动',
 '平台推出实名认证限时优惠活动，完成认证后更有机会获得平台推荐优质岗位，不要错过！',
 0, 1, NULL, DATE_SUB(NOW(), INTERVAL 15 DAY)),
(8,  25, NULL, '感谢使用 UniSeek',
 '感谢您一直以来的信任与支持，我们将持续为您推荐最合适的兼职岗位，祝您工作顺利！',
 0, 0, NULL, DATE_SUB(NOW(), INTERVAL 13 DAY)),

-- type=1: 面试邀请 8 条（sender_id=对应HR）
(9,  10, 2, '【面试邀请】周末餐厅服务员',
 '张小芒您好，味美滋餐饮诚邀您参加周末餐厅服务员岗位面试。时间：本周五下午2点，地点：北京市朝阳区建国路88号味美滋大厦B1层，请携带身份证和简历准时参加。',
 1, 1, 1, DATE_SUB(NOW(), INTERVAL 7 DAY)),
(10, 11, 3, '【面试邀请】外卖配送员',
 '李小明您好，飞速达物流诚邀您参加外卖配送员岗位面试。时间：下周一上午10点，地点：上海市浦东新区陆家嘴环路958号配送站，请携带身份证和驾驶证。',
 1, 1, 5, DATE_SUB(NOW(), INTERVAL 6 DAY)),
(11, 12, 3, '【面试邀请】快递分拣员',
 '王大力您好，飞速达物流诚邀您参加快递分拣员岗位面试。时间：本周三下午3点，地点：上海市浦东新区川沙路5889号分拣中心办公室，请准时到达。',
 1, 0, 9, DATE_SUB(NOW(), INTERVAL 5 DAY)),
(12, 14, 4, '【面试邀请】技术助理',
 '刘志强您好，智汇科技诚邀您参加技术助理岗位面试。时间：下周二上午9:30，地点：深圳市南山区科技园南区智汇大厦8楼会议室，期待您的到来。',
 1, 1, 17, DATE_SUB(NOW(), INTERVAL 2 DAY)),
(13, 15, 5, '【面试邀请】小学陪读老师',
 '陈思雨您好，启航教育诚邀您参加小学陪读老师岗位面试。时间：本周六下午4点，地点：苏州市姑苏区十全街256号启航教育分部，请携带简历。',
 1, 0, 19, DATE_SUB(NOW(), INTERVAL 3 DAY)),
(14, 18, 3, '【面试邀请】快递分拣员',
 '吴昊天您好，飞速达物流诚邀您参加快递分拣员岗位面试。时间：下周四下午2点，地点：上海市浦东新区川沙路5889号分拣中心2楼，请准时参加。',
 1, 1, 28, DATE_SUB(NOW(), INTERVAL 2 DAY)),
(15, 21, 2, '【面试邀请】周末餐厅服务员',
 '林静怡您好，味美滋餐饮诚邀您参加周末餐厅服务员岗位面试。时间：本周日下午3点，地点：北京市朝阳区建国路88号味美滋大厦HR办公室，请提前10分钟到达。',
 1, 0, 37, DATE_SUB(NOW(), INTERVAL 3 DAY)),
(16, 24, 2, '【面试邀请】后厨帮工',
 '马晓峰您好，味美滋餐饮诚邀您参加后厨帮工岗位面试。时间：下周三上午11点，地点：北京市朝阳区望京西路12号味美滋后厨中心，请联系李经理。',
 1, 1, 46, DATE_SUB(NOW(), INTERVAL 2 DAY)),

-- type=2: 录用通知 7 条（sender_id=对应HR）
(17, 10, 2, '【录用通知】周末餐厅服务员',
 '恭喜张小芒！您已通过味美滋餐饮周末餐厅服务员的面试考核，请于下周一上午9点到北京市朝阳区建国路88号味美滋大厦办理入职手续，届时请携带身份证和银行卡。',
 2, 1, 1, DATE_SUB(NOW(), INTERVAL 5 DAY)),
(18, 12, 3, '【录用通知】外卖配送员',
 '恭喜王大力！您已通过飞速达物流外卖配送员的录用审批，请于本周五上午10点到上海市浦东新区陆家嘴环路958号配送站报到，公司会安排入职培训。',
 2, 1, 8, DATE_SUB(NOW(), INTERVAL 6 DAY)),
(19, 13, 6, '【录用通知】短视频剪辑',
 '恭喜赵晓燕！您已通过创艺空间短视频剪辑岗位的录用审批，请于下周二上午9:30到深圳市宝安区设计大厦5层办理入职。',
 2, 0, 13, DATE_SUB(NOW(), INTERVAL 4 DAY)),
(20, 13, 4, '【录用通知】软件测试实习生',
 '恭喜赵晓燕！您已通过智汇科技软件测试实习生岗位的录用审批，请于下周一上午9点到深圳市南山区智汇大厦12楼报到。',
 2, 1, 14, DATE_SUB(NOW(), INTERVAL 3 DAY)),
(21, 15, 5, '【录用通知】初中数学家教',
 '恭喜陈思雨！您已通过启航教育初中数学家教岗位的录用审批，请于本周五下午到苏州市姑苏区干将东路333号启航教育总部签署兼职协议。',
 2, 0, 18, DATE_SUB(NOW(), INTERVAL 5 DAY)),
(22, 20, 2, '【录用通知】后厨帮工',
 '恭喜孙鹏飞！您已通过味美滋后厨帮工岗位的录用审批，请于下周四上午8点到北京市朝阳区望京西路12号味美滋后厨中心报到，包食宿。',
 2, 1, 35, DATE_SUB(NOW(), INTERVAL 4 DAY)),
(23, 19, 4, '【录用通知】技术助理',
 '恭喜郑雅文！您已通过智汇科技技术助理岗位的录用审批，请于下周三上午9:30到深圳市南山区科技园南区智汇大厦8楼办理入职手续。',
 2, 0, 33, DATE_SUB(NOW(), INTERVAL 2 DAY)),

-- type=3: 淘汰通知 7 条（sender_id=对应HR）
(24, 11, 4, '【淘汰通知】软件测试实习生',
 '李小明您好，感谢您参加智汇科技软件测试实习生岗位的面试。经综合评估，您的专业背景与该岗位要求存在一定差距，很遗憾未能通过。建议您关注平台其他更适合您的岗位。',
 3, 1, 7, DATE_SUB(NOW(), INTERVAL 3 DAY)),
(25, 12, 3, '【淘汰通知】仓库管理员',
 '王大力您好，感谢您投递飞速达物流的仓库管理员岗位。由于该岗位已满员，您的申请未能成功。建议您查看我们正在招聘的其他物流岗位。',
 3, 0, 10, DATE_SUB(NOW(), INTERVAL 8 DAY)),
(26, 14, 2, '【淘汰通知】周末餐厅服务员',
 '刘志强您好，感谢您对味美滋餐饮周末餐厅服务员岗位的关注。经过综合评估，您的条件与该岗位的需求不太匹配，期待未来有更合适的合作机会。',
 3, 1, 15, DATE_SUB(NOW(), INTERVAL 4 DAY)),
(27, 15, 9, '【淘汰通知】公众号文案编辑',
 '陈思雨您好，很遗憾地通知您，万象综合服务的公众号文案编辑岗位已招满。您的简历非常优秀，我们已存档，后续有合适岗位会优先联系您。',
 3, 0, 21, DATE_SUB(NOW(), INTERVAL 5 DAY)),
(28, 23, 6, '【淘汰通知】UI设计实习生',
 '何雨桐您好，感谢您投递创艺空间UI设计实习生岗位。经过评审，您的经验与技能与该岗位的要求存在一定差距，很遗憾未能通过筛选。建议您积累更多作品后再次投递。',
 3, 1, 43, DATE_SUB(NOW(), INTERVAL 4 DAY)),
(29, 20, 2, '【淘汰通知】餐厅收银员',
 '孙鹏飞您好，感谢您投递味美滋餐饮的餐厅收银员岗位。由于该岗位已满员，您的申请未能成功。建议您查看我们正在招聘的其他餐饮岗位。',
 3, 0, 36, DATE_SUB(NOW(), INTERVAL 5 DAY)),
(30, 25, 9, '【淘汰通知】展会礼仪接待',
 '唐语嫣您好，很遗憾地通知您，万象综合服务的展会礼仪接待岗位因展会已结束而取消。您的简历非常优秀，后续有合适的展会岗位我们会第一时间联系您。',
 3, 1, 50, DATE_SUB(NOW(), INTERVAL 7 DAY));

-- ====================================================================
-- 9. chat_session - 聊天会话表（15 条）
--     基于 task_application 记录 1:1 创建
-- ====================================================================

DELETE FROM `chat_session`;

INSERT INTO `chat_session` (`id`, `task_application_id`, `employer_id`, `seeker_id`, `last_message`, `last_message_time`, `status`, `create_time`, `update_time`) VALUES
(1,  1,  2,  10, '明天下午2点，到北京市朝阳区建国路88号味美滋大厦B1层找李经理。', DATE_SUB(NOW(), INTERVAL 7 DAY) + INTERVAL 2 DAY, 0, DATE_SUB(NOW(), INTERVAL 8 DAY), NOW()),
(2,  5,  3,  11, '可以日结，每天系统自动结算，次日到账。',                                  DATE_SUB(NOW(), INTERVAL 6 DAY) + INTERVAL 12 HOUR, 0, DATE_SUB(NOW(), INTERVAL 7 DAY), NOW()),
(3,  8,  3,  12, '不客气，已为您安排了配送员的面试，届时详谈。',                              DATE_SUB(NOW(), INTERVAL 8 DAY) + INTERVAL 2 DAY, 0, DATE_SUB(NOW(), INTERVAL 9 DAY), NOW()),
(4,  11, 6,  13, '带一份纸质简历和作品集打印件即可，面试时间我们稍后短信通知。',                DATE_SUB(NOW(), INTERVAL 4 DAY) + INTERVAL 1 DAY, 0, DATE_SUB(NOW(), INTERVAL 5 DAY), NOW()),
(5,  13, 6,  13, '好的，收到，谢谢陈经理！',                                                DATE_SUB(NOW(), INTERVAL 6 DAY) + INTERVAL 2 DAY, 0, DATE_SUB(NOW(), INTERVAL 7 DAY), NOW()),
(6,  16, 4,  14, '很好，我们已经安排了下周的面试，请留意面试通知。',                          DATE_SUB(NOW(), INTERVAL 11 DAY) + INTERVAL 1 DAY, 0, DATE_SUB(NOW(), INTERVAL 12 DAY), NOW()),
(7,  18, 5,  15, '好的，那我们来安排一个试讲面试，本周六上午10点可以吗？',                     DATE_SUB(NOW(), INTERVAL 7 DAY) + INTERVAL 2 DAY, 0, DATE_SUB(NOW(), INTERVAL 8 DAY), NOW()),
(8,  22, 4,  16, '测试组对您的背景很满意，已经安排了面试时间。',                              DATE_SUB(NOW(), INTERVAL 13 DAY) + INTERVAL 2 DAY, 0, DATE_SUB(NOW(), INTERVAL 14 DAY), NOW()),
(9,  25, 7,  17, '那很好，安排您面试通过后可以直接上岗。',                                    DATE_SUB(NOW(), INTERVAL 3 DAY) + INTERVAL 1 DAY, 0, DATE_SUB(NOW(), INTERVAL 4 DAY), NOW()),
(10, 26, 8,  17, '非常好，我们录用您了，请下周一来办理入职手续。',                             DATE_SUB(NOW(), INTERVAL 5 DAY) + INTERVAL 1 DAY, 0, DATE_SUB(NOW(), INTERVAL 6 DAY), NOW()),
(11, 28, 3,  18, '好的，那我安排一个简单的面试，您明天下午方便吗？',                          DATE_SUB(NOW(), INTERVAL 2 DAY) + INTERVAL 1 DAY, 0, DATE_SUB(NOW(), INTERVAL 3 DAY), NOW()),
(12, 32, 5,  19, '主要是简单的英语口语测试和与小朋友的互动环节。',                            DATE_SUB(NOW(), INTERVAL 2 DAY) + INTERVAL 1 DAY, 0, DATE_SUB(NOW(), INTERVAL 3 DAY), NOW()),
(13, 35, 2,  20, '您的态度很好，我们决定录用您，欢迎加入味美滋团队！',                        DATE_SUB(NOW(), INTERVAL 6 DAY) + INTERVAL 1 DAY, 0, DATE_SUB(NOW(), INTERVAL 7 DAY), NOW()),
(14, 37, 2,  21, '好的，那明天下午来面试，具体时间地点HR会发短信给您。',                      DATE_SUB(NOW(), INTERVAL 3 DAY) + INTERVAL 1 DAY, 0, DATE_SUB(NOW(), INTERVAL 4 DAY), NOW()),
(15, 44, 6,  23, '下周一开始可以吗？具体情况入职当天会详细介绍。',                            DATE_SUB(NOW(), INTERVAL 3 DAY) + INTERVAL 1 DAY, 0, DATE_SUB(NOW(), INTERVAL 4 DAY), NOW());

-- ====================================================================
-- 10. chat_message - 聊天消息表（60 条 = 15 会话 × 4 条）
--     每条消息的 sender_id 在 employer_id 和 seeker_id 之间交替
-- ====================================================================

DELETE FROM `chat_message`;

INSERT INTO `chat_message` (`id`, `session_id`, `sender_id`, `message_type`, `content`, `is_read`, `send_time`) VALUES
-- Session 1: employer=2, seeker=10, base=-8d
(1,  1,  10, 0, '您好，我对周末餐厅服务员的职位很感兴趣，请问还在招聘吗？',                         1, DATE_SUB(NOW(), INTERVAL 8 DAY) + INTERVAL 1 HOUR),
(2,  1,  2,  0, '一直在招聘中，您的简历我们已经收到了，方便明天过来面试吗？',                       1, DATE_SUB(NOW(), INTERVAL 8 DAY) + INTERVAL 1 DAY),
(3,  1,  10, 0, '好的，请问明天什么时间方便呢？',                                               1, DATE_SUB(NOW(), INTERVAL 8 DAY) + INTERVAL 1 DAY + INTERVAL 2 HOUR),
(4,  1,  2,  0, '明天下午2点，到北京市朝阳区建国路88号味美滋大厦B1层找李经理。',                   0, DATE_SUB(NOW(), INTERVAL 8 DAY) + INTERVAL 2 DAY),

-- Session 2: employer=3, seeker=11, base=-7d
(5,  2,  11, 0, '请问外卖配送员的工作时间是怎么安排的？',                                         1, DATE_SUB(NOW(), INTERVAL 7 DAY) + INTERVAL 2 HOUR),
(6,  2,  3,  0, '工作时间比较灵活，主要覆盖午高峰和晚高峰时段，您可以自主选择班次。',               1, DATE_SUB(NOW(), INTERVAL 7 DAY) + INTERVAL 6 HOUR),
(7,  2,  11, 0, '那薪资方面是日结还是月结呢？',                                                 1, DATE_SUB(NOW(), INTERVAL 7 DAY) + INTERVAL 8 HOUR),
(8,  2,  3,  0, '可以日结，每天系统自动结算，次日到账。',                                       0, DATE_SUB(NOW(), INTERVAL 6 DAY) + INTERVAL 12 HOUR),

-- Session 3: employer=3, seeker=12, base=-9d
(9,  3,  12, 0, '王经理您好，我有多年仓储管理经验，看到贵司在招外卖配送员。',                     1, DATE_SUB(NOW(), INTERVAL 9 DAY) + INTERVAL 3 HOUR),
(10, 3,  3,  0, '您的经验很丰富，我们非常欢迎。建议您也可以看看仓库管理员的岗位。',                 1, DATE_SUB(NOW(), INTERVAL 9 DAY) + INTERVAL 1 DAY),
(11, 3,  12, 0, '好的，那我两个岗位都了解一下，谢谢您的建议。',                                 1, DATE_SUB(NOW(), INTERVAL 9 DAY) + INTERVAL 1 DAY + INTERVAL 4 HOUR),
(12, 3,  3,  0, '不客气，已为您安排了配送员的面试，届时详谈。',                                 0, DATE_SUB(NOW(), INTERVAL 8 DAY) + INTERVAL 2 DAY),

-- Session 4: employer=6, seeker=13, base=-5d
(13, 4,  13, 0, '陈经理您好，我是赵晓燕，学UI设计的，看到贵司在招平面设计师。',                   1, DATE_SUB(NOW(), INTERVAL 5 DAY) + INTERVAL 1 HOUR),
(14, 4,  6,  0, '您好，您的作品集我们看过了，风格很适合我们公司，欢迎来面试。',                     1, DATE_SUB(NOW(), INTERVAL 5 DAY) + INTERVAL 4 HOUR),
(15, 4,  13, 0, '太好了，请问面试需要准备什么材料吗？',                                         1, DATE_SUB(NOW(), INTERVAL 5 DAY) + INTERVAL 1 DAY),
(16, 4,  6,  0, '带一份纸质简历和作品集打印件即可，面试时间我们稍后短信通知。',                   0, DATE_SUB(NOW(), INTERVAL 4 DAY) + INTERVAL 1 DAY),

-- Session 5: employer=6, seeker=13, base=-7d
(17, 5,  6,  0, '赵晓燕您好，恭喜您通过短视频剪辑岗位的面试，下周可以入职吗？',                   1, DATE_SUB(NOW(), INTERVAL 7 DAY) + INTERVAL 6 HOUR),
(18, 5,  13, 0, '可以的，我下周三就可以入职，需要带什么材料吗？',                               1, DATE_SUB(NOW(), INTERVAL 7 DAY) + INTERVAL 1 DAY),
(19, 5,  6,  0, '带上身份证和银行卡复印件，下周一我会把入职指引发给您。',                         1, DATE_SUB(NOW(), INTERVAL 7 DAY) + INTERVAL 1 DAY + INTERVAL 3 HOUR),
(20, 5,  13, 0, '好的，收到，谢谢陈经理！',                                                   0, DATE_SUB(NOW(), INTERVAL 6 DAY) + INTERVAL 2 DAY),

-- Session 6: employer=4, seeker=14, base=-12d
(21, 6,  14, 0, '张经理您好，我投递了贵公司的技术助理岗位，想了解一下工作内容。',                 1, DATE_SUB(NOW(), INTERVAL 12 DAY) + INTERVAL 2 HOUR),
(22, 6,  4,  0, '您好，技术助理主要是协助技术总监做项目跟踪和技术文档管理。',                     1, DATE_SUB(NOW(), INTERVAL 12 DAY) + INTERVAL 6 HOUR),
(23, 6,  14, 0, '听起来很适合我，我之前在公司做过类似的文档管理工作。',                           1, DATE_SUB(NOW(), INTERVAL 12 DAY) + INTERVAL 1 DAY),
(24, 6,  4,  0, '很好，我们已经安排了下周的面试，请留意面试通知。',                             0, DATE_SUB(NOW(), INTERVAL 11 DAY) + INTERVAL 1 DAY),

-- Session 7: employer=5, seeker=15, base=-8d
(25, 7,  15, 0, '您好，我投了初中数学家教的职位，我有家教经验，希望能得到面试机会。',             1, DATE_SUB(NOW(), INTERVAL 8 DAY) + INTERVAL 3 HOUR),
(26, 7,  5,  0, '您的简历我们看过了，文案策划背景不错，数学功底如何呢？',                         1, DATE_SUB(NOW(), INTERVAL 8 DAY) + INTERVAL 1 DAY),
(27, 7,  15, 0, '我高考数学130分，大学也修过高数课程，辅导初中生完全没问题。',                   1, DATE_SUB(NOW(), INTERVAL 8 DAY) + INTERVAL 1 DAY + INTERVAL 2 HOUR),
(28, 7,  5,  0, '好的，那我们来安排一个试讲面试，本周六上午10点可以吗？',                       0, DATE_SUB(NOW(), INTERVAL 7 DAY) + INTERVAL 2 DAY),

-- Session 8: employer=4, seeker=16, base=-14d
(29, 8,  16, 0, '您好，我投了软件测试实习生岗位，我有Android开发背景，对测试很感兴趣。',          1, DATE_SUB(NOW(), INTERVAL 14 DAY) + INTERVAL 2 HOUR),
(30, 8,  4,  0, '您的简历已经转给测试团队负责人了，有结果会尽快通知您。',                         1, DATE_SUB(NOW(), INTERVAL 14 DAY) + INTERVAL 6 HOUR),
(31, 8,  16, 0, '好的，谢谢，期待贵公司的回复。',                                             1, DATE_SUB(NOW(), INTERVAL 14 DAY) + INTERVAL 1 DAY),
(32, 8,  4,  0, '测试组对您的背景很满意，已经安排了面试时间。',                                 0, DATE_SUB(NOW(), INTERVAL 13 DAY) + INTERVAL 2 DAY),

-- Session 9: employer=7, seeker=17, base=-4d
(33, 9,  17, 0, '赵经理您好，我投了家庭保洁员的岗位，我之前在美容院做过保洁工作。',               1, DATE_SUB(NOW(), INTERVAL 4 DAY) + INTERVAL 1 HOUR),
(34, 9,  7,  0, '您好，您的经验很适合，不过我们的保洁员需要自备交通工具，可以吗？',               1, DATE_SUB(NOW(), INTERVAL 4 DAY) + INTERVAL 3 HOUR),
(35, 9,  17, 0, '我有电动车，完全可以的。',                                                   1, DATE_SUB(NOW(), INTERVAL 4 DAY) + INTERVAL 6 HOUR),
(36, 9,  7,  0, '那很好，安排您面试通过后可以直接上岗。',                                     0, DATE_SUB(NOW(), INTERVAL 3 DAY) + INTERVAL 1 DAY),

-- Session 10: employer=8, seeker=17, base=-6d
(37, 10, 17, 0, '孙经理您好，我学美容护理专业的，想应聘美容导购员的岗位。',                     1, DATE_SUB(NOW(), INTERVAL 6 DAY) + INTERVAL 2 HOUR),
(38, 10, 8,  0, '您好，您的专业背景很匹配，请问之前有做美容导购的经验吗？',                     1, DATE_SUB(NOW(), INTERVAL 6 DAY) + INTERVAL 5 HOUR),
(39, 10, 17, 0, '实习期间在美容会所做过的，对皮肤管理和产品推荐都很熟悉。',                     1, DATE_SUB(NOW(), INTERVAL 6 DAY) + INTERVAL 1 DAY),
(40, 10, 8,  0, '非常好，我们录用您了，请下周一来办理入职手续。',                               0, DATE_SUB(NOW(), INTERVAL 5 DAY) + INTERVAL 1 DAY),

-- Session 11: employer=3, seeker=18, base=-3d
(41, 11, 18, 0, '您好，我是学前端开发的，想应聘贵司的快递分拣员岗位。',                         1, DATE_SUB(NOW(), INTERVAL 3 DAY) + INTERVAL 1 HOUR),
(42, 11, 3,  0, '您好，您的背景很不错，不过分拣员工作比较基础，您确定想做吗？',                 1, DATE_SUB(NOW(), INTERVAL 3 DAY) + INTERVAL 3 HOUR),
(43, 11, 18, 0, '没问题的，我想利用空闲时间兼职，锻炼一下自己。',                             1, DATE_SUB(NOW(), INTERVAL 3 DAY) + INTERVAL 6 HOUR),
(44, 11, 3,  0, '好的，那我安排一个简单的面试，您明天下午方便吗？',                           0, DATE_SUB(NOW(), INTERVAL 2 DAY) + INTERVAL 1 DAY),

-- Session 12: employer=5, seeker=19, base=-3d
(45, 12, 19, 0, '您好，我英语专业八级，投了贵公司的小学陪读老师岗位。',                         1, DATE_SUB(NOW(), INTERVAL 3 DAY) + INTERVAL 2 HOUR),
(46, 12, 5,  0, '您的英语水平非常好，我们正好需要英语特长的小学陪读老师。',                     1, DATE_SUB(NOW(), INTERVAL 3 DAY) + INTERVAL 4 HOUR),
(47, 12, 19, 0, '那太好了，请问面试会考察哪些内容呢？',                                       1, DATE_SUB(NOW(), INTERVAL 3 DAY) + INTERVAL 1 DAY),
(48, 12, 5,  0, '主要是简单的英语口语测试和与小朋友的互动环节。',                             0, DATE_SUB(NOW(), INTERVAL 2 DAY) + INTERVAL 1 DAY),

-- Session 13: employer=2, seeker=20, base=-7d
(49, 13, 20, 0, '李经理您好，我之前做过餐饮管理，想应聘后厨帮工岗位。',                         1, DATE_SUB(NOW(), INTERVAL 7 DAY) + INTERVAL 2 HOUR),
(50, 13, 2,  0, '您好，您有餐饮管理经验，做后厨帮工有些屈才了，不过我们欢迎您的加入。',           1, DATE_SUB(NOW(), INTERVAL 7 DAY) + INTERVAL 5 HOUR),
(51, 13, 20, 0, '没关系的，我想从基层做起，全面了解后厨的运作流程。',                           1, DATE_SUB(NOW(), INTERVAL 7 DAY) + INTERVAL 1 DAY),
(52, 13, 2,  0, '您的态度很好，我们决定录用您，欢迎加入味美滋团队！',                           0, DATE_SUB(NOW(), INTERVAL 6 DAY) + INTERVAL 1 DAY),

-- Session 14: employer=2, seeker=21, base=-4d
(53, 14, 21, 0, '您好，我投了贵店的餐厅服务员岗位，请问还在招人吗？',                           1, DATE_SUB(NOW(), INTERVAL 4 DAY) + INTERVAL 1 HOUR),
(54, 14, 2,  0, '还在招聘中，我们看了您的简历，会计专业的背景很特别，有兴趣做收银岗位吗？',       1, DATE_SUB(NOW(), INTERVAL 4 DAY) + INTERVAL 3 HOUR),
(55, 14, 21, 0, '收银也可以的，我之前在实习的时候用过收银系统，比较熟练。',                     1, DATE_SUB(NOW(), INTERVAL 4 DAY) + INTERVAL 6 HOUR),
(56, 14, 2,  0, '好的，那明天下午来面试，具体时间地点HR会发短信给您。',                         0, DATE_SUB(NOW(), INTERVAL 3 DAY) + INTERVAL 1 DAY),

-- Session 15: employer=6, seeker=23, base=-4d
(57, 15, 23, 0, '陈经理您好，我对短视频剪辑岗位很感兴趣，有2年的剪辑经验。',                      1, DATE_SUB(NOW(), INTERVAL 4 DAY) + INTERVAL 2 HOUR),
(58, 15, 6,  0, '您好，您提供的作品集很不错，我们非常满意，面试已经通过了。',                     1, DATE_SUB(NOW(), INTERVAL 4 DAY) + INTERVAL 4 HOUR),
(59, 15, 23, 0, '太好了，谢谢陈经理！请问什么时候可以开始工作呢？',                             1, DATE_SUB(NOW(), INTERVAL 4 DAY) + INTERVAL 1 DAY),
(60, 15, 6,  0, '下周一开始可以吗？具体情况入职当天会详细介绍。',                             0, DATE_SUB(NOW(), INTERVAL 3 DAY) + INTERVAL 1 DAY);

-- ====================================================================
-- 11. daily_statistics - 运营日报统计表（7 条）
--     最近 7 天的运营日报，数据呈合理波动
-- ====================================================================

DELETE FROM `daily_statistics`;

INSERT INTO `daily_statistics` (`id`, `stat_date`, `new_user_count`, `new_enterprise_count`, `new_task_count`, `new_resume_count`, `new_delivery_count`, `new_interview_count`, `new_entry_count`, `create_time`) VALUES
(1, DATE_SUB(CURDATE(), INTERVAL 1 DAY),  35, 2, 12, 22, 42, 8,  5,  NOW()),
(2, DATE_SUB(CURDATE(), INTERVAL 2 DAY),  28, 1, 8,  18, 35, 6,  3,  NOW()),
(3, DATE_SUB(CURDATE(), INTERVAL 3 DAY),  15, 0, 15, 12, 28, 10, 2,  NOW()),
(4, DATE_SUB(CURDATE(), INTERVAL 4 DAY),  42, 3, 10, 30, 50, 12, 7,  NOW()),
(5, DATE_SUB(CURDATE(), INTERVAL 5 DAY),  22, 1, 6,  15, 20, 4,  1,  NOW()),
(6, DATE_SUB(CURDATE(), INTERVAL 6 DAY),  48, 2, 18, 25, 55, 15, 6,  NOW()),
(7, DATE_SUB(CURDATE(), INTERVAL 7 DAY),  12, 0, 20, 10, 30, 5,  4,  NOW());

-- ====================================================================
-- 12. complaint - 用户投诉处理表（5 条）
--     status: 0-待处理(2条), 1-处理中(1条), 2-已结案(2条)
-- ====================================================================

DELETE FROM `complaint`;

INSERT INTO `complaint` (`id`, `complainant_id`, `target_type`, `target_id`, `type`, `content`, `status`, `handler_id`, `handle_result`, `create_time`, `update_time`) VALUES
(1, 10, 1, 2, 1,
 '投递了飞速达物流的外卖配送员岗位后，一直没有任何回复，打了招聘信息上的联系电话也打不通，体验非常差，希望能给个说法。',
 0, NULL, NULL, DATE_SUB(NOW(), INTERVAL 5 DAY), NOW()),
(2, 14, 1, 1, 2,
 '味美滋餐饮发布的周末餐厅服务员岗位，标注最低120元/天，但实际上只能拿到80元/天，薪资严重不符，涉嫌虚假宣传。',
 2, 1, '经平台运营核实，味美滋餐饮已确认岗位薪资标注存在误差，已要求企业更正薪资信息，并向求职者致歉补偿。投诉人表示接受处理结果。',
 DATE_SUB(NOW(), INTERVAL 10 DAY), NOW()),
(3, 11, 2, 13, 1,
 '在参加面试过程中，求职者赵晓燕态度非常不专业，迟到半小时且没有任何解释，沟通时也不尊重人，严重浪费了我们的时间。',
 0, NULL, NULL, DATE_SUB(NOW(), INTERVAL 3 DAY), NOW()),
(4, 20, 1, 1, 3,
 '在味美滋后厨帮工期间发现工作环境非常差，卫生条件堪忧，存在严重安全隐患，与招聘时描述的完全不符，希望平台介入处理。',
 1, 1, NULL, DATE_SUB(NOW(), INTERVAL 7 DAY), NOW()),
(5, 21, 2, 2, 4,
 '味美滋的HR李经理在沟通中使用不文明用语，说话态度恶劣，让我感到非常不舒服和不受尊重，希望平台能对这种行为进行严肃处理。',
 2, 1, '经核实，该HR在沟通过程中确实存在言辞不当的情况，已对相关HR进行警告教育，并依据平台规则扣除其信用分10分。投诉人对处理结果表示满意。',
 DATE_SUB(NOW(), INTERVAL 8 DAY), NOW());

-- ====================================================================
-- 13. operation_log - 操作日志审计表（20 条）
--     覆盖多种操作类型和目标类型，按时间顺序分布
-- ====================================================================

DELETE FROM `operation_log`;

INSERT INTO `operation_log` (`id`, `operator_id`, `operation_type`, `target_type`, `target_id`, `detail`, `ip_address`, `create_time`) VALUES
(1,  NULL, 'REGISTER',       'USER',        10, '{"registerType":"phone"}',                       '192.168.1.100', DATE_SUB(NOW(), INTERVAL 28 DAY)),
(2,  10,   'SAVE_RESUME',    'USER',        10, '{"updatedFields":["skills","experience"]}',       '192.168.1.101', DATE_SUB(NOW(), INTERVAL 27 DAY)),
(3,  10,   'LOGIN',          'USER',        10, '{}',                                            '192.168.1.101', DATE_SUB(NOW(), INTERVAL 27 DAY)),
(4,  10,   'APPLY',          'APPLICATION', 1,  '{"taskId":1}',                                   '192.168.1.101', DATE_SUB(NOW(), INTERVAL 8 DAY)),
(5,  2,    'LOGIN',          'USER',        2,  '{}',                                            '192.168.1.200', DATE_SUB(NOW(), INTERVAL 8 DAY)),
(6,  2,    'AUDIT_TASK',     'TASK',        1,  '{"fromStatus":0,"toStatus":1}',                  '192.168.1.200', DATE_SUB(NOW(), INTERVAL 10 DAY)),
(7,  2,    'HIRE',           'APPLICATION', 1,  '{"fromStatus":1,"toStatus":3}',                  '192.168.1.200', DATE_SUB(NOW(), INTERVAL 5 DAY)),
(8,  3,    'LOGIN',          'USER',        3,  '{}',                                            '192.168.1.201', DATE_SUB(NOW(), INTERVAL 7 DAY)),
(9,  3,    'AUDIT_TASK',     'TASK',        4,  '{"fromStatus":0,"toStatus":1}',                  '192.168.1.201', DATE_SUB(NOW(), INTERVAL 12 DAY)),
(10, 3,    'HIRE',           'APPLICATION', 8,  '{"fromStatus":1,"toStatus":3}',                  '192.168.1.201', DATE_SUB(NOW(), INTERVAL 6 DAY)),
(11, 4,    'LOGIN',          'USER',        4,  '{}',                                            '192.168.1.202', DATE_SUB(NOW(), INTERVAL 6 DAY)),
(12, 4,    'AUDIT_ENTERPRISE','ENTERPRISE', 3,  '{"fromStatus":0,"toStatus":1}',                  '192.168.1.202', DATE_SUB(NOW(), INTERVAL 23 DAY)),
(13, 5,    'LOGIN',          'USER',        5,  '{}',                                            '192.168.1.203', DATE_SUB(NOW(), INTERVAL 5 DAY)),
(14, 5,    'COMPLETE',       'APPLICATION', 18, '{"fromStatus":3,"toStatus":5}',                  '192.168.1.203', DATE_SUB(NOW(), INTERVAL 3 DAY)),
(15, 11,   'LOGIN',          'USER',        11, '{}',                                            '192.168.1.111', DATE_SUB(NOW(), INTERVAL 7 DAY)),
(16, 11,   'APPLY',          'APPLICATION', 5,  '{"taskId":4}',                                   '192.168.1.111', DATE_SUB(NOW(), INTERVAL 7 DAY)),
(17, 13,   'LOGIN',          'USER',        13, '{}',                                            '192.168.1.113', DATE_SUB(NOW(), INTERVAL 5 DAY)),
(18, 13,   'APPLY',          'APPLICATION', 11, '{"taskId":12}',                                  '192.168.1.113', DATE_SUB(NOW(), INTERVAL 5 DAY)),
(19, 1,    'COMPLAINT',      'COMPLAINT',   2,  '{"fromStatus":0,"toStatus":2}',                  '192.168.1.1',   DATE_SUB(NOW(), INTERVAL 8 DAY)),
(20, 1,    'AUDIT_ENTERPRISE','ENTERPRISE', 6,  '{"fromStatus":0,"toStatus":1,"note":"审核通过"}', '192.168.1.1',   DATE_SUB(NOW(), INTERVAL 2 DAY));

-- ====================================================================
-- 数据量汇总
-- user:               25 条（管理员 1 + 企业 HR 8 + 求职者 16）
-- real_name_auth:     24 条
-- enterprise:         8 条
-- resume:             16 条
-- task:               20 条
-- task_application:   50 条
-- notification:       30 条
-- chat_session:       15 条
-- chat_message:       60 条
-- daily_statistics:   7 条
-- complaint:          5 条
-- operation_log:      20 条
-- 总计: 280 条记录
-- ====================================================================

-- ====================================================================
-- 提交事务，恢复外键检查
-- ====================================================================

COMMIT;

SET FOREIGN_KEY_CHECKS = 1;
