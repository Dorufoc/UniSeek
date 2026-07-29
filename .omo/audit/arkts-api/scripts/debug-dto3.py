from pathlib import Path
path = Path('uniseek_java/src/main/java/com/uniseek/dto/ApplyRequest.java')
lines = path.read_text(encoding='utf-8').splitlines()
for i, ln in enumerate(lines):
    print(i+1, [ord(c) for c in ln[-5:]], repr(ln))
