import json
from pathlib import Path

doc = json.loads(Path('.omo/audit/arkts-api/java-vue-contract.json').read_text(encoding='utf-8'))
samples = [
    ('POST', '/api/applications'),
    ('POST', '/api/auth/login'),
    ('POST', '/api/tasks'),
    ('PUT', '/api/tasks/{id}'),
    ('GET', '/api/tasks'),
    ('PUT', '/api/resume'),
]
for method, endpoint in samples:
    for r in doc['matrix']:
        if r['httpMethod'] == method and r['endpoint'] == endpoint:
            body_fields = r['requestFields'].get('body', [])
            query_fields = r['requestFields'].get('query', [])
            print(f"{method} {endpoint}: body={[(f['type'], len(f.get('fields', []))) for f in body_fields]}, query={[(f['type'], len(f.get('fields', []))) for f in query_fields]}")
            break
