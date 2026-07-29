import importlib.util
p = '.omo/audit/arkts-api/scripts/extract-java-vue-contract.py'
spec = importlib.util.spec_from_file_location('e', p)
e = importlib.util.module_from_spec(spec)
spec.loader.exec_module(e)
print('path', e.find_java_type_file('ApplyRequest'))
print('fields', e.parse_dto_fields('ApplyRequest'))
