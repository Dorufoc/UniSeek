import re
from pathlib import Path

text = Path('uniseek_vue/src/api/application.ts').read_text(encoding='utf-8')
pattern = re.compile(
    r'(?s)(?:/\*\*.*?\*/\s*)?export\s+(?:const|async\s+function)\s+(\w+)[^;]*?(?:await\s+)?request\.(get|post|put|delete|patch)'
    r'(?:<[^<>]*(?:<[^<>]*>)*[^<>]*>)?\s*\(\s*([\'"`])([^\'"`]*?)\3',
    re.DOTALL
)
for m in pattern.finditer(text):
    print(m.group(1), m.group(2), repr(m.group(4)))
