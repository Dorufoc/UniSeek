import re
from pathlib import Path

text = Path('uniseek_java/src/main/java/com/uniseek/admin/controller/AdminUserController.java').read_text(encoding='utf-8')
lines = text.splitlines()
pending = []
sig_buffer = None
for idx, line in enumerate(lines):
    s = line.strip()
    if re.match(r'@(GetMapping|PostMapping|PutMapping|DeleteMapping|PatchMapping)(?:\s*\(([^)]*)\))?', s):
        m = re.match(r'@(GetMapping|PostMapping|PutMapping|DeleteMapping|PatchMapping)(?:\s*\(([^)]*)\))?', s)
        pending.append({'name':m.group(1),'content':m.group(2) or ''})
        continue
    if sig_buffer is not None:
        sig_buffer += ' ' + s
        if ')' in line:
            sig = sig_buffer
            print('FOUND SIG', sig[:200])
            print('PENDING', pending)
            m_paren = re.search(r'\((.*)\)', sig, re.DOTALL)
            if m_paren:
                params_text = m_paren.group(1)
                print('PARAMS_TEXT', repr(params_text[:300]))
                # split
                parts = []
                depth=0; cur=[]
                openers={'(','<','[','{'}; closers={')','>',']','}'}
                for ch in params_text:
                    if ch in openers: depth+=1
                    elif ch in closers and depth>0: depth-=1
                    if ch==',' and depth==0:
                        parts.append(''.join(cur).strip()); cur=[]
                    else:
                        cur.append(ch)
                if cur: parts.append(''.join(cur).strip())
                print('SPLIT COUNT', len(parts))
                for p in parts:
                    print('P', p)
            sig_buffer=None; pending=[]
        continue
    if pending and '(' in line and not s.startswith('@') and not s.endswith(';'):
        if ')' in line:
            print('SINGLE LINE SIG', s)
        else:
            sig_buffer = s
            print('START BUFFER', s)
