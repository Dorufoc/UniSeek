#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
只读脚本：从当前工作树提取 Java 可用 API 与 Vue 实际调用矩阵。
产物：.omo/audit/arkts-api/java-vue-contract.json
"""

import json
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
JAVA_SRC = ROOT / "uniseek_java" / "src" / "main" / "java"
VUE_API_DIR = ROOT / "uniseek_vue" / "src" / "api"
OUT_FILE = ROOT / ".omo" / "audit" / "arkts-api" / "java-vue-contract.json"


def run_cmd(cmd):
    try:
        return subprocess.check_output(cmd, shell=True, stderr=subprocess.STDOUT, text=True, timeout=30).strip()
    except Exception as e:
        return f"failed: {e}"


def extract_strings(s):
    return re.findall(r'"([^"]*)"', s)


def strip_annotations(text):
    return re.sub(r'@\w+(?:\([^)]*\))?\s*', '', text).strip()


def split_top_level(text, sep=','):
    """按顶层分隔符拆分字符串，仅考虑 () / [] / {} / <> 的嵌套深度。"""
    parts = []
    depth = 0
    cur = []
    openers = {'(', '<', '[', '{'}
    closers = {')', '>', ']', '}'}
    for ch in text:
        if ch in openers:
            depth += 1
        elif ch in closers and depth > 0:
            depth -= 1
        if ch == sep and depth == 0:
            parts.append(''.join(cur).strip())
            cur = []
        else:
            cur.append(ch)
    if cur:
        parts.append(''.join(cur).strip())
    return parts


def find_java_type_file(type_name):
    for p in JAVA_SRC.rglob(type_name + ".java"):
        return p
    return None


def parse_javadoc_comment(lines, start_idx):
    """向上查找最近的完整 /** ... */ 注释，返回其文本（不含 * 前缀）。"""
    i = start_idx - 1
    comment_lines = []
    while i >= 0:
        ln = lines[i].rstrip()
        if ln.strip().endswith("*/") or comment_lines:
            comment_lines.insert(0, ln)
        if ln.strip().startswith("/**"):
            break
        i -= 1
    if not comment_lines:
        return ""
    text = "\n".join(comment_lines)
    text = re.sub(r'/\*\*', '', text)
    text = re.sub(r'\*/', '', text)
    text = re.sub(r'^\s*\*\s?', '', text, flags=re.MULTILINE)
    return text.strip()


DTO_CACHE = {}


def _clean_comment(lines):
    txt = "\n".join(lines)
    txt = re.sub(r'/\*\*', '', txt)
    txt = re.sub(r'\*/', '', txt)
    txt = re.sub(r'^\s*\*\s?', '', txt, flags=re.MULTILINE)
    return " ".join(txt.split())


def parse_dto_fields(type_name, max_fields=200):
    if type_name in DTO_CACHE:
        return DTO_CACHE[type_name]
    path = find_java_type_file(type_name)
    if not path:
        DTO_CACHE[type_name] = None
        return None
    lines = path.read_text(encoding="utf-8").splitlines()
    fields = []
    pending_comments = []
    in_comment = False
    comment_buf = []
    for idx, line in enumerate(lines):
        s = line.strip()
        if s.startswith("/**"):
            in_comment = True
            comment_buf = [line]
            if s.endswith("*/"):
                pending_comments.append(comment_buf)
                in_comment = False
                comment_buf = []
            continue
        if in_comment:
            comment_buf.append(line)
            if s.endswith("*/"):
                pending_comments.append(comment_buf)
                in_comment = False
                comment_buf = []
            continue
        m = re.match(r'^\s*(?:@\w+\s+)*private\s+(.+?)\s+(\w+)\s*(?:=.*)?;', line)
        if m:
            ftype, name = m.group(1).strip(), m.group(2).strip()
            desc = ""
            if pending_comments:
                desc = _clean_comment(pending_comments[-1])
            constraints = []
            for ann in ("NotBlank", "NotNull", "Size", "Pattern", "Email", "Positive", "Min", "Max", "DateTimeFormat"):
                if re.search(rf'@{ann}\b', line):
                    constraints.append(ann)
            fields.append({
                "name": name,
                "type": ftype,
                "description": desc,
                "constraints": constraints,
                "line": idx + 1,
                "sourceFile": path.as_posix().replace(ROOT.as_posix() + "/", "")
            })
            pending_comments = []
            if len(fields) >= max_fields:
                break
    DTO_CACHE[type_name] = fields or None
    return DTO_CACHE[type_name]


def extract_response_schema(type_str):
    """解析返回类型，生成 responseFields 结构。"""
    s = re.sub(r'\s+', ' ', type_str).strip()
    wrappers = []
    while True:
        m = re.match(r'^(ApiResult|ResponseEntity|PageResult|IPage|List|Set)\s*<(.+)>\s*$', s)
        if not m:
            break
        wrappers.append(m.group(1))
        s = m.group(2).strip()
    if "Map" in s:
        return {"dataType": s, "fields": [], "wrappers": wrappers}
    base = re.sub(r'<.*>', '', s)
    fields = parse_dto_fields(base) if base else None
    return {"dataType": s, "fields": fields or [], "wrappers": wrappers}


def parse_webmvc_public_paths():
    public = {
        "/api/auth/register",
        "/api/auth/login",
        "/api/v1/telemetry",
    }
    cfg = JAVA_SRC / "com" / "uniseek" / "config" / "WebMvcConfig.java"
    if cfg.exists():
        text = cfg.read_text(encoding="utf-8")
        m = re.search(r'excludePathPatterns\s*\((.*?)\)', text, re.DOTALL)
        if m:
            for s in extract_strings(m.group(1)):
                public.add(s)
    intercept = JAVA_SRC / "com" / "uniseek" / "config" / "JwtAuthInterceptor.java"
    if intercept.exists():
        text = intercept.read_text(encoding="utf-8")
        m = re.search(r'WHITE_LIST\s*=\s*Arrays\.asList\s*\((.*?)\)', text, re.DOTALL)
        if m:
            for s in extract_strings(m.group(1)):
                public.add(s)
    return sorted(public)


def is_public_path(path, public_patterns):
    for pat in public_patterns:
        if pat.endswith("/**"):
            if path.startswith(pat[:-2]):
                return True
        elif path.startswith(pat) and pat.endswith("/"):
            if path.startswith(pat):
                return True
        elif path == pat or path.startswith(pat + "/"):
            return True
    return False


def normalize_endpoint(method, path):
    """将端点路径中的动态段统一为 :param，便于 Java 与 Vue 的占位符名称差异对齐。"""
    segs = [s for s in path.split("/") if s]
    norm = []
    for s in segs:
        if s.startswith(("${", "{", ":")):
            norm.append(":param")
        else:
            norm.append(s)
    return method.upper(), tuple(norm)


def _skip_generic(text, start):
    """跳过可选的类型参数 <...>，返回 ')'/表达式之后的位置；未匹配则返回原位置。"""
    i = start
    while i < len(text) and text[i].isspace():
        i += 1
    if i >= len(text) or text[i] != '<':
        return start
    depth = 0
    j = i
    while j < len(text):
        c = text[j]
        if c == '<':
            depth += 1
        elif c == '>':
            depth -= 1
            if depth == 0:
                return j + 1
        j += 1
    return start


def _parse_string_literal(text, start):
    """从 start 开始解析字符串字面量（单/双/反引号），返回 (value, end_index)。"""
    i = start
    while i < len(text) and text[i].isspace():
        i += 1
    if i >= len(text) or text[i] not in '\'"`':
        return None, start
    quote = text[i]
    i += 1
    value_chars = []
    while i < len(text):
        c = text[i]
        if c == quote:
            return ''.join(value_chars), i + 1
        if c == '\\' and i + 1 < len(text):
            value_chars.append(text[i + 1])
            i += 2
            continue
        value_chars.append(c)
        i += 1
    return None, start


def parse_vue_apis():
    """解析 uniseek_vue/src/api/*.ts 中的 request.* 封装，返回按归一化端点的调用列表。"""
    calls = {}
    if not VUE_API_DIR.exists():
        return calls
    export_re = re.compile(
        r'(?s)(?:/\*\*.*?\*/\s*)?export\s+(?:const|async\s+function)\s+(\w+)',
        re.DOTALL
    )
    request_re = re.compile(r'request\.(get|post|put|delete|patch)\b', re.IGNORECASE)
    for f in VUE_API_DIR.glob("*.ts"):
        text = f.read_text(encoding="utf-8")
        exports = list(export_re.finditer(text))
        for idx, exp in enumerate(exports):
            func_name = exp.group(1)
            block_start = exp.start()
            block_end = exports[idx + 1].start() if idx + 1 < len(exports) else len(text)
            block = text[block_start:block_end]
            # 函数块内可能包含多个 request.* 调用
            for rm in request_re.finditer(block):
                method = rm.group(1).upper()
                pos = _skip_generic(block, rm.end())
                # 跳到左括号
                while pos < len(block) and block[pos].isspace():
                    pos += 1
                if pos >= len(block) or block[pos] != '(':
                    continue
                pos += 1
                raw_path, _ = _parse_string_literal(block, pos)
                if raw_path is None:
                    continue
                # 去掉查询字符串；对模板字符串中的动态参数不做展开，按静态部分匹配
                path_part = raw_path.split('?')[0].split('#')[0]
                full_path = path_part if path_part.startswith("/api") else "/api" + path_part
                norm = normalize_endpoint(method, full_path)
                line_no = text[:block_start].count("\n") + 1
                info = {
                    "file": f.as_posix().replace(ROOT.as_posix() + "/", ""),
                    "function": func_name,
                    "line": line_no,
                    "method": method,
                    "endpoint": full_path
                }
                calls.setdefault(norm, []).append(info)
    return calls


def hint_role_from_text(text):
    roles = []
    if re.search(r'超级管理员', text):
        roles.append("role=99")
    if re.search(r'运营管理员|管理员', text) and "role=99" not in text:
        roles.append("role=9+")
    if re.search(r'企业\s*HR|HR|招聘者', text, re.IGNORECASE):
        roles.append("role=1")
    if re.search(r'求职者', text):
        roles.append("role=0")
    return roles


def parse_controller(file_path, public_patterns, vue_calls):
    rows = []
    text = file_path.read_text(encoding="utf-8")
    lines = text.splitlines()

    # 定位 class 声明
    in_class = False
    for idx, line in enumerate(lines):
        if re.search(r'\bclass\s+\w+', line):
            in_class = True
            break

    if not in_class:
        return rows

    # 仅扫描类体（简单处理：从 class 行开始）
    pending_annotations = []
    sig_buffer = None
    sig_start_line = None
    for idx, line in enumerate(lines):
        if not in_class:
            if re.search(r'\bclass\s+\w+', line):
                in_class = True
            continue
        s = line.strip()
        if s.startswith("//"):
            continue
        m_anno = re.match(r'@(GetMapping|PostMapping|PutMapping|DeleteMapping|PatchMapping)(?:\s*\(([^)]*)\))?', s)
        if m_anno:
            if sig_buffer is None:
                pending_annotations.append({
                    "line": idx + 1,
                    "name": m_anno.group(1),
                    "content": m_anno.group(2) or ""
                })
            continue
        # 多行方法签名缓冲
        if sig_buffer is not None:
            sig_buffer += ' ' + s
            # 通过括号深度判断方法签名是否结束，避免被 @RequestParam(...) 等注解内的 ')' 误判
            depth = sig_buffer.count('(') - sig_buffer.count(')')
            if depth <= 0:
                sig = sig_buffer
                method_line = sig_start_line
                sig_buffer = None
                sig_start_line = None
                _process_signature(sig, method_line, pending_annotations, lines, idx, file_path, public_patterns, vue_calls, rows)
                pending_annotations = []
            continue
        # 方法签名检测：包含 ( 且不是注解，不是字段声明结束 ;
        if pending_annotations and '(' in line and not s.startswith('@') and not s.endswith(';'):
            # 统计本行括号深度，若已平衡则为单行签名；否则开启缓冲
            if line.count('(') - line.count(')') <= 0:
                _process_signature(s, idx + 1, pending_annotations, lines, idx, file_path, public_patterns, vue_calls, rows)
                pending_annotations = []
            else:
                sig_buffer = s
                sig_start_line = idx + 1
            continue
    return rows


def _process_signature(sig, method_line, pending_annotations, lines, idx, file_path, public_patterns, vue_calls, rows):
    m_paren = re.search(r'\((.*)\)', sig, re.DOTALL)
    if not m_paren:
        return
    params_text = m_paren.group(1)
    params = split_top_level(params_text, ',')

    bare = strip_annotations(sig[:sig.find('(')])
    for mod in ("public", "private", "protected", "static", "final"):
        bare = re.sub(rf'^{mod}\s+', '', bare)
        bare = re.sub(rf'\s+{mod}\s+', ' ', bare)
    m_name = re.match(r'^(.+?)\s+(\w+)\s*$', bare)
    if not m_name:
        return
    return_type, method_name = m_name.group(1).strip(), m_name.group(2).strip()

    for anno in pending_annotations:
        http_method = {
            "GetMapping": "GET", "PostMapping": "POST",
            "PutMapping": "PUT", "DeleteMapping": "DELETE",
            "PatchMapping": "PATCH"
        }[anno["name"]]
        path_vals = extract_strings(anno["content"])
        method_path = path_vals[0] if path_vals else ""
        if method_path.startswith('/'):
            endpoint = (class_base_for(file_path).rstrip('/') + method_path).rstrip('/')
        else:
            endpoint = (class_base_for(file_path).rstrip('/') + '/' + method_path).rstrip('/')

        # 请求参数
        request_fields = {"path": [], "query": [], "body": [], "multipart": []}
        for p in params:
            if not p.strip():
                continue
            has_body = '@RequestBody' in p
            has_path = '@PathVariable' in p
            rp_match = re.search(r'@RequestParam\s*\(([^)]*)\)', p)
            has_multipart = 'MultipartFile' in p
            stripped = strip_annotations(p)
            parts = stripped.split()
            if len(parts) < 2:
                continue
            ptype, pname = parts[0], parts[-1]
            if has_body:
                dto_fields = parse_dto_fields(ptype.split('<')[0])
                request_fields["body"].append({
                    "type": ptype, "name": pname,
                    "fields": dto_fields or [],
                    "contentType": "application/json"
                })
            elif has_multipart:
                request_fields["multipart"].append({"type": ptype, "name": pname, "contentType": "multipart/form-data"})
            elif rp_match:
                opts = rp_match.group(1)
                defv = re.search(r'defaultValue\s*=\s*"([^"]+)"', opts)
                req = re.search(r'required\s*=\s*(\w+)', opts)
                request_fields["query"].append({
                    "type": ptype, "name": pname,
                    "defaultValue": defv.group(1) if defv else None,
                    "required": req.group(1).lower() == 'true' if req else None
                })
            elif has_path:
                request_fields["path"].append({"type": ptype, "name": pname})
            else:
                if http_method in ("GET", "DELETE"):
                    dto_fields = parse_dto_fields(ptype.split('<')[0])
                    request_fields["query"].append({
                        "type": ptype, "name": pname,
                        "fields": dto_fields or []
                    })
                else:
                    request_fields["body"].append({
                        "type": ptype, "name": pname,
                        "fields": (parse_dto_fields(ptype.split('<')[0]) or []),
                        "contentType": "application/json"
                    })

        response_schema = extract_response_schema(return_type)
        response_fields = response_schema

        auth_required = not is_public_path(endpoint, public_patterns)

        doc_text = parse_javadoc_comment(lines, idx)
        role_hints = hint_role_from_text(doc_text)
        if not role_hints:
            role_hints = hint_role_from_text(method_path + " " + method_name + " " + file_path.name)
        role_constraints = ', '.join(role_hints) if role_hints else '无角色注解；仅 JWT 认证'

        norm = normalize_endpoint(http_method, endpoint)
        vue_matches = vue_calls.get(norm, [])
        vue_call = None
        if vue_matches:
            vm = vue_matches[0]
            vue_call = {
                "file": vm["file"],
                "function": vm["function"],
                "line": vm["line"],
                "endpoint": vm["endpoint"]
            }

        is_admin = endpoint.startswith('/api/admin')
        is_telemetry = endpoint.startswith('/api/v1/telemetry')
        source = "out-of-arkts-scope" if (is_admin or is_telemetry) else "java-source-truth"

        row = {
            "module": module_from_path(file_path, endpoint),
            "endpoint": endpoint,
            "httpMethod": http_method,
            "authRequired": auth_required,
            "roleConstraints": role_constraints if source != "out-of-arkts-scope" else "admin/telemetry 专属",
            "sourceOfTruth": source,
            "javaSource": {
                "file": file_path.as_posix().replace(ROOT.as_posix() + "/", ""),
                "line": method_line,
                "symbol": f"{file_path.stem}.{method_name}"
            },
            "vueCall": vue_call,
            "apiMdConflict": None,
            "requestFields": request_fields,
            "responseFields": response_fields,
            "notes": doc_text.split('\n')[0] if doc_text else ""
        }
        apply_api_md_conflict(row)
        if row["apiMdConflict"] and row["sourceOfTruth"] != "out-of-arkts-scope":
            row["sourceOfTruth"] = "api-md-conflict"
        rows.append(row)


_CLASS_BASE_CACHE = {}


def class_base_for(file_path):
    if file_path in _CLASS_BASE_CACHE:
        return _CLASS_BASE_CACHE[file_path]
    text = file_path.read_text(encoding="utf-8")
    for m in re.finditer(r'@RequestMapping\s*\(([^)]*)\)', text):
        after = text[m.end():]
        # 确保这个注解出现在 class 声明之前
        if re.search(r'\bclass\s+\w+', after):
            vals = extract_strings(m.group(1))
            if vals:
                base = vals[0]
                _CLASS_BASE_CACHE[file_path] = base
                return base
    _CLASS_BASE_CACHE[file_path] = ""
    return ""


def module_from_path(file_path, endpoint):
    name = file_path.stem.replace("Controller", "").replace("Admin", "admin-")
    if endpoint.startswith("/api/admin"):
        return "admin"
    if endpoint.startswith("/api/v1/telemetry"):
        return "telemetry"
    mapping = {
        "Auth": "auth",
        "User": "user",
        "Resume": "resume",
        "Task": "task",
        "Application": "application",
        "Favorite": "favorite",
        "Enterprise": "enterprise",
        "Chat": "chat",
        "Category": "category",
        "Region": "region",
        "Notification": "notification",
        "Upload": "upload",
    }
    return mapping.get(name, name.lower() or "unknown")


def apply_api_md_conflict(row):
    """基于已知的 api.md 与 Java/Vue 不一致点，填充 apiMdConflict。"""
    ep = row["endpoint"]
    conflicts = []

    # 认证登录请求字段
    if ep == "/api/auth/login":
        conflicts.append({
            "field": "requestBody.account",
            "javaValue": "account (LoginRequest)",
            "apiMdValue": "phone",
            "vueValue": "account",
            "description": "api.md 描述登录请求参数为 phone，Java/Vue 实际使用 account 兼容手机号/邮箱"
        })
    # 当前用户信息 token 有效期（额外说明）
    if ep == "/api/auth/current-user":
        conflicts.append({
            "field": "token.ttl",
            "javaValue": "7 天 (JwtUtil.EXPIRATION)",
            "apiMdValue": "30 分钟",
            "description": "JWT 有效期文档与实现不一致"
        })

    # 用户资料更新
    if ep == "/api/user/profile":
        conflicts.append({
            "field": "requestParam.location",
            "javaValue": "@RequestParam nickname/avatarUrl/phone/email (query)",
            "apiMdValue": "Body nickname/avatar",
            "vueValue": "request.put('/user/profile', null, { params })",
            "description": "文档写为 Body，Java/Vue 实际使用 query 参数；avatar 字段名在 Java 为 avatarUrl"
        })

    # 简历
    if ep == "/api/resume" and row["httpMethod"] == "PUT":
        conflicts.append({
            "field": "requestBody.realName",
            "javaValue": "ResumeRequest 不含 realName（服务端从 real_name_auth 取）",
            "apiMdValue": "realName 可选字段",
            "vueValue": "ResumeSaveParams 不含 realName",
            "description": "api.md 请求体包含 realName，Java/Vue 实际不包含"
        })
    if ep == "/api/resume/upload-attachment":
        conflicts.append({
            "field": "responseData.url",
            "javaValue": "{ url: string }",
            "apiMdValue": "{ attachmentUrl: string }",
            "vueValue": "{ url: string }",
            "description": "返回字段名不一致"
        })

    # 职位
    if ep == "/api/tasks" and row["httpMethod"] == "GET":
        conflicts.append({
            "field": "query.status",
            "javaValue": "TaskSearchRequest 无 status 字段",
            "apiMdValue": "status 查询参数",
            "vueValue": "TaskSearchParams 无 status",
            "description": "api.md 支持按职位状态筛选，Java/Vue 当前未实现"
        })
    if re.match(r'^/api/tasks/[^/]+/status$', ep) and row["httpMethod"] == "PUT":
        conflicts.append({
            "field": "requestBody.status/reason",
            "javaValue": "@RequestParam targetStatus (query)",
            "apiMdValue": "Body status + reason",
            "vueValue": "query targetStatus",
            "description": "状态更新参数位置与字段不一致，且无 reason 字段"
        })
    if ep == "/api/enterprise/tasks" and row["httpMethod"] == "GET":
        conflicts.append({
            "field": "query.status",
            "javaValue": "无 status 查询参数",
            "apiMdValue": "status 可选查询参数",
            "vueValue": "未传 status",
            "description": "本企业职位列表缺少状态筛选"
        })

    # 投递
    if ep == "/api/applications/my":
        conflicts.append({
            "field": "query.status",
            "javaValue": "无 status 查询参数",
            "apiMdValue": "status 可选查询参数",
            "vueValue": "未传 status",
            "description": "我的投递列表缺少状态筛选"
        })
    if re.match(r'^/api/tasks/[^/]+/applications$', ep) and row["httpMethod"] == "GET":
        conflicts.append({
            "field": "query.status",
            "javaValue": "无 status 查询参数",
            "apiMdValue": "status 可选查询参数",
            "vueValue": "未传 status",
            "description": "职位投递列表缺少状态筛选"
        })
    if re.match(r'^/api/applications/[^/]+/complete$', ep):
        conflicts.append({
            "field": "requestBody.settlementAmount",
            "javaValue": "CompleteRequest 仅 hrNote",
            "apiMdValue": "仅 hrNote",
            "vueValue": "CompleteApplicationParams 含 settlementAmount?",
            "description": "Vue 接口定义含 settlementAmount，Java 与 api.md 均只处理 hrNote"
        })

    # 消息
    if ep == "/api/messages/unread-count":
        conflicts.append({
            "field": "responseData",
            "javaValue": "Map<String,Integer> { unreadCount }",
            "apiMdValue": "{ totalUnread, systemUnread, interviewUnread, offerUnread, rejectUnread }",
            "vueValue": "同 api.md",
            "description": "未读消息数返回结构与 api.md 不一致"
        })

    # 聊天
    if ep == "/api/chat/sessions" and row["httpMethod"] == "GET":
        conflicts.append({
            "field": "responseData",
            "javaValue": "List<ChatSessionVO>",
            "apiMdValue": "PageResult<ChatSessionVO>",
            "vueValue": "ChatSessionVO[]",
            "description": "会话列表响应类型不一致，且无 page/pageSize 分页参数"
        })
    if re.match(r'^/api/chat/sessions/[^/]+/messages$', ep) and row["httpMethod"] == "GET":
        conflicts.append({
            "field": "responseData",
            "javaValue": "List<ChatMessageVO>",
            "apiMdValue": "{ records, hasMore }",
            "vueValue": "ChatMessageVO[]",
            "description": "聊天历史消息响应结构不一致"
        })
    if re.match(r'^/api/chat/sessions/[^/]+/read$', ep) and row["httpMethod"] == "PUT":
        conflicts.append({
            "field": "responseData",
            "javaValue": "ApiResult<Void>",
            "apiMdValue": "{ affectedCount }",
            "vueValue": "void",
            "description": "标记会话已读响应结构不一致"
        })

    # 收藏：无显式冲突；但在 api.md 汇总表缺失，属于缺失
    if ep.startswith("/api/favorites") and row["sourceOfTruth"] != "out-of-arkts-scope":
        conflicts.append({
            "field": "endpoint.documentation",
            "javaValue": ep,
            "apiMdValue": "api.md 汇总表未列出收藏接口",
            "description": "收藏模块 Controller 已实现且 Vue 已调用，但 api.md 正文中无对应章节"
        })

    if conflicts:
        row["apiMdConflict"] = conflicts


def main():
    public_patterns = parse_webmvc_public_paths()
    vue_calls = parse_vue_apis()

    matrix = []

    controller_dirs = [
        JAVA_SRC / "com" / "uniseek" / "controller",
        JAVA_SRC / "com" / "uniseek" / "user" / "controller",
        JAVA_SRC / "com" / "uniseek" / "upload" / "controller",
        JAVA_SRC / "com" / "uniseek" / "admin" / "controller",
    ]
    for d in controller_dirs:
        if d.exists():
            for f in sorted(d.glob("*.java")):
                matrix.extend(parse_controller(f, public_patterns, vue_calls))

    # 以 Java endpoint 为键建立索引，用于合并 Vue 实际调用
    lookup = {}
    for r in matrix:
        lookup[normalize_endpoint(r["httpMethod"], r["endpoint"])] = r

    for (method, norm), calls in vue_calls.items():
        if not calls:
            continue
        display = calls[0]["endpoint"]
        if norm in lookup:
            lookup[norm]["vueCall"] = {
                "file": calls[0]["file"],
                "function": calls[0]["function"],
                "line": calls[0]["line"],
                "endpoint": display
            }
            continue
        # admin/telemetry 已在 Java 侧标记为 out-of-arkts-scope，此处不再重复生成行
        if display.startswith(("/api/admin", "/api/v1/telemetry")):
            continue
        matrix.append({
            "module": module_from_path(ROOT / calls[0]["file"], display),
            "endpoint": display,
            "httpMethod": method,
            "authRequired": None,
            "roleConstraints": "未在 Java Controller 中定位到注解",
            "sourceOfTruth": "vue-fact-call",
            "javaSource": None,
            "vueCall": {
                "file": calls[0]["file"],
                "function": calls[0]["function"],
                "line": calls[0]["line"],
                "endpoint": display
            },
            "apiMdConflict": None,
            "requestFields": {},
            "responseFields": {},
            "notes": "Vue API 存在但实际未在已扫描的 Java Controller 中找到对应方法，需人工复核"
        })

    # 基于规范化键去重：优先保留 Java 侧来源（含 out-of-arkts-scope/java-source-truth/api-md-conflict）
    dedup = {}
    for r in matrix:
        key = (r["httpMethod"], normalize_endpoint(r["httpMethod"], r["endpoint"]))
        existing = dedup.get(key)
        if existing is None:
            dedup[key] = r
        else:
            # 若已有行为 vue-fact-call 且新行有 Java 来源，替换
            if existing.get("sourceOfTruth") == "vue-fact-call" and existing.get("javaSource") is None and r.get("javaSource") is not None:
                # 保留已有 Vue 调用证据
                if r.get("vueCall") is None and existing.get("vueCall"):
                    r = dict(r)
                    r["vueCall"] = existing["vueCall"]
                dedup[key] = r
    matrix = list(dedup.values())

    # 排序：先按模块，再按 endpoint
    matrix.sort(key=lambda r: (r["module"], r["endpoint"], r["httpMethod"]))

    env = {
        "mvn": run_cmd("mvn -v"),
        "node": run_cmd("node -v"),
        "npm": run_cmd("npm -v"),
    }
    head = run_cmd("git rev-parse HEAD")
    status = run_cmd("git status --short")

    doc = {
        "meta": {
            "baseline-pending": True,
            "gitHead": head,
            "gitStatusSummary": status.splitlines() if status else [],
            "environment": env,
            "generatedAt": datetime.now(timezone.utc).isoformat(),
            "sourceRoots": {
                "java": JAVA_SRC.as_posix().replace(ROOT.as_posix() + "/", ""),
                "vueApi": VUE_API_DIR.as_posix().replace(ROOT.as_posix() + "/", "")
            }
        },
        "matrix": matrix
    }

    OUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    OUT_FILE.write_text(json.dumps(doc, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Wrote {len(matrix)} rows to {OUT_FILE}")


if __name__ == "__main__":
    main()
