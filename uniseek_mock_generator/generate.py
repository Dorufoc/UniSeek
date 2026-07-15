#!/usr/bin/env python3
"""
UniSeek Mock Data Generator - 主编排入口

按顺序调用所有生成器，生成完整的 SQL 文件。
总共生成约 318,000 条记录，覆盖 12 张业务表。

用法:
    python generate.py

输出:
    ../uniseek_mock_data_large.sql
"""

import os
import sys
import time

# 将项目根目录加入 sys.path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from config import (
    NOTIFICATION_COUNT, CHAT_SESSION_COUNT, CHAT_MESSAGE_COUNT,
    COMPLAINT_COUNT, OPERATION_LOG_COUNT,
)
from sql_output import SQLWriter
from generators.user_gen import generate_users
from generators.enterprise_gen import generate_enterprises
from generators.resume_gen import generate_resumes
from generators.task_gen import generate_tasks
from generators.application_gen import generate_applications
from generators.notification_chat_gen import generate_notifications_chat_complaints
from generators.log_stat_gen import generate_operation_logs, generate_daily_statistics


def main():
    """主流程：按依赖顺序依次调用各生成器，最后执行配额更新。"""
    output_path = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "uniseek_mock_data_large.sql",
    )

    print("UniSeek Mock Data Generator")
    print("=" * 50)
    print(f"输出路径: {output_path}")
    print()

    start_time = time.time()

    with SQLWriter(output_path) as writer:
        # =====================================================================
        # Step 1: 按外键依赖逆序 DELETE 已有数据
        # =====================================================================
        # 注意：不删除 category 和 region（种子数据）
        print("Step 1/6: 写入 DELETE 语句...")
        DELETE_ORDER = [
            "chat_message", "chat_session", "notification",
            "task_application", "complaint", "operation_log",
            "daily_statistics", "task", "resume", "enterprise",
            "real_name_auth", "user",
        ]
        writer.write_delete(DELETE_ORDER)

        # =====================================================================
        # Step 2: 生成用户数据（含实名认证）
        # =====================================================================
        print("Step 2/6: 生成用户数据...")
        all_user_ids, seeker_ids, hr_ids, admin_ids = generate_users(writer)
        print(f"  -> {len(all_user_ids)} 个用户, {len(seeker_ids)} 个求职者, "
              f"{len(hr_ids)} 个 HR, {len(admin_ids)} 个管理员")

        # =====================================================================
        # Step 3: 生成企业数据
        # =====================================================================
        print("Step 3/6: 生成企业数据...")
        enterprise_ids, hr_enterprise_map = generate_enterprises(writer, hr_ids)
        print(f"  -> {len(enterprise_ids)} 个企业")

        # =====================================================================
        # Step 4: 生成简历数据
        # =====================================================================
        print("Step 4/6: 生成简历数据...")
        resume_ids, resume_id_map = generate_resumes(writer, seeker_ids)
        print(f"  -> {len(resume_ids)} 份简历")

        # =====================================================================
        # Step 5: 生成岗位数据
        # =====================================================================
        print("Step 5/6: 生成岗位数据...")
        task_ids = generate_tasks(writer, enterprise_ids, hr_enterprise_map)
        print(f"  -> {len(task_ids)} 个岗位")

        # =====================================================================
        # Step 6: 生成投递数据（大规模数据）
        # =====================================================================
        print("Step 5/6: 生成投递数据...")
        app_ids, app_info_list = generate_applications(
            writer, seeker_ids, task_ids, hr_enterprise_map, resume_id_map,
        )
        print(f"  -> {len(app_ids)} 条投递记录")

        # =====================================================================
        # Step 7: 生成通知、聊天会话、聊天消息、投诉
        # =====================================================================
        print("Step 5/6: 生成通知/聊天/投诉数据...")
        # 注意: generate_notifications_chat_complaints 接受一个 user_names 参数
        # 但该参数在函数内部未实际使用，传空字典即可
        generate_notifications_chat_complaints(
            writer, app_info_list, hr_ids, all_user_ids,
            admin_ids, enterprise_ids, {},
        )
        print(f"  -> {NOTIFICATION_COUNT} 条通知, {CHAT_SESSION_COUNT} 个会话, "
              f"{CHAT_MESSAGE_COUNT} 条消息, {COMPLAINT_COUNT} 条投诉")

        # =====================================================================
        # Step 8: 生成操作日志和运营日报
        # =====================================================================
        print("Step 5/6: 生成日志和统计数据...")
        generate_operation_logs(writer, all_user_ids, seeker_ids, hr_ids,
                                admin_ids, app_info_list)
        generate_daily_statistics(writer)
        print(f"  -> {OPERATION_LOG_COUNT} 条操作日志, 365 条运营日报")

        # =====================================================================
        # Step 9: 根据实际录用人数更新 remaining_quota
        # =====================================================================
        print("Step 6/6: 更新剩余配额...")
        writer.write_comment("根据实际录用人数（status=3 或 5）更新剩余招聘配额")
        writer.write_update("""
UPDATE `task` t
SET t.`remaining_quota` = t.`total_quota` - (
    SELECT COALESCE(COUNT(*), 0)
    FROM `task_application` a
    WHERE a.`task_id` = t.`id` AND a.`status` IN (3, 5)
)
        """.strip())

        writer.write_comment("剩余配额归零的岗位标记为已满员")
        writer.write_update("""
UPDATE `task`
SET `status` = 2
WHERE `remaining_quota` <= 0 AND `status` = 1
        """.strip())

        total_rows = writer.get_row_count()

    elapsed = time.time() - start_time

    print()
    print("=" * 50)
    print("生成完成!")
    print(f"写入总行数: {total_rows:,}")
    print(f"输出文件: {output_path}")
    print(f"耗时: {elapsed:.1f}s")
    print("=" * 50)


if __name__ == "__main__":
    main()
