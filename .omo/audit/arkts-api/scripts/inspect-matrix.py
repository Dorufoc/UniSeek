import json, collections
with open('.omo/audit/arkts-api/java-vue-contract.json','r',encoding='utf-8') as f:
    doc=json.load(f)
print('rows', len(doc['matrix']))
print('env', doc['meta']['environment'])
by=collections.defaultdict(list)
for r in doc['matrix']:
    by[(r['module'], r['sourceOfTruth'])].append(r['httpMethod']+' '+r['endpoint'])
for (m,s), eps in sorted(by.items()):
    print(m, s, len(eps), eps[:3])
no_vue=[r for r in doc['matrix'] if r['vueCall'] is None and r['sourceOfTruth']!='out-of-arkts-scope']
print('\nNo vue call count', len(no_vue))
for r in no_vue:
    print(r['module'], r['httpMethod'], r['endpoint'])
print('\nRows with apiMdConflict')
count=0
for r in doc['matrix']:
    if r['apiMdConflict']:
        count+=1
        print(r['module'], r['httpMethod'], r['endpoint'])
print('conflict rows', count)
