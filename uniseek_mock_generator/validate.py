#!/usr/bin/env python3
"""
UniSeek Mock Data Validator - SQL 文件独立验证器

在不需要 MySQL 的情况下验证生成的 SQL 文件正确性。
检查项：行数校验、唯一约束校验、外键引用完整性校验。

用法:
    python validate.py [sql_file_path]

默认 SQL 文件: ../uniseek_mock_data_large.sql
"""

import os
import re
import sys
from collections import defaultdict
from typing import Any, Dict, List, Optional, Set, Tuple


# =============================================================================
# 配置：各表的预期行数及约束定义
# =============================================================================

TABLE_CONFIG: Dict[str, Dict[str, Any]] = {
    "user": {"count": 8000, "unique": ["phone", "email"]},
    "real_name_auth": {"count": 7000, "unique": ["user_id", "id_card"]},
    "enterprise": {"count": 400, "unique": ["user_id", "credit_code"]},
    "resume": {"count": 7000, "unique": ["user_id"]},
    "task": {"count": 5000, "unique": []},
    "task_application": {"count": 80000, "unique": ["task_id,applicant_id"]},
    "notification": {"count": 60000, "unique": []},
    "chat_session": {"count": 25000, "unique": ["task_application_id"]},
    "chat_message": {"count": 100000, "unique": []},
    "operation_log": {"count": 25000, "unique": []},
    "daily_statistics": {"count": 365, "unique": ["stat_date"]},
}

# 外键约束定义：(子表列名, 父表名, 父表列名)
FK_CONSTRAINTS: Dict[str, List[Tuple[str, str, str]]] = {
    "real_name_auth": [
        ("user_id", "user", "id"),
    ],
    "enterprise": [
        ("user_id", "user", "id"),
    ],
    "resume": [
        ("user_id", "user", "id"),
    ],
    "task": [
        ("enterprise_id", "enterprise", "id"),
    ],
    "task_application": [
        ("task_id", "task", "id"),
        ("applicant_id", "user", "id"),
        ("hr_id", "user", "id"),
    ],
    "notification": [
        ("receiver_id", "user", "id"),
        ("sender_id", "user", "id"),
    ],
    "chat_session": [
        ("task_application_id", "task_application", "id"),
        ("employer_id", "user", "id"),
        ("seeker_id", "user", "id"),
    ],
    "chat_message": [
        ("session_id", "chat_session", "id"),
        ("sender_id", "user", "id"),
    ],
    "operation_log": [
        ("operator_id", "user", "id"),
    ],
}

# 允许的行数偏差比例
COUNT_TOLERANCE = 0.05  # ±5%


# =============================================================================
# SQL 解析器
# =============================================================================

def _strip_outer_parens(s: str) -> str:
    """去除最外层的一对括号（如果存在）。"""
    s = s.strip()
    if s.startswith("(") and s.endswith(")"):
        # 需要确保括号是匹配的
        depth = 0
        for i, ch in enumerate(s):
            if ch == "(":
                depth += 1
            elif ch == ")":
                depth -= 1
                if depth == 0 and i < len(s) - 1:
                    # 括号提前闭合，说明不是外层括号
                    return s
        return s[1:-1]
    return s


def _split_values_by_commas(row_str: str) -> List[str]:
    """按逗号分割一行值，同时尊重单引号内的逗号。

    Args:
        row_str: 一行值的字符串（已去除外层括号）

    Returns:
        拆分后的值列表
    """
    values: List[str] = []
    current: List[str] = []
    in_single_quote = False
    in_double_quote = False
    i = 0
    while i < len(row_str):
        ch = row_str[i]
        if ch == "'" and not in_double_quote:
            # 处理转义的单引号
            if i + 1 < len(row_str) and row_str[i + 1] == "'":
                current.append(ch)
                current.append(row_str[i + 1])
                i += 2
                continue
            in_single_quote = not in_single_quote
            current.append(ch)
        elif ch == '"' and not in_single_quote:
            in_double_quote = not in_double_quote
            current.append(ch)
        elif ch == "," and not in_single_quote and not in_double_quote:
            values.append("".join(current).strip())
            current = []
        else:
            current.append(ch)
        i += 1
    # 添加最后一个值
    if current:
        values.append("".join(current).strip())
    return values


def _parse_sql_value(raw: str) -> Any:
    """将 SQL 字面量解析为 Python 对象。

    Args:
        raw: SQL 值字符串，如 '123', 'hello', NULL, '{"a":1}'

    Returns:
        解析后的 Python 对象（int, str, None, float）
    """
    raw = raw.strip()
    if raw.upper() == "NULL":
        return None
    if raw.startswith("'") and raw.endswith("'"):
        # 去除外层引号，并处理转义
        inner = raw[1:-1]
        inner = inner.replace("\\'", "'").replace("\\\\", "\\")
        return inner
    if raw.startswith('"') and raw.endswith('"'):
        inner = raw[1:-1]
        return inner
    # 尝试解析为数字
    try:
        if "." in raw:
            return float(raw)
        return int(raw)
    except ValueError:
        return raw


# =============================================================================
# SQL 文件解析
# =============================================================================

def parse_sql_file(filepath: str) -> Dict[str, Dict[str, Any]]:
    """解析 SQL 文件，提取每个表的 INSERT 数据。

    Args:
        filepath: SQL 文件路径

    Returns:
        嵌套字典: {
            "user": {
                "columns": ["id", "phone", ...],
                "rows": [[1, 13900000001, ...], [2, ...], ...]
            },
            ...
        }
    """
    if not os.path.isfile(filepath):
        print(f"错误: 文件不存在 - {filepath}")
        sys.exit(1)

    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    tables_data: Dict[str, Dict[str, Any]] = {}
    pos = 0
    content_len = len(content)

    while pos < content_len:
        # 查找下一个 INSERT INTO
        insert_pos = content.find("INSERT INTO `", pos)
        if insert_pos == -1:
            break

        # 提取表名
        start = insert_pos + len("INSERT INTO `")
        end = content.find("`", start)
        if end == -1:
            break
        table_name = content[start:end].lower()
        pos = end + 1

        # 跳过空白，找到列名左括号
        while pos < content_len and content[pos] in " \t\r\n":
            pos += 1
        if pos >= content_len or content[pos] != "(":
            continue

        # 提取列名（在括号内）
        paren_depth = 1
        pos += 1
        cols_buf: List[str] = []
        in_sq = False
        while pos < content_len and paren_depth > 0:
            ch = content[pos]
            if ch == "'":
                in_sq = not in_sq
                cols_buf.append(ch)
            elif ch == "(" and not in_sq:
                paren_depth += 1
                if paren_depth > 1:
                    cols_buf.append(ch)
            elif ch == ")" and not in_sq:
                paren_depth -= 1
                if paren_depth > 0:
                    cols_buf.append(ch)
            else:
                cols_buf.append(ch)
            pos += 1

        columns_str = "".join(cols_buf)
        columns = [c.strip().strip("`") for c in columns_str.split(",")]

        # 跳过空白找到 VALUES
        while pos < content_len and content[pos] in " \t\r\n":
            pos += 1

        # 确认 VALUES 关键字
        if not content[pos:].upper().startswith("VALUES"):
            continue
        pos += 6  # 跳过 "VALUES"

        # 跳过空白，找到第一行数据
        while pos < content_len and content[pos] in " \t\r\n":
            pos += 1

        # 按行解析数据（跟踪括号深度和引号状态）
        rows: List[List[Any]] = []
        paren_depth = 0
        in_sq = False
        row_buf: List[str] = []
        started = False

        while pos < content_len:
            ch = content[pos]

            # 处理引号内的内容
            if ch == "'":
                in_sq = not in_sq
                if started:
                    row_buf.append(ch)
                pos += 1
                continue

            if in_sq:
                if started:
                    row_buf.append(ch)
                pos += 1
                continue

            # 不在引号内
            if ch == "(" and paren_depth == 0:
                started = True
                paren_depth = 1
                row_buf = []
            elif ch == "(":
                paren_depth += 1
                row_buf.append(ch)
            elif ch == ")":
                paren_depth -= 1
                if paren_depth == 0:
                    # 行结束
                    row_str = "".join(row_buf)
                    if row_str.strip():
                        row_values = _split_values_by_commas(row_str)
                        parsed = [_parse_sql_value(v) for v in row_values]
                        rows.append(parsed)
                    started = False
                    # 看看下一个字符是否是分号（INSERT 结束）
                    next_pos = pos + 1
                    while next_pos < content_len and content[next_pos] in " \t\r\n":
                        next_pos += 1
                    if next_pos < content_len and content[next_pos] in ";,":
                        if content[next_pos] == ";":
                            pos = next_pos + 1
                            break
                        # 逗号：继续下一行
                        pos = next_pos + 1
                        continue
                else:
                    row_buf.append(ch)
            else:
                if started:
                    row_buf.append(ch)

            pos += 1

        # 累加或创建表数据
        if table_name in tables_data:
            tables_data[table_name]["rows"].extend(rows)
        else:
            tables_data[table_name] = {
                "columns": columns,
                "rows": rows,
            }

    return tables_data


# =============================================================================
# 验证函数
# =============================================================================

def validate_row_counts(tables_data: Dict) -> List[str]:
    """验证每张表的行数是否在目标值的 ±5% 范围内。

    Args:
        tables_data: 解析后的表数据

    Returns:
        错误信息列表（空表示全部通过）
    """
    errors: List[str] = []
    total_rows = 0

    for table, config in TABLE_CONFIG.items():
        if table not in tables_data:
            errors.append(f"[行数] {table}: 未找到任何数据")
            continue
        actual = len(tables_data[table]["rows"])
        expected = config["count"]
        total_rows += actual
        lower = int(expected * (1 - COUNT_TOLERANCE))
        upper = int(expected * (1 + COUNT_TOLERANCE))
        if actual < lower or actual > upper:
            errors.append(
                f"[行数] {table}: {actual} 行, 预期 {expected} 行 "
                f"(允许范围 {lower}-{upper}) - 失败"
            )
        else:
            print(f"  [行数] {table}: {actual} 行, 预期 {expected} 行 - 通过")

    print(f"  [行数] 总计: {total_rows} 行")
    return errors


def validate_unique_constraints(tables_data: Dict) -> List[str]:
    """验证每张表的唯一约束。

    对 TABLE_CONFIG 中 unique 非空的列，检查是否有重复值。
    复合约束用逗号分隔列名，如 "task_id,applicant_id"。

    Args:
        tables_data: 解析后的表数据

    Returns:
        错误信息列表
    """
    errors: List[str] = []

    for table, config in TABLE_CONFIG.items():
        unique_cols = config.get("unique", [])
        if not unique_cols:
            continue
        if table not in tables_data:
            continue

        columns = tables_data[table]["columns"]
        rows = tables_data[table]["rows"]

        for constraint in unique_cols:
            # 支持复合约束: "col1,col2"
            col_names = [c.strip() for c in constraint.split(",")]
            # 查找各列的索引
            col_indices: List[int] = []
            for col_name in col_names:
                try:
                    col_indices.append(columns.index(col_name))
                except ValueError:
                    errors.append(
                        f"[唯一约束] {table}: 找不到列 '{col_name}'"
                    )
                    continue

            if len(col_indices) != len(col_names):
                continue

            if len(col_indices) == 1:
                idx = col_indices[0]
                values = [row[idx] for row in rows if row[idx] is not None]
                if len(values) != len(set(values)):
                    dup_count = len(values) - len(set(values))
                    errors.append(
                        f"[唯一约束] {table}.{col_names[0]}: "
                        f"发现 {dup_count} 个重复值 - 失败"
                    )
                else:
                    print(
                        f"  [唯一约束] {table}.{col_names[0]}: "
                        f"{len(values)} 个唯一值 - 通过"
                    )
            else:
                # 复合约束：用元组组合多个列的值
                tuples = []
                for row in rows:
                    key = tuple(row[i] for i in col_indices)
                    if None not in key:
                        tuples.append(key)
                if len(tuples) != len(set(tuples)):
                    dup_count = len(tuples) - len(set(tuples))
                    col_str = ",".join(col_names)
                    errors.append(
                        f"[唯一约束] {table}.({col_str}): "
                        f"发现 {dup_count} 个重复组合 - 失败"
                    )
                else:
                    col_str = ",".join(col_names)
                    print(
                        f"  [唯一约束] {table}.({col_str}): "
                        f"{len(tuples)} 个唯一组合 - 通过"
                    )

    return errors


def validate_fk_references(tables_data: Dict) -> List[str]:
    """验证外键引用完整性。

    检查每个 FK 约束中，子表的外键值是否都存在于父表的主键列中。

    Args:
        tables_data: 解析后的表数据

    Returns:
        错误信息列表
    """
    errors: List[str] = []

    # 先建立所有父表的主键值集合
    pk_values: Dict[str, Set[Any]] = {}
    for table_name, data in tables_data.items():
        columns = data["columns"]
        rows = data["rows"]
        try:
            id_idx = columns.index("id")
        except ValueError:
            continue
        pk_values[table_name] = {row[id_idx] for row in rows}

    # 检查每个外键
    for child_table, constraints in FK_CONSTRAINTS.items():
        if child_table not in tables_data:
            errors.append(
                f"[外键] {child_table}: 未找到数据，跳过 FK 检查"
            )
            continue

        columns = tables_data[child_table]["columns"]
        rows = tables_data[child_table]["rows"]

        for fk_col, parent_table, pk_col in constraints:
            # 查找子表外键列索引
            try:
                fk_idx = columns.index(fk_col)
            except ValueError:
                errors.append(
                    f"[外键] {child_table}.{fk_col}: 找不到该列 - 失败"
                )
                continue

            # 获取父表的主键集合
            parent_pks = pk_values.get(parent_table, set())

            # 检查每个 FK 值
            missing_refs: Set[Any] = set()
            null_count = 0
            for row in rows:
                fk_val = row[fk_idx]
                if fk_val is None:
                    null_count += 1
                    continue
                if fk_val not in parent_pks:
                    missing_refs.add(fk_val)

            total_checked = len(rows) - null_count
            if missing_refs:
                errors.append(
                    f"[外键] {child_table}.{fk_col} → {parent_table}.{pk_col}: "
                    f"{len(missing_refs)} 个值找不到引用 "
                    f"(共 {total_checked} 个非空值) - 失败"
                )
            else:
                print(
                    f"  [外键] {child_table}.{fk_col} → {parent_table}.{pk_col}: "
                    f"{total_checked} 个引用全部有效 - 通过"
                )

    return errors


def validate_update_statements(filepath: str) -> List[str]:
    """验证 UPDATE 语句是否存在。

    Args:
        filepath: SQL 文件路径

    Returns:
        错误信息列表
    """
    errors: List[str] = []
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    # 检查 remaining_quota 更新
    if "UPDATE `task` t" in content and "remaining_quota" in content:
        print("  [UPDATE] remaining_quota 更新语句 - 通过")
    else:
        errors.append("[UPDATE] 未找到 remaining_quota 更新语句 - 失败")

    # 检查 status = 2 更新
    if "SET `status` = 2" in content:
        print("  [UPDATE] 满员标记更新语句 - 通过")
    else:
        errors.append("[UPDATE] 未找到满员标记更新语句 - 失败")

    return errors


# =============================================================================
# 主入口
# =============================================================================

def main():
    """执行所有验证检查并输出报告。"""
    # 确定 SQL 文件路径
    if len(sys.argv) > 1:
        sql_path = sys.argv[1]
    else:
        sql_path = os.path.join(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
            "uniseek_mock_data_large.sql",
        )

    print(f"UniSeek Mock Data Validator")
    print(f"{'=' * 50}")
    print(f"SQL 文件: {sql_path}")
    print()

    # Step 1: 解析 SQL 文件
    print("Step 1/4: 解析 SQL 文件...")
    tables_data = parse_sql_file(sql_path)
    print(f"  发现 {len(tables_data)} 张表: {', '.join(sorted(tables_data.keys()))}")
    print()

    # Step 2: 验证行数
    print("Step 2/4: 验证行数...")
    count_errors = validate_row_counts(tables_data)
    print()

    # Step 3: 验证唯一约束
    print("Step 3/4: 验证唯一约束...")
    unique_errors = validate_unique_constraints(tables_data)
    print()

    # Step 4: 验证外键引用
    print("Step 4/4: 验证外键引用...")
    fk_errors = validate_fk_references(tables_data)
    print()

    # Step 5: 验证 UPDATE 语句
    print("Step 5/5: 验证 UPDATE 语句...")
    update_errors = validate_update_statements(sql_path)
    print()

    # =========================================================================
    # 汇总报告
    # =========================================================================
    all_errors = count_errors + unique_errors + fk_errors + update_errors
    total_checks = (
        len(TABLE_CONFIG)  # 行数检查
        + sum(len(cfg.get("unique", [])) for cfg in TABLE_CONFIG.values())  # 唯一约束
        + sum(len(fks) for fks in FK_CONSTRAINTS.values())  # 外键
        + 2  # UPDATE 语句
    )
    passed = total_checks - len(all_errors)

    print(f"{'=' * 50}")
    print(f"验证报告")
    print(f"{'=' * 50}")
    print(f"通过: {passed}/{total_checks}")

    if all_errors:
        print(f"失败: {len(all_errors)}/{total_checks}")
        print()
        print("错误详情:")
        for i, err in enumerate(all_errors, 1):
            print(f"  {i}. {err}")
    else:
        print("所有检查全部通过!")

    print(f"{'=' * 50}")

    # 返回退出码
    return 1 if all_errors else 0


if __name__ == "__main__":
    sys.exit(main())
