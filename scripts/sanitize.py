#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
DOCX 清理脚本
功能：解压 DOCX，清理 word/document.xml 中的不规范 XML 实体和空白，
      然后重新打包为有效的 DOCX 文件。
用法：python scripts/sanitize.py [文件路径]
      如果不指定文件路径，默认清理 uniseek-training-report/UniSeek实训报告.docx
"""

import os
import re
import sys
import shutil
import tempfile
import zipfile
from xml.etree import ElementTree as ET


def sanitize_docx(docx_path):
    """清理 DOCX 文件中的 XML 问题"""
    print(f"正在清理: {docx_path}")

    if not os.path.exists(docx_path):
        print(f"错误: 文件不存在 - {docx_path}")
        return False

    # 创建临时目录
    temp_dir = tempfile.mkdtemp(prefix="docx_sanitize_")

    try:
        # 解压 DOCX
        with zipfile.ZipFile(docx_path, 'r') as zip_ref:
            zip_ref.extractall(temp_dir)

        # 清理 document.xml
        doc_xml_path = os.path.join(temp_dir, "word", "document.xml")
        if os.path.exists(doc_xml_path):
            with open(doc_xml_path, 'r', encoding='utf-8') as f:
                content = f.read()

            # 修复可能的不规范 XML 实体
            # 确保 & 符号正确转义（除已有实体外）
            content = re.sub(r'&amp;', '&', content)
            content = re.sub(r'&(?!(?:amp|lt|gt|quot|apos|#x?[0-9a-fA-F]+);)', '&amp;', content)

            # 移除多余的空白（保留有意义空白）
            content = re.sub(r'>\s+<', '><', content)

            with open(doc_xml_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print("  - word/document.xml 已清理")

        # 验证 XML 格式
        try:
            ET.parse(doc_xml_path)
            print("  - XML 格式验证通过")
        except ET.ParseError as e:
            print(f"  - 警告: XML 解析错误: {e}")
            return False

        # 清理 header/footer XML
        for root_dir, _, files in os.walk(temp_dir):
            for fname in files:
                if fname.endswith('.xml'):
                    fpath = os.path.join(root_dir, fname)
                    with open(fpath, 'r', encoding='utf-8') as f:
                        content = f.read()
                    content = re.sub(r'>\s+<', '><', content)
                    with open(fpath, 'w', encoding='utf-8') as f:
                        f.write(content)

        # 重新打包为 DOCX
        temp_docx = docx_path + ".tmp"
        with zipfile.ZipFile(temp_docx, 'w', zipfile.ZIP_DEFLATED) as zip_out:
            for root_dir, _, files in os.walk(temp_dir):
                for fname in files:
                    fpath = os.path.join(root_dir, fname)
                    arcname = os.path.relpath(fpath, temp_dir)
                    zip_out.write(fpath, arcname)

        # 替换原文件
        shutil.move(temp_docx, docx_path)
        print(f"清理完成: {docx_path}")
        return True

    except Exception as e:
        print(f"错误: {e}")
        return False
    finally:
        # 清理临时目录
        shutil.rmtree(temp_dir, ignore_errors=True)


if __name__ == '__main__':
    # 默认路径
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    default_path = os.path.join(
        base_dir,
        "uniseek-training-report",
        "UniSeek实训报告.docx"
    )

    docx_path = sys.argv[1] if len(sys.argv) > 1 else default_path
    success = sanitize_docx(docx_path)
    sys.exit(0 if success else 1)
