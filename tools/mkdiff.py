import difflib, sys, io
base, cur, out, files = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4:]
with io.open(out, 'w', encoding='utf-8', newline='\n') as o:
    for f in files:
        a = io.open(base + '/' + f, encoding='utf-8', errors='replace').read().replace('\r\n','\n').splitlines(True)
        b = io.open(cur + '/' + f, encoding='utf-8', errors='replace').read().replace('\r\n','\n').splitlines(True)
        o.writelines(difflib.unified_diff(a, b, 'a/' + f, 'b/' + f, n=3))
print('ok')
