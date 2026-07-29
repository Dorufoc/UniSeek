import re
from pathlib import Path

path = Path('uniseek_java/src/main/java/com/uniseek/dto/ApplyRequest.java')
lines = path.read_text(encoding='utf-8').splitlines()
fields = []
in_comment = False
comment_buf = []
for idx, line in enumerate(lines):
    s = line.strip()
    if s.startswith("/**"):
        in_comment = True
        comment_buf = [line]
        continue
    if in_comment:
        comment_buf.append(line)
        if s.endswith("*/"):
            in_comment = False
        continue
    m = re.match(r'^\s*(?:@\w+\s+)*private\s+(.+?)\s+(\w+)\s*(?:=.*)?;', line)
    print(idx+1, repr(line), bool(m))
    if m:
        fields.append(m.group(2))
    comment_buf = []
print('fields', fields)
