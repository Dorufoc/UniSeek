import json
from pathlib import Path

doc = json.loads(Path('.omo/audit/arkts-api/java-vue-contract.json').read_text(encoding='utf-8'))
for r in doc['matrix']:
    if r['endpoint'] in ('/api/admin/users', '/api/auth/login', '/api/tasks', '/api/applications', '/api/resume/user/{userId}', '/api/auth/logout'):
        print('---', r['httpMethod'], r['endpoint'], 'module', r['module'], 'source', r['sourceOfTruth'], 'vueCall', bool(r['vueCall']))
        print('requestFields', r.get('requestFields'))
        print('responseFields dataType', r['responseFields'].get('dataType'))
