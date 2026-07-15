# ==============================================================================
# UniSeek 兼职招聘平台 - SQL 输出写入器
# ==============================================================================
# 提供批量 INSERT 支持与自增 ID 管理，每 BATCH_SIZE 行自动 flush。

import os
from config import BATCH_SIZE


class SQLWriter:
    """
    SQL 文件写入器。

    特性：
    - 批量 INSERT，每 BATCH_SIZE 行自动 flush
    - 自增 ID 管理（按表名维护计数器）
    - 事务包裹（START TRANSACTION / COMMIT）
    - 执行前禁用外键检查
    """

    def __init__(self, filepath: str):
        """
        初始化 SQLWriter。

        Args:
            filepath: 输出的 SQL 文件路径
        """
        self.filepath = filepath
        self.file = None
        self._current_table = None
        self._row_count = 0
        self._total_row_count = 0
        self._batch_rows = 0
        self._buffer = []
        self._last_columns = []
        self._id_counters = {}  # table_name -> next_id

    def open(self):
        """打开文件并写入文件头。"""
        self.file = open(self.filepath, 'w', encoding='utf-8')
        self._write_header()
        return self

    def close(self):
        """flush 剩余批次、写入文件尾、关闭文件。"""
        self._flush_batch()
        self._write_footer()
        if self.file:
            self.file.close()

    def __enter__(self):
        self.open()
        return self

    def __exit__(self, *args):
        self.close()

    def _write_header(self):
        """写入 SQL 文件头注释和事务前缀。"""
        self.file.write("-- ====================================================================\n")
        self.file.write("-- UniSeek 兼职招聘平台 - 大规模 Mock 数据\n")
        self.file.write("-- 生成时间: " + __import__('datetime').datetime.now().strftime('%Y-%m-%d %H:%M:%S') + "\n")
        self.file.write("-- 数据量: 约 32 万条\n")
        self.file.write("-- ====================================================================\n\n")
        self.file.write("SET FOREIGN_KEY_CHECKS = 0;\n")
        self.file.write("SET NAMES utf8mb4;\n")
        self.file.write("START TRANSACTION;\n\n")

    def _write_footer(self):
        """写入 SQL 文件尾，恢复外键检查并提交事务。"""
        self.file.write("\nSET FOREIGN_KEY_CHECKS = 1;\n")
        self.file.write("COMMIT;\n")

    def next_id(self, table_name: str) -> int:
        """
        获取指定表的下一个自增 ID。

        Args:
            table_name: 表名

        Returns:
            自增 ID（从 1 开始）
        """
        self._id_counters.setdefault(table_name, 1)
        nid = self._id_counters[table_name]
        self._id_counters[table_name] = nid + 1
        return nid

    def write_delete(self, tables: list):
        """
        按给定顺序写入 DELETE 语句。

        Args:
            tables: 表名列表（按外键依赖逆序排列）
        """
        self.file.write("-- DELETE existing data in reverse FK order\n")
        for table in tables:
            self.file.write(f"DELETE FROM `{table}`;\n")
        self.file.write("\n")

    def begin_insert(self, table: str, columns: list):
        """
        开始一个新的 INSERT 语句。

        Args:
            table: 表名
            columns: 列名列表
        """
        self._flush_batch()
        self._current_table = table
        self._last_columns = columns
        cols_str = ", ".join([f"`{c}`" for c in columns])
        self._buffer = [f"INSERT INTO `{table}` ({cols_str}) VALUES\n"]
        self._row_count = 0
        self._batch_rows = 0

    def add_row(self, values: list):
        """
        向当前 INSERT 添加一行。达到 BATCH_SIZE 时自动 flush。

        Args:
            values: 值列表，支持 int / float / str / None 类型
        """
        if self._batch_rows >= BATCH_SIZE:
            self._flush_batch()
            cols_str = ", ".join([f"`{c}`" for c in self._last_columns])
            self._buffer = [f"INSERT INTO `{self._current_table}` ({cols_str}) VALUES\n"]
            self._batch_rows = 0

        prefix = "" if self._batch_rows == 0 else ",\n"

        escaped = []
        for v in values:
            if v is None:
                escaped.append("NULL")
            elif isinstance(v, int):
                escaped.append(str(v))
            elif isinstance(v, float):
                escaped.append(f"{v:.7f}")
            elif isinstance(v, str):
                # 转义单引号和反斜杠
                ev = v.replace("\\", "\\\\").replace("'", "\\'")
                escaped.append(f"'{ev}'")
            else:
                escaped.append(f"'{str(v)}'")

        self._buffer.append(f"{prefix}({', '.join(escaped)})")
        self._row_count += 1
        self._total_row_count += 1
        self._batch_rows += 1

    def _flush_batch(self):
        """将当前 INSERT 缓冲区写入文件。"""
        if self._buffer and self._batch_rows > 0:
            self._buffer.append(";\n")
            for chunk in self._buffer:
                self.file.write(chunk)
            self._buffer = []
            self._batch_rows = 0
            self.file.flush()  # 大文件写入时及时落盘

    def write_update(self, sql: str):
        """
        写入原生 UPDATE SQL。

        Args:
            sql: UPDATE 语句（不包含分号）
        """
        self._flush_batch()
        self.file.write(sql + ";\n\n")

    def get_row_count(self) -> int:
        """返回已写入的总行数（跨所有表累计）。"""
        return self._total_row_count

    def write_comment(self, comment: str):
        """写入 SQL 注释。"""
        self._flush_batch()
        self.file.write(f"-- {comment}\n")
