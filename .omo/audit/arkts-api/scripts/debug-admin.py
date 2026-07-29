import sys, re, importlib.util
from pathlib import Path
script = Path(__file__).resolve().parent / 'extract-java-vue-contract.py'
spec = importlib.util.spec_from_file_location('extract', script)
e = importlib.util.module_from_spec(spec)
spec.loader.exec_module(e)
p=Path(__file__).resolve().parents[4]/'uniseek_java/src/main/java/com/uniseek/admin/controller/AdminUserController.java'
print('file exists', p.exists())
public=e.parse_webmvc_public_paths()
vue=e.parse_vue_apis()
rows=e.parse_controller(p, public, vue)
for r in rows:
    print(r['httpMethod'], r['endpoint'], r['javaSource']['symbol'])
print('---')
p2=Path(__file__).resolve().parents[4]/'uniseek_java/src/main/java/com/uniseek/admin/controller/AdminEnterpriseController.java'
rows2=e.parse_controller(p2, public, vue)
for r in rows2:
    print(r['httpMethod'], r['endpoint'], r['javaSource']['symbol'])
