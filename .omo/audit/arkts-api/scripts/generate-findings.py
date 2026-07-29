import json
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
MATRIX_FILE = ROOT / ".omo" / "audit" / "arkts-api" / "java-vue-contract.json"
OUT_FILE = ROOT / ".omo" / "audit" / "arkts-api" / "java-vue-findings.json"

doc = json.loads(MATRIX_FILE.read_text(encoding="utf-8"))
matrix = doc["matrix"]

findings = {
    "generatedAt": doc["meta"]["generatedAt"],
    "totalRows": len(matrix),
    "sourceOfTruth": defaultdict(int),
    "noJavaSource": [],
    "noVueCall": [],
    "apiMdConflicts": [],
    "dtoParseFailures": [],
}

for row in matrix:
    findings["sourceOfTruth"][row["sourceOfTruth"]] += 1
    if row["sourceOfTruth"] == "vue-fact-call" and not row.get("javaSource"):
        findings["noJavaSource"].append({
            "module": row["module"],
            "method": row["httpMethod"],
            "endpoint": row["endpoint"],
            "vueFile": row.get("vueCall", {}).get("file"),
            "vueFunction": row.get("vueCall", {}).get("function"),
            "line": row.get("vueCall", {}).get("line"),
        })
    if row.get("vueCall") is None and row["sourceOfTruth"] != "out-of-arkts-scope":
        findings["noVueCall"].append({
            "module": row["module"],
            "method": row["httpMethod"],
            "endpoint": row["endpoint"],
            "javaSource": row.get("javaSource"),
        })
    if row.get("apiMdConflict"):
        for conflict in row["apiMdConflict"]:
            findings["apiMdConflicts"].append({
                "module": row["module"],
                "method": row["httpMethod"],
                "endpoint": row["endpoint"],
                "conflict": conflict,
            })
    # 收集 DTO 未解析的 body 项
    for part in ("body", "query"):
        for f in row.get("requestFields", {}).get(part, []):
            if f.get("type") in (None, ""):
                continue
            if f.get("fields") == [] and f.get("type") not in ("int", "Integer", "long", "Long", "String", "boolean", "Boolean", "MultipartFile"):
                findings["dtoParseFailures"].append({
                    "module": row["module"],
                    "endpoint": row["endpoint"],
                    "part": part,
                    "name": f.get("name"),
                    "type": f.get("type"),
                })

findings["sourceOfTruth"] = dict(findings["sourceOfTruth"])
OUT_FILE.write_text(json.dumps(findings, ensure_ascii=False, indent=2), encoding="utf-8")
print(f"Wrote findings to {OUT_FILE}")
print(json.dumps({k: len(v) if isinstance(v, list) else v for k, v in findings.items() if k != "generatedAt"}, ensure_ascii=False, indent=2))
